/// Project Neo - Community Preview Screen
///
/// "El Portal" - Preview screen shown before joining a community.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/neo_theme.dart';
import '../../domain/entities/community_entity.dart';
import '../utils/category_utils.dart';

class CommunityPreviewScreen extends ConsumerStatefulWidget {
  final CommunityEntity community;

  const CommunityPreviewScreen({
    super.key,
    required this.community,
  });

  @override
  ConsumerState<CommunityPreviewScreen> createState() =>
      _CommunityPreviewScreenState();
}

class _CommunityPreviewScreenState
    extends ConsumerState<CommunityPreviewScreen> {
  final _accessCodeController = TextEditingController();
  bool _isAccessCodeValid = false;

  @override
  void dispose() {
    _accessCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildCommunityInfo(),
                const SizedBox(height: 16),
                _buildThematicTags(),
                const SizedBox(height: 24),
                _buildWelcomeContent(),
                const SizedBox(height: 100), // Bottom padding for action bar
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomActionBar(),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEADER - SLIVER APP BAR WITH HERO ANIMATION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSliverAppBar() {
    final coverUrl = widget.community.bannerUrl;
    final iconUrl = widget.community.iconUrl;

    return SliverAppBar(
      expandedHeight: 280,
      floating: false,
      pinned: true,
      backgroundColor: Colors.black,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Cover Image with Hero animation
            Hero(
              tag: 'community_cover_${widget.community.id}',
              child: Material(
                type: MaterialType.transparency,
                child: coverUrl != null
                    ? Image.network(
                        coverUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _buildPlaceholderBackground(),
                      )
                    : _buildPlaceholderBackground(),
              ),
            ),

            // Dark gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.9),
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),

            // Community Logo (overlapping at bottom)
            Positioned(
              left: 20,
              bottom: 20,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(17),
                  child: iconUrl != null
                      ? Image.network(
                          iconUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholderIcon(),
                        )
                      : _buildPlaceholderIcon(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _parseColor(widget.community.theme.primaryColor),
            _parseColor(widget.community.theme.secondaryColor),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.groups_rounded,
          size: 100,
          color: Colors.white.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _parseColor(widget.community.theme.primaryColor),
            _parseColor(widget.community.theme.accentColor),
          ],
        ),
      ),
      child: const Icon(
        Icons.groups_rounded,
        color: Colors.white,
        size: 40,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COMMUNITY INFO SECTION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCommunityInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            widget.community.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),

          // Stats Row
          Row(
            children: [
              // Members
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: NeoColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: NeoColors.border,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.people_alt_rounded,
                      size: 16,
                      color: NeoColors.accent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_formatMemberCount(widget.community.memberCount)} Miembros',
                      style: NeoTextStyles.labelMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Online indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: NeoColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: NeoColors.border,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981), // Green
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Activa',
                      style: NeoTextStyles.labelMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Description
          if (widget.community.description != null) ...[
            const SizedBox(height: 16),
            Text(
              widget.community.description!,
              style: NeoTextStyles.bodyMedium.copyWith(
                color: NeoColors.textSecondary,
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // THEMATIC TAGS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildThematicTags() {
    if (widget.community.categoryIds.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Temáticas',
            style: NeoTextStyles.labelLarge.copyWith(
              color: NeoColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.community.categoryIds.map((categoryId) {
              final categoryInfo = CategoryUtils.getCategoryInfo(categoryId);
              final color = categoryInfo?.color ??
                  CategoryUtils.getCategoryColor(categoryId);
              final name = categoryInfo?.name ??
                  CategoryUtils.getCategoryName(categoryId);
              final emoji = categoryInfo?.emoji ??
                  CategoryUtils.getCategoryEmoji(categoryId);

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: color.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      emoji,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      name,
                      style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WELCOME CONTENT
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildWelcomeContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: NeoColors.accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: NeoColors.accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Bienvenida y Reglas',
                style: NeoTextStyles.headlineSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Welcome content card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: NeoColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: NeoColors.border,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeSection(
                  icon: Icons.waving_hand,
                  iconColor: const Color(0xFFFBBF24),
                  title: '¡Bienvenido!',
                  content:
                      'Nos alegra que estés interesado en unirte a nuestra comunidad. Aquí encontrarás un espacio para compartir, aprender y conectar con personas que comparten tus intereses.',
                ),
                const SizedBox(height: 20),
                _buildWelcomeSection(
                  icon: Icons.rule,
                  iconColor: NeoColors.accent,
                  title: 'Reglas de la Comunidad',
                  content:
                      '• Respeta a todos los miembros\n• No spam ni contenido inapropiado\n• Mantén las conversaciones en tema\n• Sé amable y constructivo\n• Disfruta y participa activamente',
                ),
                const SizedBox(height: 20),
                _buildWelcomeSection(
                  icon: Icons.stars,
                  iconColor: const Color(0xFFEC4899),
                  title: 'Qué Esperar',
                  content:
                      'Contenido exclusivo, eventos especiales, chats activos y una comunidad vibrante esperándote. ¡Únete ahora y sé parte de algo especial!',
                ),
              ],
            ),
          ),

          // Private community access code
          if (widget.community.isPrivate) ...[
            const SizedBox(height: 24),
            _buildAccessCodeSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildWelcomeSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: NeoTextStyles.bodyLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                content,
                style: NeoTextStyles.bodyMedium.copyWith(
                  color: NeoColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccessCodeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFBBF24).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFBBF24).withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lock_outline,
                color: Color(0xFFFBBF24),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Comunidad Privada',
                style: NeoTextStyles.headlineSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Esta comunidad requiere un código de acceso para unirse. Solicítalo al administrador.',
            style: NeoTextStyles.bodyMedium.copyWith(
              color: NeoColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _accessCodeController,
            style: NeoTextStyles.bodyMedium.copyWith(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Ingresa el código de acceso',
              hintStyle: NeoTextStyles.bodyMedium.copyWith(
                color: NeoColors.textTertiary,
              ),
              prefixIcon: const Icon(
                Icons.vpn_key,
                color: NeoColors.textTertiary,
              ),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: NeoColors.border,
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: NeoColors.border,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFFBBF24),
                  width: 2,
                ),
              ),
            ),
            onChanged: (value) {
              setState(() {
                // Simple validation - in production, verify against backend
                _isAccessCodeValid = value.trim().length >= 4;
              });
            },
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BOTTOM ACTION BAR
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildBottomActionBar() {
    final canJoin = !widget.community.isPrivate || _isAccessCodeValid;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border(
          top: BorderSide(
            color: NeoColors.border.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          child: Row(
            children: [
              // Secondary Button - Enter as Guest
              Expanded(
                flex: 2,
                child: OutlinedButton(
                  onPressed: _enterAsGuest,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: NeoColors.border,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.visibility_outlined, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Observador',
                        style: NeoTextStyles.labelLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Primary Button - Join
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  onPressed: canJoin ? _joinCommunity : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _parseColor(widget.community.theme.accentColor),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: NeoColors.card,
                    disabledForegroundColor: NeoColors.textTertiary,
                    elevation: canJoin ? 8 : 0,
                    shadowColor: canJoin
                        ? _parseColor(widget.community.theme.accentColor)
                            .withValues(alpha: 0.5)
                        : Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        canJoin ? Icons.add_circle_outline : Icons.lock_outline,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Unirse',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  void _joinCommunity() {
    // Navigate to community home as member
    context.push('/community_home', extra: {
      'community': widget.community,
      'isGuest': false,
    });
  }

  void _enterAsGuest() {
    // Navigate to community home as guest/observer
    context.push('/community_home', extra: {
      'community': widget.community,
      'isGuest': true,
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  String _formatMemberCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  Color _parseColor(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return const Color(0xFF8B5CF6); // Fallback purple
    }
  }
}
