/// Project Neo - My Communities Screen
///
/// Vertical list of community cards with "+ Create a new Neo" option.
/// Entry point to the Community Wizard.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/neo_theme.dart';
import '../../domain/entities/community_entity.dart';
import '../providers/community_providers.dart';
import 'create_community_screen.dart';

class MyCommunitiesScreen extends ConsumerWidget {
  const MyCommunitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final communitiesAsync = ref.watch(userCommunitiesProvider);
    
    return Scaffold(
      backgroundColor: NeoColors.background,
      appBar: AppBar(
        backgroundColor: NeoColors.background,
        title: Text(
          'Mis Comunidades',
          style: NeoTextStyles.headlineMedium.copyWith(color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: communitiesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: NeoColors.accent),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: NeoColors.error),
              const SizedBox(height: 16),
              Text(
                'Error cargando comunidades',
                style: NeoTextStyles.bodyLarge.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(userCommunitiesProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (communities) => _buildCommunityList(context, communities),
      ),
    );
  }

  Widget _buildCommunityList(BuildContext context, List<CommunityEntity> communities) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: communities.length + 1, // +1 for create card
      itemBuilder: (context, index) {
        if (index == communities.length) {
          return _CreateCommunityCard(
            onTap: () => _navigateToWizard(context),
          ).animate(delay: (index * 80).ms).fadeIn().slideY(
            begin: 0.2,
            duration: 300.ms,
            curve: Curves.easeOut,
          );
        }
        
        final community = communities[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _CommunityCard(
            community: community,
            onTap: () => _navigateToCommunity(context, community),
          ).animate(delay: (index * 80).ms).fadeIn().slideY(
            begin: 0.2,
            duration: 300.ms,
            curve: Curves.easeOut,
          ),
        );
      },
    );
  }

  void _navigateToWizard(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const CommunityWizardScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _navigateToCommunity(BuildContext context, CommunityEntity community) {
    Navigator.of(context).pushNamed('/community', arguments: community);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// COMMUNITY CARD
// ═══════════════════════════════════════════════════════════════════════════

class _CommunityCard extends StatelessWidget {
  final CommunityEntity community;
  final VoidCallback onTap;

  const _CommunityCard({
    required this.community,
    required this.onTap,
  });

  Color get _accentColor {
    try {
      final hex = community.theme.primaryColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return NeoColors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: NeoColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: NeoColors.border),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: _accentColor.withOpacity(0.2),
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(15)),
                image: community.iconUrl != null
                    ? DecorationImage(
                        image: NetworkImage(community.iconUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: community.iconUrl == null
                  ? Center(
                      child: Text(
                        community.title.isNotEmpty 
                            ? community.title[0].toUpperCase()
                            : '?',
                        style: NeoTextStyles.displaySmall.copyWith(
                          color: _accentColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : null,
            ),
            
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      community.title,
                      style: NeoTextStyles.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (community.description != null)
                      Text(
                        community.description!,
                        style: NeoTextStyles.bodySmall.copyWith(
                          color: NeoColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.people,
                          size: 14,
                          color: NeoColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatMemberCount(community.memberCount),
                          style: NeoTextStyles.labelSmall.copyWith(
                            color: NeoColors.textTertiary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _accentColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            community.isPrivate ? 'Privada' : 'Pública',
                            style: NeoTextStyles.labelSmall.copyWith(
                              color: _accentColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Arrow
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Icon(
                Icons.chevron_right,
                color: NeoColors.textTertiary,
              ),
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
}

// ═══════════════════════════════════════════════════════════════════════════
// CREATE COMMUNITY CARD (DASHED BORDER)
// ═══════════════════════════════════════════════════════════════════════════

class _CreateCommunityCard extends StatelessWidget {
  final VoidCallback onTap;

  const _CreateCommunityCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: NeoColors.card.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: NeoColors.accent.withOpacity(0.5),
            width: 2,
          ),
        ),
        child: CustomPaint(
          painter: _DashedBorderPainter(
            color: NeoColors.accent.withOpacity(0.3),
            strokeWidth: 2,
            dashWidth: 8,
            dashSpace: 4,
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: NeoColors.accent.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: NeoColors.accent.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.add,
                    color: NeoColors.accent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Crear un nuevo Neo',
                      style: NeoTextStyles.labelLarge.copyWith(
                        color: NeoColors.accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Funda tu propia comunidad',
                      style: NeoTextStyles.bodySmall.copyWith(
                        color: NeoColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashSpace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(16),
      ));

    // Draw dashed border
    final dashPath = _createDashedPath(path);
    canvas.drawPath(dashPath, paint);
  }

  Path _createDashedPath(Path source) {
    final dashPath = Path();
    for (final pathMetric in source.computeMetrics()) {
      double distance = 0;
      while (distance < pathMetric.length) {
        final len = dashWidth;
        dashPath.addPath(
          pathMetric.extractPath(distance, distance + len),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }
    return dashPath;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
