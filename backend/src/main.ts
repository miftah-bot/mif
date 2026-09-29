import { ConfigService } from '@nestjs/config';
import { createConfiguredApp } from './app-factory';

async function bootstrap() {
  const app = await createConfiguredApp();
  const config = app.get(ConfigService);
  const port = Number(config.get('PORT') ?? 3000);
  await app.listen(port, '0.0.0.0');
}
bootstrap().catch(error => {
  console.error('Fatal bootstrap error', error);
  process.exit(1);
});