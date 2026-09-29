-- Distributor Platform v25 production baseline.
-- Generated from backend/prisma/schema.prisma; intended for a fresh production database bootstrap.
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TYPE "LocationType" AS ENUM ('WAREHOUSE', 'SALES');
CREATE TYPE "SaleStatus" AS ENUM ('DRAFT', 'CONFIRMED', 'WAREHOUSE_PENDING', 'COMPLETED', 'PARTIALLY_DELIVERED', 'CANCELLED');
CREATE TYPE "PaymentMethod" AS ENUM ('CASH', 'BANK', 'TELEBIRR', 'OTHER');
CREATE TYPE "WarehouseRequestType" AS ENUM ('CUSTOMER_FULFILLMENT', 'STOCK_REPLENISHMENT');
CREATE TYPE "RequestStatus" AS ENUM ('PENDING', 'PICKING', 'READY', 'PARTIALLY_DELIVERED', 'DELIVERED', 'CANCELLED');
CREATE TYPE "InventoryMovementType" AS ENUM ('PURCHASE', 'SALE', 'TRANSFER_IN', 'TRANSFER_OUT', 'CUSTOMER_FULFILLMENT', 'RETURN', 'ADJUSTMENT', 'DAMAGE');
CREATE TYPE "TransferStatus" AS ENUM ('REQUESTED', 'APPROVED', 'SENT', 'IN_TRANSIT', 'RECEIVED', 'CANCELLED');
CREATE TYPE "StockOwnerType" AS ENUM ('WAREHOUSE', 'SALESPERSON');
CREATE TYPE "ApprovalType" AS ENUM ('DISCOUNT', 'PRICE', 'CREDIT_LIMIT', 'STOCK_ADJUSTMENT', 'SALE_CANCEL', 'REPLENISHMENT');
CREATE TYPE "ApprovalStatus" AS ENUM ('PENDING', 'APPROVED', 'REJECTED');
CREATE TYPE "PurchaseStatus" AS ENUM ('DRAFT', 'ORDERED', 'PARTIALLY_RECEIVED', 'RECEIVED', 'CANCELLED');
CREATE TYPE "ExpensePaymentMethod" AS ENUM ('CASH', 'BANK', 'TELEBIRR', 'OTHER');
CREATE TYPE "SubscriptionStatus" AS ENUM ('TRIAL', 'ACTIVE', 'PAST_DUE', 'SUSPENDED', 'CANCELLED', 'EXPIRED');
CREATE TYPE "BillingCycle" AS ENUM ('MONTHLY', 'YEARLY');
CREATE TYPE "ReturnStatus" AS ENUM ('REQUESTED', 'APPROVED', 'RECEIVED', 'REJECTED');
CREATE TYPE "SyncOperationStatus" AS ENUM ('PROCESSING', 'SUCCEEDED', 'FAILED');

CREATE TABLE "Tenant" (
  "id" TEXT NOT NULL DEFAULT gen_random_uuid()::text,
  "name" TEXT NOT NULL,
  "businessCode" TEXT NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  "status" TEXT NOT NULL DEFAULT 'ACTIVE',
  "salesSequence" INTEGER NOT NULL DEFAULT 0,
  "warehouseRequestSequence" INTEGER NOT NULL DEFAULT 0,
  "purchaseSequence" INTEGER NOT NULL DEFAULT 0,
  "returnSequence" INTEGER NOT NULL DEFAULT 0,
  "transferSequence" INTEGER NOT NULL DEFAULT 0,
  "subscriptionStatus" "SubscriptionStatus" NOT NULL DEFAULT 'TRIAL',
  "trialEndsAt" TIMESTAMP(3),
  PRIMARY KEY ("id")
);

CREATE TABLE "Plan" (
  "id" TEXT NOT NULL DEFAULT gen_random_uuid()::text,
  "code" TEXT NOT NULL,
  "name" TEXT NOT NULL,
  "monthlyPrice" DECIMAL(18,2) NOT NULL,
  "yearlyPrice" DECIMAL(18,2) NOT NULL,
  "maxUsers" INTEGER,
  "maxSalesLocations" INTEGER,
  "maxWarehouses" INTEGER,
  "active" BOOLEAN NOT NULL DEFAULT true,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  PRIMARY KEY ("id")
);

CREATE TABLE "Subscription" (
  "id" TEXT NOT NULL DEFAULT gen_random_uuid()::text,
  "tenantId" TEXT NOT NULL,
  "planId" TEXT NOT NULL,
  "status" "SubscriptionStatus" NOT NULL DEFAULT 'TRIAL',
  "billingCycle" "BillingCycle" NOT NULL DEFAULT 'MONTHLY',
  "startsAt" TIMESTAMP(3) NOT NULL,
  "endsAt" TIMESTAMP(3) NOT NULL,
  "trialEndsAt" TIMESTAMP(3),
  "cancelledAt" TIMESTAMP(3),
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  PRIMARY KEY ("id")
);

