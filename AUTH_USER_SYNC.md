# Supabase Auth User Sync

## Overview

Supabase stores authentication users in `auth.users` (internal table). Your application data is stored in `public.users`. This document explains how they sync automatically.

## How It Works

### Automatic Sync on Signup

When a user signs up via Supabase Auth:

1. **Supabase creates** a record in `auth.users` (authentication)
2. **Trigger fires** automatically (`on_auth_user_created`)
3. **Function runs** (`handle_new_user()`)
4. **Record created** in `public.users` (your application data)

### What Gets Synced

```typescript
// From auth.users → public.users
{
  id: auth_user.id,                                    // Same UUID
  email: auth_user.email,                              // Email address
  first_name: auth_user.raw_user_meta_data.first_name, // From signup metadata
  last_name: auth_user.raw_user_meta_data.last_name,   // From signup metadata
  role_id: default_role_id,                            // Default: employee role
  is_active: true                                      // Active by default
}
```

## Frontend Implementation

### Sign Up with Metadata

When users sign up, pass their name in metadata:

```typescript
// src/lib/auth.ts or your auth service
import { supabase } from './supabase';

export async function signUp(email: string, password: string, firstName: string, lastName: string) {
  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: {
      data: {
        first_name: firstName,  // ← This gets synced to public.users
        last_name: lastName,    // ← This gets synced to public.users
      }
    }
  });

  if (error) throw error;
  return data;
}
```

### Example Sign Up Form

```tsx
// src/components/SignUpForm.tsx
import { useState } from 'react';
import { signUp } from '@/lib/auth';

export function SignUpForm() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    try {
      await signUp(email, password, firstName, lastName);
      // User is now in both auth.users AND public.users
      alert('Check your email to confirm your account!');
    } catch (error) {
      console.error('Sign up error:', error);
    }
  };

  return (
    <form onSubmit={handleSubmit}>
      <input
        type="text"
        placeholder="First Name"
        value={firstName}
        onChange={(e) => setFirstName(e.target.value)}
        required
      />
      <input
        type="text"
        placeholder="Last Name"
        value={lastName}
        onChange={(e) => setLastName(e.target.value)}
        required
      />
      <input
        type="email"
        placeholder="Email"
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        required
      />
      <input
        type="password"
        placeholder="Password"
        value={password}
        onChange={(e) => setPassword(e.target.value)}
        required
      />
      <button type="submit">Sign Up</button>
    </form>
  );
}
```

## Accessing User Data

### Get Current User

```typescript
// Get auth user
const { data: { user } } = await supabase.auth.getUser();

// Get full user profile from public.users
const { data: profile } = await supabase
  .from('users')
  .select('*, roles(*)')
  .eq('id', user.id)
  .single();

console.log(profile);
// {
//   id: 'uuid',
//   email: 'user@example.com',
//   first_name: 'John',
//   last_name: 'Doe',
//   role_id: 3,
//   roles: { name: 'employee', description: '...' },
//   is_active: true,
//   created_at: '...',
//   updated_at: '...'
// }
```

### Backend Access (NestJS)

```typescript
// src/common/decorators/user.decorator.ts (already exists)
import { createParamDecorator, ExecutionContext } from '@nestjs/common';

export const User = createParamDecorator(
  (data: unknown, ctx: ExecutionContext) => {
    const request = ctx.switchToHttp().getRequest();
    return request.user; // Set by AuthGuard
  },
);

// Usage in controller
@Get('profile')
@UseGuards(AuthGuard)
async getProfile(@User() user: any) {
  // user.id is the UUID from auth.users
  const profile = await this.supabase
    .from('users')
    .select('*, roles(*)')
    .eq('id', user.id)
    .single();
    
  return profile.data;
}
```

## Querying Auth Users

### Get All Auth Users (Admin Only)

```typescript
// Backend only - requires service role key
import { createClient } from '@supabase/supabase-js';

const supabaseAdmin = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_KEY // ← Service role key, not anon key
);

// List all auth users
const { data: { users }, error } = await supabaseAdmin.auth.admin.listUsers();

console.log(users);
// [
//   { id: 'uuid', email: 'user@example.com', ... },
//   ...
// ]
```

### Get User by ID

```typescript
// Get from public.users (your app data)
const { data: user } = await supabase
  .from('users')
  .select('*')
  .eq('id', userId)
  .single();

// Get from auth.users (admin only)
const { data: { user: authUser } } = await supabaseAdmin.auth.admin.getUserById(userId);
```

## Updating User Data

