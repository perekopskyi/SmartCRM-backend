# Order Statuses - Dynamic Entity Feature

## Overview

Order statuses have been converted from a static ENUM to a flexible database table, allowing you to create, modify, and manage custom statuses without code changes.

## Benefits

✅ **Dynamic Status Creation** - Add new statuses via UI or SQL  
✅ **Custom Colors** - Assign colors for visual distinction  
✅ **Sorting Control** - Define display order with `sort_order`  
✅ **Active/Inactive** - Disable statuses without deleting them  
✅ **Localization Ready** - Store display names for different languages  
✅ **No Code Changes** - Add statuses without redeploying

## Table Structure

```sql
CREATE TABLE order_statuses (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,           -- Internal identifier (e.g., 'in_progress')
    display_name VARCHAR(100) NOT NULL,         -- User-facing name (e.g., 'In Progress')
    color VARCHAR(20),                          -- Hex color code (e.g., '#F59E0B')
    description TEXT,                           -- Optional description
    is_active BOOLEAN DEFAULT true,             -- Enable/disable status
    sort_order INTEGER DEFAULT 0,               -- Display order
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

## Default Statuses

| ID | Name | Display Name | Color | Sort Order | Description |
|----|------|--------------|-------|------------|-------------|
| 1 | new | New | #3B82F6 (Blue) | 1 | New order received |
| 2 | in_progress | In Progress | #F59E0B (Amber) | 2 | Order is being processed |
| 3 | assembly | Assembly | #8B5CF6 (Purple) | 3 | Assembly phase |
| 4 | installation | Installation | #EC4899 (Pink) | 4 | Installation phase |
| 5 | completed | Completed | #10B981 (Green) | 5 | Order completed |
| 6 | cancelled | Cancelled | #EF4444 (Red) | 6 | Order cancelled |
| 7 | overdue | Overdue | #DC2626 (Dark Red) | 7 | Order is overdue |

## Usage Examples

### Creating a New Status

```sql
INSERT INTO order_statuses (name, display_name, color, description, sort_order)
VALUES ('quality_check', 'Quality Check', '#06B6D4', 'Quality inspection phase', 8);
```

### Updating a Status

```sql
UPDATE order_statuses
SET display_name = 'Quality Inspection',
    color = '#0EA5E9'
WHERE name = 'quality_check';
```

### Disabling a Status

```sql
UPDATE order_statuses
SET is_active = false
WHERE name = 'overdue';
```

### Reordering Statuses

```sql
UPDATE order_statuses SET sort_order = 1 WHERE name = 'new';
UPDATE order_statuses SET sort_order = 2 WHERE name = 'in_progress';
UPDATE order_statuses SET sort_order = 3 WHERE name = 'quality_check';
UPDATE order_statuses SET sort_order = 4 WHERE name = 'assembly';
-- ... etc
```

### Querying Orders by Status

```sql
-- Get all orders in "In Progress" status
SELECT o.*, os.display_name AS status_name, os.color AS status_color
FROM orders o
JOIN order_statuses os ON o.status_id = os.id
WHERE os.name = 'in_progress';
```

### Getting Active Statuses for Dropdown

```sql
SELECT id, name, display_name, color
FROM order_statuses
WHERE is_active = true
ORDER BY sort_order;
```

## Frontend Integration

### TypeScript Type

```typescript
interface OrderStatus {
  id: number;
  name: string;
  display_name: string;
  color: string;
  description?: string;
  is_active: boolean;
  sort_order: number;
  created_at: string;
}
```

### API Endpoints (Suggested)

```typescript
// Get all active statuses
GET /api/order-statuses?active=true

// Get all statuses (admin only)
GET /api/order-statuses

// Create new status (admin only)
POST /api/order-statuses
{
  "name": "quality_check",
  "display_name": "Quality Check",
  "color": "#06B6D4",
  "description": "Quality inspection phase",
  "sort_order": 8
}

// Update status (admin only)
PATCH /api/order-statuses/:id
{
  "display_name": "Quality Inspection",
  "color": "#0EA5E9"
}

