# SmartCRM Database ER Diagram

## Entity Relationship Diagram

```mermaid
erDiagram
    roles ||--o{ users : "has"
    users ||--o{ orders : "manages"
    users ||--o{ tasks : "assigned_to"
    users ||--o{ transactions : "created_by"
    users ||--o{ files : "uploaded_by"
    users ||--o{ task_logs : "performed_by"
    
    customers ||--o{ orders : "places"
    customers ||--o{ transactions : "has"
    
    order_statuses ||--o{ orders : "has_status"
    
    orders ||--o{ order_items : "contains"
    orders ||--o{ tasks : "has"
    orders ||--o{ transactions : "has"
    orders ||--o{ files : "has"
    orders ||--o{ task_logs : "has"
    
    tasks ||--o{ task_items : "contains"
    tasks ||--o{ task_logs : "has"
    
    roles {
        int id PK
        enum name "owner|accountant|employee|contractor|customer"
        text description
        timestamp created_at
    }
    
    users {
        uuid id PK
        varchar email UK
        varchar first_name
        varchar last_name
        varchar phone
        int role_id FK
        boolean is_active
        timestamp created_at
        timestamp updated_at
    }
    
    customers {
        int id PK
        varchar first_name
        varchar last_name
        varchar phone
        varchar email
        text address
        decimal balance
        text notes
        timestamp created_at
        timestamp updated_at
    }
    
    order_statuses {
        int id PK
        varchar name UK
        varchar display_name
        varchar color
        text description
        boolean is_active
        int sort_order
        timestamp created_at
    }
    
    orders {
        int id PK
        int customer_id FK
        uuid employee_id FK
        int status_id FK
        text address
        decimal total_amount
        decimal balance
        text notes
        timestamp created_at
        timestamp updated_at
        timestamp completed_at
    }
    
    order_items {
        int id PK
        int order_id FK
        text description
        int quantity
        decimal unit_price
        decimal total_price "COMPUTED"
        timestamp created_at
    }
    
    tasks {
        int id PK
        int order_id FK
        uuid employee_id FK
        varchar title
        text description
        enum status "todo|in_progress|done"
        timestamp due_date
        timestamp created_at
        timestamp updated_at
        timestamp completed_at
    }
    
    task_items {
        int id PK
        int task_id FK
        varchar item_type
        text description
        boolean is_completed
        timestamp created_at
        timestamp completed_at
    }
    
    transactions {
        int id PK
        int order_id FK
        int customer_id FK
        decimal amount
        enum type "income|expense|refund"
        enum payment_type "cash|cashless|online"
        text description
        timestamp date
        uuid created_by FK
        timestamp created_at
    }
    
    files {
        int id PK
        int order_id FK
        varchar file_name
        text file_path
        int file_size
        varchar mime_type
        uuid uploaded_by FK
        timestamp created_at
    }
    
    task_logs {
        int id PK
        int task_id FK
        int order_id FK
        uuid user_id FK
        varchar action
        text description
        timestamp created_at
    }
```

## Table Relationships

### **Core Entities**

1. **roles** → **users** (1:N)
   - Each user has one role
   - A role can be assigned to many users

2. **users** (Employees)
   - Manages orders
   - Assigned to tasks
   - Creates transactions
   - Uploads files
   - Performs actions (task_logs)

3. **customers**
   - Places orders
   - Has transaction history
   - Has balance tracking

### **Order Management**

1. **orders**
   - Belongs to one customer
   - Managed by one employee
   - Contains multiple order_items
   - Has multiple tasks
   - Has transaction history
   - Can have attached files

2. **order_items**
   - Line items for each order
   - Tracks quantity, price, and total

### **Task Management**

1. **tasks**
   - Belongs to one order
   - Assigned to one employee
   - Contains checklist items (task_items)
   - Has activity logs

2. **task_items**
   - Checklist items for tasks
   - Predefined types (removal, delivery, installation, etc.)

### **Financial Tracking**

1. **transactions**
   - Linked to orders and customers
   - Tracks income, expenses, refunds
   - Multiple payment types

### **Supporting Tables**

1. **files**
   - Attached to orders
   - Tracks uploader and metadata

2. **task_logs**
   - Activity history for tasks and orders
   - Audit trail

## Data Flow

```mermaid
graph TD
    A[Customer] -->|places| B[Order]
    B -->|contains| C[Order Items]
    B -->|generates| D[Tasks]
    D -->|assigned to| E[Employee]
    D -->|has| F[Task Items]
    B -->|creates| G[Transactions]
    G -->|updates| H[Customer Balance]
    G -->|updates| I[Order Balance]
    E -->|performs| J[Task Logs]
    B -->|has| K[Files]
```

## Key Features

### Financial Tracking

- Customer balance management
- Order balance tracking (paid vs. total)
- Transaction history with types (income/expense/refund)
- Multiple payment methods

### Task Management Features

- Tasks linked to orders
- Checklist items for each task
- Employee assignment
- Status tracking
- Activity logs

### Audit Trail

- `created_at` and `updated_at` timestamps on all major tables
- `task_logs` for activity history
- User tracking on transactions and files

### Flexibility

- ENUM types for standardized values
- Soft relationships (nullable FKs where appropriate)
- Computed columns (e.g., `total_price` in order_items)
- Views for common queries

## Indexes Strategy

- **Primary Keys**: All tables have indexed PKs
- **Foreign Keys**: All FKs are indexed for join performance
- **Status Fields**: Indexed for filtering
- **Date Fields**: Indexed for time-based queries
- **Email/Phone**: Indexed for search functionality

## Triggers

- **Auto-update timestamps**: `updated_at` automatically updated on record changes
- **Future enhancements**: Could add triggers for:
  - Auto-calculate order totals from order_items
  - Auto-update customer balance from transactions
  - Auto-create task_logs on status changes
