/// Project Neo - Community User Profile Screen
///
/// Rich user profile within a community with wall, activity, and custom tags
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/neo_theme.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/user_title_tag.dart';
import '../../domain/entities/wall_post.dart';
import '../../domain/entities/pinned_content.dart';
import '../providers/user_profile_provider.dart';
import '../widgets/user_title_tag_widget.dart';
import '../widgets/wall_post_card.dart';
import '../widgets/pinned_content_card.dart';
import '../widgets/activity_grid_item.dart';
import '../widgets/follow_button.dart';
import '../../domain/entities/friendship_status.dart';

class CommunityUserProfileScreen extends ConsumerStatefulWidget {
  final String userId;
  final String communityId;

  const CommunityUserProfileScreen({
    super.key,
    required this.userId,
    required this.communityId,
  });

  @override
  ConsumerState<CommunityUserProfileScreen> createState() =>
      _CommunityUserProfileScreenState();
}

class _CommunityUserProfileScreenState
    extends ConsumerState<CommunityUserProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  WallPrivacyLevel _wallPrivacy = WallPrivacyLevel.public;
  final TextEditingController _wallInputController = TextEditingController();
  bool _isPostingToWall = false;
  
  // TODO: Implement real privacy and friendship checks
  final bool _isFriend = true; // Change to false to test privacy
  
  // Friendship status for testing (change to test different states)
  FriendshipStatus _friendshipStatus = FriendshipStatus.friends; // Try: notFollowing, followingThem, friends

  // Pinned content - TODO: Connect to real data when content feature is ready
  late List<PinnedContent> _pinnedContent;
  late List<PinnedContent> _activityItems;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializePlaceholderContent();
  }

  void _initializePlaceholderContent() {
    // Placeholder for pinned content and activity
    // TODO: Connect to real content when feature is ready
    final now = DateTime.now();

    // Pinned Content
    _pinnedContent = [
      PinnedContent(
        id: 'pin_1',
        type: ContentType.blog,
        title: 'Guía Completa de Flutter',
        pinnedOrder: 0,
        createdAt: now.subtract(const Duration(days: 10)),
        views: 1234,
        likes: 89,
      ),
      PinnedContent(
        id: 'pin_2',
        type: ContentType.wiki,
        title: 'Mejores Prácticas en Dart',
        pinnedOrder: 1,
        createdAt: now.subtract(const Duration(days: 15)),
        views: 987,
        likes: 67,
      ),
      PinnedContent(
        id: 'pin_3',
        type: ContentType.blog,
        title: 'Top 10 Tips para Developers',
        pinnedOrder: 2,
        createdAt: now.subtract(const Duration(days: 20)),
        views: 2345,
        likes: 156,
      ),
    ];

    // Activity Items (mixed content)
    _activityItems = [
      PinnedContent(
        id: 'act_1',
        type: ContentType.blog,
        title: 'Introducción a Riverpod',
        createdAt: now.subtract(const Duration(days: 1)),
        views: 456,
        likes: 34,
      ),
      PinnedContent(
        id: 'act_2',
        type: ContentType.quiz,
        title: 'Quiz: Conoces Flutter?',
        createdAt: now.subtract(const Duration(days: 3)),
        views: 789,
        likes: 56,
      ),
      PinnedContent(
        id: 'act_3',
        type: ContentType.wiki,
        title: 'Arquitectura Clean en Flutter',
        createdAt: now.subtract(const Duration(days: 5)),
        views: 1234,
        likes: 98,
      ),
      PinnedContent(
        id: 'act_4',
        type: ContentType.blog,
        title: 'Animaciones Avanzadas',
        createdAt: now.subtract(const Duration(days: 7)),
        views: 567,
        likes: 45,
      ),
      PinnedContent(
        id: 'act_5',
        type: ContentType.quiz,
        title: 'Test de Widgets',
        createdAt: now.subtract(const Duration(days: 9)),
        views: 345,
        likes: 23,
      ),
      PinnedContent(
        id: 'act_6',
        type: ContentType.blog,
        title: 'State Management Patterns',
        createdAt: now.subtract(const Duration(days: 12)),
        views: 890,
        likes: 67,
      ),
      PinnedContent(
        id: 'act_7',
        type: ContentType.wiki,
        title: 'Guía de Testing',
        createdAt: now.subtract(const Duration(days: 14)),
        views: 678,
        likes: 54,
      ),
      PinnedContent(
        id: 'act_8',
        type: ContentType.blog,
        title: 'Performance Optimization',
        createdAt: now.subtract(const Duration(days: 16)),
        views: 1123,
        likes: 89,
      ),
      PinnedContent(
        id: 'act_9',
        type: ContentType.quiz,
        title: 'Dart Fundamentals Quiz',
        createdAt: now.subtract(const Duration(days: 18)),
        views: 456,
        likes: 34,
      ),
      PinnedContent(
        id: 'act_10',
        type: ContentType.blog,
        title: 'Custom Widgets Tutorial',
        createdAt: now.subtract(const Duration(days: 21)),
        views: 789,
        likes: 61,
      ),
      PinnedContent(
        id: 'act_11',
        type: ContentType.wiki,
        title: 'Navigation Best Practices',
        createdAt: now.subtract(const Duration(days: 25)),
        views: 567,
        likes: 43,
      ),
      PinnedContent(
        id: 'act_12',
        type: ContentType.blog,
        title: 'Responsive Design Tips',
        createdAt: now.subtract(const Duration(days: 30)),
        views: 1234,
        likes: 92,
      ),
    ];
  }

  @override
  void dispose() {
    _tabController.dispose();
    _wallInputController.dispose();
    super.dispose();
  }

  bool canPostOnWall(bool isOwner) {
    if (isOwner) return true;
    if (_wallPrivacy == WallPrivacyLevel.public) return true;
    if (_wallPrivacy == WallPrivacyLevel.friendsOnly && _isFriend) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // 1. Get current user
    final currentUser = ref.watch(currentUserProvider);
    
    // 2. Fetch target user if not current
    final isCurrentUser = widget.userId == currentUser?.id;
    final AsyncValue<UserEntity?> targetUserAsync = isCurrentUser 
        ? AsyncValue.data(currentUser) 
        : ref.watch(userProfileProvider(widget.userId));
        
    final displayUser = isCurrentUser ? currentUser : targetUserAsync.value;
    
    // 3. Handle loading
    if (targetUserAsync.isLoading && displayUser == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: NeoColors.accent),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          // Header with avatar, name, tags, stats
          _buildHeader(displayUser, isCurrentUser),
          
          // Tabs
          _buildTabBar(),
          
          // Tab content
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildWallTab(displayUser, isCurrentUser),
                _buildActivityTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(UserEntity? user, bool isOwner) {
    if (user == null) return const SliverToBoxAdapter(child: SizedBox());
    
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8, // SafeArea padding
          left: NeoSpacing.md,
          right: NeoSpacing.md,
          bottom: NeoSpacing.md,
        ),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          border: Border(
            bottom: BorderSide(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
        ),
        child: Column(
          children: [
            // Top bar: 3-dot menu + NeoCoins
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 3-dot menu button
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  color: NeoColors.card,
                  onSelected: (value) {
                    if (value == 'privacy') {
                      // TODO: Show privacy settings dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Configuración de privacidad (próximamente)'),
                          backgroundColor: NeoColors.accent,
                        ),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      value: 'privacy',
                      child: Row(
                        children: [
                          Icon(Icons.privacy_tip_outlined, color: NeoColors.accent, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            'Privacidad del Muro',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // NeoCoins widget
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '🪙',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${user.neocoinsBalance.toInt()}', 
                        style: TextStyle(
                          color: const Color(0xFFFFD700),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Avatar (compacted)
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: NeoColors.accent.withValues(alpha: 0.2),
                border: Border.all(
                  color: NeoColors.accent,
                  width: 3,
                ),
              ),
              child: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        user.avatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.person,
                          color: NeoColors.accent,
                          size: 40,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.person,
                      color: NeoColors.accent,
                      size: 40,
                    ),
            ),
            
            const SizedBox(height: 8),
            
            // Username + Level badge (same row)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  user.username,
                  style: NeoTextStyles.headlineMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Nv ${user.clearanceLevel}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Title Tags - From Supabase
            _buildTitleTags(),
            
            const SizedBox(height: 12),

            // Bio (ADDED)
            if (user.bio != null && user.bio!.isNotEmpty) ...[
                Text(
                    user.bio!,
                    textAlign: TextAlign.center,
                    style: NeoTextStyles.bodyMedium.copyWith(
                        color: NeoColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
            ],
            
            // Stats - From Supabase
            _buildStats(),
            
    
            // Follow button (hidden if viewing own profile)
            if (!isOwner) ...[
              const SizedBox(height: 12),
              FollowButton(
                status: _friendshipStatus,
                onPressed: () {
                  setState(() {
                    // Cycle through states for demo
                    switch (_friendshipStatus) {
                      case FriendshipStatus.notFollowing:
                        _friendshipStatus = FriendshipStatus.followingThem;
                        break;
                      case FriendshipStatus.followingThem:
                        _friendshipStatus = FriendshipStatus.friends;
                        break;
                      case FriendshipStatus.friends:
                        _friendshipStatus = FriendshipStatus.notFollowing;
                        break;
                    }
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int value) {
    return Column(
      children: [
        Text(
          '$value',
          style: NeoTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: NeoColors.accent,
          ),
        ),
        Text(
          label,
          style: NeoTextStyles.bodySmall.copyWith(
            color: NeoColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverTabBarDelegate(
        TabBar(
          controller: _tabController,
          indicator: const BoxDecoration(), // Remove line indicator
          dividerColor: Colors.transparent, // Remove divider
          labelColor: NeoColors.accent,
          unselectedLabelColor: NeoColors.textSecondary,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
          tabs: const [
            Tab(text: 'Muro'),
            Tab(text: 'Actividad'),
          ],
        ),
      ),
    );
  }

  Widget _buildWallTab(UserEntity? user, bool isOwner) {
    return Container(
      color: Colors.black,
      child: ListView(
        padding: const EdgeInsets.all(NeoSpacing.md),
        children: [
          // Input box (conditional)
          if (canPostOnWall(isOwner)) ...[
            _buildWallInput(user, isOwner),
            const SizedBox(height: NeoSpacing.lg),
          ],
          
          // Wall posts - From Supabase
          _buildWallPosts(isOwner),
        ],
      ),
    );
  }

  Widget _buildPrivacySettings() {
    return Container(
      padding: const EdgeInsets.all(NeoSpacing.md),
      decoration: BoxDecoration(
        color: NeoColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: NeoColors.accent.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.settings_outlined,
            color: NeoColors.accent,
            size: 20,
          ),
          const SizedBox(width: NeoSpacing.sm),
          Text(
            'Privacidad del Muro:',
            style: NeoTextStyles.bodyMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          DropdownButton<WallPrivacyLevel>(
            value: _wallPrivacy,
            dropdownColor: NeoColors.card,
            style: const TextStyle(color: NeoColors.accent),
            underline: Container(),
            items: const [
              DropdownMenuItem(
                value: WallPrivacyLevel.public,
                child: Text('Público'),
              ),
              DropdownMenuItem(
                value: WallPrivacyLevel.friendsOnly,
                child: Text('Solo Amigos'),
              ),
              DropdownMenuItem(
                value: WallPrivacyLevel.closed,
                child: Text('Cerrado'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _wallPrivacy = value;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWallInput(UserEntity? user, bool isOwner) {
    final placeholder = isOwner 
        ? 'Publica en tu muro'
        : 'Escribe en el muro de ${user?.username ?? '...'}';
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(30), // Pill shape
      ),
      child: Row(
        children: [
          // Input field
          Expanded(
            child: TextField(
              controller: _wallInputController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: placeholder,
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _handleSendPost(),
            ),
          ),
          
          // Send button (integrated)
          if (_isPostingToWall)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: NeoColors.accent,
              ),
            )
          else
            IconButton(
              icon: const Icon(
                Icons.send,
                color: NeoColors.accent,
                size: 20,
              ),
              onPressed: _handleSendPost,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
  
  Future<void> _handleSendPost() async {
    final content = _wallInputController.text.trim();
    if (content.isEmpty || _isPostingToWall) return;
    
    setState(() {
      _isPostingToWall = true;
    });
    
    final success = await ref
        .read(userWallPostsProvider(widget.userId).notifier)
        .createWallPost(content);
    
    setState(() {
      _isPostingToWall = false;
    });
    
    if (success) {
      _wallInputController.clear();
      // Optionally show success feedback
    } else {
      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al publicar. Intenta de nuevo.'),
            backgroundColor: NeoColors.error,
          ),
        );
      }
    }
  }

  Widget _buildActivityTab() {
    return Container(
      color: Colors.black,
      child: ListView(
        padding: const EdgeInsets.all(NeoSpacing.md),
        children: [
          // Pinned section header
          Row(
            children: [
              const Icon(
                Icons.push_pin,
                color: NeoColors.accent,
                size: 20,
              ),
              const SizedBox(width: NeoSpacing.xs),
              Text(
                'Destacados',
                style: NeoTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: NeoSpacing.md),
          
          // Pinned content (horizontal scroll with reorder)
          SizedBox(
            height: 145, // Increased from 120 to fix overflow
            child: ReorderableListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _pinnedContent.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (oldIndex < newIndex) {
                    newIndex -= 1;
                  }
                  final item = _pinnedContent.removeAt(oldIndex);
                  _pinnedContent.insert(newIndex, item);
                });
              },
              itemBuilder: (context, index) {
                final content = _pinnedContent[index];
                return Padding(
                  key: ValueKey(content.id),
                  padding: const EdgeInsets.only(right: NeoSpacing.sm),
                  child: PinnedContentCard(
                    content: content,
                    onTap: () {
                      // TODO: Navigate to content
                    },
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: NeoSpacing.xl),
          
          // Activity grid header
          Row(
            children: [
              const Icon(
                Icons.grid_view,
                color: NeoColors.accent,
                size: 20,
              ),
              const SizedBox(width: NeoSpacing.xs),
              Text(
                'Toda la Actividad',
                style: NeoTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: NeoSpacing.md),
          
          // Activity grid (2 columns)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: NeoSpacing.md,
              mainAxisSpacing: NeoSpacing.md,
              childAspectRatio: 0.85,
            ),
            itemCount: _activityItems.length,
            itemBuilder: (context, index) {
              final item = _activityItems[index];
              return ActivityGridItem(
                content: item,
                onTap: () {
                  // TODO: Navigate to content
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NEW PROVIDER-BASED BUILDERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Build title tags from Supabase
  Widget _buildTitleTags() {
    final tagsAsync = ref.watch(userTagsProvider(widget.userId));

    return tagsAsync.when(
      loading: () => const SizedBox(height: 24),
      error: (_, __) => const SizedBox.shrink(),
      data: (tags) {
        if (tags.isEmpty) return const SizedBox.shrink();
        
        return Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          runSpacing: 6,
          children: tags.map((tag) => UserTitleTagWidget(tag: tag)).toList(),
        );
      },
    );
  }

  /// Build stats from Supabase
  Widget _buildStats() {
    final statsAsync = ref.watch(userStatsProvider(widget.userId));

    return statsAsync.when(
      loading: () => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('Seguidores', 0),
          Container(width: 1, height: 30, color: Colors.white24),
          _buildStatItem('Siguiendo', 0),
        ],
      ),
      error: (_, __) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('Seguidores', 0),
          Container(width: 1, height: 30, color: Colors.white24),
          _buildStatItem('Siguiendo', 0),
        ],
      ),
      data: (stats) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('Seguidores', stats.followersCount),
          Container(width: 1, height: 30, color: Colors.white24),
          _buildStatItem('Siguiendo', stats.followingCount),
        ],
      ),
    );
  }

  /// Build wall posts from Supabase
  Widget _buildWallPosts(bool isOwner) {
    final wallPostsAsync = ref.watch(userWallPostsProvider(widget.userId));

    return wallPostsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(NeoSpacing.xl),
        child: Center(
          child: CircularProgressIndicator(color: NeoColors.accent),
        ),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(NeoSpacing.xl),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.error_outline, color: NeoColors.error, size: 48),
              const SizedBox(height: NeoSpacing.md),
              Text(
                'Error cargando posts',
                style: NeoTextStyles.bodyMedium.copyWith(color: NeoColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
      data: (posts) {
        if (posts.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(NeoSpacing.xl),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    color: NeoColors.textTertiary,
                    size: 48,
                  ),
                  const SizedBox(height: NeoSpacing.md),
                  Text(
                    'Aún no hay posts en el muro',
                    style: NeoTextStyles.bodyMedium.copyWith(
                      color: NeoColors.textSecondary,
                    ),
                  ),
                  if (canPostOnWall(isOwner)) ...[ 
                    const SizedBox(height: NeoSpacing.sm),
                    Text(
                      '¡Sé el primero en escribir!',
                      style: NeoTextStyles.bodySmall.copyWith(
                        color: NeoColors.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        return Column(
          children: posts.map((post) => WallPostCard(
            post: post,
            onLike: () {
              // TODO: Implement like
            },
            canDelete: isOwner || post.authorId == ref.read(currentUserProvider)?.id,
            onDelete: () {
              // TODO: Implement delete
            },
          )).toList(),
        );
      },
    );
  }
}

// Tab bar delegate for sticky tabs
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Colors.grey[900],
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
