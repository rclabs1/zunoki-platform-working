-- Create oauth_tokens table for Google Ads and other OAuth providers
-- This table stores OAuth tokens with Firebase UID for multi-user isolation

CREATE TABLE public.oauth_tokens (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id text NOT NULL,                    -- Firebase UID for multi-user isolation
  platform text NOT NULL,                  -- 'google_ads', 'meta_ads', 'youtube', etc.
  access_token text NOT NULL,               -- OAuth access token
  refresh_token text,                       -- OAuth refresh token (optional)
  expires_at timestamp with time zone,     -- Token expiration timestamp
  scope text,                              -- OAuth scopes granted
  account_info jsonb,                      -- Platform-specific account information
  created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT oauth_tokens_pkey PRIMARY KEY (id),
  CONSTRAINT oauth_tokens_user_platform_unique UNIQUE (user_id, platform)
);

-- Create index for faster queries by user_id
CREATE INDEX idx_oauth_tokens_user_id ON public.oauth_tokens (user_id);

-- Create index for faster queries by platform
CREATE INDEX idx_oauth_tokens_platform ON public.oauth_tokens (platform);

-- Create index for token expiration cleanup
CREATE INDEX idx_oauth_tokens_expires_at ON public.oauth_tokens (expires_at);

-- Enable Row Level Security for multi-user isolation
ALTER TABLE public.oauth_tokens ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can only access their own tokens
-- Note: Since we use Firebase Auth, we'll need to set the user context in application code
CREATE POLICY "oauth_tokens_user_isolation" ON public.oauth_tokens
  FOR ALL 
  USING (user_id = current_setting('app.current_user_id', true));

-- Grant necessary permissions to authenticated users
-- Note: Adjust these based on your Supabase setup
GRANT SELECT, INSERT, UPDATE, DELETE ON public.oauth_tokens TO authenticated;
GRANT USAGE ON SEQUENCE oauth_tokens_id_seq TO authenticated;

-- Comments for documentation
COMMENT ON TABLE public.oauth_tokens IS 'Stores OAuth tokens for advertising platforms with Firebase UID isolation';
COMMENT ON COLUMN public.oauth_tokens.user_id IS 'Firebase UID for multi-user data isolation';
COMMENT ON COLUMN public.oauth_tokens.platform IS 'Platform identifier (google_ads, meta_ads, youtube, etc.)';
COMMENT ON COLUMN public.oauth_tokens.access_token IS 'OAuth access token for API calls';
COMMENT ON COLUMN public.oauth_tokens.refresh_token IS 'OAuth refresh token for token renewal';
COMMENT ON COLUMN public.oauth_tokens.account_info IS 'Platform-specific account data (customer IDs, account names, etc.)';