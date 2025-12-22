/// Project Neo - Wall Post Card
///
/// Facebook-style post card for user walls
library;

import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/theme/neo_theme.dart';
import '../../domain/entities/wall_post.dart';

class WallPostCard extends StatelessWidget {
  final WallPost post;
  final VoidCallback? onLike;
  final VoidCallback? onDelete;
  final bool canDelete;

  const WallPostCard({
    super.key,
    required this.post,
    this.onLike,
    this.onDelete,
    this.canDelete = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: NeoSpacing.md),
      padding: const EdgeInsets.all(NeoSpacing.md),
      decoration: BoxDecoration(
        color: NeoColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar + Name + Time
          Row(
            children: [
              // Avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: NeoColors.accent.withValues(alpha: 0.2),
                  border: Border.all(
                    color: NeoColors.accent,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.person,
                  color: NeoColors.accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: NeoSpacing.sm),
              
              // Name and time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.authorName,
                      style: NeoTextStyles.bodyLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      timeago.format(post.timestamp, locale: 'es'),
                      style: NeoTextStyles.bodySmall.copyWith(
                        color: NeoColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Delete button (if allowed)
              if (canDelete)
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 20,
                  ),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          
          const SizedBox(height: NeoSpacing.md),
          
          // Content
          Text(
            post.content,
            style: NeoTextStyles.bodyMedium.copyWith(
              color: Colors.white,
              height: 1.5,
            ),
          ),
          
          const SizedBox(height: NeoSpacing.md),
          
          // Actions: Like
          Row(
            children: [
              InkWell(
                onTap: onLike,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: post.isLikedByCurrentUser
                        ? NeoColors.accent.withValues(alpha: 0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: post.isLikedByCurrentUser
                          ? NeoColors.accent
                          : Colors.white24,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        post.isLikedByCurrentUser
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: post.isLikedByCurrentUser
                            ? NeoColors.accent
                            : Colors.white70,
                        size: 16,
                      ),
                      if (post.likes > 0) ...[
                        const SizedBox(width: 4),
                        Text(
                          '${post.likes}',
                          style: TextStyle(
                            color: post.isLikedByCurrentUser
                                ? NeoColors.accent
                                : Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
