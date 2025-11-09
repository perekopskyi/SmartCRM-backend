# Supabase Migrations

This directory contains all database migrations for SmartCRM.

## Structure

```
supabase/
├── migrations/
│   ├── 20251109000000_initial_schema.sql
│   └── 20251109000001_auth_user_sync.sql
└── README.md
```

## Running Migrations

### Method 1: Supabase CLI (Recommended)

```bash
# Install Supabase CLI globally
npm install -g supabase

# Login to Supabase
supabase login

# Link to your project
supabase link --project-ref your-project-ref

# Push migrations to Supabase
supabase db push
```

### Method 2: Supabase Dashboard

1. Go to your Supabase project dashboard
2. Navigate to **SQL Editor**
3. Open the migration file: `migrations/20251109000000_initial_schema.sql`
4. Copy the entire contents
5. Paste into the SQL Editor
6. Click **Run**

### Method 3: Direct SQL Execution

```bash
# Using psql
psql -h db.your-project.supabase.co \
     -U postgres \
     -d postgres \
     -f migrations/20251109000000_initial_schema.sql
```

## Migration Files

### 20251109000000_initial_schema.sql

**Description:** Initial database schema

**Includes:**
- ENUM types (role_type, payment_type, transaction_type, task_status_type)
- Core tables (users, customers, orders, order_items, tasks, task_items, transactions, files, task_logs)
- Supporting tables (roles, order_statuses)
- Indexes for performance
- Triggers for auto-updating timestamps
- Seed data (default roles and order statuses)
- Views (order_summary, customer_stats)
- Row Level Security (RLS) policies

### 20251109000001_auth_user_sync.sql

**Description:** Automatic sync of Supabase Auth users to public.users table

**Includes:**
- `handle_new_user()` function - Creates user record on signup
- `on_auth_user_created` trigger - Fires when auth.users record is created
- Optional: Sync existing auth users (commented out by default)

**Purpose:** When a user signs up via Supabase Auth, automatically create a corresponding record in `public.users` with their email, name (from metadata), and default role.

**📖 See [AUTH_USER_SYNC.md](../AUTH_USER_SYNC.md) for detailed documentation**

## Creating New Migrations

When you need to modify the database schema:

1. Create a new migration file with timestamp:
   ```bash
   # Format: YYYYMMDDHHMMSS_description.sql
   touch migrations/20251109120000_add_customer_notes.sql
   ```

2. Write your migration SQL:
   ```sql
   -- Add new column
   ALTER TABLE customers ADD COLUMN notes TEXT;
   
   -- Create index if needed
   CREATE INDEX idx_customers_notes ON customers(notes);
   ```

3. Test the migration locally first

4. Apply to production using one of the methods above

## Best Practices

1. **Never modify existing migration files** - Always create new ones
2. **Use timestamps** in migration filenames for ordering
3. **Test migrations** on a staging database first
4. **Backup database** before running migrations in production
5. **Write reversible migrations** when possible (include DOWN migration)
6. **Document changes** in migration comments

## Rollback

If you need to rollback a migration:

```sql
-- Example: Rollback adding a column
ALTER TABLE customers DROP COLUMN notes;
```

**Note:** Supabase doesn't have built-in rollback. You need to write reverse migrations manually.

## Verifying Migrations

After running migrations, verify:

```sql
-- Check tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public';

-- Check seed data
SELECT * FROM roles;
SELECT * FROM order_statuses;

-- Check RLS is enabled
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public';
```

## Troubleshooting

### Error: "relation already exists"

The migration has already been run. Either:
- Skip this migration
- Drop the table first (⚠️ data loss)
- Create a new migration to modify the existing table

### Error: "permission denied"

Ensure you're using the correct database credentials with sufficient permissions.

### Error: "syntax error"

Check your SQL syntax. Common issues:
- Missing semicolons
- Incorrect ENUM syntax
- Invalid column types

## Environment Variables

Ensure these are set before running migrations:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your-service-role-key
```

**Note:** Use the **service role key** for migrations, not the anon key.

## Resources

- [Supabase CLI Documentation](https://supabase.com/docs/guides/cli)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Database Schema](../../database/ER_DIAGRAM.md)
