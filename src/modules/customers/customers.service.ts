import { Injectable, NotFoundException } from '@nestjs/common';
import { SupabaseService } from '../../common/supabase/supabase.service';
import { CreateCustomerDto, UpdateCustomerDto } from './dto/customer.dto';

@Injectable()
export class CustomersService {
  constructor(private readonly supabaseService: SupabaseService) {}

  async findAll() {
    const supabase = this.supabaseService.getClient();

    // Use customer_stats view for aggregated data
    const { data, error } = await supabase
      .from('customer_stats')
      .select('*')
      .order('id', { ascending: false });

    if (error) {
      throw new Error(`Failed to fetch customers: ${error.message}`);
    }

    // Transform snake_case to camelCase for frontend
    return data.map((customer) => ({
      id: customer.id,
      name: customer.customer_name,
      email: customer.email,
      phone: customer.phone,
      balance: customer.balance,
      totalOrders: customer.total_orders,
      totalSpent: customer.total_spent,
      lastOrderDate: customer.last_order_date,
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
      firstName: data.first_name,
      lastName: data.last_name,
      email: data.email,
      phone: data.phone,
      address: data.address,
      balance: data.balance,
      notes: data.notes,
      createdAt: data.created_at,
      updatedAt: data.updated_at,
    };
  }

  async create(createCustomerDto: CreateCustomerDto) {
    const supabase = this.supabaseService.getClient();

    const { data, error } = await supabase
      .from('customers')
      .insert([
        {
          first_name: createCustomerDto.first_name,
          last_name: createCustomerDto.last_name,
          email: createCustomerDto.email,
          phone: createCustomerDto.phone,
          address: createCustomerDto.address,
          notes: createCustomerDto.notes,
        },
      ])
      .select()
      .single();

    if (error) {
      throw new Error(`Failed to create customer: ${error.message}`);
    }

    return {
      id: data.id,
      firstName: data.first_name,
      lastName: data.last_name,
      email: data.email,
      phone: data.phone,
      address: data.address,
      balance: data.balance,
      notes: data.notes,
      createdAt: data.created_at,
      updatedAt: data.updated_at,
    };
  }

  async update(id: number, updateCustomerDto: UpdateCustomerDto) {
    const supabase = this.supabaseService.getClient();

    const updateData: any = {};
    if (updateCustomerDto.first_name !== undefined) updateData.first_name = updateCustomerDto.first_name;
    if (updateCustomerDto.last_name !== undefined) updateData.last_name = updateCustomerDto.last_name;
    if (updateCustomerDto.email !== undefined) updateData.email = updateCustomerDto.email;
    if (updateCustomerDto.phone !== undefined) updateData.phone = updateCustomerDto.phone;
    if (updateCustomerDto.address !== undefined) updateData.address = updateCustomerDto.address;
    if (updateCustomerDto.notes !== undefined) updateData.notes = updateCustomerDto.notes;

    const { data, error } = await supabase
      .from('customers')
      .update(updateData)
      .eq('id', id)
      .select()
      .single();

    if (error || !data) {
      throw new NotFoundException(`Customer with ID ${id} not found`);
    }

    return {
      id: data.id,
      firstName: data.first_name,
      lastName: data.last_name,
      email: data.email,
      phone: data.phone,
      address: data.address,
      balance: data.balance,
      notes: data.notes,
      createdAt: data.created_at,
      updatedAt: data.updated_at,
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
