const REQUIRED = [
  'DATABASE_URL',
  'JWT_ACCESS_SECRET',
  'PLATFORM_ADMIN_KEY',
  'RECOVERY_DELIVERY_WEBHOOK_SECRET',
  'HEALTH_METRICS_KEY',
];

const failures = [];

const present = (name) => {
  const value = process.env[name];
  return typeof value === 'string' && value.trim().length > 0;
};

for (const name of REQUIRED) {
  if (present(name)) console.log(`PASS ${name} is configured`);
  else failures.push(`${name} is missing or empty`);
}

const databaseUrl = process.env.DATABASE_URL?.trim();
if (databaseUrl) {
  try {
    const parsed = new URL(databaseUrl);
    if (parsed.protocol !== 'postgresql:' && parsed.protocol !== 'postgres:') {
      failures.push('DATABASE_URL must use postgresql:// or postgres://');
    } else if (!parsed.hostname) {
      failures.push('DATABASE_URL must include a hostname');
    } else {
      console.log(`PASS DATABASE_URL is a valid ${parsed.protocol} URL`);
    }
  } catch {
    failures.push('DATABASE_URL is not a valid URL');
  }
}

const nodeEnv = process.env.NODE_ENV;
if (nodeEnv === 'production') console.log('PASS NODE_ENV=production');
else failures.push('NODE_ENV must be production');

for (const [name, expected] of [
  ['JWT_ISSUER', 'distributor-platform'],
  ['JWT_AUDIENCE', 'distributor-mobile'],
  ['RECOVERY_DELIVERY_MODE', 'webhook'],
]) {
  if (process.env[name] === expected) console.log(`PASS ${name}=${expected}`);
  else failures.push(`${name} must equal ${expected}`);
}

for (const name of ['RECOVERY_DELIVERY_WEBHOOK_URL']) {
  const value = process.env[name]?.trim();
  if (!value) failures.push(`${name} is missing or empty`);
  else {
    try {
      const parsed = new URL(value);
      if (parsed.protocol !== 'https:') failures.push(`${name} must use HTTPS`);
      else console.log(`PASS ${name} is an HTTPS URL`);
    } catch {
      failures.push(`${name} is not a valid URL`);
    }
  }
}

if (failures.length) {
  for (const failure of failures) console.error(`FAIL ${failure}`);
  process.exit(1);
}

console.log('Production configuration preflight: PASS');
