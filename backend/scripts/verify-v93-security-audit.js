const fs=require('node:fs'); const path=require('node:path');
const root=path.resolve(__dirname,'..'); const read=f=>fs.readFileSync(f,'utf8');
const pkg=JSON.parse(read(path.join(root,'package.json'))); const schema=read(path.join(root,'prisma','schema.prisma')); const factory=read(path.join(root,'src','app-factory.ts'));
const checks=[]; const add=(n,p)=>checks.push({n,p:Boolean(p)});
add('Node 22 engine',pkg.engines?.node==='22.x'); add('Committed lockfile',fs.existsSync(path.join(root,'package-lock.json')));
add('Tenant-safe authorization relation',/fields:\s*\[tenantId, userId\][\s\S]*references:\s*\[tenantId, id\]/.test(schema));
add('Auth session revocation',/revokedAt\s+DateTime\?/.test(schema)); add('CORS allowlist',/origin: origins\.length \? origins : false/.test(factory));
add('Rate limiter',/new ApiRateLimiter\(/.test(factory)); add('Security headers',['X-Content-Type-Options','X-Frame-Options','Strict-Transport-Security'].every(h=>factory.includes(h)));
add('SBOM evidence present',fs.existsSync(path.join(root,'.release','dependency-sbom-v93.cdx.json')));
add('npm audit evidence present',fs.existsSync(path.join(root,'.release','npm-audit-v93.json')));
const auditPath=path.join(root,'.release','npm-audit-v93.json');
if(fs.existsSync(auditPath)){try{const a=JSON.parse(read(auditPath)); const vulns=Object.values(a.vulnerabilities||{}); const blocking=vulns.filter(v=>['high','critical'].includes(String(v.severity).toLowerCase())); add('No high/critical npm audit findings',blocking.length===0,blocking.map(v=>v.name+':'+v.severity).join(', '));}catch(e){add('npm audit evidence is valid JSON',false,e.message)}}
for(const c of checks) console.log((c.p?'PASS':'FAIL')+' '+c.n);
console.log('V93 security audit: '+(checks.every(c=>c.p)?'PASS':'FAIL')); process.exit(checks.every(c=>c.p)?0:1);
