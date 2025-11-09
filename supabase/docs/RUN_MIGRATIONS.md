# 🚀 Run Migrations - Quick Guide

## Prerequisites

You need your Supabase project credentials. Get them from:
1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project
3. Go to **Settings** → **API**
4. Copy:
   - **Project URL** (e.g., `https://xxxxx.supabase.co`)
   - **Project API keys** → **anon/public** key

## Step-by-Step Instructions

### Step 1: Open Supabase SQL Editor

1. Go to your Supabase Dashboard
2. Click **SQL Editor** in the left sidebar
3. Click **+ New query**

### Step 2: Copy Migration SQL

Open this file in your code editor:
```
backend/supabase/migrations/20251109000000_initial_schema.sql
```

Select all (Cmd+A / Ctrl+A) and copy (Cmd+C / Ctrl+C)

### Step 3: Paste and Run

1. Paste the SQL into the Supabase SQL Editor
2. Click **Run** (or press Cmd+Enter / Ctrl+Enter)
3. Wait 5-10 seconds for completion

### Step 4: Verify Success

You should see: **"Success. No rows returned"**

Check the **Table Editor** in the left sidebar. You should see these tables:
- customers
- files
- order_items
- order_statuses
- orders
- roles
- task_items
- task_logs
- tasks
- transactions
- users

### Step 5: Verify Seed Data

Run this query in SQL Editor:

```sql
SELECT * FROM roles;
```

You should see 5 roles:
- owner
- accountant  
- employee
- contractor
- customer

Run this query:

```sql
SELECT * FROM order_statuses ORDER BY sort_order;
```

You should see 7 statuses:
- new (Blue)
- in_progress (Amber)
- assembly (Purple)
- installation (Pink)
- completed (Green)
- cancelled (Red)
- overdue (Dark Red)

## ✅ Done!

Your database is now ready! 

## Next Steps

1. **Install dependencies** (if you haven't):
   ```bash
   cd backend
   pnpm install
   ```

2. **Set up environment variables**:
   ```bash
   cp .env.example .env
   ```
   
   Edit `.env` and add your Supabase credentials:
   ```env
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_KEY=your-anon-key-here
   PORT=2005
   NODE_ENV=development
   FRONTEND_URL=http://localhost:2000
   ```

3. **Start the backend**:
   ```bash
   pnpm run start:dev
   ```

4. **Test the API**:
   - Open http://localhost:2005/api (Swagger docs)
   - Try creating a customer
   - Verify data appears in Supabase

## Troubleshooting

### "relation already exists"
Migration already ran. You're good to go!

### "permission denied"
Make sure you're logged into Supabase Dashboard.

### Tables not showing
Refresh the page (Cmd+R / Ctrl+R).

## Need Help?

Check the detailed guides:
- [MIGRATION_GUIDE.md](./MIGRATION_GUIDE.md) - Detailed migration instructions
- [DATABASE.md](./DATABASE.md) - Database documentation
- [../database/ER_DIAGRAM.md](../database/ER_DIAGRAM.md) - Schema diagram
