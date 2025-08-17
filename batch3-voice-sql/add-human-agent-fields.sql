-- Add human agent fields to the existing agents table
-- This script adds the necessary fields to support manual human agent creation

-- Add platform_contacts field for storing platform-specific contact information
ALTER TABLE public.agents 
ADD COLUMN IF NOT EXISTS platform_contacts JSONB DEFAULT '{}';

-- Add human agent specific fields
ALTER TABLE public.agents 
ADD COLUMN IF NOT EXISTS working_hours TEXT DEFAULT '9:00 AM - 5:00 PM';

ALTER TABLE public.agents 
ADD COLUMN IF NOT EXISTS timezone TEXT DEFAULT 'UTC';

ALTER TABLE public.agents 
ADD COLUMN IF NOT EXISTS availability_status TEXT DEFAULT 'available';

ALTER TABLE public.agents 
ADD COLUMN IF NOT EXISTS max_concurrent_conversations INTEGER DEFAULT 5;

-- Add check constraint for availability_status
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'agents' 
        AND constraint_name = 'agents_availability_status_check'
    ) THEN
        ALTER TABLE public.agents 
        ADD CONSTRAINT agents_availability_status_check 
        CHECK (availability_status IN ('available', 'busy', 'offline'));
    END IF;
END $$;

-- Add comments for documentation
COMMENT ON COLUMN public.agents.platform_contacts IS 'JSONB field storing platform-specific contact information for human agents. Example: {"whatsapp": "+1234567890", "email": "agent@example.com", "telegram": "@username"}';

COMMENT ON COLUMN public.agents.working_hours IS 'Working hours for human agents (e.g., "9:00 AM - 5:00 PM")';

COMMENT ON COLUMN public.agents.timezone IS 'Timezone for human agents (e.g., "UTC", "America/New_York")';

COMMENT ON COLUMN public.agents.availability_status IS 'Current availability status for human agents';

COMMENT ON COLUMN public.agents.max_concurrent_conversations IS 'Maximum number of concurrent conversations a human agent can handle';

-- Create useful indexes
CREATE INDEX IF NOT EXISTS idx_agents_platform_contacts 
ON public.agents USING GIN (platform_contacts);

CREATE INDEX IF NOT EXISTS idx_agents_human_available 
ON public.agents (user_id, type, availability_status) 
WHERE type = 'human' AND availability_status = 'available';

CREATE INDEX IF NOT EXISTS idx_agents_human_active 
ON public.agents (user_id, type, is_active) 
WHERE type = 'human' AND is_active = true;

-- Verify the changes
DO $$
BEGIN
    RAISE NOTICE 'Human agent fields have been added to the agents table successfully!';
    RAISE NOTICE 'New fields: platform_contacts, working_hours, timezone, availability_status, max_concurrent_conversations';
    RAISE NOTICE 'Indexes created for better query performance';
END $$;