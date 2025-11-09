# SmartCRM Visual Database Schema

## Simplified Visual Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                         SMARTCRM DATABASE                            │
└─────────────────────────────────────────────────────────────────────┘

┌──────────────┐
│    ROLES     │
│──────────────│
│ id           │
│ name         │◄──────┐
│ description  │       │
└──────────────┘       │
                       │
                       │ role_id
                       │
┌──────────────┐       │
│    USERS     │       │
│──────────────│       │
│ id (UUID)    │───────┘
│ email        │
│ first_name   │
│ last_name    │
│ phone        │
│ is_active    │
└──────┬───────┘
       │
       │ employee_id
       │
       ├─────────────────────────────────────────────┐
       │                                             │
       │                                             │
       ▼                                             ▼
┌──────────────┐                              ┌──────────────┐
│  CUSTOMERS   │                              │    TASKS     │
│──────────────│                              │──────────────│
│ id           │                              │ id           │
│ first_name   │                              │ order_id     │
│ last_name    │                              │ employee_id  │
│ phone        │                              │ title        │
│ email        │                              │ description  │
│ address      │                              │ status       │
│ balance      │                              │ due_date     │
│ notes        │                              └──────┬───────┘
└──────┬───────┘                                     │
       │                                             │
       │ customer_id                                 │ task_id
       │                                             │
       ▼                                             ▼
┌──────────────┐      ┌──────────────────┐    ┌──────────────┐
│    ORDERS    │      │ ORDER_STATUSES   │    │  TASK_ITEMS  │
│──────────────│      │──────────────────│    │──────────────│
│ id           │      │ id               │    │ id           │
│ customer_id  │◄─┐   │ name (UK)        │    │ task_id      │
│ employee_id  │  │   │ display_name     │    │ item_type    │
│ status_id    │──┼──►│ color            │    │ description  │
│ address      │  │   │ description      │    │ is_completed │
│ total_amount │  │   │ is_active        │    └──────────────┘
│ balance      │  │   │ sort_order       │
│ notes        │  │   └──────────────────┘
└──────┬───────┘  │
       │                              │
       │ order_id                     │ order_id
       │                              │
       ├──────────────┬───────────────┼──────────────┬──────────────┐
       │              │               │              │              │
       ▼              ▼               ▼              ▼              ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│ ORDER_ITEMS  │ │TRANSACTIONS  │ │    FILES     │ │  TASK_LOGS   │ │    TASKS     │
│──────────────│ │──────────────│ │──────────────│ │──────────────│ │──────────────│
│ id           │ │ id           │ │ id           │ │ id           │ │ (see above)  │
│ order_id     │ │ order_id     │ │ order_id     │ │ order_id     │ └──────────────┘
│ description  │ │ customer_id  │ │ file_name    │ │ task_id      │
│ quantity     │ │ amount       │ │ file_path    │ │ user_id      │
│ unit_price   │ │ type         │ │ file_size    │ │ action       │
│ total_price  │ │ payment_type │ │ mime_type    │ │ description  │
└──────────────┘ │ description  │ │ uploaded_by  │ └──────────────┘
                 │ created_by   │ └──────────────┘
                 └──────────────┘
```

## Data Flow Diagram

```
┌─────────────┐
│  Customer   │
│  (Client)   │
└──────┬──────┘
       │
       │ 1. Places Order
       ▼
┌─────────────┐
│    Order    │◄───────────┐
│             │            │
│ • Items     │            │ 3. Manages
│ • Status    │            │
│ • Total     │            │
└──────┬──────┘     ┌──────┴──────┐
       │            │   Employee  │
       │            │   (User)    │
       │            └─────────────┘
       │ 2. Generates              │
       ▼                           │
┌─────────────┐                    │
│    Tasks    │◄───────────────────┘
│             │            4. Assigned to
│ • Checklist │
│ • Status    │
│ • Due Date  │
└──────┬──────┘
       │
       │ 5. Logs Activity
       ▼
┌─────────────┐
│  Task Logs  │
│  (Audit)    │
└─────────────┘

       ┌─────────────┐
       │    Order    │
       └──────┬──────┘
              │
              │ 6. Creates
              ▼
       ┌─────────────┐
       │Transaction  │
       │             │
       │ • Amount    │
       │ • Type      │
       │ • Payment   │
       └──────┬──────┘
              │
              │ 7. Updates
              ▼
       ┌─────────────┐
       │  Balances   │
       │             │
       │ • Customer  │
       │ • Order     │
       └─────────────┘
```

## Table Relationships Summary

### Core Business Flow

```
Customer → Order → Order Items
                 → Tasks → Task Items
                 → Transactions
                 → Files
                 → Task Logs

Employee → Manages Orders
        → Assigned Tasks
        → Creates Transactions
        → Uploads Files