// Delete/Deactivate status (admin only)
DELETE /api/order-statuses/:id
```

### React Component Example

```tsx
import { Badge } from '@/components/ui/badge';

interface OrderStatusBadgeProps {
  status: OrderStatus;
}

export function OrderStatusBadge({ status }: OrderStatusBadgeProps) {
  return (
    <Badge 
      style={{ 
        backgroundColor: status.color,
        color: '#fff'
      }}
    >
      {status.display_name}
    </Badge>
  );
}
```

### Status Dropdown

```tsx
import { Select } from '@/components/ui/select';

interface StatusSelectProps {
  value: number;
  onChange: (statusId: number) => void;
  statuses: OrderStatus[];
}

export function StatusSelect({ value, onChange, statuses }: StatusSelectProps) {
  return (
    <Select value={value} onValueChange={onChange}>
      {statuses
        .filter(s => s.is_active)
        .sort((a, b) => a.sort_order - b.sort_order)
        .map(status => (
          <option key={status.id} value={status.id}>
            <span style={{ color: status.color }}>●</span> {status.display_name}
          </option>
        ))}
    </Select>
  );
}
```

## Backend Integration (NestJS)

### Entity

```typescript
// src/order-statuses/entities/order-status.entity.ts
import { Entity, Column, PrimaryGeneratedColumn, CreateDateColumn, OneToMany } from 'typeorm';
import { Order } from '../../orders/entities/order.entity';

@Entity('order_statuses')
export class OrderStatus {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ unique: true, length: 50 })
  name: string;

  @Column({ length: 100 })
  display_name: string;

  @Column({ nullable: true, length: 20 })
  color?: string;

  @Column({ type: 'text', nullable: true })
  description?: string;

  @Column({ default: true })
  is_active: boolean;

  @Column({ default: 0 })
  sort_order: number;

  @CreateDateColumn()
  created_at: Date;

  @OneToMany(() => Order, order => order.status)
  orders: Order[];
}
```

### Updated Order Entity

```typescript
// src/orders/entities/order.entity.ts
import { Entity, Column, ManyToOne, JoinColumn } from 'typeorm';
import { OrderStatus } from '../../order-statuses/entities/order-status.entity';

@Entity('orders')
export class Order {
  // ... other fields

  @ManyToOne(() => OrderStatus, status => status.orders)
  @JoinColumn({ name: 'status_id' })
  status: OrderStatus;

  @Column()
  status_id: number;

  // ... other fields
}
```

### Service

```typescript
// src/order-statuses/order-statuses.service.ts
import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { OrderStatus } from './entities/order-status.entity';

@Injectable()
export class OrderStatusesService {
  constructor(
    @InjectRepository(OrderStatus)
    private orderStatusesRepository: Repository<OrderStatus>,
  ) {}

  async findAll(activeOnly = false): Promise<OrderStatus[]> {
    const query = this.orderStatusesRepository.createQueryBuilder('status');
    
    if (activeOnly) {
      query.where('status.is_active = :active', { active: true });
    }
    
    return query.orderBy('status.sort_order', 'ASC').getMany();
  }

  async findByName(name: string): Promise<OrderStatus> {
    return this.orderStatusesRepository.findOne({ where: { name } });
  }

  async create(data: Partial<OrderStatus>): Promise<OrderStatus> {
    const status = this.orderStatusesRepository.create(data);
    return this.orderStatusesRepository.save(status);
  }

  async update(id: number, data: Partial<OrderStatus>): Promise<OrderStatus> {
    await this.orderStatusesRepository.update(id, data);
    return this.orderStatusesRepository.findOne({ where: { id } });
  }

  async deactivate(id: number): Promise<void> {
    await this.orderStatusesRepository.update(id, { is_active: false });
  }
}
```

## Migration Considerations

### If Migrating from ENUM

If you previously used an ENUM type, you'll need to:

1. **Create the new table**
2. **Seed default statuses**
3. **Add status_id column to orders**
4. **Migrate existing data**
5. **Drop old status column**
6. **Drop ENUM type**

```sql
-- 1. Create order_statuses table (already in schema.sql)

