# SmartCRM Database Documentation

## Overview

SmartCRM uses **Supabase (PostgreSQL)** as its database. This document provides an overview of the database schema, migrations, and best practices.

## Quick Links

- [Schema Diagram](../database/ER_DIAGRAM.md)
- [Visual Schema](../database/VISUAL_SCHEMA.md)
- [Analysis](../database/ANALYSIS.md)
- [Order Statuses Feature](../database/ORDER_STATUSES_FEATURE.md)

## Database Structure

### Core Tables

1. **roles** - User role definitions (owner, accountant, employee, contractor, customer)
2. **users** - Employee/user accounts (linked to Supabase Auth)
3. **customers** - Customer information and balance tracking
4. **order_statuses** - Dynamic order status definitions (customizable)
5. **orders** - Customer orders with status tracking
6. **order_items** - Line items for each order
7. **tasks** - Tasks associated with orders
8. **task_items** - Checklist items for tasks
9. **transactions** - Financial transactions (income/expense/refund)
10. **files** - File attachments for orders
11. **task_logs** - Activity audit trail

### Views

- **order_summary** - Aggregated order data with customer, employee, and status info
- **customer_stats** - Customer statistics (total orders, spending, last order)

## Migrations

### Location

All migrations are stored in `/backend/supabase/migrations/`

### Migration Files

- `20251109000000_initial_schema.sql` - Initial database schema with all tables, indexes, triggers, and seed data

### Running Migrations

#### Option 1: Supabase CLI (Recommended)

```bash
# Install Supabase CLI if not already installed
npm install -g supabase

# Link to your Supabase project
supabase link --project-ref your-project-ref

# Run migrations
supabase db push
```

#### Option 2: Supabase Dashboard

1. Go to your Supabase project dashboard
2. Navigate to **SQL Editor**
3. Copy the contents of the migration file
4. Execute the SQL

#### Option 3: Migration Script

```bash
# From backend directory
npm run migrate
```

## Environment Variables

Required environment variables in `.env`:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your-anon-key-here
```

## Row Level Security (RLS)

All tables have RLS enabled with the following policies:

- **Authenticated users** can view, create, update, and delete most records
- **Users** can only update their own profile
- **Task logs** are read-only (except for creation)

### Customizing RLS

To add more granular permissions (e.g., role-based access):

```sql
-- Example: Only owners can delete customers
CREATE POLICY "Only owners can delete customers" ON customers
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM users 
            JOIN roles ON users.role_id = roles.id
            WHERE users.id = auth.uid() 
            AND roles.name = 'owner'
        )
    );
```

## ENUM Types

The following ENUM types are defined:

- `role_type`: 'owner', 'accountant', 'employee', 'contractor', 'customer'
- `payment_type`: 'cash', 'cashless', 'online'
- `transaction_type`: 'income', 'expense', 'refund'
- `task_status_type`: 'todo', 'in_progress', 'done'

**Note:** Order statuses are stored in the `order_statuses` table (not ENUM) for flexibility.

## Key Features

### 1. Dynamic Order Statuses

Order statuses are stored in a table, allowing you to:
- Add new statuses without code changes
- Assign custom colors
- Control display order
- Enable/disable statuses

See [Order Statuses Feature](../database/ORDER_STATUSES_FEATURE.md) for details.

### 2. Automatic Timestamps

Tables with `updated_at` columns automatically update on record changes via triggers.

### 3. Computed Columns

- `order_items.total_price` = `quantity * unit_price` (auto-calculated)

### 4. Cascade Deletes

- Deleting an **order** cascades to: order_items, tasks, files
- Deleting a **customer** cascades to: orders (and their children)
- Deleting a **task** cascades to: task_items, task_logs

### 5. Audit Trail

All significant actions are logged in `task_logs` for accountability.

## Common Queries

### Get all orders with customer and status info

```sql
SELECT * FROM order_summary
WHERE status_name = 'in_progress'
ORDER BY created_at DESC;
```

### Get customer statistics

```sql
SELECT * FROM customer_stats
ORDER BY total_spent DESC;
```

### Get orders for a specific customer

```sql
SELECT o.*, os.display_name AS status
FROM orders o
JOIN order_statuses os ON o.status_id = os.id
WHERE o.customer_id = $1
ORDER BY o.created_at DESC;
```

### Get tasks assigned to an employee

```sql
SELECT t.*, o.id AS order_id, c.first_name || ' ' || c.last_name AS customer_name
FROM tasks t
JOIN orders o ON t.order_id = o.id
JOIN customers c ON o.customer_id = c.id
WHERE t.employee_id = $1
AND t.status != 'done'
ORDER BY t.due_date ASC;
```

### Get financial summary

```sql
SELECT 
    type,
    payment_type,
    COUNT(*) AS transaction_count,
    SUM(amount) AS total_amount
