-- Temporarily disable RLS for oauth_tokens table to allow token storage
-- This is for testing purposes only

-- Disable RLS on oauth_tokens table
ALTER TABLE public.oauth_tokens DISABLE ROW LEVEL SECURITY;

-- Disable RLS on user_activities table  
ALTER TABLE public.user_activities DISABLE ROW LEVEL SECURITY;

-- Note: This temporarily removes security restrictions
-- Remember to re-enable RLS after testing with proper policies