# README_V104 — Runtime Certification Promotion

V104 adds a cross-workflow promotion contract between `runtime-gate` and `production-gate`.

## Contract
- `runtime-gate` publishes the current release certification artifact after backend, mobile, closure, evidence, and integrity checks.
- `production-gate` can run from `workflow_run` after `runtime-gate` completes and consumes only the artifact from that exact workflow run.
- The promotion verifier binds the certification to the triggering workflow name, workflow run ID, source commit SHA, release version, and successful runtime conclusion.
- Production promotion independently requires `git ls-files --error-unmatch backend/package-lock.json` at the same source commit.

## Local status
The local workspace cannot execute a GitHub workflow or obtain the cross-workflow artifact, so the promotion verifier is expected to report BLOCKED locally.

No fabricated runtime certification, lockfile, Docker image, Flutter build, or Android AAB is included in this release archive.
