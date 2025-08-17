-- Fix team_members table to support AI agents
-- This adds the missing agent_id column that the marketplace expects

-- Add agent_id column to team_members table
ALTER TABLE public.team_members 
ADD COLUMN agent_id uuid;

-- Add foreign key constraint to agents table
ALTER TABLE public.team_members 
ADD CONSTRAINT team_members_agent_id_fkey 
FOREIGN KEY (agent_id) REFERENCES public.agents(id) ON DELETE CASCADE;

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_team_members_agent_id 
ON public.team_members(agent_id);

-- Update the unique constraint to handle both human and AI members
-- Drop the old constraint if it exists and recreate it to allow NULL values
ALTER TABLE public.team_members 
DROP CONSTRAINT IF EXISTS team_members_team_id_user_id_key;

-- Create a unique constraint that allows either user_id OR agent_id but not both
CREATE UNIQUE INDEX team_members_unique_member 
ON public.team_members(team_id, COALESCE(user_id::text, agent_id::text));

-- Add check constraint to ensure either user_id OR agent_id is set, but not both
ALTER TABLE public.team_members 
ADD CONSTRAINT team_members_member_type_check 
CHECK (
  (user_id IS NOT NULL AND agent_id IS NULL) OR 
  (user_id IS NULL AND agent_id IS NOT NULL)
);

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ Successfully added agent_id column to team_members table!';
    RAISE NOTICE '🤖 Teams can now have both human members and AI agents';
    RAISE NOTICE '🔗 Foreign key relationship: team_members.agent_id -> agents.id';
    RAISE NOTICE '⚡ Index created for optimal query performance';
    RAISE NOTICE '🛡️ Constraints ensure data integrity (either user_id OR agent_id)';
END $$;