/// Project Neo - Pinned Content Card
///
/// Horizontal card for pinned blogs/wikis with drag handle
library;

import 'package:flutter/material.dart';
import '../../../../core/theme/neo_theme.dart';
import '../../domain/entities/pinned_content.dart';

class PinnedContentCard extends StatelessWidget {
  final PinnedContent content;
  final VoidCallback? onTap;

  const PinnedContentCard({
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 200,
        height: 120,
        decoration: BoxDecoration(
          color: NeoColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getTypeColor().withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Stack(
          children: [
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
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          content.typeLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
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
                    style: NeoTextStyles.bodyLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4),
                  
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
                          fontSize: 11,
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
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Drag handle (top right)
            Positioned(
              top: 8,
              right: 8,
              child: Icon(
                Icons.drag_indicator,
                color: Colors.white.withValues(alpha: 0.3),
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