CREATE TABLE "User" (
  "id" TEXT NOT NULL DEFAULT gen_random_uuid()::text,
  "tenantId" TEXT NOT NULL,
  "name" TEXT NOT NULL,
  "phone" TEXT NOT NULL,
  "passwordHash" TEXT NOT NULL,
  "role" TEXT NOT NULL,
  "primaryLocationId" TEXT,
  "status" TEXT NOT NULL DEFAULT 'ACTIVE',
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  PRIMARY KEY ("id"),
  UNIQUE ("tenantId", "phone")
);

CREATE TABLE "Location" (
  "id" TEXT NOT NULL DEFAULT gen_random_uuid()::text,
  "tenantId" TEXT NOT NULL,
  "name" TEXT NOT NULL,
  "code" TEXT NOT NULL,
  "type" "LocationType" NOT NULL,
  "preferredWarehouseId" TEXT,
  "status" BOOLEAN NOT NULL DEFAULT true,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY ("id"),
  UNIQUE ("tenantId", "code")
);

CREATE TABLE "Product" (
  "id" TEXT NOT NULL DEFAULT gen_random_uuid()::text,
  "tenantId" TEXT NOT NULL,
  "name" TEXT NOT NULL,
  "sku" TEXT NOT NULL,
  "barcode" TEXT,
  "costPrice" DECIMAL(18,2) NOT NULL,
  "sellingPrice" DECIMAL(18,2) NOT NULL,
  "minimumStock" DECIMAL(18,3) NOT NULL DEFAULT 0,
  "targetStock" DECIMAL(18,3) NOT NULL DEFAULT 0,
  "active" BOOLEAN NOT NULL DEFAULT true,
  PRIMARY KEY ("id"),
  UNIQUE ("tenantId", "sku")
);

CREATE TABLE "Customer" (
  "id" TEXT NOT NULL DEFAULT gen_random_uuid()::text,
  "tenantId" TEXT NOT NULL,
  "name" TEXT NOT NULL,
  "phone" TEXT,
  "creditLimit" DECIMAL(18,2) NOT NULL DEFAULT 0,
  "currentBalance" DECIMAL(18,2) NOT NULL DEFAULT 0,
  "customerGroupId" TEXT,
  "active" BOOLEAN NOT NULL DEFAULT true,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY ("id")
);

CREATE TABLE "InventoryBalance" (
  "id" TEXT NOT NULL DEFAULT gen_random_uuid()::text,
  "tenantId" TEXT NOT NULL,
  "productId" TEXT NOT NULL,
  "locationId" TEXT NOT NULL,
  "ownerType" "StockOwnerType" NOT NULL,
  "ownerId" TEXT NOT NULL,
  "quantity" DECIMAL(18,3) NOT NULL DEFAULT 0,
  "reservedQuantity" DECIMAL(18,3) NOT NULL DEFAULT 0,
  "availableQuantity" DECIMAL(18,3) NOT NULL DEFAULT 0,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  PRIMARY KEY ("id"),
  UNIQUE ("tenantId", "productId", "locationId", "ownerType", "ownerId")
);

CREATE TABLE "Sale" (
  "id" TEXT NOT NULL DEFAULT gen_random_uuid()::text,
  "tenantId" TEXT NOT NULL,
  "saleNumber" TEXT NOT NULL,
  "customerId" TEXT NOT NULL,
  "salesLocationId" TEXT NOT NULL,
  "salespersonId" TEXT NOT NULL,
  "subtotal" DECIMAL(18,2) NOT NULL,
  "discount" DECIMAL(18,2) NOT NULL DEFAULT 0,
  "tax" DECIMAL(18,2) NOT NULL DEFAULT 0,
  "grandTotal" DECIMAL(18,2) NOT NULL,
  "paidAmount" DECIMAL(18,2) NOT NULL DEFAULT 0,
  "creditAmount" DECIMAL(18,2) NOT NULL DEFAULT 0,
  "status" "SaleStatus" NOT NULL DEFAULT 'DRAFT',
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  PRIMARY KEY ("id"),
  UNIQUE ("tenantId", "saleNumber")
);

CREATE TABLE "SaleItem" (
  "id" TEXT NOT NULL DEFAULT gen_random_uuid()::text,
  "saleId" TEXT NOT NULL,
  "productId" TEXT NOT NULL,
  "requestedQuantity" DECIMAL(18,3) NOT NULL,
  "salespersonQuantity" DECIMAL(18,3) NOT NULL,
  "warehouseQuantity" DECIMAL(18,3) NOT NULL,
  "unitPrice" DECIMAL(18,2) NOT NULL,
  "unitCost" DECIMAL(18,2) NOT NULL,
  "lineTotal" DECIMAL(18,2) NOT NULL,
  PRIMARY KEY ("id")
);

