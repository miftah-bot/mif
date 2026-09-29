import { INestApplication, ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { ConfigService } from '@nestjs/config';
import { randomUUID } from 'crypto';
import { ApiRateLimiter } from './api-rate-limiter';
import { CommonApiExceptionFilter } from './common-api-exception.filter';
import { AppModule } from './app.module';
import { MetricsService } from './observability/metrics.service';
import { OperationalLoggerService } from './observability/operational-logger.service';
import { createRequestObservabilityMiddleware } from './observability/request-observability.middleware';
import express from 'express';

export async function createConfiguredApp(): Promise<INestApplication> {
  const app = await NestFactory.create(AppModule, { cors: false, bodyParser: false });
  app.use(express.json({ limit: '256kb' }));
  app.use(express.urlencoded({ extended: false, limit: '64kb' }));
  app.enableShutdownHooks();
  app.use(createRequestObservabilityMiddleware(app.get(MetricsService), app.get(OperationalLoggerService)));
  app.getHttpAdapter().getInstance().disable('x-powered-by');

  const config = app.get(ConfigService);
  const apiRateLimiter = new ApiRateLimiter({
    windowMs: Number(config.get('API_RATE_LIMIT_WINDOW_MS') ?? 60_000),
    limit: Number(config.get('API_RATE_LIMIT_PER_WINDOW') ?? 240),
    maxBuckets: Number(config.get('API_RATE_LIMIT_MAX_KEYS') ?? 20_000),
  });

  app.use((req: any, res: any, next: any) => {
    const incoming = typeof req.headers['x-request-id'] === 'string' ? req.headers['x-request-id'].slice(0, 128) : '';
    const requestId = incoming || randomUUID();
    req.requestId = requestId;
    res.setHeader('X-Request-Id', requestId);
    res.setHeader('X-Content-Type-Options', 'nosniff');
    res.setHeader('X-Frame-Options', 'DENY');
    res.setHeader('Referrer-Policy', 'no-referrer');
    res.setHeader('Permissions-Policy', 'camera=(), microphone=(), geolocation=()');
    res.setHeader('Cache-Control', 'no-store');
    if (config.get('NODE_ENV') === 'production') {
      res.setHeader('Strict-Transport-Security', 'max-age=31536000; includeSubDomains');
    }

    const requestPath = String(req.originalUrl ?? req.url ?? '');
    if (req.method !== 'OPTIONS' && !requestPath.startsWith('/api/v1/health')) {
      const key = String(req.socket?.remoteAddress ?? req.ip ?? 'unknown').slice(0, 128);
      const result = apiRateLimiter.consume(key);
      res.setHeader('X-RateLimit-Limit', String(result.limit));
      res.setHeader('X-RateLimit-Remaining', String(result.remaining));
      if (!result.allowed) {
        res.setHeader('Retry-After', String(result.retryAfterSeconds));
        return res.status(429).json({
          error: {
            code: 'RATE_LIMITED',
            message: 'Too many requests; try again later',
            details: { retryAfterSeconds: result.retryAfterSeconds },
            requestId,
          },
        });
      }
    }
    next();
  });

  const origins = (config.get('APP_ORIGINS') ?? '').split(',').map(x => x.trim()).filter(Boolean);
  app.setGlobalPrefix('api/v1');
  app.enableCors({ origin: origins.length ? origins : false, credentials: true });
  app.useGlobalPipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }));
  app.useGlobalFilters(new CommonApiExceptionFilter());
  return app;
}
