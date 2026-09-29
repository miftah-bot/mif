-- v62: explicit bearer-token sessions with revocation and tenant-safe ownership.
-- Raw access tokens are never persisted; only the token JTI is stored.

CREATE TABLE "AuthSession" (
  "id" TEXT NOT NULL DEFAULT gen_random_uuid()::text,
  "tenantId" TEXT NOT NULL,
  "userId" TEXT NOT NULL,
  "tokenJti" TEXT NOT NULL,
  "expiresAt" TIMESTAMP(3) NOT NULL,
  "revokedAt" TIMESTAMP(3),
  "ipAddress" TEXT,
  "userAgent" TEXT,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "AuthSession_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "AuthSession_tokenJti_key" ON "AuthSession" ("tokenJti");
CREATE INDEX "AuthSession_tenantId_userId_revokedAt_idx" ON "AuthSession" ("tenantId", "userId", "revokedAt");
CREATE INDEX "AuthSession_expiresAt_idx" ON "AuthSession" ("expiresAt");

ALTER TABLE "AuthSession"
  ADD CONSTRAINT "AuthSession_tenant_fkey"
  FOREIGN KEY ("tenantId") REFERENCES "Tenant"("id")
  ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "AuthSession"
  ADD CONSTRAINT "AuthSession_tenant_user_fkey"
  FOREIGN KEY ("tenantId", "userId") REFERENCES "User"("tenantId", "id")
  ON DELETE CASCADE ON UPDATE CASCADE;
