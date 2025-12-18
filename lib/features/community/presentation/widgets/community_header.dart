/// Project Neo - Community Header
///
/// Parallax header with Squircle logo and community info.
library;

import 'package:flutter/material.dart';
import '../../../../core/theme/neo_theme.dart';
import '../../../../core/widgets/squircle_avatar.dart';
import '../../domain/entities/community_entity.dart';

/// Parallax header for community screen
class CommunityHeader extends StatelessWidget {
  final CommunityEntity community;
  final double expandedHeight;
  final double collapsedHeight;
  final VoidCallback? onJoin;
  final bool isMember;
  
  const CommunityHeader({
    super.key,
    required this.community,
    this.expandedHeight = 280,
    this.collapsedHeight = 80,
    this.onJoin,
    this.isMember = false,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: expandedHeight,
      collapsedHeight: collapsedHeight,
      pinned: true,
      stretch: true,
      backgroundColor: NeoColors.background,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: NeoColors.card.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(NeoSpacing.smallRadius),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: NeoColors.card.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(NeoSpacing.smallRadius),
            ),
            child: const Icon(Icons.more_vert_rounded, size: 18),
          ),
          onPressed: () => _showOptionsMenu(context),
        ),
        const SizedBox(width: NeoSpacing.sm),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Banner image with parallax
            if (community.bannerUrl != null)
              Image.network(
                community.bannerUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildDefaultBanner(),
              )
            else
              _buildDefaultBanner(),
            
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    NeoColors.background.withValues(alpha: 0.5),
                    NeoColors.background,
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
            
            // Community info
            Positioned(
              left: NeoSpacing.lg,
              right: NeoSpacing.lg,
              bottom: NeoSpacing.lg,
              child: _buildCommunityInfo(context),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDefaultBanner() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _parseColor(community.theme.primaryColor),
            _parseColor(community.theme.accentColor),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCommunityInfo(BuildContext context) {
    final accentColor = _parseColor(community.accentColor);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Squircle logo
        Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: SquircleAvatar(
            imageUrl: community.iconUrl,
            size: 72,
          ),
        ),
        
        const SizedBox(width: NeoSpacing.md),
        
        // Title and stats
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                community.title,
                style: NeoTextStyles.headlineLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: NeoColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: NeoColors.border,
                        width: NeoSpacing.borderWidth,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people_alt_rounded,
                          size: 14,
                          color: accentColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatMemberCount(community.memberCount),
                          style: NeoTextStyles.labelMedium,
                        ),
                      ],
                    ),
                  ),
                  if (community.isPrivate) ...[
                    const SizedBox(width: NeoSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: NeoColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: NeoColors.border,
                          width: NeoSpacing.borderWidth,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.lock_rounded,
                            size: 14,
                            color: NeoColors.warning,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Privado',
                            style: NeoTextStyles.labelMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        
        // Join button
        if (!isMember && onJoin != null)
          ElevatedButton(
            onPressed: onJoin,
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              padding: const EdgeInsets.symmetric(
                horizontal: NeoSpacing.md,
                vertical: NeoSpacing.sm,
              ),
            ),
            child: Text(
              'Unirse',
              style: NeoTextStyles.button,
            ),
          ),
      ],
    );
  }
  
  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: NeoColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(NeoSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: NeoColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: NeoSpacing.lg),
            ListTile(
              leading: const Icon(Icons.share_rounded),
              title: const Text('Compartir'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('Notificaciones'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.report_outlined, color: NeoColors.error),
              title: const Text('Reportar', style: TextStyle(color: NeoColors.error)),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatMemberCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
  
  Color _parseColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
