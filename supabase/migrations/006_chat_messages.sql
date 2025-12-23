-- =====================================================================
-- Migration: Chat Messages Table
-- Description: Realtime messaging infrastructure for chat channels
-- =====================================================================

-- TABLA DE MENSAJES DE CHAT
CREATE TABLE public.chat_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    channel_id UUID NOT NULL REFERENCES public.chat_channels(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users_global(id),
    content TEXT, -- El texto del mensaje
    image_url TEXT, -- Por si envían foto
    type VARCHAR(20) DEFAULT 'text', -- 'text', 'image', 'system'
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices para mejor rendimiento
CREATE INDEX idx_chat_messages_channel ON public.chat_messages(channel_id);
CREATE INDEX idx_chat_messages_created_at ON public.chat_messages(created_at DESC);
CREATE INDEX idx_chat_messages_user ON public.chat_messages(user_id);

-- HABILITAR REALTIME (¡Vital para el chat!)
ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_messages;

-- SEGURIDAD (RLS)
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

-- Ver mensajes: Solo miembros de la comunidad
CREATE POLICY "Ver mensajes" ON public.chat_messages
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.chat_channels c
            JOIN public.memberships m ON m.community_id = c.community_id
            WHERE c.id = chat_messages.channel_id AND m.user_id = auth.uid()
        )
    );

-- Enviar mensajes: Solo miembros
CREATE POLICY "Enviar mensajes" ON public.chat_messages
    FOR INSERT WITH CHECK (
        auth.uid() = user_id AND
        EXISTS (
            SELECT 1 FROM public.chat_channels c
            JOIN public.memberships m ON m.community_id = c.community_id
            WHERE c.id = channel_id AND m.user_id = auth.uid()
        )
    );

-- Actualizar un mensaje: Solo el autor puede editar (opcional)
CREATE POLICY "Actualizar mensajes propios" ON public.chat_messages
    FOR UPDATE USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Eliminar un mensaje: Solo el autor puede eliminar (opcional)
CREATE POLICY "Eliminar mensajes propios" ON public.chat_messages
    FOR DELETE USING (auth.uid() = user_id);
