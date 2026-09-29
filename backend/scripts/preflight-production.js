const REQUIRED=['DATABASE_URL','JWT_ACCESS_SECRET','PLATFORM_ADMIN_KEY','RECOVERY_DELIVERY_WEBHOOK_SECRET','HEALTH_METRICS_KEY'];
const fail=[]; for(const k of REQUIRED) if(!process.env[k]) fail.push(k);
if(process.env.NODE_ENV!=='production') fail.push('NODE_ENV=production');
const url=process.env.DATABASE_URL||'';
if(url && !/^postgres(?:ql):\/\/[^\s]+$/.test(url)) fail.push('DATABASE_URL valid PostgreSQL URL');
if(process.env.JWT_ISSUER!=='distributor-platform') fail.push('JWT_ISSUER=distributor-platform');
if(process.env.JWT_AUDIENCE!=='distributor-mobile') fail.push('JWT_AUDIENCE=distributor-mobile');
if(process.env.RECOVERY_DELIVERY_MODE!=='webhook') fail.push('RECOVERY_DELIVERY_MODE=webhook');
const webhook=process.env.RECOVERY_DELIVERY_WEBHOOK_URL||'';
if(webhook && !/^https:\/\//.test(webhook)) fail.push('RECOVERY_DELIVERY_WEBHOOK_URL=https://...');
if(fail.length){console.error('Production configuration preflight: BLOCKED'); for(const x of fail) console.error(' - '+x); process.exit(2)}
console.log('Production configuration preflight: PASS'); console.log('All required production variables and invariants are present.');
