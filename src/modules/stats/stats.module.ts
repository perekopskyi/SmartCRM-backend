import { Module } from '@nestjs/common';
import { StatsController } from './stats.controller';
import { StatsService } from './stats.service';
import { SupabaseModule } from '../../common/supabase/supabase.module';

@Module({
  imports: [SupabaseModule],
  controllers: [StatsController],
  providers: [StatsService],
})
export class StatsModule {}
