-- v55: make UserRoleAssignment tenant-safe at the database boundary.
-- Prevents a role assignment row from pointing at a User belonging to another tenant.

CREATE UNIQUE INDEX "User_tenantId_id_key" ON "User" ("tenantId", "id");

ALTER TABLE "UserRoleAssignment" DROP CONSTRAINT "UserRoleAssignment_userId_fkey";

ALTER TABLE "UserRoleAssignment" ADD CONSTRAINT "UserRoleAssignment_tenantId_userId_fkey"
  FOREIGN KEY ("tenantId", "userId") REFERENCES "User"("tenantId", "id")
  ON DELETE CASCADE ON UPDATE CASCADE;
