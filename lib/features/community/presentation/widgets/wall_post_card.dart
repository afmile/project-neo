import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/theme/neo_theme.dart';
import '../../domain/entities/wall_post.dart';

class WallPostCard extends ConsumerStatefulWidget {
  final WallPost post;
  final VoidCallback? onLike;
  final VoidCallback? onDelete;
  final VoidCallback? onComment;
  final bool isProfilePost;
  final bool canDelete;
  final bool isThreadView;

  const WallPostCard({
    super.key,
    required this.post,
    this.onLike,
    this.onDelete,
    this.onComment,
    this.isProfilePost = false,
    this.canDelete = false,
    this.isThreadView = false,
  });

  @override
  ConsumerState<WallPostCard> createState() => _WallPostCardState();
}

class _WallPostCardState extends ConsumerState<WallPostCard> {
  // Aquí puedes mantener lógica local si necesitas expandir comentarios
  // Por ahora nos enfocamos en el diseño Threads puro

  @override
  Widget build(BuildContext context) {
    // Especificaciones Threads: Avatar 40px, Linea 2px gris oscuro
    const double avatarSize = 40.0;
    const double leftColumnWidth = 58.0; 

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // COLUMNA IZQUIERDA: Avatar + Línea
          SizedBox(
            width: leftColumnWidth,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                // Línea Conectora
                Positioned(
                  top: 50, 
                  bottom: 0,
                  child: Container(
                    width: 2,
                    color: const Color(0xFF333333),
                  ),
                ),
                
                // Avatar
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 2), // Borde falso para cortar línea
                    ),
                    child: CircleAvatar(
                      radius: avatarSize / 2,
                      backgroundColor: Colors.grey[800],
                      backgroundImage: widget.post.authorAvatar != null
                          ? NetworkImage(widget.post.authorAvatar!)
                          : null,
                      child: widget.post.authorAvatar == null
                          ? const Icon(Icons.person, color: Colors.white, size: 20)
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // COLUMNA DERECHA: Contenido
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Username + Time
                  Row(
                    children: [
                      Text(
                        widget.post.authorName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        timeago.format(widget.post.timestamp, locale: 'es_short'),
                        style: const TextStyle(
                          color: Color(0xFF616161),
                          fontSize: 14,
                        ),
                      ),
                      // Menú de opciones
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_horiz, color: Color(0xFF616161), size: 20),
                        padding: EdgeInsets.zero,
                        itemBuilder: (context) => [
                          if (widget.onDelete != null || widget.canDelete)
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Eliminar', style: TextStyle(color: NeoColors.error)),
                            ),
                          const PopupMenuItem(
                            value: 'report',
                            child: Text('Reportar'),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'delete') widget.onDelete?.call();
                        },
                      ),
                    ],
                  ),

                  // Contenido Texto
                  Padding(
                    padding: const EdgeInsets.only(top: 2, bottom: 8),
                    child: Text(
                      widget.post.content,
                      style: const TextStyle(
                        color: Color(0xFFF3F5F7),
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ),

                  // Acciones (Likes, Comentarios)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        // Botón Like
                        _ActionButton(
                          icon: widget.post.isLikedByCurrentUser ? Icons.favorite : Icons.favorite_border,
                          color: widget.post.isLikedByCurrentUser ? Colors.red : Colors.white,
                          label: widget.post.likes > 0 ? '${widget.post.likes}' : '',
                          onTap: widget.onLike,
                        ),
                        const SizedBox(width: 16),
                        
                        // Botón Comentar
                        _ActionButton(
                          icon: Icons.chat_bubble_outline,
                          label: widget.post.commentsCount > 0 ? '${widget.post.commentsCount}' : '',
                          onTap: widget.onComment,
                        ),
                        const SizedBox(width: 16),
                        
                        // Botón Compartir/Enviar
                        const _ActionButton(icon: Icons.send_outlined),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    this.color = Colors.white,
    this.label = '',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.transparent, // Hitbox expandido
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
