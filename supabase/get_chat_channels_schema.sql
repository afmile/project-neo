-- ============================================================================
-- Query para ver TODAS las columnas reales de chat_channels
-- Ejecuta en Supabase SQL Editor
-- ============================================================================

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'chat_channels'
  AND table_schema = 'public'
ORDER BY ordinal_position;
