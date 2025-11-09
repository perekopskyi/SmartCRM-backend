# Database Migration Guide

## Quick Start - Run Migrations Now

### Option 1: Supabase Dashboard (Recommended)

1. **Open Supabase Dashboard**
   - Go to [https://supabase.com/dashboard](https://supabase.com/dashboard)
   - Select your SmartCRM project

2. **Navigate to SQL Editor**
   - Click on **SQL Editor** in the left sidebar
   - Click **New Query**

3. **Copy Migration SQL**
   - Open: `backend/supabase/migrations/20251109000000_initial_schema.sql`
   - Copy the entire file contents (Cmd+A, Cmd+C)

4. **Execute Migration**
   - Paste into the SQL Editor
   - Click **Run** (or press Cmd+Enter)
   - Wait for completion (should take 5-10 seconds)

5. **Verify Success**
   - You should see "Success. No rows returned"
   - Check the **Table Editor** to see your new tables

### Option 2: Supabase CLI

```bash
# From the backend directory
cd backend

# Install Supabase CLI (if not installed)
npm install -g supabase

# Login to Supabase
supabase login

# Link to your project
supabase link --project-ref YOUR_PROJECT_REF

# Push migration
supabase db push
```

### Option 3: psql Command Line

```bash
# Get your database connection string from Supabase Dashboard
# Settings > Database > Connection String (Direct connection)

psql "postgresql://postgres:[YOUR-PASSWORD]@db.[YOUR-PROJECT-REF].supabase.co:5432/postgres" \
  -f supabase/migrations/20251109000000_initial_schema.sql
```

## Verification Steps

After running the migration, verify it worked:

### 1. Check Tables

In Supabase Dashboard → **Table Editor**, you should see:

- ✅ roles
- ✅ order_statuses
- ✅ users
- ✅ customers
- ✅ orders
- ✅ order_items
- ✅ tasks
- ✅ task_items
- ✅ transactions
- ✅ files
- ✅ task_logs

### 2. Check Seed Data

Run this query in SQL Editor:

```sql
-- Check roles
SELECT * FROM roles;
-- Should return 5 roles: owner, accountant, employee, contractor, customer

-- Check order statuses
SELECT * FROM order_statuses ORDER BY sort_order;
-- Should return 7 statuses: new, in_progress, assembly, installation, completed, cancelled, overdue
```

### 3. Check Views

```sql
-- These views should exist
SELECT * FROM order_summary LIMIT 1;
SELECT * FROM customer_stats LIMIT 1;
```

### 4. Check RLS

```sql
-- Verify RLS is enabled
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY tablename;
-- All tables should have rowsecurity = true
```

## What This Migration Creates

### Tables (11)

1. **roles** - User role definitions
2. **order_statuses** - Dynamic order statuses (customizable)
3. **users** - Employee/user accounts
4. **customers** - Customer information
5. **orders** - Customer orders
6. **order_items** - Order line items
7. **tasks** - Tasks for orders
8. **task_items** - Task checklist items
9. **transactions** - Financial transactions
10. **files** - File attachments
11. **task_logs** - Activity audit trail

### ENUM Types (4)

- `role_type`
- `payment_type`
- `transaction_type`
- `task_status_type`

### Indexes (19)

Strategic indexes on foreign keys and frequently queried columns for performance.

### Triggers (4)

Auto-update `updated_at` timestamps on:
- users
- customers
- orders
- tasks

### Views (2)

- `order_summary` - Aggregated order data
- `customer_stats` - Customer statistics

### Seed Data

- **5 roles**: owner, accountant, employee, contractor, customer
- **7 order statuses**: new, in_progress, assembly, installation, completed, cancelled, overdue

### Row Level Security (RLS)

All tables have RLS enabled with policies for authenticated users.

## Troubleshooting

### Error: "relation already exists"

**Cause:** Migration has already been run.

**Solution:** 
- Skip this migration, or
- Drop all tables first (⚠️ **WARNING: This deletes all data!**)

```sql
-- Only run if you want to start fresh
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO public;
```

### Error: "permission denied"

**Cause:** Insufficient database permissions.

**Solution:**
- Make sure you're logged in to Supabase Dashboard
- Use the service role key (not anon key) if using API
- Contact your Supabase project admin

### Error: "syntax error"

**Cause:** SQL syntax issue or incomplete copy/paste.

**Solution:**
- Make sure you copied the ENTIRE migration file
- Check for any special characters that might have been corrupted
- Try copying in smaller chunks

### Tables Not Showing in Table Editor

**Cause:** Cache or refresh issue.

**Solution:**
- Refresh the page (Cmd+R / Ctrl+R)
- Clear browser cache
- Try a different browser

## Next Steps

After successful migration:

1. ✅ **Update Backend Code**
   - Create NestJS entities matching the schema
   - Update DTOs and services
   - Test API endpoints

2. ✅ **Update Frontend Code**
   - Generate TypeScript types from Supabase
   - Update API calls to match new schema
   - Test UI components

3. ✅ **Create Test Data**
   - Add sample customers
   - Create test orders
   - Verify all relationships work

4. ✅ **Test Authentication**
   - Sign up a new user
   - Verify user is created in `users` table
   - Test RLS policies

## Rollback

If you need to rollback this migration:

```sql
-- ⚠️ WARNING: This will delete ALL data!

-- Drop all tables
DROP TABLE IF EXISTS task_logs CASCADE;
DROP TABLE IF EXISTS files CASCADE;
DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS task_items CASCADE;
DROP TABLE IF EXISTS tasks CASCADE;
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS order_statuses CASCADE;
DROP TABLE IF EXISTS roles CASCADE;

-- Drop views
DROP VIEW IF EXISTS customer_stats;
DROP VIEW IF EXISTS order_summary;

-- Drop ENUM types
DROP TYPE IF EXISTS task_status_type;
DROP TYPE IF EXISTS transaction_type;
DROP TYPE IF EXISTS payment_type;
DROP TYPE IF EXISTS role_type;

-- Drop function
DROP FUNCTION IF EXISTS update_updated_at_column();
```

## Support

- 📖 [Database Schema Documentation](./DATABASE.md)
- 📊 [ER Diagram](../database/ER_DIAGRAM.md)
- 🔧 [Supabase Documentation](https://supabase.com/docs)
- 💬 Need help? Check the project README or contact the team

---

**Ready to migrate?** Follow Option 1 above to get started! 🚀