### Update Profile (Public Data)

```typescript
// Update public.users (application data)
const { data, error } = await supabase
  .from('users')
  .update({
    first_name: 'Jane',
    last_name: 'Smith',
    phone: '+1234567890'
  })
  .eq('id', userId)
  .select()
  .single();
```

### Update Auth Data (Email/Password)

```typescript
// Update email (requires re-authentication)
const { data, error } = await supabase.auth.updateUser({
  email: 'newemail@example.com'
});

// Update password
const { data, error } = await supabase.auth.updateUser({
  password: 'newpassword123'
});

// Update metadata
const { data, error } = await supabase.auth.updateUser({
  data: {
    first_name: 'Jane',
    last_name: 'Smith'
  }
});
```

## Default Role Assignment

New users are automatically assigned the **employee** role. To change this:

### Option 1: Modify the Trigger

Edit the migration file:

```sql
-- Change default role from 'employee' to 'customer'
SELECT id INTO default_role_id FROM roles WHERE name = 'customer' LIMIT 1;
```

### Option 2: Update After Signup

```typescript
// After signup, update the role
async function signUpAsCustomer(email: string, password: string, firstName: string, lastName: string) {
  // Sign up
  const { data: authData } = await supabase.auth.signUp({
    email,
    password,
    options: { data: { first_name: firstName, last_name: lastName } }
  });

  // Get customer role ID
  const { data: customerRole } = await supabase
    .from('roles')
    .select('id')
    .eq('name', 'customer')
    .single();

  // Update user role
  await supabase
    .from('users')
    .update({ role_id: customerRole.id })
    .eq('id', authData.user.id);
}
```

## Handling Existing Auth Users

If you already have users in `auth.users` before running this migration, they won't be in `public.users`. 

### Sync Existing Users

Run this SQL in Supabase SQL Editor:

```sql
-- Sync all existing auth users to public.users
INSERT INTO public.users (id, email, first_name, last_name, role_id, is_active)
SELECT 
    au.id,
    au.email,
    COALESCE(au.raw_user_meta_data->>'first_name', ''),
    COALESCE(au.raw_user_meta_data->>'last_name', ''),
    (SELECT id FROM roles WHERE name = 'employee' LIMIT 1),
    true
FROM auth.users au
WHERE NOT EXISTS (
    SELECT 1 FROM public.users pu WHERE pu.id = au.id
);
```

## Troubleshooting

### User Not Created in public.users

**Check:**
1. Trigger exists: `SELECT * FROM pg_trigger WHERE tgname = 'on_auth_user_created';`
2. Function exists: `SELECT * FROM pg_proc WHERE proname = 'handle_new_user';`
3. Roles table has data: `SELECT * FROM roles;`

**Fix:**
Re-run the migration or manually create the trigger.

### Missing first_name/last_name

**Cause:** Metadata not passed during signup.

**Fix:** Always pass metadata:
```typescript
await supabase.auth.signUp({
  email,
  password,
  options: {
    data: { first_name: 'John', last_name: 'Doe' }
  }
});
```

### Permission Denied

**Cause:** RLS policies blocking insert.

**Fix:** The trigger runs with `SECURITY DEFINER`, bypassing RLS. If still failing, check:
```sql
-- Verify trigger security
SELECT proname, prosecdef FROM pg_proc WHERE proname = 'handle_new_user';
-- prosecdef should be true
```

## Best Practices

1. **Always pass metadata** during signup (first_name, last_name)
2. **Use public.users** for application data (role, phone, preferences)
3. **Use auth.users** only for authentication (email, password)
4. **Keep IDs in sync** - both tables use the same UUID
5. **Update metadata** when user changes their name
6. **Use service role key** for admin operations only

## Security Notes

- ✅ Trigger runs with `SECURITY DEFINER` (bypasses RLS)
- ✅ Only fires on INSERT (not UPDATE/DELETE)
- ✅ Default role is 'employee' (not 'owner')
- ⚠️ Service role key should never be exposed to frontend
- ⚠️ Use anon key for frontend operations

## Summary

```
User Signs Up
     ↓
auth.users (Supabase Auth)
     ↓
Trigger: on_auth_user_created
     ↓
Function: handle_new_user()
     ↓
public.users (Your App Data)
     ↓
User Can Login & Use App
```

**Key Points:**
- ✅ Automatic sync on signup
- ✅ Same UUID in both tables
- ✅ Pass metadata for first_name/last_name
- ✅ Default role: employee
- ✅ Access via `public.users` for app data
