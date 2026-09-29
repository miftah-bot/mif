-- V85 performance indexes
CREATE INDEX "Sale_tenantId_createdAt_salesLocationId_idx" ON "Sale" ("tenantId", "createdAt", "salesLocationId");
CREATE INDEX "Sale_tenantId_createdAt_salespersonId_idx" ON "Sale" ("tenantId", "createdAt", "salespersonId");
CREATE INDEX "Payment_tenantId_createdAt_saleId_idx" ON "Payment" ("tenantId", "createdAt", "saleId");
CREATE INDEX "Customer_tenantId_active_currentBalance_idx" ON "Customer" ("tenantId", "active", "currentBalance");
CREATE INDEX "InventoryBalance_tenantId_locationId_ownerType_productId_idx" ON "InventoryBalance" ("tenantId", "locationId", "ownerType", "productId");
CREATE INDEX "CashSession_tenantId_status_closedAt_idx" ON "CashSession" ("tenantId", "status", "closedAt");
CREATE INDEX "SyncOperation_tenantId_status_createdAt_idx" ON "SyncOperation" ("tenantId", "status", "createdAt");
CREATE INDEX "SalesReturn_tenantId_locationId_createdAt_idx" ON "SalesReturn" ("tenantId", "locationId", "createdAt");
