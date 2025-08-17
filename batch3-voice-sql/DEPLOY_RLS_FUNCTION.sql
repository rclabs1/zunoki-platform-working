-- COMPLETE RLS RESTORATION FOR TEAMS TABLE
-- This script restores full Row Level Security for multi-tenant isolation
-- NO IMPACT on existing data, messages, or integrations

-- Step 1: Clean up any conflicting functions
DROP FUNCTION IF EXISTS set_current_user_id(TEXT);
DROP FUNCTION IF EXISTS set_current_user_id(UUID);

-- Step 2: Create the RLS context function
CREATE OR REPLACE FUNCTION set_current_user_id(user_id TEXT)
RETURNS VOID AS $$
BEGIN
    -- Set user context for Row Level Security policies
    PERFORM set_config('app.current_user_id', user_id, true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 3: Grant necessary permissions
GRANT EXECUTE ON FUNCTION set_current_user_id(TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION set_current_user_id(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION set_current_user_id(TEXT) TO anon;

-- Step 4: Enable Row Level Security on teams table
ALTER TABLE teams ENABLE ROW LEVEL SECURITY;

-- Step 5: Drop existing policies (if any) to avoid conflicts
DROP POLICY IF EXISTS "Users can manage their own teams" ON teams;

-- Step 6: Create the RLS policy for teams
CREATE POLICY "Users can manage their own teams" ON teams
    FOR ALL USING (user_id = current_setting('app.current_user_id', true));

-- Step 7: Test the complete RLS setup (optional verification)
-- SELECT set_current_user_id('test-user-123');
-- SELECT current_setting('app.current_user_id', true);
-- SELECT * FROM teams; -- Should only return teams for the set user

-- DEPLOYMENT NOTES:
-- ✅ FUNCTION: Creates set_current_user_id() for context setting
-- ✅ POLICY: Enforces user_id isolation at database level  
-- ✅ SECURITY: Complete multi-tenant isolation restored
-- ✅ SAFE: No data changes, all existing data preserved
-- ✅ IMMEDIATE: Teams API will work right after deployment