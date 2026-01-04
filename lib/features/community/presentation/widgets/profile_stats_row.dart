/// Project Neo - Profile Stats Row
///
/// Displays user statistics (followers, following, karma/reputation)
library;

import 'package:flutter/material.dart';
import '../../../../core/theme/neo_theme.dart';
import '../../domain/entities/user_stats.dart';

class ProfileStatsRow extends StatelessWidget {
  final UserStats stats;
  final VoidCallback? onFollowersTap;
  final VoidCallback? onFollowingTap;
  final VoidCallback? onKarmaTap;

  const ProfileStatsRow({
    super.key,
    required this.stats,
    this.onFollowersTap,
    this.onFollowingTap,
    this.onKarmaTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            label: 'Seguidores',
            value: stats.followersCount,
            onTap: onFollowersTap,
          ),
          
          Container(
            width: 1,
            height: 40,
            color: NeoColors.border,
          ),
          
          _buildStatItem(
            label: 'Siguiendo',
            value: stats.followingCount,
            onTap: onFollowingTap,
          ),
          
          Container(
            width: 1,
            height: 40,
            color: NeoColors.border,
          ),
          
          _buildStatItem(
            label: 'Karma',
            value: 0, // Placeholder TODO: Implement karma/reputation system
            onTap: onKarmaTap,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required int value,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Text(
              _formatNumber(value),
              style: NeoTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: NeoColors.accent,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: NeoTextStyles.labelSmall.copyWith(
                color: NeoColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
