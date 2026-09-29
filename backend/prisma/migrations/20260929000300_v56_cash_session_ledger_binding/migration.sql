-- v56: bind cash receipts and supplier cash disbursements to the exact cash session.
-- This prevents cross-location/session leakage during reconciliation.
-- Migration is deliberately fail-closed when an old cash session is still open.

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM "CashSession" WHERE "status" = 'OPEN') THEN
    RAISE EXCEPTION 'V56 requires all cash sessions to be closed before migration';
  END IF;
END $$;

ALTER TABLE "CashSession"
  ADD CONSTRAINT "CashSession_tenantId_id_key" UNIQUE ("tenantId", "id");

ALTER TABLE "Payment"
  ADD COLUMN "cashSessionId" TEXT;

ALTER TABLE "SupplierPayment"
  ADD COLUMN "cashSessionId" TEXT;

CREATE INDEX "Payment_tenantId_cashSessionId_idx"
  ON "Payment" ("tenantId", "cashSessionId");

CREATE INDEX "SupplierPayment_tenantId_cashSessionId_idx"
  ON "SupplierPayment" ("tenantId", "cashSessionId");

ALTER TABLE "Payment"
  ADD CONSTRAINT "Payment_tenantId_cashSessionId_fkey"
  FOREIGN KEY ("tenantId", "cashSessionId") REFERENCES "CashSession"("tenantId", "id")
  ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "SupplierPayment"
  ADD CONSTRAINT "SupplierPayment_tenantId_cashSessionId_fkey"
  FOREIGN KEY ("tenantId", "cashSessionId") REFERENCES "CashSession"("tenantId", "id")
  ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "Payment"
  ADD CONSTRAINT "Payment_cashSession_method_check"
  CHECK ("cashSessionId" IS NULL OR "method" = 'CASH');

ALTER TABLE "SupplierPayment"
  ADD CONSTRAINT "SupplierPayment_cashSession_method_check"
  CHECK ("cashSessionId" IS NULL OR "method" = 'CASH');

-- Only one active cash drawer/session may exist per tenant sales location.
CREATE UNIQUE INDEX "CashSession_one_open_per_location_idx"
  ON "CashSession" ("tenantId", "locationId")
  WHERE "status" = 'OPEN';
