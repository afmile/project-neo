/// Project Neo - Profile Header Section
///
/// Premium header displaying user avatar, name, level, and titles
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/neo_theme.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/member_title.dart';
import '../providers/user_titles_provider.dart';

class ProfileHeaderSection extends ConsumerWidget {
  final UserEntity user;
  final String communityId;
  final bool isOnline;
  final bool isVerified;

  const ProfileHeaderSection({
    super.key,
    required this.user,
    required this.communityId,
    this.isOnline = false,
    this.isVerified = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fetch titles for this user
    final titlesAsync = ref.watch(userTitlesProvider(UserTitlesParams(
      userId: user.id,
      communityId: communityId,
      maxTitles: 3,
    )));

    return Column(
      children: [
        // Avatar with ring and online dot
        Stack(
          clipBehavior: Clip.none,
          children: [
            // Avatar with glow effect
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: NeoColors.accent.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: NeoColors.accent,
                    width: 3,
                  ),
                ),
                child: ClipOval(
                  child: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                      ? Image.network(
                          user.avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildDefaultAvatar(),
                        )
                      : _buildDefaultAvatar(),
                ),
              ),
            ),
            
            // Online indicator dot
            if (isOnline)
              Positioned(
                right: 4,
                bottom: 4,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: NeoColors.online,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.black,
                      width: 3,
                    ),
                  ),
                ),
              ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Display name (local nickname or global username)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                user.username,
                style: NeoTextStyles.headlineLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            // Verified badge
            if (isVerified) ...[
              const SizedBox(width: 6),
              const Icon(
                Icons.verified,
                color: NeoColors.accent,
                size: 20,
              ),
            ],
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Level badge
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Nivel ${user.clearanceLevel}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // User Titles (Amino-style) - Right below level badge
        titlesAsync.when(
          loading: () => const SizedBox(height: 24),
          error: (_, __) => const SizedBox.shrink(),
          data: (titles) => _buildTitlesRow(titles),
        ),
      ],
    );
  }

  Widget _buildTitlesRow(List<MemberTitle> titles) {
    if (titles.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final memberTitle in titles)
            _buildTitleChip(memberTitle),
        ],
      ),
    );
  }

  Widget _buildTitleChip(MemberTitle memberTitle) {
    final title = memberTitle.title;
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: title.style.bgColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: title.style.bgColor.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title.style.iconName != null) ...[
            Icon(
              _getIconData(title.style.iconName!),
              size: 12,
              color: title.style.fgColor,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            title.name,
            style: TextStyle(
              color: title.style.fgColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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

  Widget _buildDefaultAvatar() {
    return Container(
      color: NeoColors.accent.withValues(alpha: 0.2),
      child: const Icon(
        Icons.person,
        color: NeoColors.accent,
        size: 50,
      ),
    );
  }
}
