/// Project Neo - Activity Grid Item
///
/// Bento-style card for activity grid showing user's content
library;

import 'package:flutter/material.dart';
import '../../../../core/theme/neo_theme.dart';
import '../../domain/entities/pinned_content.dart';
import 'package:timeago/timeago.dart' as timeago;

class ActivityGridItem extends StatelessWidget {
  final PinnedContent content;
  final VoidCallback? onTap;

  const ActivityGridItem({
    super.key,
    required this.content,
    this.onTap,
  });

  Color _getTypeColor() {
    switch (content.type) {
      case ContentType.blog:
        return const Color(0xFF8B5CF6);
      case ContentType.wiki:
        return const Color(0xFF10B981);
      case ContentType.quiz:
        return const Color(0xFF3B82F6);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: NeoColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            // Gradient overlay for text readability
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(NeoSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getTypeColor(),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          content.typeIcon,
                          style: const TextStyle(fontSize: 10),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          content.typeLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Title
                  Text(
                    content.title,
                    style: NeoTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Date
                  Text(
                    timeago.format(content.createdAt, locale: 'es'),
                    style: TextStyle(
                      color: NeoColors.textTertiary,
                      fontSize: 10,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Stats
                  Row(
                    children: [
                      Icon(
                        Icons.visibility_outlined,
                        size: 12,
                        color: NeoColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${content.views}',
                        style: TextStyle(
                          color: NeoColors.textTertiary,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.favorite_border,
                        size: 12,
                        color: NeoColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${content.likes}',
                        style: TextStyle(
                          color: NeoColors.textTertiary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
