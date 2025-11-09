-- Auth User Sync Migration
-- Created: 2025-11-09
-- Description: Automatically syncs Supabase Auth users to public.users table

-- ============================================
-- AUTH USER SYNC
-- ============================================

-- Function to handle new user signup
-- This automatically creates a user record when someone signs up via Supabase Auth
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    default_role_id INTEGER;
BEGIN
    -- Get the default role (employee) for new users
    SELECT id INTO default_role_id FROM roles WHERE name = 'employee' LIMIT 1;
    
    -- Insert new user into public.users table
    INSERT INTO public.users (id, email, first_name, last_name, role_id, is_active)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'first_name', ''),
        COALESCE(NEW.raw_user_meta_data->>'last_name', ''),
        default_role_id,
        true
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to sync auth.users to public.users
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================
-- SYNC EXISTING USERS (Optional)
-- ============================================

-- Uncomment the following to sync existing auth users to public.users
-- This is useful if you already have users in auth.users before running this migration


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
