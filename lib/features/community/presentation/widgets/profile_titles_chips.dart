/// Project Neo - Profile Titles Chips
///
/// Displays user titles (Amino-style tags) with colorful chips
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/neo_theme.dart';
import '../../domain/entities/member_title.dart';
import '../providers/user_titles_provider.dart';

class ProfileTitlesChips extends ConsumerWidget {
  final String userId;
  final String communityId;
  final int maxTitles;

  const ProfileTitlesChips({
    super.key,
    required this.userId,
    required this.communityId,
    this.maxTitles = 4, // Default: show max 4 titles
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titlesAsync = ref.watch(userTitlesProvider(UserTitlesParams(
      userId: userId,
      communityId: communityId,
      maxTitles: maxTitles,
    )));

    return titlesAsync.when(
      loading: () => const SizedBox(height: 40),
      error: (_, __) => const SizedBox.shrink(),
      data: (titles) {
        if (titles.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'TÍTULOS',
                style: NeoTextStyles.labelSmall.copyWith(
                  color: NeoColors.textSecondary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            
            // Title chips
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final memberTitle in titles)
                  _buildTitleChip(memberTitle),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildTitleChip(MemberTitle memberTitle) {
    final title = memberTitle.title;
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: title.style.bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: title.style.bgColor.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Optional icon
          if (title.style.iconName != null) ...[
            Icon(
              _getIconData(title.style.iconName!),
              size: 14,
              color: title.style.fgColor,
            ),
            const SizedBox(width: 4),
          ],
          
          // Title text
          Text(
            title.name,
            style: TextStyle(
              color: title.style.fgColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Center(
        child: Text(
          'Sin títulos aún',
          style: NeoTextStyles.bodySmall.copyWith(
            color: NeoColors.textTertiary,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'star':
        return Icons.star;
      case 'crown':
        return Icons.emoji_events;
      case 'verified':
        return Icons.verified;
      case 'diamond':
        return Icons.diamond;
      case 'shield':
        return Icons.shield;
      case 'heart':
        return Icons.favorite;
      case 'fire':
        return Icons.local_fire_department;
      case 'rocket':
        return Icons.rocket_launch;
      default:
        return Icons.label;
    }
  }
}
