/// Project Neo - Community User Profile Screen
///
/// Rich user profile within a community with wall, activity, and custom tags
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/neo_theme.dart';
import '../../domain/entities/user_title_tag.dart';
import '../../domain/entities/wall_post.dart';
import '../../domain/entities/pinned_content.dart';
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
  
  // Mock data
  final String _username = 'Ana García';
  final int _level = 42;
  final int _followers = 1234;
  final int _following = 567;
  final int _posts = 89;
  final bool _isOwner = false; // Change to true to test owner features
  final bool _isFriend = true; // Change to false to test privacy
  
  // Friendship status for testing (change to test different states)
  FriendshipStatus _friendshipStatus = FriendshipStatus.friends; // Try: notFollowing, followingThem, friends

  late List<UserTitleTag> _titleTags;
  late List<WallPost> _wallPosts;
  late List<PinnedContent> _pinnedContent;
  late List<PinnedContent> _activityItems;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeMockData();
  }

  void _initializeMockData() {
    // Title Tags - Colorful and vibrant
    _titleTags = [
      const UserTitleTag(
        text: 'Líder',
        backgroundColor: Color(0xFF8B5CF6),
        textColor: Colors.white,
        displayOrder: 0,
      ),
      const UserTitleTag(
        text: 'Artista 🎨',
        backgroundColor: Color(0xFFEC4899),
        textColor: Colors.white,
        displayOrder: 1,
      ),
      const UserTitleTag(
        text: 'Veterano',
        backgroundColor: Color(0xFF10B981),
        textColor: Colors.white,
        displayOrder: 2,
      ),
    ];

    // Wall Posts
    final now = DateTime.now();
    _wallPosts = [
      WallPost(
        id: 'post_1',
        authorId: 'user_1',
        authorName: 'Carlos Ruiz',
        content: '¡Felicidades por tu nuevo logro! 🎉 Te lo mereces totalmente.',
        timestamp: now.subtract(const Duration(hours: 2)),
        likes: 15,
        isLikedByCurrentUser: true,
      ),
      WallPost(
        id: 'post_2',
        authorId: 'user_2',
        authorName: 'María López',
        content: 'Gracias por tu ayuda con el proyecto. Eres increíble! 💪',
        timestamp: now.subtract(const Duration(hours: 5)),
        likes: 8,
        isLikedByCurrentUser: false,
      ),
      WallPost(
        id: 'post_3',
        authorId: 'user_3',
        authorName: 'Pedro Sánchez',
        content: 'Excelente tutorial sobre Flutter! Me ayudó mucho.',
        timestamp: now.subtract(const Duration(days: 1)),
        likes: 23,
        isLikedByCurrentUser: true,
      ),
      WallPost(
        id: 'post_4',
        authorId: 'user_4',
        authorName: 'Laura Martínez',
        content: 'Nos vemos en el evento de mañana! 🚀',
        timestamp: now.subtract(const Duration(days: 2)),
        likes: 12,
        isLikedByCurrentUser: false,
      ),
      WallPost(
        id: 'post_5',
        authorId: 'user_5',
        authorName: 'Diego Torres',
        content: 'Increíble trabajo en la comunidad. Sigue así! 🌟',
        timestamp: now.subtract(const Duration(days: 3)),
        likes: 31,
        isLikedByCurrentUser: true,
      ),
    ];

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
    super.dispose();
  }

  bool get _canPostOnWall {
    if (_isOwner) return true;
    if (_wallPrivacy == WallPrivacyLevel.public) return true;
    if (_wallPrivacy == WallPrivacyLevel.friendsOnly && _isFriend) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          // Header with avatar, name, tags, stats
          _buildHeader(),
          
          // Tabs
          _buildTabBar(),
          
          // Tab content
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildWallTab(),
                _buildActivityTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(NeoSpacing.lg),
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
            // Back button
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Spacer(),
              ],
            ),
            
            const SizedBox(height: NeoSpacing.md),
            
            // Avatar
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: NeoColors.accent.withValues(alpha: 0.2),
                border: Border.all(
                  color: NeoColors.accent,
                  width: 3,
                ),
              ),
              child: const Icon(
                Icons.person,
                color: NeoColors.accent,
                size: 50,
              ),
            ),
            
            const SizedBox(height: NeoSpacing.md),
            
            // Username
            Text(
              _username,
              style: NeoTextStyles.headlineLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: NeoSpacing.xs),
            
            // Level badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Nivel $_level',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            const SizedBox(height: NeoSpacing.md),
            
            // Title Tags - Wrap for multiple tags
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: _titleTags
                  .map((tag) => UserTitleTagWidget(tag: tag))
                  .toList(),
            ),
            
            const SizedBox(height: NeoSpacing.lg),
            
            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem('Seguidores', _followers),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white24,
                ),
                _buildStatItem('Siguiendo', _following),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white24,
                ),
                _buildStatItem('Posts', _posts),
              ],
            ),
            
            // Follow button (hidden if viewing own profile)
            if (!_isOwner) ...[
              const SizedBox(height: NeoSpacing.lg),
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
          style: NeoTextStyles.headlineSmall.copyWith(
            fontWeight: FontWeight.bold,
            color: NeoColors.accent,
          ),
        ),
        Text(
          label,
          style: NeoTextStyles.bodySmall.copyWith(
            color: NeoColors.textSecondary,
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
          indicatorColor: NeoColors.accent,
          indicatorWeight: 3,
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

  Widget _buildWallTab() {
    return Container(
      color: Colors.black,
      child: ListView(
        padding: const EdgeInsets.all(NeoSpacing.md),
        children: [
          // Privacy settings (owner only)
          if (_isOwner) ...[
            _buildPrivacySettings(),
            const SizedBox(height: NeoSpacing.md),
          ],
          
          // Input box (conditional)
          if (_canPostOnWall) ...[
            _buildWallInput(),
            const SizedBox(height: NeoSpacing.lg),
          ],
          
          // Wall posts
          ..._wallPosts.map((post) => WallPostCard(
                post: post,
                onLike: () {
                  // TODO: Implement like
                },
                canDelete: _isOwner || post.authorId == 'current_user_id',
                onDelete: () {
                  // TODO: Implement delete
                },
              )),
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

  Widget _buildWallInput() {
    return Container(
      padding: const EdgeInsets.all(NeoSpacing.md),
      decoration: BoxDecoration(
        color: NeoColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: NeoColors.accent.withValues(alpha: 0.2),
              border: Border.all(
                color: NeoColors.accent,
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.person,
              color: NeoColors.accent,
              size: 20,
            ),
          ),
          const SizedBox(width: NeoSpacing.sm),
          
          // Input field
          Expanded(
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Escribe algo en el muro de $_username...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          
          // Send button
          IconButton(
            icon: const Icon(
              Icons.send,
              color: NeoColors.accent,
            ),
            onPressed: () {
              // TODO: Implement post
            },
          ),
        ],
      ),
    );
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
            height: 120,
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
