/// Project Neo - Community Home Screen
///
/// Immersive community interior screen with tabs.
library;

import 'package:flutter/material.dart';
import '../../../../core/theme/neo_theme.dart';
import '../../../community/domain/entities/community_entity.dart';

class CommunityHomeScreen extends StatefulWidget {
  final CommunityEntity community;

  const CommunityHomeScreen({
    super.key,
    required this.community,
  });

  @override
  State<CommunityHomeScreen> createState() => _CommunityHomeScreenState();
}

class _CommunityHomeScreenState extends State<CommunityHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
      floatingActionButton: _buildFAB(),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEADER - SLIVER APP BAR
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSliverAppBar() {
    final coverUrl = widget.community.bannerUrl;

    return SliverAppBar(
      expandedHeight: 200,
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
        title: Text(
          widget.community.title,
          style: NeoTextStyles.headlineSmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                offset: const Offset(0, 1),
                blurRadius: 3,
                color: Colors.black.withValues(alpha: 0.8),
              ),
            ],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Cover Image
            if (coverUrl != null)
              Image.network(
                coverUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholderBackground(),
              )
            else
              _buildPlaceholderBackground(),

            // Dark gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.6),
                    Colors.black.withValues(alpha: 0.9),
                  ],
                  stops: const [0.3, 0.7, 1.0],
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
          size: 80,
          color: Colors.white.withValues(alpha: 0.3),
        ),
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

  Widget _buildDestacadosTab() {
    // Dummy blog cards
    final blogs = List.generate(
      5,
      (index) => {
        'title': 'Blog Post ${index + 1}',
        'image': null,
      },
    );

    return ListView.builder(
      padding: const EdgeInsets.all(NeoSpacing.md),
      itemCount: blogs.length,
      itemBuilder: (context, index) {
        final blog = blogs[index];
        return Container(
          margin: const EdgeInsets.only(bottom: NeoSpacing.md),
          height: 200,
          decoration: BoxDecoration(
            color: NeoColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: NeoColors.border,
              width: NeoSpacing.borderWidth,
            ),
          ),
          child: Stack(
            children: [
              // Placeholder gradient
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        NeoColors.accent.withValues(alpha: 0.2),
                        NeoColors.accent.withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                ),
              ),
              // Title
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Text(
                  blog['title'] as String,
                  style: NeoTextStyles.headlineSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

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
      padding: const EdgeInsets.all(NeoSpacing.md),
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

  Widget _buildMiembrosTab() {
    // Dummy members (leaders and curators)
    final leaders = List.generate(2, (index) => 'Líder ${index + 1}');
    final curators = List.generate(5, (index) => 'Curador ${index + 1}');

    return ListView(
      padding: const EdgeInsets.all(NeoSpacing.md),
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
  // FAB
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [
            Color(0xFF8B5CF6), // Purple
            Color(0xFF3B82F6), // Blue
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () {
          // TODO: Implement create action
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 32,
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
