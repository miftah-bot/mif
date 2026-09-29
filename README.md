# OmniDev Distributor Platform — V104

V104 adds cross-workflow runtime certification promotion to the current release path.

## Current release identity
- Root: 0.104.0
- Backend: 0.104.0
- Mobile: 0.104.0+104
- Release build: 104

## Core stack
- Backend: 0.104.0
- Mobile: 0.104.0+104
- CI/CD: GitHub Actions
- Containers: Docker
- Architecture: tenant-aware, multi-role distributor platform

## Authorization
The platform supports multi-role authorization. A seller/cashier can also hold the administrator role through role assignments while remaining tenant/location scoped.

## Release verification
A complete runtime release requires real CI execution for dependency installation, PostgreSQL/Prisma, backend build/tests, HTTP E2E, Docker, Flutter tests, and Android App Bundle generation. A committed and tracked backend/package-lock.json is required for production release closure.

## Honest status
The local workspace does not contain a fabricated package-lockfile or fabricated runtime artifacts. CI-only runtime evidence is reported as BLOCKED until the real toolchains and network-backed dependency resolution execute.

## V104 release promotion
- Runtime certification is promoted only from a completed runtime-gate workflow run for the exact source commit.
- Production promotion verifies the tracked backend lockfile again at that same source commit.
- Cross-workflow artifact verification is fail-closed; missing or mismatched runtime certification is BLOCKED.