```

### Relationship Cardinality

| Parent | Relationship | Child | Type |
|--------|--------------|-------|------|
| **roles** | has | **users** | 1:N |
| **order_statuses** | has | **orders** | 1:N |
| **customers** | places | **orders** | 1:N |
| **users** | manages | **orders** | 1:N |
| **orders** | contains | **order_items** | 1:N |
| **orders** | has | **tasks** | 1:N |
| **orders** | has | **transactions** | 1:N |
| **orders** | has | **files** | 1:N |
| **tasks** | assigned to | **users** | N:1 |
| **tasks** | contains | **task_items** | 1:N |
| **tasks** | has | **task_logs** | 1:N |
| **customers** | has | **transactions** | 1:N |

## ENUM Types Reference

### order_statuses (Table - Dynamic)

Order statuses are now stored in a flexible table, allowing you to create custom statuses:

```
┌─────────────┬──────────────┬─────────┬────────────┐
│    name     │ display_name │  color  │ sort_order │
├─────────────┼──────────────┼─────────┼────────────┤
│    new      │     New      │ #3B82F6 │     1      │
│ in_progress │ In Progress  │ #F59E0B │     2      │
│  assembly   │   Assembly   │ #8B5CF6 │     3      │
│installation │Installation  │ #EC4899 │     4      │
│  completed  │  Completed   │ #10B981 │     5      │
│  cancelled  │  Cancelled   │ #EF4444 │     6      │
│   overdue   │   Overdue    │ #DC2626 │     7      │
└─────────────┴──────────────┴─────────┴────────────┘

✨ You can add new statuses via INSERT INTO order_statuses
```

### task_status_type

```
┌─────────────┐
│    todo     │ → Not started
├─────────────┤
│ in_progress │ → Being worked on
├─────────────┤
│    done     │ → Completed
└─────────────┘
```

### task_item_type (VARCHAR - Flexible)

Task item types are now stored as VARCHAR for maximum flexibility:

```
Common values:
- removal
- blum
- box
- wrapping
- delivery
- installation
- other

✨ You can use any custom value as needed
```

### payment_type

```
┌─────────────┐
│    cash     │ → Cash payment
├─────────────┤
│  cashless   │ → Bank transfer
├─────────────┤
│   online    │ → Online payment
└─────────────┘
```

### transaction_type

```
┌─────────────┐
│   income    │ → Money received
├─────────────┤
│   expense   │ → Money spent
├─────────────┤
│   refund    │ → Money returned
└─────────────┘
```

### role_type

```
┌─────────────┐
│    owner    │ → Business owner
├─────────────┤
│ accountant  │ → Accountant
├─────────────┤
│  employee   │ → Regular employee
├─────────────┤
│ contractor  │ → External contractor
├─────────────┤
│  customer   │ → Customer with limited access
└─────────────┘
```

## Key Indexes

```sql
-- Performance-critical indexes
orders.customer_id     → Fast customer order lookup
orders.employee_id     → Fast employee workload lookup
orders.status_id       → Fast status filtering
orders.created_at      → Fast date range queries
order_statuses.name    → Fast status lookup by name

tasks.order_id         → Fast order task lookup
tasks.employee_id      → Fast employee task lookup
tasks.status           → Fast task filtering

transactions.order_id  → Fast order transaction history
transactions.date      → Fast financial reports

users.email            → Fast authentication
customers.phone        → Fast customer search
```

## Computed Fields

```sql
-- Automatically calculated
order_items.total_price = quantity * unit_price

-- Auto-updated via triggers
*.updated_at = NOW() (on UPDATE)
```

## Cascade Behaviors

```sql
-- When order is deleted:
DELETE orders → CASCADE DELETE order_items
              → CASCADE DELETE tasks
              → CASCADE DELETE files
              → SET NULL transactions.order_id

-- When customer is deleted:
DELETE customers → CASCADE DELETE orders (and children)
                 → SET NULL transactions.customer_id

-- When task is deleted:
DELETE tasks → CASCADE DELETE task_items
             → CASCADE DELETE task_logs
```

## Security Considerations

1. **Row Level Security (RLS)** - Should be enabled in Supabase
2. **User Isolation** - Users should only see their assigned data
3. **Role-based Access** - Different permissions per role
4. **Audit Trail** - All changes logged via task_logs
5. **Soft Deletes** - Consider adding `deleted_at` instead of hard deletes

## Performance Optimization

1. **Indexes** - All FKs and frequently queried fields indexed
2. **Views** - Pre-computed joins for common queries
3. **Partitioning** - Consider partitioning large tables by date
4. **Archiving** - Move old completed orders to archive tables
5. **Caching** - Cache frequently accessed data (roles, statuses)

## Future Enhancements

1. **Notifications** - Table for system notifications
2. **Comments** - Comments on orders/tasks
3. **Attachments** - Multiple file types per order
4. **Templates** - Order templates for recurring work
5. **Inventory** - Track materials and stock
6. **Invoicing** - Generate invoices from orders
7. **Calendar** - Schedule tasks and appointments
8. **Reports** - Pre-built report templates
9. **Multi-language** - Translation tables for UI
10. **Webhooks** - External integrations
