/// Project Neo - Community Card Widget
///
/// Reusable card for horizontal community lists.
library;

import 'package:flutter/material.dart';
import '../../../../core/theme/neo_theme.dart';

/// A card widget for displaying communities in horizontal lists
class CommunityCard extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final int memberCount;
  final VoidCallback? onTap;
  final Color? accentColor;

  const CommunityCard({
    super.key,
    required this.title,
    this.imageUrl,
    required this.memberCount,
    this.onTap,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? NeoColors.accent;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        height: 180,
        margin: const EdgeInsets.only(right: NeoSpacing.md),
        decoration: BoxDecoration(
          color: NeoColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: NeoColors.border,
            width: NeoSpacing.borderWidth,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Background gradient or image
            Positioned.fill(
              child: imageUrl != null
                  ? Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholderBackground(accent),
                    )
                  : _buildPlaceholderBackground(accent),
            ),
            
            // Dark gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha:0.6),
                      Colors.black.withValues(alpha:0.9),
                    ],
                    stops: const [0.4, 0.75, 1.0],
                  ),
                ),
              ),
            ),
            
            // Content at bottom
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                   Text(
                    title,
                    style: NeoTextStyles.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                      shadows: [
                        Shadow(
                          offset: const Offset(0, 1),
                          blurRadius: 2,
                          color: Colors.black.withValues(alpha:0.5),
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.people_alt_rounded,
                        size: 14,
                        color: Colors.white.withValues(alpha:0.8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatMemberCount(memberCount),
                        style: NeoTextStyles.labelSmall.copyWith(
                          color: Colors.white.withValues(alpha:0.8),
                          fontWeight: FontWeight.w500,
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

  Widget _buildPlaceholderBackground(Color accent) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.3),
            accent.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.groups_rounded,
          size: 40,
          color: accent.withValues(alpha: 0.5),
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
}
