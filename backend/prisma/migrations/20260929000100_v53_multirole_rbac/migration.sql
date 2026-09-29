-- v53: Multi-role RBAC under OmniDev authorization principles.
-- Keeps User.role as a backward-compatible primary-role field while role assignments become authoritative.

CREATE TYPE "UserRole" AS ENUM ('ADMIN', 'OWNER', 'MANAGER', 'SUPER_ADMIN', 'SALESPERSON', 'WAREHOUSE_WORKER');

CREATE TABLE "UserRoleAssignment" (
  "id" TEXT NOT NULL DEFAULT gen_random_uuid()::text,
  "tenantId" TEXT NOT NULL,
  "userId" TEXT NOT NULL,
  "role" "UserRole" NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "UserRoleAssignment_userId_role_key" ON "UserRoleAssignment" ("userId", "role");
CREATE INDEX "UserRoleAssignment_tenantId_role_idx" ON "UserRoleAssignment" ("tenantId", "role");
CREATE INDEX "UserRoleAssignment_userId_idx" ON "UserRoleAssignment" ("userId");

ALTER TABLE "UserRoleAssignment" ADD CONSTRAINT "UserRoleAssignment_tenantId_fkey"
  FOREIGN KEY ("tenantId") REFERENCES "Tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "UserRoleAssignment" ADD CONSTRAINT "UserRoleAssignment_userId_fkey"
  FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- Backfill every supported legacy single role into the authoritative assignment table.
INSERT INTO "UserRoleAssignment" ("id", "tenantId", "userId", "role")
SELECT gen_random_uuid()::text, "tenantId", "id", "role"::"UserRole"
FROM "User"
WHERE "role" IN ('ADMIN', 'OWNER', 'MANAGER', 'SUPER_ADMIN', 'SALESPERSON', 'WAREHOUSE_WORKER');
