/// Project Neo - Community Home Screen
///
/// Independent mini-app with own navigation system.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/neo_theme.dart';
import '../../../community/domain/entities/community_entity.dart';
import '../../../community/domain/entities/post_entity.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../widgets/facepile_widget.dart';
import '../widgets/live_indicator_widget.dart';
import '../../../chat/presentation/screens/community_chats_screen.dart';
import '../../../chat/presentation/widgets/chat_catalog_grid.dart';
import '../../../chat/presentation/screens/create_chat_screen.dart';
import 'community_user_profile_screen.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'community_members_screen.dart';
import 'create_content_screen.dart';
import 'content_detail_screen.dart';
import '../providers/content_providers.dart';
import '../providers/community_presence_provider.dart';
import '../providers/community_members_provider.dart';
import '../providers/wall_posts_paginated_provider.dart';
import '../providers/home_vivo_providers.dart'; // NEW
import '../providers/local_identity_providers.dart'; // Local identity provider
import '../widgets/wall_post_card.dart';
import '../widgets/sala_card.dart'; // NEW
import '../widgets/post_list_tile.dart'; // NEW
import '../widgets/identity_card.dart'; // NEW
import 'community_studio_screen.dart';
import '../../../chat/presentation/screens/chat_room_screen.dart'; // NEW
import '../../../chat/domain/entities/community_chat_room_entity.dart'; // NEW
import '../../../../core/beta/beta.dart'; // Beta feedback button
import '../widgets/notification_bell_widget.dart'; // Notifications

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
  
  // Wall post composer
  final _wallPostController = TextEditingController();
  bool _isPostingWall = false;

  // Removed: Dummy online users for facepile, now using real data

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 5,
      vsync: this,
    ); // Changed from 4 to 5
    isMember = !widget.isGuest;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _wallPostController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check if keyboard is visible
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildBody(),
          // Beta Feedback FAB - positioned at bottom-right
          if (isMember && !keyboardVisible)
            Positioned(
              right: 16,
              bottom: 90, // Above bottom nav
              child: FloatingActionButton.small(
                heroTag: 'feedback_fab',
                backgroundColor: NeoColors.accent,
                onPressed: () => _showFeedbackModal(context),
                child: const Icon(Icons.feedback_outlined, color: Colors.white, size: 20),
              ),
            ),
        ],
      ),
      floatingActionButton: isMember && !keyboardVisible
          ? _buildCentralFAB()
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: isMember
          ? _buildInternalBottomNav()
          : _buildJoinBar(),
    );
  }
  
  void _showFeedbackModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FeedbackModalWrapper(
        currentRoute: GoRouter.of(context).routerDelegate.currentConfiguration.fullPath,
      ),
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
        return CommunityMembersScreen(
          communityId: widget.community.id,
          onSwitchToProfileTab: () => setState(() => _currentNavIndex = 4),
        ); // Community Members Tab
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
        return [_buildSliverAppBar(), _buildSliverTabBar()];
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
        // Notification bell
        NotificationBellWidget(
          communityId: widget.community.id,
          iconColor: Colors.white,
        ),
        // Neo Studio button for owners
        if (_isOwner())
          IconButton(
            icon: Icon(
              Icons.settings,
              color: _parseColor(widget.community.theme.primaryColor),
            ),
            tooltip: 'Neo Studio',
            onPressed: _navigateToStudio,
          ),
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
            // Menu Options
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (context) => Container(
                decoration: const BoxDecoration(
                  color: NeoColors.card,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.notifications_outlined,
                          color: Colors.white,
                        ),
                        title: const Text(
                          'Configuración',
                          style: TextStyle(color: Colors.white),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          context.pushNamed(
                            'community-settings',
                            pathParameters: {'id': widget.community.id},
                            extra: {
                              'name': widget.community.title,
                              'color': _parseColor(
                                widget.community.theme.primaryColor,
                              ),
                            },
                          );
                        },
                      ),
                      // More options can form here
                    ],
                  ),
                ),
              ),
            );
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
                      border: Border.all(color: Colors.white, width: 2.5),
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
                        Builder(
                          builder: (context) {
                            final presenceState = ref.watch(
                              communityPresenceProvider(widget.community.id),
                            );
                            final membersAsync = ref.watch(
                              communityMembersProvider(widget.community.id),
                            );
                            final onlineCount = presenceState.onlineCount;

                            // Get avatars of online users
                            final onlineAvatars = membersAsync.when(
                              data: (members) => members
                                  .where(
                                    (m) => presenceState.isUserOnline(m.id),
                                  )
                                  .take(3)
                                  .map((m) => m.avatarUrl ?? '')
                                  .toList(),
                              loading: () => <String>[],
                              error: (_, __) => <String>[],
                            );

                            return Row(
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
                                Text(
                                  '$onlineCount Online',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Facepile
                                FacepileWidget(
                                  avatarUrls: onlineAvatars,
                                  maxVisible: 3,
                                  size: 24,
                                ),
                              ],
                            );
                          },
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
      child: const Icon(Icons.groups_rounded, color: Colors.white, size: 32),
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
          dividerColor: Colors.transparent, // Remove white separator line
          tabs: const [
            Tab(
              text: 'Inicio',
            ), // Changed from 'Destacados' to 'Inicio' (Home VIVO)
            Tab(text: 'Muro'),
            Tab(text: 'Blogs'),
            Tab(text: 'Chats'),
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
        _buildHomeVivoTab(), // Changed from _buildDestacadosTab()
        _buildMuroTab(),
        _buildBlogsTab(),
        ChatCatalogGrid(communityId: widget.community.id),
        _buildWikisTab(),
      ],
    );
  }

  // Tab content - Home VIVO (new landing experience)
  Widget _buildHomeVivoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 80), // Space for FAB
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // 1. "Ahora mismo" - Active chat channels
          _buildAhoraMismoSection(),
          const SizedBox(height: 24),
          // 2. "Destacado" - Pinned post (if exists)
          _buildDestacadoSection(),
          // 3. "Actividad reciente" - Recent posts
          _buildActividadRecienteSection(),
          const SizedBox(height: 24),
          // 4. "Tu identidad aquí" - Local identity
          _buildIdentidadLocalSection(),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HOME VIVO SECTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Section: "Ahora mismo" - Active chat channels
  Widget _buildAhoraMismoSection() {
    final channelsAsync = ref.watch(chatChannelsProvider(widget.community.id));

    return channelsAsync.when(
      loading: () {
        print('🔄 [HOME VIVO] Loading chat channels...');
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
      error: (error, stack) {
        print('❌ [HOME VIVO] Error in chatChannelsProvider: $error');
        print('   Stack: $stack');
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.red.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '⚠️ Error cargando salas',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: TextStyle(
                    color: Colors.red.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      data: (channels) {
        print('✅ [HOME VIVO] Received ${channels.length} channels');
        if (channels.isEmpty) {
          // Empty state
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.white.withValues(alpha: 0.5),
                    size: 40,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'No hay salas activas',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Crea la primera sala para conectar con la comunidad',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 13,
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '🎯 Ahora mismo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate to Chats tab (index 3)
                      _tabController.animateTo(3);
                    },
                    child: const Text(
                      'Ver todas',
                      style: TextStyle(
                        color: NeoColors.accent,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Horizontal scroll of chat channels
            SizedBox(
              height: 140,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: channels.length,
                itemBuilder: (context, index) {
                  final channel = channels[index];
                  return SalaCard(
                    title: channel.title,
                    description: channel.description,
                    backgroundImageUrl: channel.backgroundImageUrl,
                    memberCount: channel.memberCount,
                    onTap: () {
                      // Navigate to chat room screen
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ChatRoomScreen(
                            room: CommunityChatRoomEntity(
                              id: channel.id,
                              communityId: widget.community.id,
                              type: RoomType.public,
                              title: channel.title,
                              description: channel.description,
                              backgroundImageUrl: channel.backgroundImageUrl,
                              memberCount: channel.memberCount,
                              lastMessageTime: DateTime.now(),
                              isPinned: channel.isPinned,
                              voiceEnabled: false, // V1: No voice
                              videoEnabled: false, // V1: No video
                              projectionEnabled: false, // V1: No projection
                              createdAt:
                                  DateTime.now(), // Not critical for display
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  /// Section: "Destacado" - Pinned post hero card
  Widget _buildDestacadoSection() {
    final pinnedPostAsync = ref.watch(pinnedPostProvider(widget.community.id));

    return pinnedPostAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
      data: (pinnedPost) {
        if (pinnedPost == null) {
          // No pinned post, hide section
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '📌 Destacado',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate to Blogs tab (or any feed)
                      _tabController.animateTo(2);
                    },
                    child: const Text(
                      'Ver más',
                      style: TextStyle(
                        color: NeoColors.accent,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Hero pinned post card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () => _navigateToDetail(pinnedPost),
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: NeoColors.accent.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Cover image if exists
                      if (pinnedPost.coverImageUrl != null)
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              pinnedPost.coverImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stack) =>
                                  Container(),
                            ),
                          ),
                        ),
                      // Gradient overlay
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.3),
                                Colors.black.withValues(alpha: 0.8),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Content
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: NeoColors.accent.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                '📌 DESTACADO',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              pinnedPost.title ?? 'Sin título',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              pinnedPost.content ?? '',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 14,
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
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  /// Section: "Actividad reciente" - Recent posts
  Widget _buildActividadRecienteSection() {
    final recentPostsAsync = ref.watch(
      recentActivityProvider(widget.community.id),
    );

    return recentPostsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (error, stack) => const SizedBox.shrink(),
      data: (posts) {
        if (posts.isEmpty) {
          // Empty state
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.article_outlined,
                    color: Colors.white.withValues(alpha: 0.5),
                    size: 40,
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Aún no hay actividad',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Sé el primero en compartir algo',
                          style: TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Text(
                '⚡ Actividad reciente',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // List of posts
            ...posts.map(
              (post) => PostListTile(
                post: post,
                onTap: () => _navigateToDetail(post),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Section: "Tu identidad aquí" - Local identity card
  Widget _buildIdentidadLocalSection() {
    final identityAsync = ref.watch(
      myLocalIdentityProvider(widget.community.id),
    );

    return identityAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
      data: (identity) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '👤 Tu identidad aquí',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Identity card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: IdentityCard(
                identity: identity,
                onTap: () {
                  // Navigate to local identity screen
                  context.goNamed(
                    'local-identity',
                    pathParameters: {'communityId': widget.community.id},
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LEGACY TAB METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  // Tab content - Legacy tabs
  Widget _buildBlogsTab() {
    return _buildRealFeedTab(PostType.blog);
  }

  Widget _buildWikisTab() {
    return _buildRealFeedTab(PostType.wiki);
  }

  /// Build Muro tab with paginated wall posts (infinite scroll)
  Widget _buildMuroTab() {
    return Column(
      children: [
        // Composer at top
        _buildWallPostComposer(),
        // Feed
        Expanded(child: _buildWallPostsFeed()),
      ],
    );
  }
  
  /// Build wall post composer widget
  Widget _buildWallPostComposer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: NeoColors.surface,
        border: Border(
          bottom: BorderSide(
            color: NeoColors.border.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _wallPostController,
              maxLines: 3,
              minLines: 1,
              enabled: !_isPostingWall,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: '¿Qué estás pensando?',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 14,
                ),
                filled: true,
                fillColor: NeoColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 44,
            child: ElevatedButton(
              onPressed: _isPostingWall ? null : _submitWallPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: NeoColors.accent,
                foregroundColor: Colors.white,
                disabledBackgroundColor: NeoColors.accent.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: _isPostingWall
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Publicar'),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Submit wall post
  Future<void> _submitWallPost() async {
    final content = _wallPostController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escribe algo para publicar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() => _isPostingWall = true);
    
    final success = await ref
        .read(wallPostsPaginatedProvider(widget.community.id).notifier)
        .createPost(content);
    
    if (!mounted) return;
    
    setState(() => _isPostingWall = false);
    
    if (success) {
      _wallPostController.clear();
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Publicado!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al publicar. Inténtalo de nuevo.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  /// Build wall posts feed
  Widget _buildWallPostsFeed() {
    final wallPostsAsync = ref.watch(
      wallPostsPaginatedProvider(widget.community.id),
    );

    return wallPostsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: NeoColors.accent),
      ),
      error: (error, stackTrace) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Error cargando posts: $error',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref
                    .read(
                      wallPostsPaginatedProvider(widget.community.id).notifier,
                    )
                    .refresh();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: NeoColors.accent,
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
      data: (paginated) {
        if (paginated.posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.forum_outlined,
                  size: 64,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                const SizedBox(height: 16),
                Text(
                  'No hay posts en el muro aún',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sé el primero en publicar',
                  style: TextStyle(
                    color: NeoColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            // Infinite scroll trigger using externalized threshold
            if (notification is ScrollEndNotification &&
                notification.metrics.pixels >=
                    notification.metrics.maxScrollExtent *
                        kInfiniteScrollThreshold) {
              if (!paginated.isLoadingMore && paginated.hasMore) {
                print('🔄 Triggering loadNextPage via scroll');
                ref
                    .read(
                      wallPostsPaginatedProvider(widget.community.id).notifier,
                    )
                    .loadNextPage();
              }
            }
            return false;
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount:
                paginated.posts.length + (paginated.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              // Loading indicator at bottom
              if (index == paginated.posts.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: NeoColors.accent,
                    ),
                  ),
                );
              }

              final post = paginated.posts[index];
              final currentUserId = ref.read(currentUserProvider)?.id;

              return WallPostCard(
                post: post,
                canDelete: post.authorId == currentUserId,
                onLike: () {
                  ref
                      .read(
                        wallPostsPaginatedProvider(
                          widget.community.id,
                        ).notifier,
                      )
                      .toggleLike(post.id);
                },
                onDelete: () async {
                  final deleted = await ref
                      .read(
                        wallPostsPaginatedProvider(
                          widget.community.id,
                        ).notifier,
                      )
                      .deletePost(post.id);
                  
                  if (deleted && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Post eliminado'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
              );
            },
          ),
        );
      },
    );
  }

  /// Build feed tab using real Supabase data
  Widget _buildRealFeedTab(PostType? typeFilter) {
    final feedState = ref.watch(
      feedProvider((communityId: widget.community.id, typeFilter: typeFilter)),
    );

    if (feedState.isLoading && feedState.posts.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF6366F1)),
      );
    }

    if (feedState.error != null && feedState.posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              feedState.error!,
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref
                  .read(
                    feedProvider((
                      communityId: widget.community.id,
                      typeFilter: typeFilter,
                    )).notifier,
                  )
                  .refresh(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (feedState.posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              typeFilter == null
                  ? Icons.grid_view_outlined
                  : typeFilter == PostType.blog
                  ? Icons.article_outlined
                  : Icons.menu_book_outlined,
              size: 64,
              color: Colors.white.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Text(
              typeFilter == null
                  ? 'No hay contenido aún'
                  : 'No hay ${typeFilter.displayName}s aún',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () =>
                  _navigateToCreateContent(typeFilter ?? PostType.blog),
              child: const Text('Crear el primero'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref
          .read(
            feedProvider((
              communityId: widget.community.id,
              typeFilter: typeFilter,
            )).notifier,
          )
          .refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: feedState.posts.length + (feedState.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= feedState.posts.length) {
            // Load more trigger
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref
                  .read(
                    feedProvider((
                      communityId: widget.community.id,
                      typeFilter: typeFilter,
                    )).notifier,
                  )
                  .loadMore();
            });
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }

          final post = feedState.posts[index];
          return _buildPostCard(post);
        },
      ),
    );
  }

  Widget _buildPostCard(PostEntity post) {
    // Check if this post is rejected and belongs to current user
    final currentUserId = ref.read(currentUserProvider)?.id;
    final isOwnRejectedPost =
        post.moderationStatus == ModerationStatus.rejected &&
        post.authorId == currentUserId;
    final isPending =
        post.moderationStatus == ModerationStatus.pending &&
        post.authorId == currentUserId;

    return GestureDetector(
      onTap: () => _navigateToDetail(post),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(16),
          border: isOwnRejectedPost
              ? Border.all(color: Colors.red.withOpacity(0.7), width: 2)
              : isPending
              ? Border.all(color: Colors.amber.withOpacity(0.5), width: 1)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rejected warning banner
            if (isOwnRejectedPost)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.15),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.visibility_off,
                      color: Colors.red.shade300,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Oculto por seguridad',
                        style: TextStyle(
                          color: Colors.red.shade300,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (post.aiFlaggedReason != null)
                      Tooltip(
                        message: post.aiFlaggedReason!,
                        child: Icon(
                          Icons.info_outline,
                          color: Colors.red.shade300,
                          size: 16,
                        ),
                      ),
                  ],
                ),
              ),
            // Pending banner
            if (isPending)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.vertical(
                    top: isOwnRejectedPost
                        ? Radius.zero
                        : const Radius.circular(14),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      color: Colors.amber.shade300,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Pendiente de revisión',
                      style: TextStyle(
                        color: Colors.amber.shade300,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            // Cover image if present
            if (post.coverImageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: (isOwnRejectedPost || isPending)
                      ? Radius.zero
                      : const Radius.circular(16),
                ),
                child: Image.network(
                  post.coverImageUrl!,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 140,
                    color: const Color(0xFF6366F1).withOpacity(0.3),
                    child: const Icon(
                      Icons.image,
                      color: Colors.white54,
                      size: 48,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getTypeBadgeColor(post.postType),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      post.postType.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Title
                  Text(
                    post.title ?? 'Sin título',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Preview
                  if (post.content != null)
                    Text(
                      post.content!,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 12),
                  // Footer
                  Row(
                    children: [
                      // Author
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: const Color(0xFF6366F1),
                        backgroundImage: post.authorAvatarUrl != null
                            ? NetworkImage(post.authorAvatarUrl!)
                            : null,
                        child: post.authorAvatarUrl == null
                            ? Text(
                                (post.authorUsername ?? 'U')[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        post.authorUsername ?? 'Usuario',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      // Reactions
                      GestureDetector(
                        onTap: () => _togglePostReaction(post),
                        child: Row(
                          children: [
                            Icon(
                              post.isLikedByCurrentUser
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: post.isLikedByCurrentUser
                                  ? Colors.red
                                  : Colors.white54,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${post.reactionsCount}',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Comments
                      Row(
                        children: [
                          const Icon(
                            Icons.chat_bubble_outline,
                            color: Colors.white54,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${post.commentsCount}',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
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

  void _togglePostReaction(PostEntity post) {
    ref
        .read(
          feedProvider((
            communityId: widget.community.id,
            typeFilter: null,
          )).notifier,
        )
        .toggleReaction(post.id);
  }

  void _navigateToDetail(PostEntity post) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ContentDetailScreen(postId: post.id, initialPost: post),
      ),
    );
  }

  void _navigateToCreateContent(PostType type) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateContentScreen(
          communityId: widget.community.id,
          postType: type,
          communityName: widget.community.title,
        ),
      ),
    );
  }

  Color _getTypeBadgeColor(PostType type) {
    switch (type) {
      case PostType.blog:
        return const Color(0xFF6366F1);
      case PostType.wiki:
        return const Color(0xFF10B981);
      case PostType.poll:
        return const Color(0xFFF59E0B);
      case PostType.quiz:
        return const Color(0xFFEF4444);
      case PostType.wallPost:
        return const Color(0xFF8B5CF6);
    }
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
              (context, index) =>
                  _buildMemberItem('Usuario ${index + 1}', isLeader: index < 2),
              childCount: 10,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMemberItem(String name, {required bool isLeader}) {
    // Generate a mock user ID based on name
    final userId = 'user_${name.replaceAll(' ', '_').toLowerCase()}';

    return InkWell(
      onTap: () {
        // Navigate to user profile
        Navigator.of(context).pushNamed(
          '/community-user-profile',
          arguments: {'userId': userId, 'communityId': widget.community.id},
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
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
                color: (isLeader ? Colors.amber : NeoColors.accent).withValues(
                  alpha: 0.2,
                ),
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
            const SizedBox(width: NeoSpacing.xs),
            Icon(Icons.chevron_right, color: NeoColors.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CHATS VIEW - INDEX 3 (BENTO GRID)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildChatsView() {
    return CommunityChatsScreen(communityId: widget.community.id);
  }

  Widget _buildPerfilView() {
    // Get current user ID
    final currentUser = ref.watch(currentUserProvider);
    final userId = currentUser?.id ?? 'current_user_id'; // Fallback for demo

    // Render the actual CommunityUserProfileScreen
    return CommunityUserProfileScreen(
      userId: userId,
      communityId: widget.community.id,
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
            _buildNavItem(Icons.people_alt, 'Miembros', 1),
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
          onTap: () {
            // Always show general create modal which now includes Chat
            _showGeneralCreateModal();
          },
          customBorder: const CircleBorder(),
          child: const Icon(Icons.add, color: Colors.white, size: 32),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GENERAL CREATE MODAL (BENTO GRID)
  // ═══════════════════════════════════════════════════════════════════════════

  void _showGeneralCreateModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
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
            Text(
              'Crear Contenido',
              style: NeoTextStyles.headlineMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Bento Grid - 2 columns
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _buildBentoCard(
                  icon: Icons.chat_bubble_outline,
                  label: 'Sala de Chat',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            CreateChatScreen(communityId: widget.community.id),
                      ),
                    );
                  },
                ),
                _buildBentoCard(
                  icon: Icons.article_outlined,
                  label: 'Blog',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToCreateContent(PostType.blog);
                  },
                ),
                _buildBentoCard(
                  icon: Icons.poll_outlined,
                  label: 'Encuesta',
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEC4899), Color(0xFFDB2777)],
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToCreateContent(PostType.poll);
                  },
                ),
                _buildBentoCard(
                  icon: Icons.quiz_outlined,
                  label: 'Quiz',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToCreateContent(PostType.quiz);
                  },
                ),
                _buildBentoCard(
                  icon: Icons.menu_book_outlined,
                  label: 'Wiki',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToCreateContent(PostType.wiki);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildBentoCard({
    required IconData icon,
    required String label,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.white),
            const SizedBox(height: 12),
            Text(
              label,
              style: NeoTextStyles.bodyLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CHAT CREATE MODAL
  // ═══════════════════════════════════════════════════════════════════════════

  void _showChatCreateModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
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
            Text(
              'Crear Chat',
              style: NeoTextStyles.headlineMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Private Room Card
            InkWell(
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to CreatePrivateRoomScreen
                Navigator.pushNamed(
                  context,
                  '/create-private-room',
                  arguments: widget.community.id,
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.lock_outline,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sala Privada',
                            style: NeoTextStyles.headlineSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Crea un grupo con tus amigos',
                            style: NeoTextStyles.bodyMedium.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
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
                backgroundColor: _parseColor(
                  widget.community.theme.accentColor,
                ),
                foregroundColor: Colors.white,
                elevation: 8,
                shadowColor: _parseColor(
                  widget.community.theme.accentColor,
                ).withValues(alpha: 0.5),
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

  /// Check if current user is the community owner
  bool _isOwner() {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    return currentUserId != null && currentUserId == widget.community.ownerId;
  }

  /// Navigate to Neo Studio (admin panel)
  void _navigateToStudio() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            CommunityStudioScreen(community: widget.community),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0.05, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
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
    return Container(color: Colors.black, child: tabBar);
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════════════════
// FEEDBACK MODAL WRAPPER (for Beta feedback)
// ═══════════════════════════════════════════════════════════════════════════

class _FeedbackModalWrapper extends ConsumerStatefulWidget {
  final String currentRoute;
  
  const _FeedbackModalWrapper({required this.currentRoute});

  @override
  ConsumerState<_FeedbackModalWrapper> createState() => _FeedbackModalWrapperState();
}

class _FeedbackModalWrapperState extends ConsumerState<_FeedbackModalWrapper> {
  FeedbackType _selectedType = FeedbackType.suggestion;
  final _messageController = TextEditingController();
  
  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final submitState = ref.watch(feedbackNotifierProvider);
    
    // Listen for success
    ref.listen<FeedbackSubmitState>(feedbackNotifierProvider, (prev, next) {
      if (next == FeedbackSubmitState.success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Gracias por tu feedback!'),
            backgroundColor: NeoColors.success,
          ),
        );
        ref.read(feedbackNotifierProvider.notifier).reset();
      }
    });
    
    return Container(
      margin: EdgeInsets.only(
        top: MediaQuery.of(context).size.height * 0.15,
      ),
      decoration: const BoxDecoration(
        color: NeoColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: NeoColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Enviar Feedback',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: NeoColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tu opinión nos ayuda a mejorar',
                style: TextStyle(color: NeoColors.textSecondary),
              ),
              const SizedBox(height: 24),
              const Text(
                'Tipo de feedback',
                style: TextStyle(
                  color: NeoColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildTypeChip('🐛 Bug', FeedbackType.bug),
                  const SizedBox(width: 8),
                  _buildTypeChip('💡 Sugerencia', FeedbackType.suggestion),
                  const SizedBox(width: 8),
                  _buildTypeChip('💬 Otro', FeedbackType.other),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _messageController,
                maxLines: 5,
                maxLength: 2000,
                decoration: InputDecoration(
                  hintText: 'Describe tu feedback aquí...',
                  filled: true,
                  fillColor: NeoColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: NeoColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: NeoColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: NeoColors.accent),
                  ),
                ),
              ),
              if (submitState == FeedbackSubmitState.error)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    ref.read(feedbackNotifierProvider.notifier).lastError ?? 'Error',
                    style: const TextStyle(color: NeoColors.error),
                  ),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: submitState == FeedbackSubmitState.submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NeoColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: submitState == FeedbackSubmitState.submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Enviar Feedback'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTypeChip(String label, FeedbackType type) {
    final selected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? NeoColors.accent : NeoColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? NeoColors.accent : NeoColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : NeoColors.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
  
  void _submit() {
    ref.read(feedbackNotifierProvider.notifier).submit(
      type: _selectedType,
      message: _messageController.text,
      currentRoute: widget.currentRoute,
    );
  }
}
