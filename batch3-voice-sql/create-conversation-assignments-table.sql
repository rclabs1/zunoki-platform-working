-- Create conversation_agent_assignments table for conversation assignment functionality
-- This table is required by /api/conversations/[conversationId]/assign

CREATE TABLE public.conversation_agent_assignments (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  conversation_id uuid NOT NULL,
  user_id text NOT NULL,
  agent_type text NOT NULL CHECK (agent_type = ANY (ARRAY['ai_agent'::text, 'human'::text])),
  agent_id text NOT NULL,
  agent_name text NOT NULL,
  assigned_by text NOT NULL,
  assignment_reason text DEFAULT 'Manual assignment'::text,
  status text NOT NULL DEFAULT 'active'::text CHECK (status = ANY (ARRAY['active'::text, 'inactive'::text])),
  auto_response_enabled boolean DEFAULT true,
  assigned_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT conversation_agent_assignments_pkey PRIMARY KEY (id),
  CONSTRAINT conversation_agent_assignments_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES public.crm_conversations(id)
);

-- Add RLS (Row Level Security) for multi-tenant isolation
ALTER TABLE public.conversation_agent_assignments ENABLE ROW LEVEL SECURITY;

-- Create RLS policy to ensure users can only see their own assignments
CREATE POLICY "Users can only see their own conversation assignments" ON public.conversation_agent_assignments
    FOR ALL USING (user_id = auth.uid()::text);

-- Create index for better performance
CREATE INDEX conversation_agent_assignments_conversation_id_idx ON public.conversation_agent_assignments(conversation_id);
CREATE INDEX conversation_agent_assignments_user_id_idx ON public.conversation_agent_assignments(user_id);
CREATE INDEX conversation_agent_assignments_status_idx ON public.conversation_agent_assignments(status);