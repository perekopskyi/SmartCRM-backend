import { Controller, Get, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { StatsService } from './stats.service';
import { AuthGuard } from '../../common/guards/auth.guard';

@ApiTags('stats')
@ApiBearerAuth()
@UseGuards(AuthGuard)
@Controller('stats')
export class StatsController {
  constructor(private readonly statsService: StatsService) {}

  @Get()
  @ApiOperation({ summary: 'Get dashboard statistics' })
  @ApiResponse({
    status: 200,
    description: 'Returns dashboard statistics including total customers, orders, revenue, and average order value',
  })
  async getStats() {
    return this.statsService.getStats();
  }
}
