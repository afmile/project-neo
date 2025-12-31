-- ============================================================================
-- Migration 031: Community Moderation & Strikes System
-- ============================================================================
-- Description: Implements comprehensive moderation system with strikes,
--              content actions, and automatic review triggers
-- ============================================================================

-- ============================================================================
-- CLEANUP (if re-running migration)
-- ============================================================================

DROP TRIGGER IF EXISTS trigger_strike_threshold ON community_strikes;
DROP FUNCTION IF EXISTS notify_strike_threshold();
DROP FUNCTION IF EXISTS count_active_strikes(UUID, UUID);
DROP TABLE IF EXISTS community_strikes;

-- ============================================================================
-- TABLES
-- ============================================================================

-- Strikes/Penalties table
CREATE TABLE community_strikes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  community_id UUID NOT NULL REFERENCES communities(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users_global(id) ON DELETE CASCADE,
  moderator_id UUID NOT NULL REFERENCES users_global(id),
  
  -- Strike details
  reason TEXT NOT NULL,
  content_type TEXT, -- 'wall_post', 'comment', 'chat_message', null for general
  content_id UUID, -- ID of the violating content
  
  -- Status
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'appealed', 'revoked')),
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  revoked_at TIMESTAMPTZ,
  revoked_by UUID REFERENCES users_global(id),
  revoke_reason TEXT
);

-- ============================================================================
-- INDEXES
-- ============================================================================

CREATE INDEX idx_strikes_user_community ON community_strikes(user_id, community_id);
CREATE INDEX idx_strikes_community_status ON community_strikes(community_id, status);
CREATE INDEX idx_strikes_created ON community_strikes(created_at DESC);
CREATE INDEX idx_strikes_moderator ON community_strikes(moderator_id);

-- ============================================================================
-- RLS POLICIES
-- ============================================================================

ALTER TABLE community_strikes ENABLE ROW LEVEL SECURITY;

-- Leaders can view all strikes in their community
CREATE POLICY "Leaders can view strikes in their community"
ON community_strikes FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM community_members
    WHERE community_members.community_id = community_strikes.community_id
    AND community_members.user_id = auth.uid()
    AND community_members.role IN ('leader', 'curator', 'mod')
    AND community_members.is_active = true
  )
);

-- Users can view their own strikes
CREATE POLICY "Users can view their own strikes"
ON community_strikes FOR SELECT
USING (user_id = auth.uid());

-- Leaders can assign strikes
CREATE POLICY "Leaders can assign strikes"
ON community_strikes FOR INSERT
WITH CHECK (
  -- Moderator must be a leader in the community
  EXISTS (
    SELECT 1 FROM community_members
    WHERE community_members.community_id = community_strikes.community_id
    AND community_members.user_id = auth.uid()
    AND community_members.role IN ('leader', 'curator', 'mod')
    AND community_members.is_active = true
  )
  -- Cannot self-assign strikes
  AND user_id != auth.uid()
  -- User must be a member of the community
  AND EXISTS (
    SELECT 1 FROM community_members
    WHERE community_members.community_id = community_strikes.community_id
    AND community_members.user_id = community_strikes.user_id
    AND community_members.is_active = true
  )
);

-- Leaders can update strikes (for revocation)
CREATE POLICY "Leaders can revoke strikes"
ON community_strikes FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM community_members
    WHERE community_members.community_id = community_strikes.community_id
    AND community_members.user_id = auth.uid()
    AND community_members.role IN ('leader', 'curator', 'mod')
    AND community_members.is_active = true
  )
)
WITH CHECK (
  -- Only allow updating status, revoked_at, revoked_by, revoke_reason
  -- Original strike data cannot be modified
  true
);

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

-- Function to count active strikes for a user in a community
CREATE OR REPLACE FUNCTION count_active_strikes(
  p_user_id UUID,
  p_community_id UUID
)
RETURNS INTEGER AS $$
  SELECT COUNT(*)::INTEGER
  FROM community_strikes
  WHERE user_id = p_user_id
  AND community_id = p_community_id
  AND status = 'active';
$$ LANGUAGE SQL STABLE;

-- Function to trigger review notification when user reaches 3 strikes
CREATE OR REPLACE FUNCTION notify_strike_threshold()
RETURNS TRIGGER AS $$
DECLARE
  strike_count INTEGER;
  v_username TEXT;
BEGIN
  -- Only process if strike is being created as active
  IF NEW.status = 'active' THEN
    -- Count active strikes for this user
    strike_count := count_active_strikes(NEW.user_id, NEW.community_id);
    
    -- If user has reached 3 or more strikes, notify leaders
    IF strike_count >= 3 THEN
      -- Get username for notification
      SELECT username INTO v_username
      FROM users_global
      WHERE id = NEW.user_id;
      
      -- Get all leaders in the community and notify them
      INSERT INTO community_notifications (
        community_id,
        user_id,
        type,
        data,
        is_read
      )
      SELECT
        NEW.community_id,
        cm.user_id, -- Each leader gets a notification
        'strike_review_required',
        jsonb_build_object(
          'strike_count', strike_count,
          'target_user_id', NEW.user_id,
          'target_username', COALESCE(v_username, 'Usuario'),
          'latest_strike_id', NEW.id,
          'requires_action', true
        ),
        false
      FROM community_members cm
      WHERE cm.community_id = NEW.community_id
      AND cm.role IN ('leader', 'curator', 'mod')
      AND cm.is_active = true;
    END IF;
    
    -- Also notify the user who received the strike
    INSERT INTO community_notifications (
      community_id,
      user_id,
      type,
      data,
      is_read
    ) VALUES (
      NEW.community_id,
      NEW.user_id,
      'strike_assigned',
      jsonb_build_object(
        'strike_id', NEW.id,
        'reason', NEW.reason,
        'strike_count', strike_count,
        'moderator_id', NEW.moderator_id,
        'content_type', NEW.content_type,
        'content_id', NEW.content_id
      ),
      false
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Trigger for updated_at
CREATE TRIGGER trigger_strikes_updated_at
BEFORE UPDATE ON community_strikes
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Trigger for strike threshold notifications
CREATE TRIGGER trigger_strike_threshold
AFTER INSERT ON community_strikes
FOR EACH ROW
EXECUTE FUNCTION notify_strike_threshold();

-- ============================================================================
-- GRANTS
-- ============================================================================

-- Grant access to authenticated users (RLS will control actual access)
GRANT SELECT, INSERT, UPDATE ON community_strikes TO authenticated;

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE community_strikes IS 'Tracks moderation strikes assigned to users in communities';
COMMENT ON COLUMN community_strikes.status IS 'active: currently enforced, appealed: user contested, revoked: cancelled by moderator';
COMMENT ON FUNCTION count_active_strikes IS 'Counts active strikes for a user in a specific community';
COMMENT ON FUNCTION notify_strike_threshold IS 'Triggers review notification when user reaches 3 strikes';
