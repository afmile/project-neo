/// Project Neo - Neo Feed Card
///
/// Custom feed card for global feed display with smart navigation.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/neo_theme.dart';
import '../providers/home_providers.dart';

class NeoFeedCard extends ConsumerWidget {
  final FeedPost post;

  const NeoFeedCard({
    super.key,
    required this.post,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _handleTap(context, ref),
      child: Container(
        margin: const EdgeInsets.only(bottom: NeoSpacing.md),
        decoration: BoxDecoration(
          color: NeoColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: NeoColors.border,
            width: NeoSpacing.borderWidth,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Community info
            Padding(
              padding: const EdgeInsets.all(NeoSpacing.md),
              child: Row(
                children: [
                  // Community avatar
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: NeoColors.accent.withValues(alpha: 0.2),
                    ),
                    child: Center(
                      child: Text(
                        post.communityAvatar,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: NeoSpacing.sm),
                  // Community name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'En: ${post.communityName}',
                          style: NeoTextStyles.bodyMedium.copyWith(
                            color: NeoColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          post.timeAgo,
                          style: NeoTextStyles.labelSmall.copyWith(
                            color: NeoColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // More options
                  IconButton(
                    icon: const Icon(
                      Icons.more_horiz,
                      color: NeoColors.textSecondary,
                      size: 20,
                    ),
                    onPressed: () {
                      // TODO: Show options menu
                    },
                  ),
                ],
              ),
            ),

            // Cover Image
            if (post.coverImageUrl != null)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(0),
                    bottom: Radius.circular(0),
                  ),
                  child: Image.network(
                    post.coverImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                  ),
                ),
              )
            else
              _buildPlaceholderImage(),

            // Content: Title and summary
            Padding(
              padding: const EdgeInsets.all(NeoSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    style: NeoTextStyles.headlineSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: NeoSpacing.xs),
                  Text(
                    post.summary,
                    style: NeoTextStyles.bodyMedium.copyWith(
                      color: NeoColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Footer: Interactions
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: NeoSpacing.md,
                vertical: NeoSpacing.sm,
              ),
              child: Row(
                children: [
                  _buildInteractionButton(
                    icon: Icons.favorite_border,
                    count: post.likes,
                    color: Colors.red,
                  ),
                  const SizedBox(width: NeoSpacing.lg),
                  _buildInteractionButton(
                    icon: Icons.chat_bubble_outline,
                    count: post.comments,
                    color: NeoColors.accent,
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.bookmark_border,
                    color: NeoColors.textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SMART NAVIGATION LOGIC (PORTERO)
  // ═══════════════════════════════════════════════════════════════════════════

  void _handleTap(BuildContext context, WidgetRef ref) {
    // Get user's joined communities
    final myCommunities = ref.read(myCommunitiesProvider);
    
    // Check if user is a member of this post's community
    final isMember = myCommunities.any((c) => c.id == post.communityId);
    
    if (isMember) {
      // User is a member → Navigate to blog detail
      context.push('/blog_detail', extra: post);
    } else {
      // User is NOT a member → Navigate to community home to join first
      // Find the community entity from all communities
      final allCommunities = ref.read(allCommunitiesProvider);
      final community = allCommunities.firstWhere(
        (c) => c.id == post.communityId,
        orElse: () {
          // Fallback: try recommended communities
          final recommended = ref.read(recommendedCommunitiesProvider);
          return recommended.firstWhere(
            (c) => c.id == post.communityId,
            orElse: () {
              // Fallback: try recent communities
              final recent = ref.read(recentCommunitiesProvider);
              return recent.firstWhere(
                (c) => c.id == post.communityId,
              );
            },
          );
        },
      );
      
      context.push('/community_home', extra: community);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UI HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPlaceholderImage() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              NeoColors.accent.withValues(alpha: 0.3),
              NeoColors.accent.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: Center(
          child: Icon(
            Icons.image_outlined,
            size: 48,
            color: NeoColors.textTertiary,
          ),
        ),
      ),
    );
  }

  Widget _buildInteractionButton({
    required IconData icon,
    required int count,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: NeoColors.textSecondary,
          size: 20,
        ),
        const SizedBox(width: 4),
        Text(
          _formatCount(count),
          style: NeoTextStyles.labelMedium.copyWith(
            color: NeoColors.textSecondary,
          ),
        ),
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }
}
