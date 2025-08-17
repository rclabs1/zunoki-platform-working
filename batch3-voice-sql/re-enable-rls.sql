-- Re-enable RLS after testing (run this regardless of success/failure)

-- Re-enable RLS on oauth_tokens table
ALTER TABLE public.oauth_tokens ENABLE ROW LEVEL SECURITY;

-- Re-enable RLS on user_activities table
ALTER TABLE public.user_activities ENABLE ROW LEVEL SECURITY;

-- Create proper RLS policies (if they don't exist)
-- For oauth_tokens table
DROP POLICY IF EXISTS "Users can manage their own OAuth tokens" ON public.oauth_tokens;
CREATE POLICY "Users can manage their own OAuth tokens" ON public.oauth_tokens
FOR ALL USING (firebase_uid = current_setting('app.current_user_id', true));

-- For user_activities table  
DROP POLICY IF EXISTS "Users can manage their own activities" ON public.user_activities;
CREATE POLICY "Users can manage their own activities" ON public.user_activities
FOR ALL USING (firebase_uid = current_setting('app.current_user_id', true));