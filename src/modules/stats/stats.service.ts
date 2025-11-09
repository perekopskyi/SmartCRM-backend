import { Injectable } from '@nestjs/common'
import { SupabaseService } from '../../common/supabase/supabase.service'

@Injectable()
export class StatsService {
  constructor(private readonly supabaseService: SupabaseService) {}

  async getStats() {
    const supabase = this.supabaseService.getClient()

    // Get total customers
    const { count: totalCustomers, error: customersError } = await supabase
      .from('customers')
      .select('*', { count: 'exact', head: true })

    if (customersError) {
      throw new Error(`Failed to fetch customers count: ${customersError.message}`)
    }

    // Get orders data for calculations
    const { data: orders, error: ordersError } = await supabase
      .from('orders')
      .select('total_amount')

    if (ordersError) {
      throw new Error(`Failed to fetch orders: ${ordersError.message}`)
    }

    const totalOrders = orders?.length || 0
    const totalRevenue = orders?.reduce((sum, order) => sum + (order.total_amount || 0), 0) || 0
    const avgOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0

    return {
      totalCustomers: totalCustomers || 0,
      totalOrders,
      totalRevenue: Number(totalRevenue.toFixed(2)),
      avgOrderValue: Number(avgOrderValue.toFixed(2)),
    }
  }
}
