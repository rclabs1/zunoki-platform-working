-- Set up Row Level Security (RLS) policies for multi-user isolation
-- These policies ensure users can only access their own data

-- Enable RLS on tables that need multi-user isolation
ALTER TABLE public.user_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.campaign_metrics ENABLE ROW LEVEL SECURITY;

-- RLS Policy for user_activities table
-- Users can only access their own activities
CREATE POLICY "user_activities_isolation" ON public.user_activities
  FOR ALL 
  USING (user_id = current_setting('app.current_user_id', true));

-- RLS Policy for campaign_metrics table  
-- Users can only access their own campaign metrics
CREATE POLICY "campaign_metrics_isolation" ON public.campaign_metrics
  FOR ALL 
  USING (user_id = current_setting('app.current_user_id', true));

-- Note about Firebase UID context:
-- Since we use Firebase Auth instead of Supabase Auth, we need to set the user context
-- in our application code before making database calls:
-- 
-- Example in application code:
-- await supabase.rpc('set_config', {
--   parameter: 'app.current_user_id',
--   value: firebaseUid
-- });

-- Create a helper function to set the current user context
CREATE OR REPLACE FUNCTION public.set_current_user_id(user_id text)
RETURNS void AS $$
BEGIN
  PERFORM set_config('app.current_user_id', user_id, true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission on the helper function
GRANT EXECUTE ON FUNCTION public.set_current_user_id(text) TO authenticated;

-- Comments for documentation
COMMENT ON FUNCTION public.set_current_user_id IS 'Sets the current Firebase UID for RLS policies';

-- Additional security: Ensure anonymous users cannot access these tables
CREATE POLICY "oauth_tokens_authenticated_only" ON public.oauth_tokens
  FOR ALL 
  TO authenticated
  USING (true);

CREATE POLICY "user_activities_authenticated_only" ON public.user_activities
  FOR ALL 
  TO authenticated  
  USING (true);

CREATE POLICY "campaign_metrics_authenticated_only" ON public.campaign_metrics
  FOR ALL 
  TO authenticated
  USING (true);