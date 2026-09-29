import { Module } from '@nestjs/common';
import { SubscriptionsModule } from './subscriptions/subscriptions.module';
import { ConfigModule } from '@nestjs/config';
import { PrismaService } from './prisma.service';
import { PickupCodeService } from './pickup-code.service';
import { StockService } from './stock.service';
import { SalesService } from './sales.service';
import { SalesController } from './sales.controller';
import { WarehouseService } from './warehouse.service';
import { WarehouseController } from './warehouse.controller';
import { AuthModule } from './auth/auth.module';
import { ProductsModule } from './products/products.module';
import { CustomersModule } from './customers/customers.module';
import { InventoryModule } from './inventory/inventory.module';
import { ReplenishmentModule } from './replenishment/replenishment.module';
import { TransfersModule } from './transfers/transfers.module';
import { ApprovalsModule } from './approvals/approvals.module';
import { AccessControlService } from './access-control';
import { ReportsModule } from './reports/reports.module';
import { SuppliersModule } from './suppliers/suppliers.module';
import { PurchasesModule } from './purchases/purchases.module';
import { ExpensesModule } from './expenses/expenses.module';
import { ReturnsModule } from './returns/returns.module';
import { PricingModule } from './pricing/pricing.module';
import { SupplierPaymentsModule } from './supplier-payments/supplier-payments.module';
import { CashModule } from './cash/cash.module';
import { PlatformModule } from './platform/platform.module';
import { SyncModule } from './sync.module';
import { HealthController } from './health.controller';
import { UsersModule } from './users.module';
import { AuditModule } from './audit/audit.module';
import { ObservabilityModule } from './observability/observability.module';
import { NotificationsModule } from './notifications/notifications.module';

@Module({
  imports: [
    SubscriptionsModule, AuditModule, ObservabilityModule, NotificationsModule,
    ConfigModule.forRoot({ isGlobal: true }), AuthModule, ProductsModule, CustomersModule,
    InventoryModule, ReplenishmentModule, TransfersModule, ApprovalsModule, ReportsModule,
    SuppliersModule, PurchasesModule, ExpensesModule, ReturnsModule, PricingModule,
    SupplierPaymentsModule, CashModule, PlatformModule, SyncModule, UsersModule
  ],
  controllers: [SalesController, WarehouseController, HealthController],
  providers: [AccessControlService, PrismaService, PickupCodeService, StockService, SalesService, WarehouseService],
})
export class AppModule {}