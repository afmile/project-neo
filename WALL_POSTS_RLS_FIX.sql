-- ============================================================================
-- FIX: RLS POLICY FOR WALL_POSTS INSERT
-- ============================================================================
-- El error "violates row-level security policy" indica que falta una policy
-- que permita INSERT cuando profile_user_id = auth.uid()

-- Primero verificar policies existentes:
-- SELECT policyname, cmd FROM pg_policies WHERE tablename = 'wall_posts';

-- Opción 1: Crear policy para INSERT
CREATE POLICY "Users can insert own wall posts"
ON wall_posts
FOR INSERT
TO authenticated
WITH CHECK (profile_user_id = auth.uid());

-- Opción 2: Si ya existe pero está mal, recrear:
-- DROP POLICY IF EXISTS "Users can insert own wall posts" ON wall_posts;
-- CREATE POLICY "Users can insert own wall posts" ON wall_posts FOR INSERT TO authenticated WITH CHECK (profile_user_id = auth.uid());

-- También agregar SELECT policy si no existe:
CREATE POLICY "Users can read wall posts in their communities"
ON wall_posts
FOR SELECT
TO authenticated
USING (true);  -- O más restrictivo: community_id IN (SELECT community_id FROM community_members WHERE user_id = auth.uid())

-- Y DELETE policy para autor:
CREATE POLICY "Authors can delete own wall posts"
ON wall_posts
FOR DELETE
TO authenticated
USING (profile_user_id = auth.uid());

-- UPDATE policy para autor:
CREATE POLICY "Authors can update own wall posts"
ON wall_posts
FOR UPDATE
TO authenticated
USING (profile_user_id = auth.uid())
WITH CHECK (profile_user_id = auth.uid());
