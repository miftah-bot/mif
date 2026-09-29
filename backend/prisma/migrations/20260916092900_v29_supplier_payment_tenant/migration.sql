-- v29: enforce tenant ownership on supplier payments.
-- Existing rows must already have a valid tenant before validation succeeds.
ALTER TABLE "SupplierPayment"
  ADD CONSTRAINT "SupplierPayment_tenant_fkey"
  FOREIGN KEY ("tenantId") REFERENCES "Tenant"("id")
  ON DELETE CASCADE ON UPDATE CASCADE;
