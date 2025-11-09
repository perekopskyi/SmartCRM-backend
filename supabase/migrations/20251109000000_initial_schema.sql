-- SmartCRM Initial Schema Migration
-- Created: 2025-11-09
-- Description: Creates all tables, indexes, triggers, views, and seed data

-- ============================================
-- ENUM TYPES
-- ============================================

-- Role types
CREATE TYPE role_type AS ENUM ('owner', 'accountant', 'employee', 'contractor', 'customer');

-- Payment types
CREATE TYPE payment_type AS ENUM ('cash', 'cashless', 'online');

-- Transaction types
CREATE TYPE transaction_type AS ENUM ('income', 'expense', 'refund');

-- Task status types
CREATE TYPE task_status_type AS ENUM ('todo', 'in_progress', 'done');

-- ============================================
-- CORE TABLES
-- ============================================

-- Roles table
CREATE TABLE roles (
    id SERIAL PRIMARY KEY,
    name role_type NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Order statuses table (flexible, can add new statuses)
CREATE TABLE order_statuses (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    display_name VARCHAR(100) NOT NULL,
    color VARCHAR(20),
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Users/Employees table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    role_id INTEGER REFERENCES roles(id),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Customers table
CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(255),
    address TEXT,
    balance DECIMAL(10, 2) DEFAULT 0.00,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Orders table
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    employee_id UUID REFERENCES users(id),
    status_id INTEGER NOT NULL REFERENCES order_statuses(id),
    address TEXT,
    total_amount DECIMAL(10, 2) DEFAULT 0.00,
    balance DECIMAL(10, 2) DEFAULT 0.00,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE
);

-- Order items table (what's included in each order)
CREATE TABLE order_items (
    id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    description TEXT NOT NULL,
    quantity INTEGER DEFAULT 1,
    unit_price DECIMAL(10, 2) NOT NULL,
    total_price DECIMAL(10, 2) GENERATED ALWAYS AS (quantity * unit_price) STORED,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tasks table
CREATE TABLE tasks (
    id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    employee_id UUID REFERENCES users(id),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    status task_status_type DEFAULT 'todo',
    due_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE
);

-- Task items (checklist items for tasks)
CREATE TABLE task_items (
    id SERIAL PRIMARY KEY,
    task_id INTEGER NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    item_type VARCHAR(100) NOT NULL,
    description TEXT,
    is_completed BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE
);

-- Transactions table (financial records)
CREATE TABLE transactions (
    id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(id) ON DELETE SET NULL,
    customer_id INTEGER REFERENCES customers(id) ON DELETE SET NULL,
    amount DECIMAL(10, 2) NOT NULL,
    type transaction_type NOT NULL,
    payment_type payment_type NOT NULL,
    description TEXT,
    date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Files/Documents table
CREATE TABLE files (
    id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(id) ON DELETE CASCADE,
    file_name VARCHAR(255) NOT NULL,
    file_path TEXT NOT NULL,
    file_size INTEGER,
    mime_type VARCHAR(100),
    uploaded_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Task logs (activity history)
CREATE TABLE task_logs (
    id SERIAL PRIMARY KEY,
    task_id INTEGER REFERENCES tasks(id) ON DELETE CASCADE,
    order_id INTEGER REFERENCES orders(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id),
    action VARCHAR(100) NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- INDEXES
-- ============================================

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role_id ON users(role_id);
CREATE INDEX idx_customers_email ON customers(email);
CREATE INDEX idx_customers_phone ON customers(phone);
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_orders_employee_id ON orders(employee_id);
CREATE INDEX idx_orders_status_id ON orders(status_id);
CREATE INDEX idx_orders_created_at ON orders(created_at);
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_tasks_order_id ON tasks(order_id);
CREATE INDEX idx_tasks_employee_id ON tasks(employee_id);
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_task_items_task_id ON task_items(task_id);
CREATE INDEX idx_transactions_order_id ON transactions(order_id);
CREATE INDEX idx_transactions_customer_id ON transactions(customer_id);
CREATE INDEX idx_transactions_date ON transactions(date);
CREATE INDEX idx_files_order_id ON files(order_id);
CREATE INDEX idx_task_logs_task_id ON task_logs(task_id);
CREATE INDEX idx_task_logs_order_id ON task_logs(order_id);

-- ============================================
-- TRIGGERS
-- ============================================

-- Update updated_at timestamp automatically
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_customers_updated_at BEFORE UPDATE ON customers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON orders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tasks_updated_at BEFORE UPDATE ON tasks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- SEED DATA
-- ============================================

-- Insert default roles
INSERT INTO roles (name, description) VALUES
    ('owner', 'Business owner with full access'),
    ('accountant', 'Financial management and reporting'),
    ('employee', 'Regular employee'),
    ('contractor', 'External contractor'),
    ('customer', 'Customer with limited access');

-- Insert default order statuses
INSERT INTO order_statuses (name, display_name, color, description, sort_order) VALUES
    ('new', 'New', '#3B82F6', 'New order received', 1),
    ('in_progress', 'In Progress', '#F59E0B', 'Order is being processed', 2),
    ('assembly', 'Assembly', '#8B5CF6', 'Assembly phase', 3),
    ('installation', 'Installation', '#EC4899', 'Installation phase', 4),
    ('completed', 'Completed', '#10B981', 'Order completed', 5),
    ('cancelled', 'Cancelled', '#EF4444', 'Order cancelled', 6),
    ('overdue', 'Overdue', '#DC2626', 'Order is overdue', 7);

-- ============================================
-- VIEWS
-- ============================================

-- Order summary view
CREATE VIEW order_summary AS
SELECT 
    o.id,
    o.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    c.phone AS customer_phone,
    o.employee_id,
    u.first_name || ' ' || u.last_name AS employee_name,
    o.status_id,
    os.name AS status_name,
    os.display_name AS status_display_name,
    os.color AS status_color,
    o.total_amount,
    o.balance,
    o.created_at,
    o.completed_at,
    COUNT(DISTINCT oi.id) AS item_count,
    COUNT(DISTINCT t.id) AS task_count
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.id
LEFT JOIN users u ON o.employee_id = u.id
LEFT JOIN order_statuses os ON o.status_id = os.id
LEFT JOIN order_items oi ON o.id = oi.order_id
LEFT JOIN tasks t ON o.id = t.order_id
GROUP BY o.id, c.id, u.id, os.id;

-- Customer statistics view
CREATE VIEW customer_stats AS
SELECT 
    c.id,
    c.first_name || ' ' || c.last_name AS customer_name,
    c.email,
    c.phone,
    c.balance,
    COUNT(DISTINCT o.id) AS total_orders,
    SUM(o.total_amount) AS total_spent,
    MAX(o.created_at) AS last_order_date
FROM customers c
LEFT JOIN orders o ON c.id = o.customer_id
GROUP BY c.id;

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE files ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_logs ENABLE ROW LEVEL SECURITY;

-- Users policies
CREATE POLICY "Users can view all users" ON users
    FOR SELECT USING (true);

CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (auth.uid() = id);

-- Customers policies (authenticated users can manage customers)
CREATE POLICY "Authenticated users can view customers" ON customers
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can create customers" ON customers
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can update customers" ON customers
    FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can delete customers" ON customers
    FOR DELETE USING (auth.role() = 'authenticated');

-- Orders policies (authenticated users can manage orders)
CREATE POLICY "Authenticated users can view orders" ON orders
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can create orders" ON orders
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can update orders" ON orders
    FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can delete orders" ON orders
    FOR DELETE USING (auth.role() = 'authenticated');

-- Order items policies (cascade from orders)
CREATE POLICY "Authenticated users can view order items" ON order_items
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can create order items" ON order_items
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can update order items" ON order_items
    FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can delete order items" ON order_items
    FOR DELETE USING (auth.role() = 'authenticated');

-- Tasks policies
CREATE POLICY "Authenticated users can view tasks" ON tasks
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can create tasks" ON tasks
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can update tasks" ON tasks
    FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can delete tasks" ON tasks
    FOR DELETE USING (auth.role() = 'authenticated');

-- Task items policies
CREATE POLICY "Authenticated users can view task items" ON task_items
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can create task items" ON task_items
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can update task items" ON task_items
    FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can delete task items" ON task_items
    FOR DELETE USING (auth.role() = 'authenticated');

-- Transactions policies
CREATE POLICY "Authenticated users can view transactions" ON transactions
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can create transactions" ON transactions
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can update transactions" ON transactions
    FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can delete transactions" ON transactions
    FOR DELETE USING (auth.role() = 'authenticated');

-- Files policies
CREATE POLICY "Authenticated users can view files" ON files
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can upload files" ON files
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can delete files" ON files
    FOR DELETE USING (auth.role() = 'authenticated');

-- Task logs policies (read-only for most, insert for authenticated)
CREATE POLICY "Authenticated users can view task logs" ON task_logs
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can create task logs" ON task_logs
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');
