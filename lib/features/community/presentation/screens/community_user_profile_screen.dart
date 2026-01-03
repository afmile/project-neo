/// Project Neo - Community User Profile Screen (Redesigned v2)
///
/// Premium user profile with SliverAppBar, Amino-style titles, and tabbed content
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/neo_theme.dart';
import '../../../../shared/widgets/destructive_action_dialog.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/user_profile_provider.dart';
import '../providers/community_providers.dart';
import '../providers/friendship_provider.dart';
import '../providers/community_follow_provider.dart';
import '../widgets/profile_header_section.dart';
import '../widgets/profile_stats_row.dart';
import '../widgets/profile_bio_card.dart';
import '../widgets/profile_action_buttons.dart';
import '../widgets/profile_tabs_widget.dart';
import '../widgets/thread_post_item.dart';
import 'local_edit_profile_screen.dart';
import 'community_users_list_screen.dart';
import 'wall_post_thread_screen.dart';

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
    final globalUser = ref.watch(currentUserProvider);
    final isOwnProfile = widget.userId == globalUser?.id;

    final profileAsync = ref.watch(
      userProfileProvider(UserProfileParams(
        userId: widget.userId,
        communityId: widget.communityId,
      )),
    );

    final statsAsync = ref.watch(userStatsProvider(UserProfileParams(
      userId: widget.userId,
      communityId: widget.communityId,
    )));

    return Scaffold(
      backgroundColor: Colors.black,
      body: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: NeoColors.accent),
        ),
        error: (error, _) => _buildErrorState(),
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text('Usuario no encontrado', style: TextStyle(color: Colors.white)),
            );
          }

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              // Collapsible SliverAppBar
              SliverAppBar(
                expandedHeight: 480, // Increased to fit profile action buttons
                pinned: true,
                floating: false,
                backgroundColor: Colors.black,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: NeoColors.textPrimary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                actions: [
                  // Unified: always show ⋯ menu for both self and other profiles
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: NeoColors.textPrimary),
                    onPressed: () {
                      _showProfileMenu(context, isOwnProfile);
                    },
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: Container(
                    color: Colors.black,
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 50),
                        child: _buildExpandedHeader(user, isOwnProfile, statsAsync),
                      ),
                    ),
                  ),
                  // Collapsed title: mini avatar + name
                  title: innerBoxIsScrolled
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: NeoColors.accent,
                              backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                                  ? NetworkImage(user.avatarUrl!)
                                  : null,
                              child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                                  ? const Icon(Icons.person, size: 16, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              user.username,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        )
                      : null,
                  centerTitle: false,
                  titlePadding: const EdgeInsets.only(left: 56, bottom: 12),
                ),
              ),
              
              // Sticky Tab Bar
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverTabBarDelegate(
                  ProfileTabsWidget(controller: _tabController),
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildMuroTab(user, isOwnProfile),
                _buildPublicacionesTab(),
                _buildActividadTab(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildExpandedHeader(
    UserEntity user,
    bool isOwnProfile,
    AsyncValue statsAsync,
  ) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          // Header: Avatar + Name + Level + Titles
          ProfileHeaderSection(
            user: user,
            communityId: widget.communityId,
            isOnline: false,
            isVerified: false,
          ),

          const SizedBox(height: 16),

          // Stats row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: statsAsync.when(
              loading: () => const SizedBox(height: 60),
              error: (_, __) => const SizedBox.shrink(),
              data: (stats) => ProfileStatsRow(
                stats: stats,
                onFollowersTap: () {
                  context.pushNamed(
                    'community-connections',
                    pathParameters: {'communityId': widget.communityId},
                    extra: {
                      'userId': widget.userId,
                      'initialType': UserListType.followers,
                    },
                  );
                },
                onFollowingTap: () {
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
            ),
          ),

          const SizedBox(height: 16),

          // Bio card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ProfileBioCard(
              bio: user.bio,
              isOwnProfile: isOwnProfile,
              onEditTap: () => _navigateToEditProfile(),
            ),
          ),

          const SizedBox(height: 16),

          // Action buttons - ONLY for other profiles (unified layout)
          // Self-profile: no action buttons here, edit option is in ⋯ menu
          if (!isOwnProfile) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Consumer(
                builder: (context, ref, child) {
                  // Watch follow status from database
                  final followStatusAsync = ref.watch(followStatusProvider(
                    FollowStatusParams(
                      communityId: widget.communityId,
                      targetUserId: widget.userId,
                    ),
                  ));

                  return followStatusAsync.when(
                    loading: () => const SizedBox(
                      height: 48,
                      child: Center(
                        child: CircularProgressIndicator(color: NeoColors.accent),
                      ),
                    ),
                    error: (_, __) => ProfileActionButtons(
                      isOwnProfile: false,
                      otherUserId: widget.userId,
                      communityId: widget.communityId,
                      isFollowing: false,
                      onFollowTap: () => _handleFollowToggle(false),
                      onMessageTap: () {
                        // TODO: Navigate to chat
                      },
                      onRequestFriendshipConfirmed: () => _handleSendFriendshipRequest(),
                    ),
                    data: (isFollowing) => ProfileActionButtons(
                      isOwnProfile: false,
                      otherUserId: widget.userId,
                      communityId: widget.communityId,
                      isFollowing: isFollowing,
                      onFollowTap: () => _handleFollowToggle(isFollowing),
                      onMessageTap: () {
                        // TODO: Navigate to chat
                      },
                      onRequestFriendshipConfirmed: () => _handleSendFriendshipRequest(),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _navigateToEditProfile() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LocalEditProfileScreen(
          communityId: widget.communityId,
        ),
      ),
    );
    ref.invalidate(userProfileProvider(UserProfileParams(
      userId: widget.userId,
      communityId: widget.communityId,
    )));
  }

  /// Unified profile menu for both self and other profiles
  void _showProfileMenu(BuildContext context, bool isOwnProfile) {
    final community = ref.read(communityByIdProvider(widget.communityId));
    
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
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.more_vert,
                      color: NeoColors.textPrimary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isOwnProfile ? 'Opciones de Perfil' : 'Opciones',
                      style: const TextStyle(
                        color: NeoColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              
              // Self profile options
              if (isOwnProfile) ...[
                _buildMenuOption(
                  context: context,
                  icon: Icons.edit_outlined,
                  title: 'Editar Perfil',
                  subtitle: 'Cambia tu identidad local',
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToEditProfile();
                  },
                ),
                _buildMenuOption(
                  context: context,
                  icon: Icons.workspace_premium_outlined,
                  title: 'Títulos',
                  subtitle: 'Gestiona tus títulos de la comunidad',
                  color: NeoColors.accent,
                  onTap: () {
                    Navigator.pop(context);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      community.when(
                        data: (comm) {
                          if (comm != null) {
                            context.pushNamed(
                              'user-titles-settings',
                              pathParameters: {'communityId': widget.communityId},
                              extra: {
                                'name': comm.title,
                                'color': _parseColor(comm.theme.primaryColor),
                              },
                            );
                          }
                        },
                        loading: () {},
                        error: (_, __) {},
                      );
                    });
                  },
                ),
                _buildMenuOption(
                  context: context,
                  icon: Icons.add_circle_outline,
                  title: 'Solicitar Título',
                  subtitle: 'Crea un título personalizado',
                  color: Colors.green,
                  onTap: () {
                    Navigator.pop(context);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      community.when(
                        data: (comm) {
                          if (comm != null) {
                            context.pushNamed(
                              'request-title',
                              pathParameters: {'communityId': widget.communityId},
                              extra: {
                                'name': comm.title,
                                'color': _parseColor(comm.theme.primaryColor),
                              },
                            );
                          }
                        },
                        loading: () {},
                        error: (_, __) {},
                      );
                    });
                  },
                ),
                _buildMenuOption(
                  context: context,
                  icon: Icons.create_outlined,
                  title: 'Crear publicación',
                  subtitle: 'Publica algo en tu muro',
                  color: NeoColors.accent,
                  onTap: () {
                    Navigator.pop(context);
                    _showCreatePostDialog();
                  },
                ),
              ] else ...[
                // Other user profile options (placeholders for future moderation features)
                _buildMenuOption(
                  context: context,
                  icon: Icons.flag_outlined,
                  title: 'Reportar',
                  subtitle: 'Reportar contenido inapropiado',
                  color: NeoColors.error,
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Próximamente: Reportar usuario'),
                        backgroundColor: NeoColors.error,
                      ),
                    );
                  },
                ),
                _buildMenuOption(
                  context: context,
                  icon: Icons.block_outlined,
                  title: 'Bloquear',
                  subtitle: 'Bloquear a este usuario',
                  color: NeoColors.error,
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Próximamente: Bloquear usuario'),
                        backgroundColor: NeoColors.error,
                      ),
                    );
                  },
                ),
              ],
              
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper method to build menu options
  Widget _buildMenuOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.white),
      title: Text(
        title,
        style: TextStyle(color: color ?? NeoColors.textPrimary),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: NeoColors.textSecondary, fontSize: 12),
      ),
      onTap: onTap,
    );
  }

  Color _parseColor(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      final fullHex = hex.length == 6 ? 'FF$hex' : hex;
      return Color(int.parse(fullHex, radix: 16));
    } catch (e) {
      return NeoColors.accent;
    }
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: NeoColors.error),
          const SizedBox(height: 16),
          Text(
            'Error al cargar perfil',
            style: NeoTextStyles.bodyLarge.copyWith(color: NeoColors.error),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FOLLOW ACTIONS (BUGFIX)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Handle follow/unfollow toggle
  Future<void> _handleFollowToggle(bool currentlyFollowing) async {
    try {
      final notifier = ref.read(followActionsProvider.notifier);
      
      final success = await notifier.toggleFollow(
        communityId: widget.communityId,
        targetUserId: widget.userId,
        currentlyFollowing: currentlyFollowing,
      );

      if (success) {
        // Invalidate follow status
        ref.invalidate(followStatusProvider(FollowStatusParams(
          communityId: widget.communityId,
          targetUserId: widget.userId,
        )));

        // Also invalidate friendship status (depends on mutual follow)
        ref.invalidate(friendshipStatusProvider(FriendshipCheckParams(
          communityId: widget.communityId,
          otherUserId: widget.userId,
        )));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(currentlyFollowing ? 'Dejaste de seguir' : '✓ Siguiendo'),
              backgroundColor: currentlyFollowing ? NeoColors.textSecondary : Colors.green,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al actualizar seguimiento'),
              backgroundColor: NeoColors.error,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error toggling follow: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: NeoColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FRIENDSHIP ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Handle sending friendship request (S5.2)
  Future<void> _handleSendFriendshipRequest() async {
    // Validate required data
    if (widget.userId.isEmpty || widget.communityId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Datos de usuario incompletos'),
            backgroundColor: NeoColors.error,
          ),
        );
      }
      return;
    }

    try {
      // Get repository
      final repo = ref.read(friendshipRepositoryProvider);

      // Send request
      final result = await repo.sendRequest(widget.communityId, widget.userId);

      if (result != null) {
        // Success: Invalidate providers to refresh UI state
        ref.invalidate(friendshipStatusProvider(FriendshipCheckParams(
          communityId: widget.communityId,
          otherUserId: widget.userId,
        )));
        ref.invalidate(pendingFriendshipRequestsProvider(widget.communityId));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🤝 Solicitud de amistad enviada'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Error from repository (could be duplicate, constraint violation, etc.)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo enviar la solicitud. Puede que ya exista una solicitud pendiente.'),
              backgroundColor: NeoColors.error,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      // Unexpected error
      debugPrint('❌ Error sending friendship request: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar solicitud: ${e.toString()}'),
            backgroundColor: NeoColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB: MURO (Wall posts)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildMuroTab(UserEntity user, bool isOwnProfile) {
    final wallPostsAsync = ref.watch(userWallPostsProvider(WallPostsFilter(
      userId: widget.userId,
      communityId: widget.communityId,
    )));

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        color: Colors.black,
        child: ListView(
          padding: const EdgeInsets.all(NeoSpacing.md),
          children: [
            // Wall posts
            wallPostsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: NeoColors.accent),
                ),
              ),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'Error al cargar publicaciones',
                    style: NeoTextStyles.bodyMedium.copyWith(color: NeoColors.error),
                  ),
                ),
              ),
              data: (posts) {
                if (posts.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 48,
                            color: NeoColors.textTertiary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Aún no hay publicaciones en este muro',
                            textAlign: TextAlign.center,
                            style: NeoTextStyles.bodyMedium.copyWith(
                              color: NeoColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: posts.asMap().entries.map((entry) {
                    final index = entry.key;
                    final post = entry.value;
                    final isLast = index == posts.length - 1;
                    
                    return ThreadPostItem(
                      authorId: post.authorId,
                      authorUsername: post.authorName,
                      authorAvatarUrl: post.authorAvatar,
                      content: post.content,
                      createdAt: post.timestamp,
                      isLast: isLast,
                      likesCount: post.likes,
                      commentsCount: post.commentsCount,
                      isLiked: post.isLikedByCurrentUser,
                      onTap: () => _openPostThread(post),
                      onLike: () {
                        ref.read(userWallPostsProvider(WallPostsFilter(
                          userId: widget.userId,
                          communityId: widget.communityId,
                        )).notifier).toggleLike(post.id);
                      },
                      onComment: () => _openPostThread(post, autoFocus: true),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
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

                        final success = await ref
                            .read(userWallPostsProvider(WallPostsFilter(
                              userId: widget.userId,
                              communityId: widget.communityId,
                            )).notifier)
                            .createWallPost(content);

                        if (!dialogContext.mounted) return;
                        
                        Navigator.pop(dialogContext);
                        
                        if (!context.mounted) return;
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Publicación creada'
                                  : 'Error al crear publicación',
                            ),
                            backgroundColor:
                                success ? Colors.green : NeoColors.error,
                          ),
                        );
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

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB: PUBLICACIONES (Blogs, Wikis, etc.)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPublicacionesTab() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(NeoSpacing.md),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 64,
              color: NeoColors.textTertiary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Publicaciones',
              style: NeoTextStyles.headlineSmall.copyWith(
                color: NeoColors.textTertiary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Blogs, wikis, encuestas y más',
              style: NeoTextStyles.bodySmall.copyWith(
                color: NeoColors.textTertiary,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: NeoColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: NeoColors.accent.withValues(alpha: 0.3)),
              ),
              child: Text(
                'Próximamente',
                style: TextStyle(
                  color: NeoColors.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB: ACTIVIDAD
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildActividadTab() {
    final globalUser = ref.watch(currentUserProvider);
    final isOwnProfile = widget.userId == globalUser?.id;
    
    // Show private message for other user profiles
    if (!isOwnProfile) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: NeoColors.textTertiary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Actividad privada',
                  style: TextStyle(
                    color: NeoColors.textSecondary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Solo el dueño del perfil puede ver esta sección',
                  style: TextStyle(
                    color: NeoColors.textTertiary,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    // Placeholder for own profile activity (future feature)
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(NeoSpacing.md),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: NeoColors.textTertiary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Actividad reciente',
              style: NeoTextStyles.headlineSmall.copyWith(
                color: NeoColors.textTertiary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Historial de acciones del usuario',
              style: NeoTextStyles.bodySmall.copyWith(
                color: NeoColors.textTertiary,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: NeoColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: NeoColors.accent.withValues(alpha: 0.3)),
              ),
              child: Text(
                'Próximamente',
                style: TextStyle(
                  color: NeoColors.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SLIVER TAB BAR DELEGATE
// ═══════════════════════════════════════════════════════════════════════════

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => 56;

  @override
  double get maxExtent => 56;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.black,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) => false;
}
