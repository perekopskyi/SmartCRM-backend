import { Injectable, NotFoundException } from '@nestjs/common';
import { SupabaseService } from '../../common/supabase/supabase.service';
import { CreateCustomerDto, UpdateCustomerDto } from './dto/customer.dto';

@Injectable()
export class CustomersService {
  constructor(private readonly supabaseService: SupabaseService) {}

  async findAll() {
    const supabase = this.supabaseService.getClient();

    const { data, error } = await supabase
      .from('customers')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) {
      throw new Error(`Failed to fetch customers: ${error.message}`);
    }

    // Transform snake_case to camelCase for frontend
    return data.map((customer) => ({
      id: customer.id,
      name: customer.name,
      email: customer.email,
      phone: customer.phone,
      totalOrders: customer.total_orders,
      totalSpent: customer.total_spent,
    }));
  }

  async findOne(id: number) {
    const supabase = this.supabaseService.getClient();

    const { data, error } = await supabase
      .from('customers')
      .select('*')
      .eq('id', id)
      .single();

    if (error || !data) {
      throw new NotFoundException(`Customer with ID ${id} not found`);
    }

    return {
      id: data.id,
      name: data.name,
      email: data.email,
      phone: data.phone,
      totalOrders: data.total_orders,
      totalSpent: data.total_spent,
    };
  }

  async create(createCustomerDto: CreateCustomerDto) {
    const supabase = this.supabaseService.getClient();

    const { data, error } = await supabase
      .from('customers')
      .insert([
        {
          name: createCustomerDto.name,
          email: createCustomerDto.email,
          phone: createCustomerDto.phone,
        },
      ])
      .select()
      .single();

    if (error) {
      throw new Error(`Failed to create customer: ${error.message}`);
    }

    return {
      id: data.id,
      name: data.name,
      email: data.email,
      phone: data.phone,
      totalOrders: data.total_orders,
      totalSpent: data.total_spent,
    };
  }

  async update(id: number, updateCustomerDto: UpdateCustomerDto) {
    const supabase = this.supabaseService.getClient();

    const { data, error } = await supabase
      .from('customers')
      .update({
        name: updateCustomerDto.name,
        email: updateCustomerDto.email,
        phone: updateCustomerDto.phone,
      })
      .eq('id', id)
      .select()
      .single();

    if (error || !data) {
      throw new NotFoundException(`Customer with ID ${id} not found`);
    }

    return {
      id: data.id,
      name: data.name,
      email: data.email,
      phone: data.phone,
      totalOrders: data.total_orders,
      totalSpent: data.total_spent,
    };
  }

  async remove(id: number) {
    const supabase = this.supabaseService.getClient();

    const { error } = await supabase.from('customers').delete().eq('id', id);

    if (error) {
      throw new NotFoundException(`Customer with ID ${id} not found`);
    }

    return { success: true, message: 'Customer deleted successfully' };
  }
}
