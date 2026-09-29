const fs = require('node:fs');
const path = require('node:path');
const { execFileSync } = require('node:child_process');

const backendRoot = path.resolve(__dirname, '..');
const repoRoot = path.resolve(backendRoot, '..');
const lockPath = path.join(backendRoot, 'package-lock.json');

if (!fs.existsSync(lockPath)) {
  console.error('Committed lockfile: BLOCKED — backend/package-lock.json is missing.');
  process.exit(2);
}

try {
  const tracked = execFileSync(
    'git',
    ['ls-files', '--error-unmatch', 'backend/package-lock.json'],
    { cwd: repoRoot, encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] },
  ).trim();
  if (tracked !== 'backend/package-lock.json') throw new Error('unexpected tracked path');
  console.log('Committed lockfile: PASS — backend/package-lock.json exists and is tracked.');
} catch {
  console.error('Committed lockfile: BLOCKED — backend/package-lock.json exists but is not tracked by git.');
  process.exit(2);
}
