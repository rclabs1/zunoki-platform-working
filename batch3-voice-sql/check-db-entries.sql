-- Check oauth_tokens table entries
SELECT 
  id,
  firebase_uid,
  platform,
  access_token IS NOT NULL as has_access_token,
  refresh_token IS NOT NULL as has_refresh_token,
  expires_at,
  created_at,
  updated_at
FROM public.oauth_tokens
ORDER BY created_at DESC
LIMIT 10;

-- Check user_activities table entries related to OAuth
SELECT 
  id,
  firebase_uid,
  action,
  metadata,
  created_at
FROM public.user_activities
WHERE action LIKE '%oauth%' OR action LIKE '%google%'
ORDER BY created_at DESC
LIMIT 10;

-- Check table existence and structure
SELECT table_name, column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name IN ('oauth_tokens', 'user_activities')
ORDER BY table_name, ordinal_position;

-- Check RLS status
SELECT 
  schemaname,
  tablename,
  rowsecurity
FROM pg_tables 
WHERE tablename IN ('oauth_tokens', 'user_activities');