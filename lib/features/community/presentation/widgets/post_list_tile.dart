/// Project Neo - Post List Tile Widget
///
/// Compact list item for community post display (Home VIVO)
library;

import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/theme/neo_theme.dart';
import '../../domain/entities/post_entity.dart';

class PostListTile extends StatelessWidget {
  final PostEntity post;
  final VoidCallback onTap;

  const PostListTile({
    super.key,
    required this.post,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getTypeColor().withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getTypeIcon(),
                color: _getTypeColor(),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    post.title ?? 'Sin título',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Metadata Row
                  Row(
                    children: [
                      // Author
                      Text(
                        post.authorUsername ?? 'Anónimo',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '•',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Time ago
                      Text(
                        timeago.format(post.createdAt, locale: 'es'),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Engagement Stats
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 14,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${post.reactionsCount}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 14,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${post.commentsCount}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTypeIcon() {
    switch (post.postType) {
      case PostType.blog:
        return Icons.article_outlined;
      case PostType.wiki:
        return Icons.menu_book_outlined;
      case PostType.poll:
        return Icons.poll_outlined;
      case PostType.quiz:
        return Icons.quiz_outlined;
      case PostType.wallPost:
        return Icons.edit_note_outlined;
    }
  }

  Color _getTypeColor() {
    switch (post.postType) {
      case PostType.blog:
        return const Color(0xFF8B5CF6); // Purple
      case PostType.wiki:
        return const Color(0xFF10B981); // Green
      case PostType.poll:
        return const Color(0xFFF59E0B); // Amber
      case PostType.quiz:
        return const Color(0xFFEC4899); // Pink
      case PostType.wallPost:
        return NeoColors.accent; // Blue
    }
  }
}