CREATE TABLE "Payment" (
  "id" TEXT NOT NULL DEFAULT gen_random_uuid()::text,
  "tenantId" TEXT NOT NULL,
  "saleId" TEXT,
  "customerId" TEXT NOT NULL,
  "amount" DECIMAL(18,2) NOT NULL,
  "method" "PaymentMethod" NOT NULL,
  "referenceNumber" TEXT,
  "receivedById" TEXT NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY ("id")
);

CREATE TABLE "CreditTransaction" (
  "id" TEXT NOT NULL DEFAULT gen_random_uuid()::text,
  "tenantId" TEXT NOT NULL,
  "customerId" TEXT NOT NULL,
  "type" TEXT NOT NULL,
  "amount" DECIMAL(18,2) NOT NULL,
  "referenceType" TEXT,
  "referenceId" TEXT,
  "description" TEXT,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY ("id")
);

CREATE TABLE "InventoryMovement" (
  "id" TEXT NOT NULL DEFAULT gen_random_uuid()::text,
  "tenantId" TEXT NOT NULL,
  "productId" TEXT NOT NULL,
  "locationId" TEXT NOT NULL,
  "userId" TEXT,
  "type" "InventoryMovementType" NOT NULL,
  "quantity" DECIMAL(18,3) NOT NULL,
  "referenceType" TEXT,
  "referenceId" TEXT,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY ("id")
);

CREATE TABLE "WarehouseRequest" (
  "id" TEXT NOT NULL DEFAULT gen_random_uuid()::text,
  "tenantId" TEXT NOT NULL,
  "requestNumber" TEXT NOT NULL,
  "requestType" "WarehouseRequestType" NOT NULL,
  "saleId" TEXT,
  "customerId" TEXT,
  "salesLocationId" TEXT NOT NULL,
  "warehouseId" TEXT NOT NULL,
  "status" "RequestStatus" NOT NULL DEFAULT 'PENDING',
  "pickupCodeHash" TEXT,
  "pickupCodeLast4" TEXT,
  "pickupCodeExpiresAt" TIMESTAMP(3),
  "pickupCodeUsedAt" TIMESTAMP(3),
  "pickupCodeAttempts" INTEGER NOT NULL DEFAULT 0,
  "createdById" TEXT NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "completedAt" TIMESTAMP(3),
  PRIMARY KEY ("id"),
  UNIQUE ("tenantId", "requestNumber")
);

CREATE TABLE "WarehouseRequestItem" (
  "id" TEXT NOT NULL DEFAULT gen_random_uuid()::text,
  "warehouseRequestId" TEXT NOT NULL,
  "productId" TEXT NOT NULL,
  "requestedQuantity" DECIMAL(18,3) NOT NULL,
  "pickedQuantity" DECIMAL(18,3) NOT NULL DEFAULT 0,
  "deliveredQuantity" DECIMAL(18,3) NOT NULL DEFAULT 0,
  PRIMARY KEY ("id")
);

CREATE TABLE "StockTransfer" (
  "id" TEXT NOT NULL DEFAULT gen_random_uuid()::text,
  "tenantId" TEXT NOT NULL,
  "transferNumber" TEXT NOT NULL,
  "fromLocationId" TEXT NOT NULL,
  "toLocationId" TEXT NOT NULL,
  "recipientUserId" TEXT,
  "status" "TransferStatus" NOT NULL DEFAULT 'REQUESTED',
  "createdById" TEXT NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "sentAt" TIMESTAMP(3),
  "receivedAt" TIMESTAMP(3),
  PRIMARY KEY ("id"),
  UNIQUE ("tenantId", "transferNumber")
);

CREATE TABLE "StockTransferItem" (
  "id" TEXT NOT NULL DEFAULT gen_random_uuid()::text,
  "stockTransferId" TEXT NOT NULL,
  "productId" TEXT NOT NULL,
  "requestedQuantity" DECIMAL(18,3) NOT NULL,
  "sentQuantity" DECIMAL(18,3) NOT NULL DEFAULT 0,
  "receivedQuantity" DECIMAL(18,3) NOT NULL DEFAULT 0,
  PRIMARY KEY ("id")
);

CREATE TABLE "Expense" (
  "id" TEXT NOT NULL DEFAULT gen_random_uuid()::text,
  "tenantId" TEXT NOT NULL,
  "category" TEXT NOT NULL,
  "description" TEXT,
  "amount" DECIMAL(18,2) NOT NULL,
  "method" "ExpensePaymentMethod" NOT NULL,
  "referenceNumber" TEXT,
  "createdById" TEXT NOT NULL,
  "cashSessionId" TEXT,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY ("id")
);

