import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/neo_theme.dart';
import '../../../../shared/widgets/destructive_action_dialog.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/community_list_providers.dart';
import '../providers/community_follow_provider.dart';
import '../providers/friendship_provider.dart';

enum UserListType {
  friends,
  followers,
  following,
}

class CommunityUserListWidget extends ConsumerStatefulWidget {
  final String communityId;
  final String userId;
  final UserListType type;

  const CommunityUserListWidget({
    super.key,
    required this.communityId,
    required this.userId,
    required this.type,
  });

  @override
  ConsumerState<CommunityUserListWidget> createState() => _CommunityUserListWidgetState();
}

class _CommunityUserListWidgetState extends ConsumerState<CommunityUserListWidget> {
  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    // 1. Determine which list to fetch
    final AsyncValue<List<UserEntity>> listAsync = switch (widget.type) {
      UserListType.friends => ref.watch(communityFriendsListProvider(widget.communityId)),
      UserListType.followers => ref.watch(followersListProvider(FollowStatusParams(
          communityId: widget.communityId,
          targetUserId: widget.userId,
        ))),
      UserListType.following => ref.watch(followingListProvider(FollowStatusParams(
          communityId: widget.communityId,
          targetUserId: widget.userId,
        ))),
    };

    // 2. Fetch my friends IDs for Badges (always needed to show who is my friend)
    final myFriendIdsAsync = ref.watch(myFriendIdsProvider(widget.communityId));

    return listAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: NeoColors.accent),
      ),
      error: (error, stack) => const Center(
        child: Text(
          'Error al cargar lista',
          style: TextStyle(color: NeoColors.error),
        ),
      ),
      data: (users) {
        if (users.isEmpty) {
          return const Center(
            child: Text(
              'Lista vacía',
              style: TextStyle(color: NeoColors.textSecondary),
            ),
          );
        }

        return myFriendIdsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: NeoColors.accent)),
          error: (_, __) => const SizedBox(), // Should not block list
          data: (myFriendIds) {
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: users.length,
              separatorBuilder: (_, __) => const Divider(color: NeoColors.border),
              itemBuilder: (context, index) {
                final user = users[index];
                final isExampleMe = user.id == currentUser?.id;
                final isFriend = myFriendIds.contains(user.id);
                
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  // Avatar
                  leading: CircleAvatar(
                    backgroundColor: NeoColors.card,
                    backgroundImage: user.avatarUrl != null 
                        ? NetworkImage(user.avatarUrl!) 
                        : null,
                    child: user.avatarUrl == null
                        ? const Icon(Icons.person, color: Colors.white)
                        : null,
                  ),
                  
                  // Name + Badge
                  title: Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isFriend && widget.type != UserListType.friends) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: NeoColors.accent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: NeoColors.accent.withValues(alpha: 0.5)),
                          ),
                          child: const Text(
                            'Amig@',
                            style: TextStyle(
                              color: NeoColors.accent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  
                  // Actions
                  trailing: isExampleMe 
                      ? null // No actions on myself
                      : _buildActionButtons(user, isFriend),
                  
                  onTap: () {
                     // Navigate to profile
                     context.pushNamed(
                       'community-user-profile',
                       extra: {
                         'userId': user.id,
                         'communityId': widget.communityId,
                       },
                     );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget? _buildActionButtons(UserEntity user, bool isFriend) {
    if (widget.type == UserListType.friends) {
      return IconButton(
        icon: const Icon(Icons.person_remove_outlined, color: NeoColors.error),
        tooltip: 'Dejar de ser amigos',
        onPressed: () => _handleUnfriend(user),
      );
    }
    return null;
  }

  Future<void> _handleUnfriend(UserEntity user) async {
    final confirmed = await DestructiveActionDialog.show(
      context: context,
      title: 'Anular amistad',
      message: '¿Estás seguro/a de que quieres eliminar a ${user.username} de tus amigos?',
      confirmText: 'Eliminar',
    );

    if (confirmed == true && mounted) {
      final success = await ref.read(friendshipRepositoryProvider)
          .removeFriendship(widget.communityId, user.id);

      if (success) {
        // Refresh the list
        ref.invalidate(communityFriendsListProvider(widget.communityId));
        ref.invalidate(myFriendIdsProvider(widget.communityId));
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('${user.username} eliminado de amigos')),
          );
        }
      }
    }
  }
}
