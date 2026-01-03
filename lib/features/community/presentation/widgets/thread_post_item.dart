import 'package:flutter/material.dart';
import '../../../../core/theme/neo_theme.dart';

class ThreadPostItem extends StatelessWidget {
  final String authorId;
  final String authorUsername;
  final String? authorAvatarUrl;
  final String content;
  final DateTime createdAt;
  final bool isLast; // Para saber si dibujar la línea hacia abajo
  final bool isReply; // Para ajustar tamaño de avatar (opcional, por ahora false)
  final int likesCount;
  final int commentsCount;
  final bool isLiked;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onComment;

  const ThreadPostItem({
    super.key,
    required this.authorId,
    required this.authorUsername,
    required this.authorAvatarUrl,
    required this.content,
    required this.createdAt,
    this.isLast = false,
    this.isReply = false,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isLiked = false,
    this.onTap,
    this.onLike,
    this.onComment,
  });

  @override
  Widget build(BuildContext context) {
    // Dimensiones según especificaciones de Threads
    final double avatarSize = isReply ? 36 : 40;
    final double leftColumnWidth = 48.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          // CRÍTICO: Permite que la línea crezca con el contenido
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ==========================================
              // COLUMNA IZQUIERDA (Avatar + Thread Line)
              // ==========================================
              SizedBox(
                width: leftColumnWidth,
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    // Thread Line (pasa por detrás del avatar)
                    if (!isLast)
                      Positioned(
                        top: 0,
                        bottom: 0,
                        left: leftColumnWidth / 2 - 1, // Centrada
                        child: Container(
                          width: 2, // Grosor 2dp
                          color: const Color(0xFF333333), // Gris medio
                        ),
                      ),

                    // Avatar
                    Container(
                      margin: const EdgeInsets.only(top: 4), // Alineación visual
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black, // Borde negro para "cortar" la línea
                        border: Border.all(
                          color: Colors.black,
                          width: 2,
                        ), // Respiro visual
                      ),
                      child: CircleAvatar(
                        radius: avatarSize / 2,
                        backgroundColor: NeoColors.accent.withValues(alpha: 0.15),
                        backgroundImage: authorAvatarUrl != null &&
                                authorAvatarUrl!.isNotEmpty
                            ? NetworkImage(authorAvatarUrl!)
                            : null,
                        child: authorAvatarUrl == null || authorAvatarUrl!.isEmpty
                            ? Text(
                                authorUsername[0].toUpperCase(),
                                style: TextStyle(
                                  color: NeoColors.accent,
                                  fontWeight: FontWeight.w600,
                                  fontSize: avatarSize / 2.5,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
              ),

              // ==========================================
              // COLUMNA DERECHA (Contenido)
              // ==========================================
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(
                    right: 16.0,
                    top: 4.0, // Alinear visualmente con avatar
                    bottom: 12.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Username y Timestamp
                      _buildHeader(),

                      const SizedBox(height: 4),

                      // Contenido del post
                      Text(
                        content,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.4, // Line height para legibilidad
                          color: Color(0xFFF3F5F7), // Blanco hueso
                          fontWeight: FontWeight.w400,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Acciones (Like, Comment, Share)
                      _buildActions(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Username (Bold)
        Text(
          authorUsername,
          style: const TextStyle(
            fontWeight: FontWeight.w600, // SemiBold
            fontSize: 15,
            color: Colors.white,
          ),
        ),

        // Timestamp (gris sutil)
        Text(
          _formatTime(createdAt),
          style: const TextStyle(
            color: Color(0xFF616161), // Gris medio
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        _buildActionButton(
          isLiked ? Icons.favorite : Icons.favorite_border,
          likesCount,
          onTap: onLike,
          color: isLiked ? Colors.red : Colors.white,
        ),
        const SizedBox(width: 16),
        _buildActionButton(
          Icons.chat_bubble_outline,
          commentsCount,
          onTap: onComment,
        ),
        const SizedBox(width: 16),
        _buildActionButton(Icons.cached, null), // Repost
        const SizedBox(width: 16),
        _buildActionButton(Icons.send, null), // Share
      ],
    );
  }

  Widget _buildActionButton(
    IconData icon,
    int? count, {
    VoidCallback? onTap,
    Color color = Colors.white,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            icon,
            size: 20, // Iconos pequeños y finos
            color: color,
          ),
          if (count != null && count > 0) ...[
            const SizedBox(width: 4),
            Text(
              count.toString(),
              style: const TextStyle(
                color: Color(0xFF616161),
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d';
    } else {
      return '${time.day}/${time.month}';
    }
  }
}