CREATE TABLE "SalesReturn" (
  "id" TEXT NOT NULL DEFAULT gen_random_uuid()::text,
  "tenantId" TEXT NOT NULL,
  "returnNumber" TEXT NOT NULL,
  "saleId" TEXT NOT NULL,
  "customerId" TEXT NOT NULL,
  "locationId" TEXT NOT NULL,
  "status" "ReturnStatus" NOT NULL DEFAULT 'REQUESTED',
  "reason" TEXT,
  "refundAmount" DECIMAL(18,2) NOT NULL DEFAULT 0,
  "creditAmount" DECIMAL(18,2) NOT NULL DEFAULT 0,
  "approvedById" TEXT,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  PRIMARY KEY ("id"),
  UNIQUE ("tenantId", "returnNumber")
);

CREATE TABLE "SalesReturnItem" (
  "id" TEXT NOT NULL DEFAULT gen_random_uuid()::text,
  "salesReturnId" TEXT NOT NULL,
  "productId" TEXT NOT NULL,
  "quantity" DECIMAL(18,3) NOT NULL,
  "unitPrice" DECIMAL(18,2) NOT NULL,
  "unitCost" DECIMAL(18,2) NOT NULL,
  "lineTotal" DECIMAL(18,2) NOT NULL,
  PRIMARY KEY ("id")
);

CREATE TABLE "CustomerGroup" (
  "id" TEXT NOT NULL DEFAULT gen_random_uuid()::text,
  "tenantId" TEXT NOT NULL,
  "name" TEXT NOT NULL,
  "description" TEXT,
  "priceListId" TEXT,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  PRIMARY KEY ("id"),
  UNIQUE ("tenantId", "name")
);

CREATE TABLE "PriceList" (
  "id" TEXT NOT NULL DEFAULT gen_random_uuid()::text,
  "tenantId" TEXT NOT NULL,
  "name" TEXT NOT NULL,
  "active" BOOLEAN NOT NULL DEFAULT true,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  PRIMARY KEY ("id"),
  UNIQUE ("tenantId", "name")
);

CREATE TABLE "PriceListItem" (
  "id" TEXT NOT NULL DEFAULT gen_random_uuid()::text,
  "priceListId" TEXT NOT NULL,
  "productId" TEXT NOT NULL,
  "sellingPrice" DECIMAL(18,2) NOT NULL,
  PRIMARY KEY ("id"),
  UNIQUE ("priceListId", "productId")
);

CREATE TABLE "Supplier" (
  "id" TEXT NOT NULL DEFAULT gen_random_uuid()::text,
  "tenantId" TEXT NOT NULL,
  "name" TEXT NOT NULL,
  "phone" TEXT,
  "address" TEXT,
  "contactPerson" TEXT,
  "balance" DECIMAL(18,2) NOT NULL DEFAULT 0,
  "active" BOOLEAN NOT NULL DEFAULT true,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  PRIMARY KEY ("id")
);

CREATE TABLE "SupplierPayment" (
  "id" TEXT NOT NULL DEFAULT gen_random_uuid()::text,
  "tenantId" TEXT NOT NULL,
  "supplierId" TEXT NOT NULL,
  "amount" DECIMAL(18,2) NOT NULL,
  "method" "ExpensePaymentMethod" NOT NULL,
  "referenceNumber" TEXT,
  "receivedById" TEXT NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY ("id")
);

CREATE TABLE "Purchase" (
  "id" TEXT NOT NULL DEFAULT gen_random_uuid()::text,
  "tenantId" TEXT NOT NULL,
  "purchaseNumber" TEXT NOT NULL,
  "supplierId" TEXT NOT NULL,
  "warehouseId" TEXT NOT NULL,
  "status" "PurchaseStatus" NOT NULL DEFAULT 'RECEIVED',
  "subtotal" DECIMAL(18,2) NOT NULL,
  "discount" DECIMAL(18,2) NOT NULL DEFAULT 0,
  "tax" DECIMAL(18,2) NOT NULL DEFAULT 0,
  "grandTotal" DECIMAL(18,2) NOT NULL,
  "paidAmount" DECIMAL(18,2) NOT NULL DEFAULT 0,
  "creditAmount" DECIMAL(18,2) NOT NULL DEFAULT 0,
  "createdById" TEXT NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  PRIMARY KEY ("id"),
  UNIQUE ("tenantId", "purchaseNumber")
);

