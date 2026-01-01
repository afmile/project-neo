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
import '../providers/wall_posts_paginated_provider.dart';
import '../providers/community_providers.dart';
import '../providers/friendship_provider.dart';
import '../widgets/profile_header_section.dart';
import '../widgets/profile_stats_row.dart';
import '../widgets/profile_bio_card.dart';
import '../widgets/profile_action_buttons.dart';
import '../widgets/profile_tabs_widget.dart';
import '../widgets/wall_post_card.dart';
import 'local_edit_profile_screen.dart';

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
  final TextEditingController _wallInputController = TextEditingController();
  bool _isPostingToWall = false;
  bool _isFollowing = false; // TODO: Connect to real follow state

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _wallInputController.dispose();
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

    final statsAsync = ref.watch(userStatsProvider(widget.userId));

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
                expandedHeight: 360,
                pinned: true,
                floating: false,
                backgroundColor: Colors.black,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: NeoColors.textPrimary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                actions: [
                  if (isOwnProfile)
                    IconButton(
                      icon: const Icon(Icons.settings, color: NeoColors.textPrimary),
                      onPressed: () {
                        _showProfileSettingsMenu(context);
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
              data: (stats) => ProfileStatsRow(stats: stats),
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

          // Action buttons (with friendship support)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ProfileActionButtons(
              isOwnProfile: isOwnProfile,
              otherUserId: isOwnProfile ? null : widget.userId,
              communityId: widget.communityId,
              isFollowing: _isFollowing,
              onFollowTap: () {
                setState(() {
                  _isFollowing = !_isFollowing;
                });
                // TODO: Implement actual follow logic
              },
              onMessageTap: () {
                // TODO: Navigate to chat
              },
              onEditTap: () => _navigateToEditProfile(),
              onRequestFriendshipConfirmed: () => _handleSendFriendshipRequest(),
            ),
          ),
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

  void _showProfileSettingsMenu(BuildContext context) {
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
                      Icons.settings,
                      color: NeoColors.textPrimary,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Configuración de Perfil',
                      style: TextStyle(
                        color: NeoColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: NeoColors.border, height: 1),
              
              // Títulos option
              ListTile(
                leading: const Icon(
                  Icons.workspace_premium_outlined,
                  color: NeoColors.accent,
                ),
                title: const Text(
                  'Títulos',
                  style: TextStyle(color: NeoColors.textPrimary),
                ),
                subtitle: const Text(
                  'Gestiona tus títulos de la comunidad',
                  style: TextStyle(color: NeoColors.textSecondary, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  
                  // Defer navigation until sheet is fully closed
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
              
              // Solicitar Título option (NEW)
              ListTile(
                leading: const Icon(
                  Icons.add_circle_outline,
                  color: Colors.green,
                ),
                title: const Text(
                  'Solicitar Título',
                  style: TextStyle(color: NeoColors.textPrimary),
                ),
                subtitle: const Text(
                  'Crea un título personalizado',
                  style: TextStyle(color: NeoColors.textSecondary, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  
                  // Defer navigation until sheet is fully closed
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
              
              // Editar Perfil option
              ListTile(
                leading: const Icon(
                  Icons.edit_outlined,
                  color: Colors.white,
                ),
                title: const Text(
                  'Editar Perfil',
                  style: TextStyle(color: NeoColors.textPrimary),
                ),
                subtitle: const Text(
                  'Cambia tu identidad local',
                  style: TextStyle(color: NeoColors.textSecondary, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToEditProfile();
                },
              ),
              
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
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
            // Wall input composer
            _buildWallInput(user, isOwnProfile),
            const SizedBox(height: NeoSpacing.lg),

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
                            isOwnProfile 
                                ? 'Tu muro está vacío\n¡Comparte algo!'
                                : 'Aún no hay publicaciones en este muro',
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
                  children: posts.map((post) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: NeoSpacing.md),
                      child: WallPostCard(
                        post: post,
                        isProfilePost: true,
                        onDelete: () async {
                          final confirmed = await DestructiveActionDialog.confirmDelete(
                            context: context,
                            itemName: 'esta publicación',
                          );

                          if (confirmed && mounted) {
                            final notifier = ref.read(
                              userWallPostsProvider(WallPostsFilter(
                                userId: widget.userId,
                                communityId: widget.communityId,
                              )).notifier,
                            );
                            await notifier.deleteWallPost(post.id);
                          }
                        },
                        onLike: () async {
                          final notifier = ref.read(
                            userWallPostsProvider(WallPostsFilter(
                              userId: widget.userId,
                              communityId: widget.communityId,
                            )).notifier,
                          );
                          await notifier.toggleLike(post.id);
                        },
                        onComment: () {
                          // Navigate to thread
                        },
                      ),
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

  Widget _buildWallInput(UserEntity user, bool isOwnProfile) {
    final placeholder = isOwnProfile
        ? 'Comparte algo en tu muro...'
        : 'Escribe en el muro de ${user.username}...';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: NeoColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: NeoColors.border, width: 1),
      ),
      child: Row(
        children: [
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
          if (_isPostingToWall)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: NeoColors.accent),
            )
          else
            IconButton(
              icon: const Icon(Icons.send, color: NeoColors.accent, size: 20),
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

    setState(() => _isPostingToWall = true);

    final success = await ref
        .read(userWallPostsProvider(WallPostsFilter(
          userId: widget.userId,
          communityId: widget.communityId,
        )).notifier)
        .createWallPost(content);

    setState(() => _isPostingToWall = false);

    if (success) {
      _wallInputController.clear();
    } else {
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
