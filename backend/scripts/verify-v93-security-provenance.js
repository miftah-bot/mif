const fs=require('node:fs'); const path=require('node:path'); const crypto=require('node:crypto');
const root=path.resolve(__dirname,'..'); const f=path.join(root,'.release','v93-security-provenance.json');
if(!fs.existsSync(f)){console.error('BLOCKED V93 provenance: artifact missing');process.exit(2)}
const pkg=JSON.parse(fs.readFileSync(path.join(root,'package.json'),'utf8')); const x=JSON.parse(fs.readFileSync(f,'utf8'));
if(x.release!==pkg.version){console.error('FAIL V93 provenance release mismatch');process.exit(1)}
for(const [rel,want] of Object.entries(x.files||{})){const abs=path.join(root,rel);const got=fs.existsSync(abs)?crypto.createHash('sha256').update(fs.readFileSync(abs)).digest('hex'):null;if(got!==want){console.error('FAIL provenance hash '+rel);process.exit(1)}}
console.log('V93 security provenance: PASS');
