const fs=require('node:fs'); const path=require('node:path'); const crypto=require('node:crypto');
const root=path.resolve(__dirname,'..'); const out=path.join(root,'.release'); fs.mkdirSync(out,{recursive:true});
const files=[path.join(root,'package.json'),path.join(root,'package-lock.json'),path.join(root,'prisma/schema.prisma')];
const sha=f=>fs.existsSync(f)?crypto.createHash('sha256').update(fs.readFileSync(f)).digest('hex'):null;
const pkg=JSON.parse(fs.readFileSync(path.join(root,'package.json'),'utf8'));
const provenance={schemaVersion:1,release:pkg.version,generatedAt:new Date().toISOString(),node:process.version,files:Object.fromEntries(files.map(f=>[path.relative(root,f),sha(f)])),ci:{githubRunId:process.env.GITHUB_RUN_ID||null,githubSha:process.env.GITHUB_SHA||null}};
fs.writeFileSync(path.join(out,'v93-security-provenance.json'),JSON.stringify(provenance,null,2)+'\n'); console.log(JSON.stringify(provenance,null,2));
if(!provenance.files['package-lock.json']) process.exitCode=2;
