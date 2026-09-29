const fs = require('node:fs');
const path = require('node:path');
const pkg = require('../package.json');

const backendRoot = path.resolve(__dirname, '..');
const repoRoot = path.resolve(backendRoot, '..');
const read = (file) => fs.readFileSync(path.join(repoRoot, file), 'utf8');
const build = fs.readFileSync(path.join(repoRoot, 'RELEASE_BUILD'), 'utf8').trim();
const runtime = read('.github/workflows/runtime-gate.yml');
const production = read('.github/workflows/production-gate.yml');
const mobile = read('mobile/pubspec.yaml');
const checks = [];
const check = (name, pass) => checks.push([name, Boolean(pass)]);

check('package version is 0.104.0', pkg.version === '0.104.0');
check('root VERSION is 0.104.0', fs.readFileSync(path.join(repoRoot, 'VERSION'), 'utf8').trim() === '0.104.0');
check('backend VERSION matches package', fs.readFileSync(path.join(backendRoot, 'VERSION'), 'utf8').trim() === pkg.version);
check('release build is 104', build === '104');
check('mobile version is 0.104.0+104', /^version:\s*0\.104\.0\+104$/m.test(mobile));
check('production workflow listens to runtime-gate workflow_run', /workflow_run:\s*[\s\S]*workflows:\s*\[runtime-gate\][\s\S]*types:\s*\[completed\]/.test(production));
check('production workflow grants actions read', /permissions:\s*[\s\S]*actions:\s*read/.test(production));
check('promotion job runs only for successful runtime-gate', production.includes("if: ${{ github.event_name == 'workflow_run' && github.event.workflow_run.conclusion == 'success' }}"));
check('current-release-contract does not run on workflow_run', production.includes("  current-release-contract:\n    if: ${{ github.event_name != 'workflow_run' }}"));
check('production-config does not run on workflow_run', production.includes("  production-config:\n    if: ${{ github.event_name != 'workflow_run' }}"));
check('backend does not run on workflow_run', production.includes("  backend:\n    if: ${{ github.event_name != 'workflow_run' }}"));
check('mobile does not run on workflow_run', production.includes("  mobile:\n    if: ${{ github.event_name != 'workflow_run' }}"));
check('release-decision does not run on workflow_run', production.includes("  release-decision:\n    if: ${{ github.event_name != 'workflow_run' && always() }}"));
check('promotion job checks out triggering head SHA', /ref:\s*\$\{\{\s*github\.event\.workflow_run\.head_sha\s*\}\}/.test(production));
check('promotion job downloads exact runtime certification artifact', production.includes('distributor-runtime-release-certification-${{ github.event.workflow_run.head_sha }}') && production.includes('run-id: ${{ github.event.workflow_run.id }}') && production.includes('github-token: ${{ github.token }}'));
check('promotion job passes triggering workflow metadata to verifier', production.includes('PROMOTION_RUN_ID: ${{ github.event.workflow_run.id }}') && production.includes('PROMOTION_HEAD_SHA: ${{ github.event.workflow_run.head_sha }}') && production.includes('PROMOTION_CONCLUSION: ${{ github.event.workflow_run.conclusion }}'));
check('promotion job invokes runtime promotion verifier', production.includes('npm run verify:runtime-promotion'));
check('promotion job independently verifies tracked lockfile', production.includes('git ls-files --error-unmatch backend/package-lock.json'));
check('runtime gate still uploads current certification', runtime.includes('distributor-runtime-release-certification-${{ github.sha }}'));
check('aggregate verification chains use V104', ['verify:all','verify:ci','verify:runtime','verify:release'].every(k => (pkg.scripts[k] || '').includes('npm run verify:v104') && !(pkg.scripts[k] || '').includes('npm run verify:v103')));
check('runtime promotion script is present', pkg.scripts['verify:runtime-promotion'] === 'node scripts/verify-runtime-promotion.js');

for (const [name, pass] of checks) console.log(`${pass ? 'PASS' : 'FAIL'} ${name}`);
if (!checks.every(([,pass]) => pass)) process.exit(1);
console.log(`V104 runtime promotion contract: PASS — ${checks.length}/${checks.length} checks.`);
