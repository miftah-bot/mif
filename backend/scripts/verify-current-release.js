const fs = require('node:fs');
const path = require('node:path');

const backendRoot = path.resolve(__dirname, '..');
const repoRoot = path.resolve(backendRoot, '..');
const pkg = JSON.parse(fs.readFileSync(path.join(backendRoot, 'package.json'), 'utf8'));
const rootVersion = fs.readFileSync(path.join(repoRoot, 'VERSION'), 'utf8').trim();
const backendVersion = fs.readFileSync(path.join(backendRoot, 'VERSION'), 'utf8').trim();
const releaseBuild = fs.readFileSync(path.join(repoRoot, 'RELEASE_BUILD'), 'utf8').trim();
const mobileText = fs.readFileSync(path.join(repoRoot, 'mobile/pubspec.yaml'), 'utf8');
const mobileVersion = (mobileText.match(/^version:\s*(.+)$/m) || [])[1] || '';
const read = (file) => fs.readFileSync(path.join(repoRoot, file), 'utf8');

const semver = /^0\.(\d+)\.0$/;
const versionMatch = pkg.version.match(semver);
const buildNumber = Number(versionMatch?.[1]);
const expectedMobileVersion = `${pkg.version}+${releaseBuild}`;
const expectedLabel = `V${releaseBuild}`;
const expectedDb = `distributor_platform_test_v${releaseBuild}`;
const expectedRestoreDb = `distributor_restore_smoke_v${releaseBuild}`;
const checks = [];
const check = (name, pass) => checks.push([name, Boolean(pass)]);

check('package version is valid current semver shape', Number.isInteger(buildNumber) && buildNumber > 0);
check('root VERSION matches package', rootVersion === pkg.version);
check('backend VERSION matches package', backendVersion === pkg.version);
check('RELEASE_BUILD matches package version', releaseBuild === String(buildNumber));
check('mobile version/build are aligned', mobileVersion === expectedMobileVersion);

const readme = read('README.md');
check('README title uses current release label', readme.startsWith(`# OmniDev Distributor Platform — ${expectedLabel}\n`));
check('README root version is current', readme.includes(`- Root: ${pkg.version}`));
check('README backend version is current', readme.includes(`- Backend: ${pkg.version}`));
check('README mobile version is current', readme.includes(`- Mobile: ${expectedMobileVersion}`));
check('README release build is current', readme.includes(`- Release build: ${releaseBuild}`));
check('README uses generic current-release verifier', readme.includes('npm run verify:current-release'));

for (const key of ['verify:all', 'verify:ci', 'verify:runtime', 'verify:release']) {
  const script = pkg.scripts[key] || '';
  check(`package ${key} promotes generic current-release verifier`, script.includes('npm run verify:current-release') && !script.includes('npm run verify:v101'));
}

for (const file of ['.github/workflows/runtime-gate.yml', '.github/workflows/production-gate.yml']) {
  const text = read(file);
  check(`${file} invokes generic current-release verifier`, text.includes('npm run verify:current-release'));
  check(`${file} uses current disposable DB namespace`, text.includes(expectedDb));
  check(`${file} uses current restore DB namespace`, text.includes(expectedRestoreDb));
}

const activeWorkflows = ['.github/workflows/runtime-gate.yml', '.github/workflows/production-gate.yml'];
const stale = [];
for (const file of activeWorkflows) {
  const text = read(file);
  for (const token of ['verify:v101', 'distributor_platform_test_v101', 'distributor_restore_smoke_v101', 'V101 release contract', 'V101 release closure contract']) {
    if (text.includes(token)) stale.push(`${file}: ${token}`);
  }
}
check('active workflows have no V101 current-release references', stale.length === 0);

for (const [name, pass] of checks) console.log(`${pass ? 'PASS' : 'FAIL'} ${name}`);
if (!checks.every(([, pass]) => pass)) {
  if (stale.length) stale.forEach((x) => console.log(`- stale ${x}`));
  process.exit(1);
}
console.log(`Current release identity contract: PASS — ${checks.length}/${checks.length} checks.`);
