/// Project Neo - Public User Profile Screen (Pasaporte)
///
/// View-only profile for viewing other users
/// Displays avatar, cover, name, badges with Follow/Message actions
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/neo_theme.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/wall_post.dart';
import '../../domain/entities/friendship_status.dart';
import '../../data/models/wall_post_model.dart';
import '../widgets/wall_post_card.dart';

class PublicUserProfileScreen extends ConsumerStatefulWidget {
  final String userId;
  final String communityId;

  const PublicUserProfileScreen({
    super.key,
    required this.userId,
    required this.communityId,
  });

  @override
  ConsumerState<PublicUserProfileScreen> createState() =>
      _PublicUserProfileScreenState();
}

class _PublicUserProfileScreenState
    extends ConsumerState<PublicUserProfileScreen> 
    with SingleTickerProviderStateMixin {
  
  UserEntity? _user;
  String _communityRole = 'member';
  bool _isLoading = true;
  bool _isFollowing = false;
  late TabController _tabController;

  // Friendship status implementation (Mocked for UI)
  FriendshipStatus _friendshipStatus = FriendshipStatus.notFollowing;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchUser();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<WallPost> _wallPosts = [];
  int _postsCount = 0;

  Future<void> _fetchUser() async {
    final supabase = Supabase.instance.client;

    try {
      // PHASE 1: IDENTIFICATION (Prioritize Local)
      Map<String, dynamic>? membershipResponse;
      Map<String, dynamic>? userResponse;

      // Try Local Membership first
      try {
        membershipResponse = await supabase
            .from('community_members')
            .select()
            .eq('user_id', widget.userId)
            .eq('community_id', widget.communityId)
            .maybeSingle();
      } catch (e) {
        debugPrint('Error fetching membership: $e');
      }

      // Try Global User second
      try {
        userResponse = await supabase
            .from('users_global')
            .select()
            .eq('id', widget.userId)
            .maybeSingle();
      } catch (e) {
        debugPrint('Error fetching global user: $e');
      }

      // If BOTH failed/missing, then truly not found
      if (membershipResponse == null && userResponse == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // Construct Display Data
      String displayUsername = 'Usuario';
      String? displayAvatar;
      String displayBio = '';
      String role = 'member';

      // 1. Defaults from Global
      if (userResponse != null) {
        displayUsername = userResponse['username'] ?? 'Usuario';
        displayAvatar = userResponse['avatar_global_url'];
        displayBio = userResponse['bio'] ?? '';
      }

      // 2. Override with Local
      if (membershipResponse != null) {
        role = membershipResponse['role'] ?? 'member';
        if (membershipResponse['nickname'] != null && membershipResponse['nickname'].toString().isNotEmpty) {
          displayUsername = membershipResponse['nickname'];
        }
        if (membershipResponse['avatar_url'] != null && membershipResponse['avatar_url'].toString().isNotEmpty) {
          displayAvatar = membershipResponse['avatar_url'];
        }
        if (membershipResponse['bio'] != null) {
          displayBio = membershipResponse['bio'];
        }
      }

      final userEntity = UserEntity(
        id: widget.userId,
        email: userResponse?['email'] ?? '',
        username: displayUsername,
        createdAt: userResponse != null
            ? (DateTime.tryParse(userResponse['created_at'] ?? '') ?? DateTime.now())
            : DateTime.now(),
        avatarUrl: displayAvatar,
        neocoinsBalance: userResponse != null
            ? (userResponse['neocoins_balance'] ?? 0).toDouble()
            : 0.0,
        isVip: userResponse?['is_vip'] ?? false,
        bio: displayBio,
      );

      if (mounted) {
        setState(() {
          _user = userEntity;
          _communityRole = role;
        });
      }

      // PHASE 2: CONTENT (Profile Wall Posts - from profile_wall_posts table)
      try {
        final responses = await Future.wait<dynamic>([
           supabase.from('profile_wall_posts').count().eq('profile_user_id', widget.userId).eq('community_id', widget.communityId),
           supabase.from('profile_wall_posts').select('*, author:users_global!profile_wall_posts_author_id_fkey(*)').eq('profile_user_id', widget.userId).eq('community_id', widget.communityId).order('created_at', ascending: false).limit(20),
        ]);
        
        final countResponse = responses[0] as int;
        final postsResponse = responses[1] as List;
        
        final currentUser = ref.read(authProvider).user;
        final postsBuilder = WallPostModel.listFromSupabase(
          postsResponse,
          currentUser?.id,
        );

        if (mounted) {
          setState(() {
            _postsCount = countResponse;
            _wallPosts = postsBuilder;
            _isLoading = false;
          });
        }
      } catch (e) {
        debugPrint('Error fetching profile posts: $e');
        if (mounted) setState(() => _isLoading = false);
      }

    } catch (e) {
      debugPrint('Critical Error fetching user data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleFollow() async {
    // TODO: Implement real follow/unfollow logic with Supabase
    setState(() {
      if (_friendshipStatus == FriendshipStatus.notFollowing) {
        _friendshipStatus = FriendshipStatus.followingThem;
      } else {
        _friendshipStatus = FriendshipStatus.notFollowing;
      }
    });
  }

  void _handleMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mensajes directos (próximamente)'),
        backgroundColor: NeoColors.accent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Handle Loading
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: NeoColors.accent),
        ),
      );
    }

    // 2. Handle Error
    if (_user == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: _buildErrorState(),
      );
    }
    
    final isOwnProfile = ref.watch(authProvider).user?.id == widget.userId;

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          // Header with avatar, name, tags, stats
          _buildHeader(_user!, isOwnProfile),
          
          // Tabs (Sticky)
          _buildTabBar(),
          
          // Tab content
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildWallTab(),
                _buildActivityTab(), // Placeholder for now
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Usuario no encontrado',
            style: NeoTextStyles.headlineSmall.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: NeoColors.accent,
            ),
            child: const Text('Volver'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(UserEntity user, bool isOwnProfile) {
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
            // Top bar: Back Button + NeoCoins
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left Side: Back Button
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),

                // Right Side: NeoCoins widget
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
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
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
              child: ClipOval(
                child: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                    ? Image.network(
                        user.avatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.person,
                          color: NeoColors.accent,
                          size: 40,
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        color: NeoColors.accent,
                        size: 40,
                      ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Username + Level badge
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  user.username,
                  style: NeoTextStyles.headlineMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
            
            // Title Tags (Placeholder or Real if implemented)
            // For now just Role Badge reused as Tag style if needed, or keeping simple
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: _getRoleColor(_communityRole).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _getRoleColor(_communityRole),
                  width: 1,
                ),
              ),
              child: Text(
                _getRoleDisplayName(_communityRole).toUpperCase(),
                style: TextStyle(
                  color: _getRoleColor(_communityRole),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            
            const SizedBox(height: 12),

            // Bio
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
            
            // Stats
            _buildStats(),
            
            // Action Buttons (Follow/Message)
            if (!isOwnProfile) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Follow Button
                  ElevatedButton(
                    onPressed: _handleFollow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _friendshipStatus == FriendshipStatus.notFollowing 
                        ? NeoColors.accent 
                        : Colors.grey[800],
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _friendshipStatus == FriendshipStatus.notFollowing
                              ? Icons.person_add
                              : Icons.check,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _friendshipStatus == FriendshipStatus.notFollowing
                              ? 'Seguir'
                              : 'Siguiendo',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Message Button
                  OutlinedButton(
                    onPressed: _handleMessage,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                         Icon(Icons.chat_bubble_outline, size: 18),
                         SizedBox(width: 8),
                         Text('Mensaje'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStatItem('Seguidores', 0),
        const SizedBox(width: 24),
        Container(width: 1, height: 24, color: Colors.white24),
        const SizedBox(width: 24),
        _buildStatItem('Siguiendo', 0),
        const SizedBox(width: 24),
        Container(width: 1, height: 24, color: Colors.white24),
        const SizedBox(width: 24),
        _buildStatItem('Posts', _postsCount),
      ],
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

  Widget _buildWallTab() {
    return Container(
      color: Colors.black,
      child: _wallPosts.isEmpty 
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.article_outlined, size: 48, color: Colors.grey[800]),
                const SizedBox(height: 12),
                Text('Aún no hay publicaciones', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(NeoSpacing.md),
            itemCount: _wallPosts.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: NeoSpacing.md),
                child: WallPostCard(
                  post: _wallPosts[index],
                  isProfilePost: true,  // Profile wall uses profile_wall_post_* tables
                ),
              );
            },
          ),
    );
  }

  Widget _buildActivityTab() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Text(
          'Próximamente',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'owner':
        return const Color(0xFFFFD700); // Gold
      case 'leader':
        return const Color(0xFF8B5CF6); // Purple
      case 'agent':
        return const Color(0xFFEC4899); // Pink
      default:
        return Colors.grey;
    }
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'owner':
        return 'Dueño';
      case 'leader':
        return 'Líder';
      case 'agent':
        return 'Agente';
      default:
        return 'Miembro';
    }
  }
}

// Helper for sticky header
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height + 16;
  @override
  double get maxExtent => _tabBar.preferredSize.height + 16;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.black, // Background color for sticky header
      padding: const EdgeInsets.only(bottom: 16),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