CREATE TABLE "PurchaseItem" (
  "id" TEXT NOT NULL DEFAULT gen_random_uuid()::text,
  "purchaseId" TEXT NOT NULL,
  "productId" TEXT NOT NULL,
  "orderedQuantity" DECIMAL(18,3) NOT NULL,
  "receivedQuantity" DECIMAL(18,3) NOT NULL DEFAULT 0,
  "unitCost" DECIMAL(18,2) NOT NULL,
  "lineTotal" DECIMAL(18,2) NOT NULL,
  PRIMARY KEY ("id")
);

CREATE TABLE "CashSession" (
  "id" TEXT NOT NULL DEFAULT gen_random_uuid()::text,
  "tenantId" TEXT NOT NULL,
  "locationId" TEXT NOT NULL,
  "openedById" TEXT NOT NULL,
  "openedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "openingCash" DECIMAL(18,2) NOT NULL DEFAULT 0,
  "closingCash" DECIMAL(18,2),
  "countedCash" DECIMAL(18,2),
  "variance" DECIMAL(18,2),
  "closedAt" TIMESTAMP(3),
  "status" TEXT NOT NULL DEFAULT 'OPEN',
  PRIMARY KEY ("id")
);

CREATE TABLE "ApprovalRequest" (
  "id" TEXT NOT NULL DEFAULT gen_random_uuid()::text,
  "tenantId" TEXT NOT NULL,
  "type" "ApprovalType" NOT NULL,
  "status" "ApprovalStatus" NOT NULL DEFAULT 'PENDING',
  "referenceType" TEXT NOT NULL,
  "referenceId" TEXT NOT NULL,
  "reason" TEXT,
  "requestedValue" JSONB,
  "requestedById" TEXT NOT NULL,
  "resolvedById" TEXT,
  "resolvedAt" TIMESTAMP(3),
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY ("id")
);

CREATE TABLE "SyncOperation" (
  "id" TEXT NOT NULL DEFAULT gen_random_uuid()::text,
  "tenantId" TEXT NOT NULL,
  "operationKey" TEXT NOT NULL,
  "operationType" TEXT NOT NULL,
  "status" "SyncOperationStatus" NOT NULL DEFAULT 'PROCESSING',
  "requestHash" TEXT NOT NULL,
  "requestPayload" JSONB NOT NULL,
  "resultPayload" JSONB,
  "errorMessage" TEXT,
  "processingToken" TEXT,
  "leaseExpiresAt" TIMESTAMP(3),
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "completedAt" TIMESTAMP(3),
  PRIMARY KEY ("id"),
  UNIQUE ("tenantId", "operationKey")
);

