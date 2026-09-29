const fs = require('node:fs');
const path = require('node:path');

const backendRoot = path.resolve(__dirname, '..');
const repoRoot = path.resolve(backendRoot, '..');
const pkg = JSON.parse(fs.readFileSync(path.join(backendRoot, 'package.json'), 'utf8'));
const artifactRoot = process.env.RUNTIME_CERT_ARTIFACT_ROOT
  ? path.resolve(repoRoot, process.env.RUNTIME_CERT_ARTIFACT_ROOT)
  : path.join(repoRoot, 'runtime-cert-artifact');
const expectedWorkflow = process.env.PROMOTION_WORKFLOW_NAME || 'runtime-gate';
const expectedRunId = process.env.PROMOTION_RUN_ID || '';
const expectedSha = process.env.PROMOTION_HEAD_SHA || '';
const expectedConclusion = process.env.PROMOTION_CONCLUSION || '';

const errors = [];
const blocked = [];
function fail(msg) { errors.push(msg); }
function block(msg) { blocked.push(msg); }

if (process.env.GITHUB_EVENT_NAME !== 'workflow_run') {
  block('promotion verifier requires workflow_run event context');
}
if (!expectedRunId) block('triggering runtime-gate run ID missing');
if (!expectedSha) block('triggering runtime-gate head SHA missing');
if (expectedWorkflow !== 'runtime-gate') fail(`unexpected promotion workflow name: ${expectedWorkflow}`);
if (expectedConclusion && expectedConclusion !== 'success') block(`runtime-gate conclusion=${expectedConclusion}`);

function findCertification(root) {
  if (!fs.existsSync(root)) return [];
  const found = [];
  const stack = [root];
  while (stack.length) {
    const current = stack.pop();
    for (const entry of fs.readdirSync(current, { withFileTypes: true })) {
      const full = path.join(current, entry.name);
      if (entry.isDirectory()) stack.push(full);
      else if (entry.isFile() && entry.name === 'release-certification-current.json') found.push(full);
    }
  }
  return found;
}

const candidates = findCertification(artifactRoot);
if (candidates.length === 0) {
  block('runtime certification artifact missing');
} else if (candidates.length !== 1) {
  fail(`expected exactly one runtime certification artifact, found ${candidates.length}`);
}

let cert = null;
if (candidates.length === 1) {
  try { cert = JSON.parse(fs.readFileSync(candidates[0], 'utf8')); }
  catch { fail('runtime certification artifact is invalid JSON'); }
}

if (cert) {
  if (cert.schemaVersion !== 1) fail('runtime certification schemaVersion must be 1');
  if (cert.status !== 'PASS') block(`runtime certification status=${cert.status}`);
  if (cert.release?.version !== pkg.version) fail('runtime certification release version mismatch');
  if (cert.ci?.githubActions !== true) fail('runtime certification is not marked as GitHub Actions evidence');
  if (expectedRunId && cert.ci?.runId !== expectedRunId) fail('runtime certification run ID mismatch');
  if (expectedSha && cert.ci?.sha !== expectedSha) fail('runtime certification source SHA mismatch');
  if (cert.upstream?.backendRuntime !== 'success') block(`backend runtime result=${cert.upstream?.backendRuntime || 'missing'}`);
  if (cert.upstream?.mobileRuntime !== 'success') block(`mobile runtime result=${cert.upstream?.mobileRuntime || 'missing'}`);
  if (cert.upstream?.closureContract !== 'success') block(`closure contract result=${cert.upstream?.closureContract || 'missing'}`);
  if (cert.productionEligible !== false && cert.productionEligible !== true) fail('runtime certification productionEligible must be boolean');
}

if (errors.length) {
  console.error('Runtime promotion: FAIL');
  errors.forEach((e) => console.error(`- ${e}`));
  process.exit(1);
}
if (blocked.length) {
  console.error('Runtime promotion: BLOCKED');
  blocked.forEach((e) => console.error(`- ${e}`));
  process.exit(2);
}
console.log(`Runtime promotion: PASS — runtime-gate run ${expectedRunId} certifies ${pkg.version} at ${expectedSha}.`);
