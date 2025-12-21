/// Project Neo - Community Home Screen
///
/// Immersive community interior screen with Amino-style aesthetics.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../../../core/theme/neo_theme.dart';
import '../../../community/domain/entities/community_entity.dart';
import '../../../home/presentation/providers/home_providers.dart';

class CommunityHomeScreen extends ConsumerStatefulWidget {
  final CommunityEntity community;

  const CommunityHomeScreen({
    super.key,
    required this.community,
  });

  @override
  ConsumerState<CommunityHomeScreen> createState() => _CommunityHomeScreenState();
}

class _CommunityHomeScreenState extends ConsumerState<CommunityHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isMember = false; // Membership state - false = visitor, true = member

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            _buildSliverAppBar(),
            _buildSliverTabBar(),
          ];
        },
        body: _buildTabBarView(),
      ),
      // Conditional bottom bar based on membership
      floatingActionButton: isMember ? _buildCentralFAB() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: isMember ? _buildBottomAppBar() : _buildJoinBar(),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEADER - SLIVER APP BAR (AMINO STYLE)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSliverAppBar() {
    final coverUrl = widget.community.bannerUrl;
    final iconUrl = widget.community.iconUrl;

    return SliverAppBar(
      expandedHeight: 220,
      floating: false,
      pinned: true,
      backgroundColor: Colors.black,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          onPressed: () {
            // TODO: Implement search
          },
        ),
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onPressed: () {
            // TODO: Implement menu
          },
        ),
      ],
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
                        errorBuilder: (_, __, ___) => _buildPlaceholderBackground(),
                      )
                    : _buildPlaceholderBackground(),
              ),
            ),

            // Strong dark gradient for contrast
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.4),
                    Colors.black.withValues(alpha: 0.85),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),

            // Bottom overlay with icon and info (Amino style)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Community Icon (overlapping)
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white,
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: iconUrl != null
                          ? Image.network(
                              iconUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _buildPlaceholderIcon(),
                            )
                          : _buildPlaceholderIcon(),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Community Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Community Name
                        Text(
                          widget.community.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),

                        // Member Stats
                        Row(
                          children: [
                            const Icon(
                              Icons.person_outline,
                              color: Colors.white70,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_formatMemberCount(widget.community.memberCount)} Miembros',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981), // Green
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              '150 Online',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
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
          size: 80,
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
        size: 32,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB BAR
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSliverTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverTabBarDelegate(
        TabBar(
          controller: _tabController,
          indicatorColor: NeoColors.accent,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: NeoColors.textSecondary,
          labelStyle: NeoTextStyles.labelLarge.copyWith(
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: NeoTextStyles.labelLarge,
          tabs: const [
            Tab(text: 'Destacados'),
            Tab(text: 'Chats'),
            Tab(text: 'Miembros'),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB BAR VIEW
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildDestacadosTab(),
        _buildChatsTab(),
        _buildMiembrosTab(),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DESTACADOS TAB - STAGGERED GRID (AMINO/PINTEREST STYLE)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildDestacadosTab() {
    // Dummy blog posts with varied heights
    final blogs = List.generate(
      12,
      (index) => {
        'title': _getBlogTitle(index),
        'height': _getBlogHeight(index),
        'gradient': _getBlogGradient(index),
      },
    );

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(12),
          sliver: SliverMasonryGrid.count(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childCount: blogs.length,
            itemBuilder: (context, index) {
              final blog = blogs[index];
              return _buildBlogCard(
                title: blog['title'] as String,
                height: blog['height'] as double,
                gradient: blog['gradient'] as List<Color>,
              );
            },
          ),
        ),
        // Add bottom padding for FAB
        const SliverToBoxAdapter(
          child: SizedBox(height: 80),
        ),
      ],
    );
  }

  Widget _buildBlogCard({
    required String title,
    required double height,
    required List<Color> gradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image/Cover area
            Container(
              height: height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradient,
                ),
              ),
              child: Stack(
                children: [
                  // Subtle pattern overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.3),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Title area
            Container(
              padding: const EdgeInsets.all(12),
              color: NeoColors.card,
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CHATS TAB
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildChatsTab() {
    // Dummy public chats
    final chats = List.generate(
      8,
      (index) => {
        'name': 'Chat Público ${index + 1}',
        'lastMessage': 'Último mensaje del chat...',
        'time': '${index + 1}h',
      },
    );

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: chats.length,
      itemBuilder: (context, index) {
        final chat = chats[index];
        return Container(
          margin: const EdgeInsets.only(bottom: NeoSpacing.sm),
          padding: const EdgeInsets.all(NeoSpacing.md),
          decoration: BoxDecoration(
            color: NeoColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: NeoColors.border,
              width: NeoSpacing.borderWidth,
            ),
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: NeoColors.accent.withValues(alpha: 0.2),
                ),
                child: const Icon(
                  Icons.chat_bubble_rounded,
                  color: NeoColors.accent,
                  size: 24,
                ),
              ),
              const SizedBox(width: NeoSpacing.md),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chat['name'] as String,
                      style: NeoTextStyles.bodyLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      chat['lastMessage'] as String,
                      style: NeoTextStyles.bodySmall.copyWith(
                        color: NeoColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Time
              Text(
                chat['time'] as String,
                style: NeoTextStyles.labelSmall.copyWith(
                  color: NeoColors.textTertiary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MIEMBROS TAB
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildMiembrosTab() {
    // Dummy members (leaders and curators)
    final leaders = List.generate(2, (index) => 'Líder ${index + 1}');
    final curators = List.generate(5, (index) => 'Curador ${index + 1}');

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        // Leaders Section
        Text(
          'Líderes',
          style: NeoTextStyles.headlineSmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: NeoSpacing.sm),
        ...leaders.map((name) => _buildMemberItem(name, isLeader: true)),
        const SizedBox(height: NeoSpacing.lg),

        // Curators Section
        Text(
          'Curadores',
          style: NeoTextStyles.headlineSmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: NeoSpacing.sm),
        ...curators.map((name) => _buildMemberItem(name, isLeader: false)),
      ],
    );
  }

  Widget _buildMemberItem(String name, {required bool isLeader}) {
    return Container(
      margin: const EdgeInsets.only(bottom: NeoSpacing.sm),
      padding: const EdgeInsets.all(NeoSpacing.md),
      decoration: BoxDecoration(
        color: NeoColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: NeoColors.border,
          width: NeoSpacing.borderWidth,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (isLeader ? Colors.amber : NeoColors.accent)
                  .withValues(alpha: 0.2),
              border: Border.all(
                color: isLeader ? Colors.amber : NeoColors.accent,
                width: 2,
              ),
            ),
            child: Icon(
              Icons.person_rounded,
              color: isLeader ? Colors.amber : NeoColors.accent,
              size: 24,
            ),
          ),
          const SizedBox(width: NeoSpacing.md),
          // Name
          Expanded(
            child: Text(
              name,
              style: NeoTextStyles.bodyLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Badge
          if (isLeader)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'LÍDER',
                style: NeoTextStyles.labelSmall.copyWith(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CENTRAL DOCKED FAB (AMINO STYLE)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCentralFAB() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [
            Color(0xFF8B5CF6), // Violet
            Color(0xFFEC4899), // Pink
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showCreationOptions,
          customBorder: const CircleBorder(),
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomAppBar() {
    return BottomAppBar(
      color: const Color(0xFF1A1A1A),
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Left side placeholder
            const SizedBox(width: 48),
            const SizedBox(width: 48),
            // Center space for FAB
            const SizedBox(width: 80),
            // Right side placeholder
            const SizedBox(width: 48),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // JOIN BAR (FOR NON-MEMBERS)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildJoinBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border(
          top: BorderSide(
            color: NeoColors.border.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _joinCommunity,
              style: ElevatedButton.styleFrom(
                backgroundColor: _parseColor(widget.community.theme.accentColor),
                foregroundColor: Colors.white,
                elevation: 8,
                shadowColor: _parseColor(widget.community.theme.accentColor)
                    .withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_circle_outline,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Unirse a la Comunidad',
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
        ),
      ),
    );
  }

  void _joinCommunity() {
    // Add community to global state
    ref.read(myCommunitiesProvider.notifier).joinCommunity(widget.community);
    
    setState(() {
      isMember = true;
    });

    // Show welcome message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                '¡Bienvenido a la comunidad!',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981), // Green
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CREATION OPTIONS MODAL
  // ═══════════════════════════════════════════════════════════════════════════

  void _showCreationOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1F1F1F),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            const Text(
              'Crear Contenido',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Options Grid
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildCreationOption(
                  icon: Icons.article_rounded,
                  label: 'Blog',
                  color: const Color(0xFF3B82F6), // Blue
                ),
                _buildCreationOption(
                  icon: Icons.poll_rounded,
                  label: 'Encuesta',
                  color: const Color(0xFF10B981), // Green
                ),
                _buildCreationOption(
                  icon: Icons.quiz_rounded,
                  label: 'Quiz',
                  color: const Color(0xFFF59E0B), // Amber
                ),
                _buildCreationOption(
                  icon: Icons.chat_rounded,
                  label: 'Chat Público',
                  color: const Color(0xFF8B5CF6), // Purple
                ),
                _buildCreationOption(
                  icon: Icons.link_rounded,
                  label: 'Link',
                  color: const Color(0xFFEC4899), // Pink
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCreationOption({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        // TODO: Implement creation action
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  Color _parseColor(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return NeoColors.accent;
    }
  }

  String _formatMemberCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }

  String _getBlogTitle(int index) {
    final titles = [
      'Bienvenidos a la comunidad',
      'Tutorial: Cómo empezar',
      'Reglas de la comunidad',
      'Evento especial este fin de semana',
      'Conoce a los moderadores',
      'Galería de arte de la comunidad',
      'Discusión: ¿Cuál es tu favorito?',
      'Anuncio importante',
      'Concurso de creatividad',
      'Historia de nuestra comunidad',
      'Tips y trucos para nuevos miembros',
      'Destacado del mes',
    ];
    return titles[index % titles.length];
  }

  double _getBlogHeight(int index) {
    // Varied heights for staggered effect
    final heights = [180.0, 220.0, 160.0, 200.0, 240.0, 190.0];
    return heights[index % heights.length];
  }

  List<Color> _getBlogGradient(int index) {
    final gradients = [
      [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
      [const Color(0xFF8B5CF6), const Color(0xFFEC4899)],
      [const Color(0xFF3B82F6), const Color(0xFF06B6D4)],
      [const Color(0xFF10B981), const Color(0xFF059669)],
      [const Color(0xFFF59E0B), const Color(0xFFEF4444)],
      [const Color(0xFFEC4899), const Color(0xFFF43F5E)],
    ];
    return gradients[index % gradients.length];
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SLIVER TAB BAR DELEGATE
// ═══════════════════════════════════════════════════════════════════════════

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Colors.black,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
