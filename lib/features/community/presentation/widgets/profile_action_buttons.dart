/// Project Neo - Profile Action Buttons
///
/// Action buttons for profile with friendship states support
/// - Own profile: Edit + Share
/// - Other profile: Follow + Message + Friendship states
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/neo_theme.dart';
import '../providers/friendship_provider.dart';
import '../screens/community_users_list_screen.dart';

class ProfileActionButtons extends ConsumerWidget {
  final bool isOwnProfile;
  final String? otherUserId;
  final String? communityId;
  final VoidCallback? onFollowTap;
  final VoidCallback? onMessageTap;
  final VoidCallback? onEditTap;
  final VoidCallback? onShareTap;
  final VoidCallback? onRequestFriendshipConfirmed;
  final VoidCallback? onUnfriendConfirmed;
  final bool isFollowing;

  const ProfileActionButtons({
    super.key,
    required this.isOwnProfile,
    this.otherUserId,
    this.communityId,
    this.onFollowTap,
    this.onMessageTap,
    this.onEditTap,
    this.onShareTap,
    this.onRequestFriendshipConfirmed,
    this.onUnfriendConfirmed,
    this.isFollowing = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isOwnProfile) {
      return _buildOwnProfileButtons();
    }
    
    return _buildOtherProfileButtons(context, ref);
  }

  Widget _buildOwnProfileButtons() {
    return Row(
      children: [
        if (onEditTap != null)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onEditTap,
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Editar Perfil'),
            ),
          ),
        
        if (onEditTap != null && onShareTap != null)
          const SizedBox(width: 12),
        
        if (onShareTap != null)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onShareTap,
              icon: const Icon(Icons.share, size: 18),
              label: const Text('Compartir'),
            ),
          ),
      ],
    );
  }

  Widget _buildOtherProfileButtons(BuildContext context, WidgetRef ref) {
    if (otherUserId != null && communityId != null) {
      // Check if we have friendship status to show friendship-aware buttons
      final friendshipAsync = ref.watch(friendshipStatusProvider(
        FriendshipCheckParams(
          communityId: communityId!,
          otherUserId: otherUserId!,
        ),
      ));
      
      return friendshipAsync.when(
        loading: () => _buildLoadingState(),
        error: (_, __) => _buildSimpleFollowButtons(),
        data: (status) {
          if (status.areFriends) {
            return _buildFriendsBadge(context);
          }
          
          if (status.haveMutualFollow) {
            return _buildMutualFollowWithFriendshipButton(status);
          }
          
          return _buildSimpleFollowButtons();
        },
      );
    }

    return _buildSimpleFollowButtons();
  }

  Widget _buildLoadingState() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2, color: NeoColors.accent),
        ),
      ],
    );
  }

  Widget _buildSimpleFollowButtons() {
    return Row(
      children: [
        // Follow/Siguiendo button
        if (onFollowTap != null)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onFollowTap,
              icon: Icon(
                isFollowing ? Icons.check : Icons.person_add,
                size: 18,
              ),
              label: Text(isFollowing ? 'Siguiendo' : 'Seguir'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isFollowing 
                    ? NeoColors.card 
                    : NeoColors.accent,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        
        if (onFollowTap != null && onMessageTap != null)
          const SizedBox(width: 12),
        
        // Message button
        if (onMessageTap != null)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onMessageTap,
              icon: const Icon(Icons.message, size: 18),
              label: const Text('Mensaje'),
            ),
          ),
      ],
    );
  }

  Widget _buildMutualFollowWithFriendshipButton(FriendshipStatusInfo status) {
    // Mutual follow + friendship request option
    return Row(
      children: [
        // Follow/Siguiendo button
        if (onFollowTap != null)
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: onFollowTap,
              icon: Icon(
                isFollowing ? Icons.check : Icons.person_add,
                size: 18,
              ),
              label: Text(isFollowing ? 'Siguiendo' : 'Seguir'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isFollowing 
                    ? NeoColors.card 
                    : NeoColors.accent,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        
        if (onFollowTap != null && onRequestFriendshipConfirmed != null)
          const SizedBox(width: 8),
        
        // Friendship button (🤝) - check status
        if (isFollowing && onRequestFriendshipConfirmed != null)
           if (status.canSendRequest)
            Builder(
              builder: (btnContext) => IconButton.filled(
                onPressed: () => _showFriendshipDialog(btnContext),
                icon: const Text('🤝', style: TextStyle(fontSize: 18)),
                tooltip: 'Pedir Amistad',
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFEC4899),
                  foregroundColor: Colors.white,
                ),
              ),
            )
          else if (status.pendingRequest != null)
             // Pending indicator
             Container(
               height: 40,
               width: 40,
               decoration: BoxDecoration(
                 color: NeoColors.card,
                 borderRadius: BorderRadius.circular(20),
                 border: Border.all(color: NeoColors.border),
               ),
               child: const Center(
                 child: Icon(Icons.hourglass_empty, size: 18, color: NeoColors.textSecondary),
               ),
             ),
        
        if (onMessageTap != null)
          const SizedBox(width: 8),
        
        // Message button
        if (onMessageTap != null)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onMessageTap,
              icon: const Icon(Icons.message, size: 18),
              label: const Text('Mensaje'),
            ),
          ),
      ],
    );
  }

  Widget _buildFriendsBadge(BuildContext context) {
    // Friends - show badge instead of follow button
    return Row(
      children: [
        // Friends badge
        Expanded(
          child: InkWell(
            onTap: () {
               final currentUserId = Supabase.instance.client.auth.currentUser?.id;
               if (currentUserId != null && communityId != null) {
                 context.pushNamed(
                   'community-users-list',
                   pathParameters: {'communityId': communityId!},
                   extra: {
                     'userId': currentUserId, // Show MY friends list
                     'type': UserListType.friends,
                   },
                 );
               }
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite, size: 18, color: Colors.green),
                  SizedBox(width: 8),
                  Text(
                    'Amig@s',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Message button
        if (onMessageTap != null)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onMessageTap,
              icon: const Icon(Icons.message, size: 18),
              label: const Text('Mensaje'),
            ),
          ),
      ],
    );
  }

  void _showUnfriendDialog(BuildContext context) {
    if (onUnfriendConfirmed == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Anular amistad', style: TextStyle(color: Colors.white)),
        content: const Text(
          '¿Deseas anular la amistad? Ambos usuarios volverán a estado "Siguiendo".',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onUnfriendConfirmed?.call();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Anular'),
          ),
        ],
      ),
    );
  }

  /// Show confirmation dialog for friendship request
  void _showFriendshipDialog(BuildContext? context, {String? username}) {
    // Use the context from the widget tree if not provided
    final dialogContext = context;
    if (dialogContext == null) return;

    showDialog(
      context: dialogContext,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Text('🤝', style: TextStyle(fontSize: 24)),
              SizedBox(width: 12),
              Text('Pedir Amistad'),
            ],
          ),
          content: Text(
            username != null 
                ? '¿Pedir amistad a @$username?'
                : '¿Pedir amistad a este usuario?',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            // No button
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('No'),
            ),
            // Yes button
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Call the callback
                onRequestFriendshipConfirmed?.call();
                debugPrint('[S5.1] Friendship request confirmed - callback invoked');
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEC4899), // Pink
              ),
              child: const Text('Sí'),
            ),
          ],
        );
      },
    );
  }
}
