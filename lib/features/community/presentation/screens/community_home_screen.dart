/// Project Neo - Community Home Screen
///
/// Independent mini-app with own navigation system.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../../../core/theme/neo_theme.dart';
import '../../../community/domain/entities/community_entity.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../widgets/facepile_widget.dart';
import '../widgets/live_indicator_widget.dart';

class CommunityHomeScreen extends ConsumerStatefulWidget {
  final CommunityEntity community;
  final bool isGuest;
  final bool isLive;

  const CommunityHomeScreen({
    super.key,
    required this.community,
    this.isGuest = false,
    this.isLive = false,
  });

  @override
  ConsumerState<CommunityHomeScreen> createState() =>
      _CommunityHomeScreenState();
}

class _CommunityHomeScreenState extends ConsumerState<CommunityHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isMember = false;
  int _currentNavIndex = 0; // Internal navigation index
  bool _isSearching = false; // Search mode toggle
  final _searchController = TextEditingController();

  // Dummy online users for facepile
  final List<String> _onlineUsers = [
    '', // Empty strings will show placeholder avatars
    '',
    '',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    isMember = !widget.isGuest;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _buildBody(),
      floatingActionButton: isMember && _currentNavIndex == 0
          ? _buildCentralFAB()
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: isMember
          ? _buildInternalBottomNav()
          : _buildJoinBar(),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BODY - SWITCHES BASED ON INTERNAL NAV INDEX
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildBody() {
    switch (_currentNavIndex) {
      case 0:
        return _buildInicioView(); // Feed
      case 1:
        return _buildMiembrosView(); // Members
      case 2:
        return _buildInicioView(); // Center button - same as feed
      case 3:
        return _buildChatsView(); // Chats
      case 4:
        return _buildPerfilView(); // Profile
      default:
        return _buildInicioView();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INICIO VIEW (FEED) - INDEX 0
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildInicioView() {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          _buildSliverAppBar(),
          _buildSliverTabBar(),
        ];
      },
      body: _buildTabBarView(),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEADER - ADVANCED SLIVER APP BAR
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSliverAppBar() {
    final coverUrl = widget.community.bannerUrl;
    final iconUrl = widget.community.iconUrl;

    return SliverAppBar(
      expandedHeight: widget.isLive ? 250 : 220,
      floating: false,
      pinned: true,
      backgroundColor: Colors.black,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        // Search icon - toggles search mode
        IconButton(
          icon: Icon(
            _isSearching ? Icons.close : Icons.search,
            color: Colors.white,
          ),
          onPressed: () {
            setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) {
                _searchController.clear();
              }
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onPressed: () {
            // TODO: Implement menu
          },
        ),
      ],
      // Animated title - switches between title and search field
      title: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _isSearching ? _buildSearchField() : null,
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
                    Colors.black.withValues(alpha: 0.4),
                    Colors.black.withValues(alpha: 0.85),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),

            // Bottom overlay with icon and info
            Positioned(
              left: 16,
              right: 16,
              bottom: widget.isLive ? 40 : 16,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Community Icon
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

                        // Member Stats with Facepile
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
                            const SizedBox(width: 8),
                            // Facepile
                            FacepileWidget(
                              avatarUrls: _onlineUsers,
                              maxVisible: 3,
                              size: 24,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Live Indicator (if active)
            if (widget.isLive)
              Positioned(
                left: 16,
                right: 16,
                bottom: 8,
                child: LiveIndicatorWidget(
                  liveTitle: 'Cine en vivo en Sala 1',
                  onTap: () {
                    // TODO: Join live session
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      key: const ValueKey('search_field'),
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Buscar blogs, usuarios, chats...',
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 14,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
        ),
        onChanged: (value) {
          setState(() {});
          // TODO: Implement search logic
        },
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
  // TAB BAR (FOR INICIO VIEW)
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
            Tab(text: 'Blogs'),
            Tab(text: 'Wikis'),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildDestacadosTab(),
        _buildBlogsTab(),
        _buildWikisTab(),
      ],
    );
  }

  // Tab content (simplified versions)
  Widget _buildDestacadosTab() {
    final blogs = List.generate(12, (index) => {
      'title': _getBlogTitle(index),
      'height': _getBlogHeight(index),
      'gradient': _getBlogGradient(index),
    });

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
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  Widget _buildBlogsTab() {
    return const Center(
      child: Text(
        'Blogs Tab',
        style: TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }

  Widget _buildWikisTab() {
    return const Center(
      child: Text(
        'Wikis Tab',
        style: TextStyle(color: Colors.white, fontSize: 18),
      ),
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
            Container(
              height: height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradient,
                ),
              ),
            ),
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
  // MIEMBROS VIEW - INDEX 1
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildMiembrosView() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text('Miembros'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => setState(() => _currentNavIndex = 0),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildMemberItem('Usuario ${index + 1}', isLeader: index < 2),
              childCount: 10,
            ),
          ),
        ),
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
        border: Border.all(color: NeoColors.border, width: 1),
      ),
      child: Row(
        children: [
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
          Expanded(
            child: Text(
              name,
              style: NeoTextStyles.bodyLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (isLeader)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
  // CHATS VIEW - INDEX 3 (BENTO GRID)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildChatsView() {
    // Dummy chat data with live status
    final chats = List.generate(8, (index) {
      return {
        'name': 'Chat ${_getChatName(index)}',
        'lastMessage': _getChatLastMessage(index),
        'wallpaper': _getChatWallpaper(index),
        'hasAudio': index % 3 == 0, // Every 3rd has audio
        'hasVideo': index % 4 == 0, // Every 4th has video
      };
    });

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text('Chats'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => setState(() => _currentNavIndex = 0),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(12),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final chat = chats[index];
                return _buildChatCard(
                  name: chat['name'] as String,
                  lastMessage: chat['lastMessage'] as String,
                  wallpaper: chat['wallpaper'] as List<Color>,
                  hasAudio: chat['hasAudio'] as bool,
                  hasVideo: chat['hasVideo'] as bool,
                );
              },
              childCount: chats.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  Widget _buildChatCard({
    required String name,
    required String lastMessage,
    required List<Color> wallpaper,
    required bool hasAudio,
    required bool hasVideo,
  }) {
    // Determine border color based on live status
    Color? borderColor;
    IconData? statusIcon;
    
    if (hasVideo) {
      borderColor = const Color(0xFFEF4444); // Red neon
      statusIcon = Icons.fiber_manual_record; // REC icon
    } else if (hasAudio) {
      borderColor = const Color(0xFF10B981); // Green neon
      statusIcon = Icons.volume_up;
    }

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
        child: Stack(
          children: [
            // Wallpaper background (darkened)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: wallpaper,
                  ),
                ),
              ),
            ),

            // Dark overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.4),
                      Colors.black.withValues(alpha: 0.7),
                      Colors.black.withValues(alpha: 0.9),
                    ],
                  ),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo with live status border
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: borderColor != null
                          ? Border.all(
                              color: borderColor,
                              width: 3,
                            )
                          : null,
                      boxShadow: borderColor != null
                          ? [
                              BoxShadow(
                                color: borderColor.withValues(alpha: 0.6),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: NeoColors.card,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.chat_bubble_rounded,
                        color: NeoColors.accent,
                        size: 28,
                      ),
                    ),
                  ),

                  // Status icon (if live)
                  if (statusIcon != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: borderColor!.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: borderColor,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            statusIcon,
                            color: borderColor,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            hasVideo ? 'LIVE' : 'AUDIO',
                            style: TextStyle(
                              color: borderColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const Spacer(),

                  // Footer: Name and last message
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastMessage,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getChatName(int index) {
    final names = [
      'General',
      'Anime Lovers',
      'Gaming Zone',
      'Off-Topic',
      'Cine Club',
      'Arte y Diseño',
      'Música',
      'Memes',
    ];
    return names[index % names.length];
  }

  String _getChatLastMessage(int index) {
    final messages = [
      'Hola a todos! Cómo están?',
      'Alguien vio el último episodio?',
      'GG! Buena partida',
      'jajaja ese meme está buenísimo',
      'Vamos a ver la película en 10 min',
      'Increíble ese fan art!',
      '🎵 Escuchando lo nuevo de...',
      'JAJAJAJA no puede ser',
    ];
    return messages[index % messages.length];
  }

  List<Color> _getChatWallpaper(int index) {
    final wallpapers = [
      [const Color(0xFF1E3A8A), const Color(0xFF3B82F6)], // Blue
      [const Color(0xFF7C2D12), const Color(0xFFEF4444)], // Red
      [const Color(0xFF065F46), const Color(0xFF10B981)], // Green
      [const Color(0xFF7C2D12), const Color(0xFFF59E0B)], // Orange
      [const Color(0xFF581C87), const Color(0xFF8B5CF6)], // Purple
      [const Color(0xFF831843), const Color(0xFFEC4899)], // Pink
      [const Color(0xFF164E63), const Color(0xFF06B6D4)], // Cyan
      [const Color(0xFF713F12), const Color(0xFFFBBF24)], // Yellow
    ];
    return wallpapers[index % wallpapers.length];
  }


  // ═══════════════════════════════════════════════════════════════════════════
  // PERFIL VIEW - INDEX 4
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPerfilView() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text('Mi Perfil'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => setState(() => _currentNavIndex = 0),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(
            child: Column(
              children: [
                // Avatar
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: NeoColors.accent.withValues(alpha: 0.2),
                    border: Border.all(color: NeoColors.accent, width: 3),
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 50,
                    color: NeoColors.accent,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Usuario Demo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Miembro desde hace 3 meses',
                  style: NeoTextStyles.bodyMedium.copyWith(
                    color: NeoColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                // Stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem('Posts', '42'),
                    _buildStatItem('Likes', '1.2K'),
                    _buildStatItem('Comments', '328'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: NeoTextStyles.labelMedium.copyWith(
            color: NeoColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INTERNAL BOTTOM NAVIGATION (5 ITEMS)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildInternalBottomNav() {
    return BottomAppBar(
      color: const Color(0xFF1A1A1A),
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home, 'Inicio', 0),
            _buildNavItem(Icons.people, 'Miembros', 1),
            const SizedBox(width: 48), // Space for FAB
            _buildNavItem(Icons.chat_bubble, 'Chats', 3),
            _buildNavItem(Icons.person, 'Perfil', 4),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentNavIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentNavIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? NeoColors.accent : NeoColors.textSecondary,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? NeoColors.accent : NeoColors.textSecondary,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CENTRAL FAB
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCentralFAB() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
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
          child: const Icon(Icons.add, color: Colors.white, size: 32),
        ),
      ),
    );
  }

  void _showCreationOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: NeoColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Crear Contenido',
              style: NeoTextStyles.headlineSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildCreationOption(Icons.article, 'Nuevo Blog', () {}),
            _buildCreationOption(Icons.poll, 'Nueva Encuesta', () {}),
            _buildCreationOption(Icons.quiz, 'Nuevo Quiz', () {}),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCreationOption(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: NeoColors.accent.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: NeoColors.accent),
      ),
      title: Text(
        label,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
      onTap: onTap,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // JOIN BAR (FOR GUESTS)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildJoinBar() {
    return Container(
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'Unirse a la Comunidad',
                    style: TextStyle(
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
    ref.read(myCommunitiesProvider.notifier).joinCommunity(widget.community);
    setState(() => isMember = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('¡Bienvenido a la comunidad!'),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  String _formatMemberCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  Color _parseColor(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return const Color(0xFF8B5CF6);
    }
  }

  String _getBlogTitle(int index) {
    final titles = [
      'Guía definitiva de RPG',
      'Top 10 Anime 2024',
      'Cómo mejorar en PvP',
      'Review: Nuevo juego',
      'Teoría del lore',
      'Fan art showcase',
      'Builds recomendados',
      'Easter eggs ocultos',
      'Speedrun tutorial',
      'Comunidad highlights',
      'Eventos próximos',
      'Discusión semanal',
    ];
    return titles[index % titles.length];
  }

  double _getBlogHeight(int index) {
    final heights = [150.0, 180.0, 200.0, 160.0, 190.0, 170.0];
    return heights[index % heights.length];
  }

  List<Color> _getBlogGradient(int index) {
    final gradients = [
      [const Color(0xFFEF4444), const Color(0xFFC026D3)],
      [const Color(0xFF3B82F6), const Color(0xFF8B5CF6)],
      [const Color(0xFF10B981), const Color(0xFF059669)],
      [const Color(0xFFF59E0B), const Color(0xFFEF4444)],
      [const Color(0xFF8B5CF6), const Color(0xFFEC4899)],
      [const Color(0xFF06B6D4), const Color(0xFF3B82F6)],
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
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.black,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) => false;
}
