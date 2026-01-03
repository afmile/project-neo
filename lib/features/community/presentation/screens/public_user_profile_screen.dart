/// Project Neo - Public User Profile Screen (Pasaporte)
///
/// View-only profile for viewing other users
/// Displays avatar, cover, name, badges with Follow/Message actions
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/neo_theme.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../screens/community_users_list_screen.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/wall_post.dart';
import '../../domain/entities/friendship_status.dart';
import '../../data/models/wall_post_model.dart';
import '../widgets/thread_post_item.dart';
import '../widgets/wall_threads_composer_launcher.dart';
import '../widgets/wall_threads_composer_sheet.dart';
import '../widgets/profile_header_widget.dart';
import '../../domain/models/community_title_model.dart';
import '../providers/community_follow_provider.dart';
import '../providers/friendship_provider.dart';
import '../widgets/profile_action_buttons.dart';
import 'wall_post_thread_screen.dart';

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

  // Header data
  String? _staffRole;
  List<CommunityTitle> _titles = [];
  int _followersCount = 0;
  int _followingCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchUser();
    _loadFollowStatus();
  }

  Future<void> _loadFollowStatus() async {
    final supabase = Supabase.instance.client;
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) return;

    try {
      final result = await supabase
          .from('community_follows')
          .select('id')
          .eq('community_id', widget.communityId)
          .eq('follower_id', currentUser.id)
          .eq('followed_id', widget.userId)
          .eq('is_active', true)
          .maybeSingle();

      if (mounted && result != null) {
        setState(() {
          _isFollowing = true;
          _friendshipStatus = FriendshipStatus.followingThem;
        });
      }
    } catch (e) {
      debugPrint('Error loading follow status: $e');
    }
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
           supabase.from('profile_wall_posts').select('*, author:users_global!profile_wall_posts_author_id_fkey(*), user_likes:profile_wall_post_likes(user_id)').eq('profile_user_id', widget.userId).eq('community_id', widget.communityId).order('created_at', ascending: false).limit(20),
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

      // Load header data (roles, titles, stats)
      await _loadHeaderData();

    } catch (e) {
      debugPrint('Critical Error fetching user data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Loads profile header data: staff role, titles, follower/following counts
  Future<void> _loadHeaderData() async {
    debugPrint('🔍 DEBUG: Iniciando carga de header data');
    debugPrint('   User ID: ${widget.userId}');
    debugPrint('   Community ID: ${widget.communityId}');

    try {
      final response = await Supabase.instance.client.rpc(
        'get_profile_header_data',
        params: {
          'p_user_id': widget.userId,
          'p_community_id': widget.communityId,
        },
      );

      debugPrint('✅ DEBUG: Response recibida: $response');

      if (response != null && mounted) {
        setState(() {
          _staffRole = response['staff_role'] as String?;

          // Parse titles
          final titlesJson = response['titles'] as List?;
          if (titlesJson != null) {
            _titles = titlesJson
                .map((t) => CommunityTitle.fromJson(t as Map<String, dynamic>))
                .toList();
          }

          _followersCount = response['followers_count'] as int? ?? 0;
          _followingCount = response['following_count'] as int? ?? 0;

          debugPrint('📊 DEBUG: Staff role = $_staffRole');
          debugPrint('📊 DEBUG: Titles = ${_titles.length}');
          debugPrint('📊 DEBUG: Followers = $_followersCount, Following = $_followingCount');
        });
      } else {
        debugPrint('⚠️ DEBUG: Response es null o widget no montado');
      }
    } catch (e) {
      debugPrint('❌ DEBUG ERROR loading header data: $e');
      // Non-critical error, don't update loading state
    }
  }

  Future<void> _handleFollow() async {
    final notifier = ref.read(followActionsProvider.notifier);
    final success = await notifier.toggleFollow(
      communityId: widget.communityId,
      targetUserId: widget.userId,
      currentlyFollowing: _isFollowing,
    );

    if (success) {
      // Invalidate provider and update local state
      ref.invalidate(followStatusProvider(FollowStatusParams(
        communityId: widget.communityId,
        targetUserId: widget.userId,
      )));
      setState(() {
        _isFollowing = !_isFollowing;
        _friendshipStatus = _isFollowing 
            ? FriendshipStatus.followingThem 
            : FriendshipStatus.notFollowing;
      });
    }
  }

  Future<void> _handleRequestFriendship() async {
    final repo = ref.read(friendshipRepositoryProvider);
    try {
      final request = await repo.sendRequest(widget.communityId, widget.userId);
      if (request != null && mounted) {
        // Refresh provider to update UI (remove 🤝 button, etc.)
        ref.invalidate(friendshipStatusProvider(FriendshipCheckParams(
          communityId: widget.communityId,
          otherUserId: widget.userId,
        )));
        
        // Refresh pending requests provider just in case
        ref.invalidate(pendingFriendshipRequestsProvider(widget.communityId));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solicitud de amistad enviada'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(
            content: Text('Error al enviar la solicitud'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error handling friendship request: $e');
    }
  }

  Future<void> _handleRemoveFriendship() async {
    final repo = ref.read(friendshipRepositoryProvider);
    try {
      final success = await repo.removeFriendship(widget.communityId, widget.userId);
      if (success && mounted) {
        // Refresh provider to update UI
        ref.invalidate(friendshipStatusProvider(FriendshipCheckParams(
          communityId: widget.communityId,
          otherUserId: widget.userId,
        )));
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Amistad anulada'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error removing friendship: $e');
    }
  }

  void _handleMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mensajes directos (próximamente)'),
        backgroundColor: NeoColors.accent,
      ),
    );
  }

  void _navigateToConnections({int initialTab = 0}) {
    context.push(
      '/communities/${widget.communityId}/users/${widget.userId}/connections',
      extra: {'initialTab': initialTab},
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isOwnProfile = false;
    final currentUser = ref.watch(authProvider).user;
    if (currentUser != null && currentUser.id == widget.userId) {
      isOwnProfile = true;
    }

    // DEBUG LOGGING - Check Mutual Follow Status
    if (!isOwnProfile) {
      final friendshipState = ref.watch(friendshipStatusProvider(
        FriendshipCheckParams(communityId: widget.communityId, otherUserId: widget.userId)
      ));
      
      friendshipState.when(
        data: (status) {
          debugPrint('🔍 DEBUG FRIENDSHIP: Mutual=${status.haveMutualFollow} | Friends=${status.areFriends} | Pending=${status.pendingRequest != null}');
        },
        error: (e, s) => debugPrint('❌ DEBUG FRIENDSHIP ERROR: $e'),
        loading: () => debugPrint('⏳ DEBUG FRIENDSHIP LOADING'),
      );
    }

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
    // DEBUG: Log header data
    debugPrint('🎨 RENDERING Header:');
    debugPrint('   User: ${user.username}');
    debugPrint('   Is self: $isOwnProfile');
    debugPrint('   Staff role: $_staffRole');
    debugPrint('   Titles count: ${_titles.length}');
    debugPrint('   Followers: $_followersCount, Following: $_followingCount');

    return SliverToBoxAdapter(
      child: Column(
        children: [
          // Top bar: Back Button + NeoCoins (SafeArea)
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              left: 8,
              right: 8,
            ),
            color: Colors.black,
            child: Row(
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
          ),

          // ProfileHeaderWidget - The new unified header
          ProfileHeaderWidget(
            profileUser: user,
            isSelfProfile: isOwnProfile,
            followersCount: _followersCount,
            followingCount: _followingCount,
            staffRole: _staffRole,
            titles: _titles,
            onFollowTap: isOwnProfile ? null : _handleFollow,
            onMessageTap: isOwnProfile ? null : _handleMessage,
            onMenuTap: () => _showProfileMenu(context),
            onFollowersTap: () => _navigateToConnections(initialTab: 0),
            onFollowingTap: () => _navigateToConnections(initialTab: 1),
          ),

          // Action Buttons (below header for other profiles)
          if (!isOwnProfile)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: ProfileActionButtons(
                isOwnProfile: isOwnProfile,
                otherUserId: widget.userId,
                communityId: widget.communityId,
                isFollowing: _isFollowing,
                onFollowTap: _handleFollow,
                onMessageTap: _handleMessage,
                onRequestFriendshipConfirmed: _handleRequestFriendship,
                onUnfriendConfirmed: _handleRemoveFriendship,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    final followersAsync = ref.watch(communityFollowerCountProvider(FollowStatusParams(
      communityId: widget.communityId,
      targetUserId: widget.userId,
    )));

    final followingAsync = ref.watch(communityFollowingCountProvider(FollowStatusParams(
      communityId: widget.communityId,
      targetUserId: widget.userId,
    )));

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStatItem(
          'Seguidores', 
          followersAsync.when(
            data: (count) => count.toString(),
            loading: () => '...',
            error: (_, __) => '0',
          ),
          onTap: () {
            context.pushNamed(
              'community-connections',
              pathParameters: {'communityId': widget.communityId},
              extra: {
                'userId': widget.userId,
                'initialType': UserListType.followers,
              },
            );
          },
        ),
        const SizedBox(width: 24),
        Container(width: 1, height: 24, color: Colors.white24),
        const SizedBox(width: 24),
        _buildStatItem(
          'Siguiendo', 
          followingAsync.when(
            data: (count) => count.toString(),
            loading: () => '...',
            error: (_, __) => '0',
          ),
          onTap: () {
             context.pushNamed(
              'community-connections',
              pathParameters: {'communityId': widget.communityId},
              extra: {
                'userId': widget.userId,
                'initialType': UserListType.following,
              },
            );
          },
        ),
        const SizedBox(width: 24),
        Container(width: 1, height: 24, color: Colors.white24),
        const SizedBox(width: 24),
        _buildStatItem('Posts', _postsCount.toString()),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
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
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverTabBarDelegate(
        TabBar(
          controller: _tabController,
          dividerColor: Colors.transparent, // Remove divider
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

  /// Show profile menu for self-profile with configuration options
  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: NeoColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.more_vert, color: NeoColors.textPrimary),
                    const SizedBox(width: 12),
                    const Text(
                      'Opciones de Perfil',
                      style: TextStyle(
                        color: NeoColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              
              // Editar Perfil
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: NeoColors.accent),
                title: const Text('Editar Perfil', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Cambia tu identidad local', style: TextStyle(color: NeoColors.textSecondary, fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  context.pushNamed(
                    'local-identity',
                    pathParameters: {'communityId': widget.communityId},
                  );
                },
              ),
              
              // Títulos
              ListTile(
                leading: const Icon(Icons.workspace_premium_outlined, color: NeoColors.accent),
                title: const Text('Títulos', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Gestiona tus títulos', style: TextStyle(color: NeoColors.textSecondary, fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  context.pushNamed(
                    'user-titles-settings',
                    pathParameters: {'communityId': widget.communityId},
                  );
                },
              ),
              
              // Solicitar Título
              ListTile(
                leading: const Icon(Icons.add_circle_outline, color: Colors.green),
                title: const Text('Solicitar Título', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Crea un título personalizado', style: TextStyle(color: NeoColors.textSecondary, fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  context.pushNamed(
                    'request-title',
                    pathParameters: {'communityId': widget.communityId},
                  );
                },
              ),
              
              // Crear publicación
              ListTile(
                leading: const Icon(Icons.create_outlined, color: NeoColors.accent),
                title: const Text('Crear publicación', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Publica algo en tu muro', style: TextStyle(color: NeoColors.textSecondary, fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showCreatePostDialog();
                },
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// Show dialog to create a wall post
  void _showCreatePostDialog() {
    final TextEditingController dialogController = TextEditingController();
    bool isPosting = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: NeoColors.card,
            title: const Text(
              'Crear publicación',
              style: TextStyle(color: NeoColors.textPrimary),
            ),
            content: TextField(
              controller: dialogController,
              autofocus: true,
              maxLines: 5,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Escribe algo en tu muro...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
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
            actions: [
              TextButton(
                onPressed: isPosting ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: isPosting
                    ? null
                    : () async {
                        final content = dialogController.text.trim();
                        if (content.isEmpty) return;

                        setDialogState(() => isPosting = true);

                        try {
                          await Supabase.instance.client
                              .from('profile_wall_posts')
                              .insert({
                            'profile_user_id': widget.userId,
                            'author_id': widget.userId,
                            'community_id': widget.communityId,
                            'content': content,
                          });
                          
                          if (!dialogContext.mounted) return;
                          Navigator.pop(dialogContext);
                          
                          // Reload wall posts
                          _fetchUser();
                          
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Publicación creada'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          setDialogState(() => isPosting = false);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: NeoColors.error,
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: NeoColors.accent,
                  foregroundColor: Colors.white,
                ),
                child: isPosting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Publicar'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWallTab() {
    return Container(
      color: Colors.black,
      child: ListView(
        padding: const EdgeInsets.all(NeoSpacing.md),
        children: [
          // Composer launcher - always first
          WallThreadsComposerLauncher(
            currentUser: UserEntity(
              id: Supabase.instance.client.auth.currentUser!.id,
              email: Supabase.instance.client.auth.currentUser!.email ?? '',
              username: Supabase.instance.client.auth.currentUser!.userMetadata?['username'] ?? 'Usuario',
              createdAt: DateTime.now(),
              avatarUrl: Supabase.instance.client.auth.currentUser!.userMetadata?['avatar_url'],
              neocoinsBalance: 0,
              isVip: false,
            ),
            profileUser: _user!,
            isSelfProfile: Supabase.instance.client.auth.currentUser!.id == widget.userId,
            onTap: () => _showComposerSheet(),
          ),
          
          // Divider sutil
          Divider(
            height: 1,
            thickness: 0.5,
            color: Colors.grey[900],
          ),
          
          // Wall posts
          if (_wallPosts.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Column(
                  children: [
                    Icon(Icons.article_outlined, size: 48, color: Colors.grey[800]),
                    const SizedBox(height: 12),
                    Text('Aún no hay publicaciones', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
            )
          else
            ...(_wallPosts.asMap().entries.map((entry) {
              final index = entry.key;
              final post = entry.value;
              final isLastPost = index == _wallPosts.length - 1;
              
              return ThreadPostItem(
                authorId: post.authorId,
                authorUsername: post.authorName,
                authorAvatarUrl: post.authorAvatar,
                content: post.content,
                createdAt: post.timestamp,
                isLast: isLastPost,
                likesCount: post.likes,
                commentsCount: post.commentsCount,
                isLiked: post.isLikedByCurrentUser,
                onTap: () => _openPostThread(post),
                onLike: () => _togglePostLike(post),
                onComment: () => _openPostThread(post, autoFocus: true),
              );
            })),
        ],
      ),
    );
  }

  void _showComposerSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => WallThreadsComposerSheet(
        currentUser: UserEntity(
          id: Supabase.instance.client.auth.currentUser!.id,
          email: Supabase.instance.client.auth.currentUser!.email ?? '',
          username: Supabase.instance.client.auth.currentUser!.userMetadata?['username'] ?? 'Usuario',
          createdAt: DateTime.now(),
          avatarUrl: Supabase.instance.client.auth.currentUser!.userMetadata?['avatar_url'],
          neocoinsBalance: 0,
          isVip: false,
        ),
        profileUser: _user!,
        communityId: widget.communityId,
        isSelfProfile: Supabase.instance.client.auth.currentUser!.id == widget.userId,
        onSuccess: () {
          // Refresh wall posts
          _fetchUser();
        },
      ),
    );
  }

  void _openPostThread(WallPost post, {bool autoFocus = false}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WallPostThreadScreen(
          post: post,
          autoFocusInput: autoFocus,
          isProfilePost: true,
        ),
      ),
    );
  }

  Future<void> _togglePostLike(WallPost post) async {
    final supabase = Supabase.instance.client;
    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    final postIndex = _wallPosts.indexWhere((p) => p.id == post.id);
    if (postIndex == -1) return;

    final wasLiked = post.isLikedByCurrentUser;
    final updatedPost = post.copyWith(
      isLikedByCurrentUser: !wasLiked,
      likes: wasLiked ? post.likes - 1 : post.likes + 1,
    );

    setState(() {
      _wallPosts[postIndex] = updatedPost;
    });

    try {
      if (wasLiked) {
        await supabase
            .from('profile_wall_post_likes')
            .delete()
            .eq('post_id', post.id)
            .eq('user_id', currentUserId);
      } else {
        await supabase.from('profile_wall_post_likes').insert({
          'post_id': post.id,
          'user_id': currentUserId,
        });
      }
    } catch (e) {
      setState(() {
        _wallPosts[postIndex] = post;
      });
      debugPrint('Error toggling post like: $e');
    }
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