-- 2. Seed default statuses (already in schema.sql)

-- 3. Add status_id column (if migrating)
ALTER TABLE orders ADD COLUMN status_id INTEGER;

-- 4. Migrate data (map old ENUM to new IDs)
UPDATE orders SET status_id = 1 WHERE status = 'new';
UPDATE orders SET status_id = 2 WHERE status = 'in_progress';
UPDATE orders SET status_id = 3 WHERE status = 'assembly';
UPDATE orders SET status_id = 4 WHERE status = 'installation';
UPDATE orders SET status_id = 5 WHERE status = 'completed';
UPDATE orders SET status_id = 6 WHERE status = 'cancelled';
UPDATE orders SET status_id = 7 WHERE status = 'overdue';

-- 5. Make status_id NOT NULL and add FK
ALTER TABLE orders ALTER COLUMN status_id SET NOT NULL;
ALTER TABLE orders ADD CONSTRAINT fk_orders_status 
  FOREIGN KEY (status_id) REFERENCES order_statuses(id);

-- 6. Drop old column and ENUM
ALTER TABLE orders DROP COLUMN status;
DROP TYPE IF EXISTS order_status_type;
```

## Best Practices

### 1. Use `name` for Code Logic

Always reference statuses by `name` in your code, not by `id`:

```typescript
// ✅ Good - stable across environments
const inProgressStatus = await statusService.findByName('in_progress');

// ❌ Bad - IDs may differ across environments
const inProgressStatus = await statusService.findById(2);
```

### 2. Cache Statuses

Since statuses change rarely, cache them:

```typescript
// Cache for 1 hour
@Cacheable('order-statuses', 3600)
async getActiveStatuses(): Promise<OrderStatus[]> {
  return this.orderStatusesRepository.find({
    where: { is_active: true },
    order: { sort_order: 'ASC' }
  });
}
```

### 3. Validate Status Transitions

Implement business logic for valid status transitions:

```typescript
const VALID_TRANSITIONS = {
  'new': ['in_progress', 'cancelled'],
  'in_progress': ['assembly', 'cancelled'],
  'assembly': ['installation', 'completed'],
  'installation': ['completed'],
  'completed': [],
  'cancelled': []
};

async canTransition(fromStatus: string, toStatus: string): boolean {
  return VALID_TRANSITIONS[fromStatus]?.includes(toStatus) ?? false;
}
```

### 4. Prevent Deletion of In-Use Statuses

```typescript
async delete(id: number): Promise<void> {
  const orderCount = await this.ordersRepository.count({
    where: { status_id: id }
  });
  
  if (orderCount > 0) {
    throw new BadRequestException(
      `Cannot delete status: ${orderCount} orders are using it`
    );
  }
  
  await this.orderStatusesRepository.delete(id);
}
```

### 5. Audit Status Changes

Log when order statuses change:

```typescript
async updateOrderStatus(orderId: number, newStatusId: number, userId: string) {
  const order = await this.ordersRepository.findOne({ where: { id: orderId } });
  const oldStatus = order.status_id;
  
  order.status_id = newStatusId;
  await this.ordersRepository.save(order);
  
  // Log the change
  await this.taskLogsRepository.save({
    order_id: orderId,
    user_id: userId,
    action: 'status_changed',
    description: `Status changed from ${oldStatus} to ${newStatusId}`
  });
}
```

## Future Enhancements

- **Workflow Rules**: Define automatic transitions based on conditions
- **Notifications**: Send notifications when status changes
- **Permissions**: Role-based access to certain statuses
- **Multi-language**: Store translations for display_name
- **Status Icons**: Add icon field for visual representation
- **Status Categories**: Group statuses (e.g., 'active', 'completed', 'cancelled')

---

**Ready to implement!** The schema is updated and ready for Supabase migration.