FROM transactions
WHERE date >= NOW() - INTERVAL '30 days'
GROUP BY type, payment_type;
```

## NestJS Integration

### Supabase Client Setup

```typescript
// src/config/supabase.config.ts
import { createClient } from '@supabase/supabase-js';

export const supabaseClient = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_KEY
);
```

### Example Service

```typescript
// src/modules/customers/customers.service.ts
import { Injectable } from '@nestjs/common';
import { supabaseClient } from '../../config/supabase.config';

@Injectable()
export class CustomersService {
  async findAll() {
    const { data, error } = await supabaseClient
      .from('customers')
      .select('*')
      .order('created_at', { ascending: false });
    
    if (error) throw error;
    return data;
  }

  async findOne(id: number) {
    const { data, error } = await supabaseClient
      .from('customers')
      .select('*')
      .eq('id', id)
      .single();
    
    if (error) throw error;
    return data;
  }

  async create(customer: CreateCustomerDto) {
    const { data, error } = await supabaseClient
      .from('customers')
      .insert(customer)
      .select()
      .single();
    
    if (error) throw error;
    return data;
  }

  async update(id: number, customer: UpdateCustomerDto) {
    const { data, error } = await supabaseClient
      .from('customers')
      .update(customer)
      .eq('id', id)
      .select()
      .single();
    
    if (error) throw error;
    return data;
  }

  async remove(id: number) {
    const { error } = await supabaseClient
      .from('customers')
      .delete()
      .eq('id', id);
    
    if (error) throw error;
  }
}
```

## TypeScript Types

Generate TypeScript types from your Supabase schema:

```bash
# Install Supabase CLI
npm install -g supabase

# Generate types
supabase gen types typescript --project-id your-project-ref > src/types/database.types.ts
```

Example usage:

```typescript
import { Database } from './types/database.types';

type Customer = Database['public']['Tables']['customers']['Row'];
type CustomerInsert = Database['public']['Tables']['customers']['Insert'];
type CustomerUpdate = Database['public']['Tables']['customers']['Update'];
```

## Backup & Restore

### Backup

```bash
# Using Supabase CLI
supabase db dump -f backup.sql

# Or using pg_dump
pg_dump -h db.your-project.supabase.co -U postgres -d postgres > backup.sql
```

### Restore

```bash
# Using Supabase CLI
supabase db reset

# Or using psql
psql -h db.your-project.supabase.co -U postgres -d postgres < backup.sql
```

## Performance Optimization

### Indexes

All foreign keys and frequently queried columns are indexed. See migration file for details.

### Query Optimization Tips

1. **Use views** for complex joins (e.g., `order_summary`)
2. **Limit results** with pagination
3. **Select only needed columns** instead of `SELECT *`
4. **Use prepared statements** to prevent SQL injection and improve performance

### Monitoring

Monitor query performance in Supabase Dashboard:
1. Go to **Database** → **Query Performance**
2. Identify slow queries
3. Add indexes as needed

## Troubleshooting

### Common Issues

#### 1. RLS Blocking Queries

If queries return empty results, check RLS policies:

```sql
-- Temporarily disable RLS for testing (NOT for production)
ALTER TABLE table_name DISABLE ROW LEVEL SECURITY;
```

#### 2. Foreign Key Violations

Ensure referenced records exist before inserting:

```sql
-- Check if customer exists before creating order
SELECT id FROM customers WHERE id = $1;
```

#### 3. ENUM Type Errors

If you need to add values to ENUM types:

```sql
ALTER TYPE role_type ADD VALUE 'new_role';
```

**Note:** You cannot remove ENUM values. Consider using a table instead (like `order_statuses`).

## Best Practices

1. **Always use transactions** for multi-table operations
2. **Validate data** in your application before inserting
3. **Use prepared statements** to prevent SQL injection
4. **Log all data modifications** in `task_logs`
5. **Test RLS policies** thoroughly before deploying
6. **Keep migrations versioned** and never modify existing migration files
7. **Use meaningful names** for custom statuses and task types
8. **Regularly backup** your database

## Migration Checklist

Before running migrations in production:

- [ ] Backup current database
- [ ] Test migration on staging environment
- [ ] Review all RLS policies
- [ ] Verify seed data is correct
- [ ] Check for breaking changes
- [ ] Update application code if schema changed
- [ ] Test all API endpoints after migration
- [ ] Monitor for errors after deployment

## Support

For database-related issues:
- Check Supabase documentation: https://supabase.com/docs
- Review migration files in `/backend/supabase/migrations/`
- Check application logs for SQL errors
- Verify environment variables are set correctly
