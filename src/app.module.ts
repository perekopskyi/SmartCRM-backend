import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { CustomersModule } from './modules/customers/customers.module';
import { OrdersModule } from './modules/orders/orders.module';
import { StatsModule } from './modules/stats/stats.module';
import { SupabaseModule } from './common/supabase/supabase.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
    }),
    SupabaseModule,
    CustomersModule,
    OrdersModule,
    StatsModule,
  ],
})
export class AppModule {}
