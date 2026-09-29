-- V84: notification delivery/read/acknowledgement lifecycle and retention metadata.
ALTER TABLE "Notification" ADD COLUMN "deliveredAt" TIMESTAMP(3);
ALTER TABLE "Notification" ADD COLUMN "acknowledgedAt" TIMESTAMP(3);
ALTER TABLE "Notification" ADD COLUMN "expiresAt" TIMESTAMP(3);

UPDATE "Notification"
SET "expiresAt" = CASE "type"
  WHEN 'LOW_STOCK' THEN "createdAt" + INTERVAL '7 days'
  WHEN 'PENDING_APPROVAL' THEN "createdAt" + INTERVAL '14 days'
  WHEN 'CASH_VARIANCE' THEN "createdAt" + INTERVAL '30 days'
  WHEN 'SYNC_FAILURE' THEN "createdAt" + INTERVAL '14 days'
END
WHERE "expiresAt" IS NULL;

CREATE INDEX "Notification_tenantId_userId_expiresAt_idx" ON "Notification"("tenantId", "userId", "expiresAt");
