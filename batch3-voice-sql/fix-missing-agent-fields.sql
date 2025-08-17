-- Add missing type and specialization fields to agents table
-- These are required for human agent creation functionality

ALTER TABLE public.agents 
ADD COLUMN IF NOT EXISTS type TEXT DEFAULT 'ai_agent' 
CHECK (type IN ('ai_agent', 'human'));

ALTER TABLE public.agents 
ADD COLUMN IF NOT EXISTS specialization TEXT[] DEFAULT '{}';

-- Update existing agents to be AI agents
UPDATE public.agents 
SET type = 'ai_agent' 
WHERE type IS NULL;