ALTER TABLE "Subscription" ADD CONSTRAINT "Subscription_tenant_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "Subscription" ADD CONSTRAINT "Subscription_plan_fkey" FOREIGN KEY ("planId") REFERENCES "Plan" ("id") ON UPDATE CASCADE;
ALTER TABLE "User" ADD CONSTRAINT "User_tenant_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "User" ADD CONSTRAINT "User_primaryLocation_fkey" FOREIGN KEY ("primaryLocationId") REFERENCES "Location" ("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "Location" ADD CONSTRAINT "Location_tenant_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "Product" ADD CONSTRAINT "Product_tenant_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "Customer" ADD CONSTRAINT "Customer_tenant_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "Customer" ADD CONSTRAINT "Customer_customerGroup_fkey" FOREIGN KEY ("customerGroupId") REFERENCES "CustomerGroup" ("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "InventoryBalance" ADD CONSTRAINT "InventoryBalance_tenant_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "InventoryBalance" ADD CONSTRAINT "InventoryBalance_product_fkey" FOREIGN KEY ("productId") REFERENCES "Product" ("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "InventoryBalance" ADD CONSTRAINT "InventoryBalance_location_fkey" FOREIGN KEY ("locationId") REFERENCES "Location" ("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "Sale" ADD CONSTRAINT "Sale_tenant_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "Sale" ADD CONSTRAINT "Sale_customer_fkey" FOREIGN KEY ("customerId") REFERENCES "Customer" ("id") ON UPDATE CASCADE;
ALTER TABLE "Sale" ADD CONSTRAINT "Sale_salesLocation_fkey" FOREIGN KEY ("salesLocationId") REFERENCES "Location" ("id") ON UPDATE CASCADE;
ALTER TABLE "Sale" ADD CONSTRAINT "Sale_salesperson_fkey" FOREIGN KEY ("salespersonId") REFERENCES "User" ("id") ON UPDATE CASCADE;
ALTER TABLE "SaleItem" ADD CONSTRAINT "SaleItem_sale_fkey" FOREIGN KEY ("saleId") REFERENCES "Sale" ("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "SaleItem" ADD CONSTRAINT "SaleItem_product_fkey" FOREIGN KEY ("productId") REFERENCES "Product" ("id") ON UPDATE CASCADE;
ALTER TABLE "Payment" ADD CONSTRAINT "Payment_tenant_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "Payment" ADD CONSTRAINT "Payment_sale_fkey" FOREIGN KEY ("saleId") REFERENCES "Sale" ("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "Payment" ADD CONSTRAINT "Payment_customer_fkey" FOREIGN KEY ("customerId") REFERENCES "Customer" ("id") ON UPDATE CASCADE;
ALTER TABLE "Payment" ADD CONSTRAINT "Payment_receivedBy_fkey" FOREIGN KEY ("receivedById") REFERENCES "User" ("id") ON UPDATE CASCADE;
ALTER TABLE "CreditTransaction" ADD CONSTRAINT "CreditTransaction_tenant_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "CreditTransaction" ADD CONSTRAINT "CreditTransaction_customer_fkey" FOREIGN KEY ("customerId") REFERENCES "Customer" ("id") ON UPDATE CASCADE;
ALTER TABLE "InventoryMovement" ADD CONSTRAINT "InventoryMovement_tenant_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "InventoryMovement" ADD CONSTRAINT "InventoryMovement_product_fkey" FOREIGN KEY ("productId") REFERENCES "Product" ("id") ON UPDATE CASCADE;
ALTER TABLE "InventoryMovement" ADD CONSTRAINT "InventoryMovement_location_fkey" FOREIGN KEY ("locationId") REFERENCES "Location" ("id") ON UPDATE CASCADE;
ALTER TABLE "InventoryMovement" ADD CONSTRAINT "InventoryMovement_createdBy_fkey" FOREIGN KEY ("userId") REFERENCES "User" ("id") ON UPDATE CASCADE;
ALTER TABLE "WarehouseRequest" ADD CONSTRAINT "WarehouseRequest_tenant_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "WarehouseRequest" ADD CONSTRAINT "WarehouseRequest_sale_fkey" FOREIGN KEY ("saleId") REFERENCES "Sale" ("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "WarehouseRequest" ADD CONSTRAINT "WarehouseRequest_customer_fkey" FOREIGN KEY ("customerId") REFERENCES "Customer" ("id") ON UPDATE CASCADE;
ALTER TABLE "WarehouseRequest" ADD CONSTRAINT "WarehouseRequest_salesLocation_fkey" FOREIGN KEY ("salesLocationId") REFERENCES "Location" ("id") ON UPDATE CASCADE;
ALTER TABLE "WarehouseRequest" ADD CONSTRAINT "WarehouseRequest_createdBy_fkey" FOREIGN KEY ("createdById") REFERENCES "User" ("id") ON UPDATE CASCADE;
ALTER TABLE "WarehouseRequestItem" ADD CONSTRAINT "WarehouseRequestItem_warehouseRequest_fkey" FOREIGN KEY ("warehouseRequestId") REFERENCES "WarehouseRequest" ("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "WarehouseRequestItem" ADD CONSTRAINT "WarehouseRequestItem_product_fkey" FOREIGN KEY ("productId") REFERENCES "Product" ("id") ON UPDATE CASCADE;
ALTER TABLE "StockTransfer" ADD CONSTRAINT "StockTransfer_tenant_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "StockTransfer" ADD CONSTRAINT "StockTransfer_fromLocation_fkey" FOREIGN KEY ("fromLocationId") REFERENCES "Location" ("id") ON UPDATE CASCADE;
ALTER TABLE "StockTransfer" ADD CONSTRAINT "StockTransfer_toLocation_fkey" FOREIGN KEY ("toLocationId") REFERENCES "Location" ("id") ON UPDATE CASCADE;
ALTER TABLE "StockTransfer" ADD CONSTRAINT "StockTransfer_recipientUser_fkey" FOREIGN KEY ("recipientUserId") REFERENCES "User" ("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "StockTransfer" ADD CONSTRAINT "StockTransfer_createdBy_fkey" FOREIGN KEY ("createdById") REFERENCES "User" ("id") ON UPDATE CASCADE;
ALTER TABLE "StockTransferItem" ADD CONSTRAINT "StockTransferItem_stockTransfer_fkey" FOREIGN KEY ("stockTransferId") REFERENCES "StockTransfer" ("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "StockTransferItem" ADD CONSTRAINT "StockTransferItem_product_fkey" FOREIGN KEY ("productId") REFERENCES "Product" ("id") ON UPDATE CASCADE;
ALTER TABLE "Expense" ADD CONSTRAINT "Expense_tenant_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "Expense" ADD CONSTRAINT "Expense_createdBy_fkey" FOREIGN KEY ("createdById") REFERENCES "User" ("id") ON UPDATE CASCADE;
ALTER TABLE "Expense" ADD CONSTRAINT "Expense_cashSession_fkey" FOREIGN KEY ("cashSessionId") REFERENCES "CashSession" ("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "SalesReturn" ADD CONSTRAINT "SalesReturn_tenant_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "SalesReturn" ADD CONSTRAINT "SalesReturn_sale_fkey" FOREIGN KEY ("saleId") REFERENCES "Sale" ("id") ON UPDATE CASCADE;
ALTER TABLE "SalesReturn" ADD CONSTRAINT "SalesReturn_customer_fkey" FOREIGN KEY ("customerId") REFERENCES "Customer" ("id") ON UPDATE CASCADE;
ALTER TABLE "SalesReturn" ADD CONSTRAINT "SalesReturn_location_fkey" FOREIGN KEY ("locationId") REFERENCES "Location" ("id") ON UPDATE CASCADE;
ALTER TABLE "SalesReturn" ADD CONSTRAINT "SalesReturn_approvedBy_fkey" FOREIGN KEY ("approvedById") REFERENCES "User" ("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "SalesReturnItem" ADD CONSTRAINT "SalesReturnItem_salesReturn_fkey" FOREIGN KEY ("salesReturnId") REFERENCES "SalesReturn" ("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "SalesReturnItem" ADD CONSTRAINT "SalesReturnItem_product_fkey" FOREIGN KEY ("productId") REFERENCES "Product" ("id") ON UPDATE CASCADE;
ALTER TABLE "CustomerGroup" ADD CONSTRAINT "CustomerGroup_tenant_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "CustomerGroup" ADD CONSTRAINT "CustomerGroup_priceList_fkey" FOREIGN KEY ("priceListId") REFERENCES "PriceList" ("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "PriceList" ADD CONSTRAINT "PriceList_tenant_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "PriceListItem" ADD CONSTRAINT "PriceListItem_priceList_fkey" FOREIGN KEY ("priceListId") REFERENCES "PriceList" ("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "PriceListItem" ADD CONSTRAINT "PriceListItem_product_fkey" FOREIGN KEY ("productId") REFERENCES "Product" ("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "Supplier" ADD CONSTRAINT "Supplier_tenant_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "SupplierPayment" ADD CONSTRAINT "SupplierPayment_supplier_fkey" FOREIGN KEY ("supplierId") REFERENCES "Supplier" ("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "SupplierPayment" ADD CONSTRAINT "SupplierPayment_receivedBy_fkey" FOREIGN KEY ("receivedById") REFERENCES "User" ("id") ON UPDATE CASCADE;
ALTER TABLE "Purchase" ADD CONSTRAINT "Purchase_tenant_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "Purchase" ADD CONSTRAINT "Purchase_supplier_fkey" FOREIGN KEY ("supplierId") REFERENCES "Supplier" ("id") ON UPDATE CASCADE;
ALTER TABLE "Purchase" ADD CONSTRAINT "Purchase_warehouse_fkey" FOREIGN KEY ("warehouseId") REFERENCES "Location" ("id") ON UPDATE CASCADE;
ALTER TABLE "Purchase" ADD CONSTRAINT "Purchase_createdBy_fkey" FOREIGN KEY ("createdById") REFERENCES "User" ("id") ON UPDATE CASCADE;
ALTER TABLE "PurchaseItem" ADD CONSTRAINT "PurchaseItem_purchase_fkey" FOREIGN KEY ("purchaseId") REFERENCES "Purchase" ("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "PurchaseItem" ADD CONSTRAINT "PurchaseItem_product_fkey" FOREIGN KEY ("productId") REFERENCES "Product" ("id") ON UPDATE CASCADE;
ALTER TABLE "CashSession" ADD CONSTRAINT "CashSession_tenant_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "CashSession" ADD CONSTRAINT "CashSession_location_fkey" FOREIGN KEY ("locationId") REFERENCES "Location" ("id") ON UPDATE CASCADE;
ALTER TABLE "CashSession" ADD CONSTRAINT "CashSession_openedBy_fkey" FOREIGN KEY ("openedById") REFERENCES "User" ("id") ON UPDATE CASCADE;
ALTER TABLE "ApprovalRequest" ADD CONSTRAINT "ApprovalRequest_tenant_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "ApprovalRequest" ADD CONSTRAINT "ApprovalRequest_requestedBy_fkey" FOREIGN KEY ("requestedById") REFERENCES "User" ("id") ON UPDATE CASCADE;
ALTER TABLE "ApprovalRequest" ADD CONSTRAINT "ApprovalRequest_resolvedBy_fkey" FOREIGN KEY ("resolvedById") REFERENCES "User" ("id") ON DELETE SET NULL ON UPDATE CASCADE;
CREATE INDEX "Subscription_tenantId_status_idx" ON "Subscription" ("tenantId", "status");
CREATE INDEX "Subscription_endsAt_idx" ON "Subscription" ("endsAt");
CREATE INDEX "User_tenantId_role_idx" ON "User" ("tenantId", "role");
CREATE INDEX "Product_tenantId_name_idx" ON "Product" ("tenantId", "name");
CREATE INDEX "Product_tenantId_barcode_idx" ON "Product" ("tenantId", "barcode");
CREATE INDEX "Customer_tenantId_name_idx" ON "Customer" ("tenantId", "name");
CREATE INDEX "Customer_tenantId_phone_idx" ON "Customer" ("tenantId", "phone");
CREATE INDEX "InventoryBalance_tenantId_locationId_ownerType_ownerId_idx" ON "InventoryBalance" ("tenantId", "locationId", "ownerType", "ownerId");
CREATE INDEX "Sale_tenantId_customerId_createdAt_idx" ON "Sale" ("tenantId", "customerId", "createdAt");
CREATE INDEX "SaleItem_saleId_idx" ON "SaleItem" ("saleId");
CREATE INDEX "Payment_tenantId_customerId_createdAt_idx" ON "Payment" ("tenantId", "customerId", "createdAt");
CREATE INDEX "CreditTransaction_tenantId_customerId_createdAt_idx" ON "CreditTransaction" ("tenantId", "customerId", "createdAt");
CREATE INDEX "InventoryMovement_tenantId_productId_createdAt_idx" ON "InventoryMovement" ("tenantId", "productId", "createdAt");
CREATE INDEX "WarehouseRequest_tenantId_requestType_status_idx" ON "WarehouseRequest" ("tenantId", "requestType", "status");
CREATE INDEX "WarehouseRequest_tenantId_pickupCodeHash_idx" ON "WarehouseRequest" ("tenantId", "pickupCodeHash");
CREATE INDEX "WarehouseRequestItem_warehouseRequestId_idx" ON "WarehouseRequestItem" ("warehouseRequestId");
CREATE INDEX "Expense_tenantId_createdAt_idx" ON "Expense" ("tenantId", "createdAt");
CREATE INDEX "Expense_tenantId_category_idx" ON "Expense" ("tenantId", "category");
CREATE INDEX "SalesReturn_tenantId_saleId_idx" ON "SalesReturn" ("tenantId", "saleId");
CREATE INDEX "SalesReturn_tenantId_customerId_createdAt_idx" ON "SalesReturn" ("tenantId", "customerId", "createdAt");
CREATE INDEX "SalesReturnItem_salesReturnId_idx" ON "SalesReturnItem" ("salesReturnId");
CREATE INDEX "Supplier_tenantId_name_idx" ON "Supplier" ("tenantId", "name");
CREATE INDEX "SupplierPayment_tenantId_supplierId_createdAt_idx" ON "SupplierPayment" ("tenantId", "supplierId", "createdAt");
CREATE INDEX "Purchase_tenantId_supplierId_createdAt_idx" ON "Purchase" ("tenantId", "supplierId", "createdAt");
CREATE INDEX "PurchaseItem_purchaseId_idx" ON "PurchaseItem" ("purchaseId");
CREATE INDEX "CashSession_tenantId_locationId_openedAt_idx" ON "CashSession" ("tenantId", "locationId", "openedAt");
CREATE INDEX "ApprovalRequest_tenantId_status_createdAt_idx" ON "ApprovalRequest" ("tenantId", "status", "createdAt");
CREATE INDEX "ApprovalRequest_tenantId_referenceType_referenceId_idx" ON "ApprovalRequest" ("tenantId", "referenceType", "referenceId");
CREATE INDEX "SyncOperation_tenantId_createdAt_idx" ON "SyncOperation" ("tenantId", "createdAt");
CREATE INDEX "SyncOperation_tenantId_status_idx" ON "SyncOperation" ("tenantId", "status");
CREATE INDEX "SyncOperation_tenantId_leaseExpiresAt_idx" ON "SyncOperation" ("tenantId", "leaseExpiresAt");

-- Default SaaS plan catalog.
INSERT INTO "Plan" ("id","code","name","monthlyPrice","yearlyPrice","maxUsers","maxSalesLocations","maxWarehouses","active","createdAt","updatedAt") VALUES
('00000000-0000-0000-0000-000000000101','STARTER','Starter',999,9990,5,1,1,true,CURRENT_TIMESTAMP,CURRENT_TIMESTAMP),
('00000000-0000-0000-0000-000000000102','BUSINESS','Business',1999,19990,15,3,2,true,CURRENT_TIMESTAMP,CURRENT_TIMESTAMP),
('00000000-0000-0000-0000-000000000103','PRO','Pro',3999,39990,NULL,NULL,NULL,true,CURRENT_TIMESTAMP,CURRENT_TIMESTAMP);