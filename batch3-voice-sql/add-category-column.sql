-- Add category column to crm_conversations table
ALTER TABLE crm_conversations 
ADD COLUMN IF NOT EXISTS category TEXT 
CHECK (category IN ('acquisition', 'engagement', 'retention', 'support', 'general'))
DEFAULT 'general';

-- Update existing conversations to have default category
UPDATE crm_conversations 
SET category = 'general' 
WHERE category IS NULL;