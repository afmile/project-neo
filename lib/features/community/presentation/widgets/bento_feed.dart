/// Project Neo - Bento Feed
///
/// Staggered grid feed with pinned post support.
library;

import 'package:flutter/material.dart';
import '../../../../core/theme/neo_theme.dart';
import '../../../../core/theme/neo_widgets.dart';
import '../../domain/entities/post_entity.dart';

/// Bento grid feed for community posts
class BentoFeed extends StatelessWidget {
  final List<PostEntity> posts;
  final Color accentColor;
  final void Function(PostEntity post)? onPostTap;
  
  const BentoFeed({
    super.key,
    required this.posts,
    this.accentColor = NeoColors.accent,
    this.onPostTap,
  });

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return _buildEmptyState();
    }
    
    return SliverPadding(
      padding: const EdgeInsets.all(NeoSpacing.md),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: NeoSpacing.md,
          crossAxisSpacing: NeoSpacing.md,
          childAspectRatio: 1,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildPostCard(context, posts[index]),
          childCount: posts.length,
        ),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.post_add_rounded,
              size: 64,
              color: NeoColors.textTertiary,
            ),
            const SizedBox(height: NeoSpacing.md),
            Text(
              'Sin publicaciones',
              style: NeoTextStyles.headlineSmall.copyWith(
                color: NeoColors.textSecondary,
              ),
            ),
            const SizedBox(height: NeoSpacing.xs),
            Text(
              'Sé el primero en publicar',
              style: NeoTextStyles.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPostCard(BuildContext context, PostEntity post) {
    // Calculate if this is a double-width card
    final isLarge = post.isPinned && post.pinSize != PinSize.normal;
    
    return NeoCard(
      onTap: onPostTap != null ? () => onPostTap!(post) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pinned indicator
          if (post.isPinned)
            Container(
              margin: const EdgeInsets.only(bottom: NeoSpacing.sm),
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.push_pin_rounded,
                    size: 12,
                    color: accentColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Fijado',
                    style: NeoTextStyles.labelSmall.copyWith(
                      color: accentColor,
                    ),
                  ),
                ],
              ),
            ),
          
          // Title with accent color
          if (post.title != null) ...[
            Text(
              post.title!,
              style: NeoTextStyles.headlineSmall.copyWith(
                color: post.isPinned ? accentColor : NeoColors.textPrimary,
              ),
              maxLines: isLarge ? 3 : 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: NeoSpacing.xs),
          ],
          
          // Content preview
          if (post.content != null)
            Expanded(
              child: Text(
                post.content!,
                style: NeoTextStyles.bodyMedium,
                maxLines: isLarge ? 6 : 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          
          const Spacer(),
          
          // Footer with author and stats
          Row(
            children: [
              // Author avatar
              CircleAvatar(
                radius: 12,
                backgroundColor: NeoColors.card,
                backgroundImage: post.authorAvatarUrl != null
                    ? NetworkImage(post.authorAvatarUrl!)
                    : null,
                child: post.authorAvatarUrl == null
                    ? const Icon(Icons.person, size: 14, color: NeoColors.textTertiary)
                    : null,
              ),
              const SizedBox(width: NeoSpacing.xs),
              Expanded(
                child: Text(
                  post.authorUsername ?? 'Anónimo',
                  style: NeoTextStyles.labelSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              // Stats
              if (post.reactionsCount > 0) ...[
                Icon(
                  Icons.favorite_rounded,
                  size: 14,
                  color: NeoColors.textTertiary,
                ),
                const SizedBox(width: 2),
                Text(
                  '${post.reactionsCount}',
                  style: NeoTextStyles.labelSmall,
                ),
              ],
              if (post.commentsCount > 0) ...[
                const SizedBox(width: NeoSpacing.sm),
                Icon(
                  Icons.chat_bubble_rounded,
                  size: 14,
                  color: NeoColors.textTertiary,
                ),
                const SizedBox(width: 2),
                Text(
                  '${post.commentsCount}',
                  style: NeoTextStyles.labelSmall,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
