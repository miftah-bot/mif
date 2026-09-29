const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const pkg = JSON.parse(fs.readFileSync(path.join(root, 'package.json'), 'utf8'));

function fail(message) {
  console.error(`Dependency contract: FAIL - ${message}`);
  process.exit(1);
}

if (pkg.engines?.node !== '22.x') fail(`Node engine must remain 22.x, found ${pkg.engines?.node ?? 'missing'}`);
const packageLock = path.join(root, 'package-lock.json');
if (fs.existsSync(packageLock)) {
  let lock;
  try { lock = JSON.parse(fs.readFileSync(packageLock, 'utf8')); }
  catch { fail('package-lock.json is not valid JSON'); }
  if (!Number.isInteger(lock.lockfileVersion)) fail('package-lock.json has no valid lockfileVersion');
  const rootEntry = lock.packages?.[''];
  if (!rootEntry || typeof rootEntry !== 'object') fail('package-lock.json is missing its root package entry');
  if (rootEntry.name && rootEntry.name !== pkg.name) fail(`lockfile package name ${rootEntry.name} does not match ${pkg.name}`);
  if (rootEntry.version && rootEntry.version !== pkg.version) fail(`lockfile package version ${rootEntry.version} does not match ${pkg.version}`);
  if (rootEntry.engines?.node && rootEntry.engines.node !== pkg.engines.node) fail('lockfile Node engine differs from package.json');
  console.log(`Dependency contract: PASS (lockfileVersion=${lock.lockfileVersion}, package=${pkg.name}@${pkg.version})`);
  process.exit(0);
}

console.log('Dependency contract: BLOCKED - backend/package-lock.json is not present.');
console.log('Generate it in a network-enabled Node 22 environment and commit the reviewed result.');
process.exit(2);
