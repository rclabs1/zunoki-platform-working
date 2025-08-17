-- Migration: Add user voice preferences table for persistent TTS settings
-- This maintains multi-user isolation while storing personalized voice settings

CREATE TABLE public.user_voice_preferences (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id text NOT NULL,
  provider text NOT NULL DEFAULT 'web'::text CHECK (provider = ANY (ARRAY['web'::text, 'elevenlabs'::text, 'sarvam'::text])),
  voice_id text, -- Specific voice ID for the provider
  rate numeric DEFAULT 0.9 CHECK (rate >= 0.5 AND rate <= 2.0),
  pitch numeric DEFAULT 1.0 CHECK (pitch >= 0.5 AND pitch <= 2.0),
  volume numeric DEFAULT 1.0 CHECK (volume >= 0.1 AND volume <= 1.0),
  use_personal_api_key boolean DEFAULT false,
  personal_api_key text, -- Encrypted storage for user's personal API key
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT user_voice_preferences_pkey PRIMARY KEY (id),
  CONSTRAINT user_voice_preferences_user_id_unique UNIQUE (user_id)
);

-- Add RLS (Row Level Security) for multi-user isolation
ALTER TABLE public.user_voice_preferences ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see/modify their own voice preferences
CREATE POLICY "Users can manage their own voice preferences" ON public.user_voice_preferences
  FOR ALL USING (user_id = current_setting('app.current_user_id', true));

-- Index for performance
CREATE INDEX idx_user_voice_preferences_user_id ON public.user_voice_preferences(user_id);

-- Comments for documentation
COMMENT ON TABLE public.user_voice_preferences IS 'Stores personalized voice/TTS preferences for each user with multi-tenant isolation';
COMMENT ON COLUMN public.user_voice_preferences.provider IS 'TTS provider: web (browser), elevenlabs, or sarvam';
COMMENT ON COLUMN public.user_voice_preferences.voice_id IS 'Provider-specific voice identifier (e.g., ElevenLabs voice ID)';
COMMENT ON COLUMN public.user_voice_preferences.personal_api_key IS 'Encrypted user personal API key for premium providers';