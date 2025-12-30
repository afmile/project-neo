/// Project Neo - Profile Action Buttons
///
/// Action buttons for profile with friendship states support
/// - Own profile: Edit + Share
/// - Other profile: Follow + Message + Friendship states
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/neo_theme.dart';
import '../providers/friendship_provider.dart';

class ProfileActionButtons extends ConsumerWidget {
  final bool isOwnProfile;
  final String? otherUserId;
  final String? communityId;
  final VoidCallback? onFollowTap;
  final VoidCallback? onMessageTap;
  final VoidCallback? onEditTap;
  final VoidCallback? onShareTap;
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
    // If we have userId and communityId, check friendship status
    if (otherUserId != null && communityId != null) {
      final friendshipAsync = ref.watch(friendshipStatusProvider(
        FriendshipCheckParams(
          communityId: communityId!,
          otherUserId: otherUserId!,
        ),
      ));

      return friendshipAsync.when(
        loading: () => _buildLoadingState(),
        error: (_, __) => _buildDefaultOtherButtons(),
        data: (status) => _buildFriendshipAwareButtons(context, ref, status),
      );
    }

    return _buildDefaultOtherButtons();
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

  Widget _buildDefaultOtherButtons() {
    return Row(
      children: [
        // Follow button
        if (onFollowTap != null)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onFollowTap,
              icon: Icon(
                isFollowing ? Icons.person_remove : Icons.person_add,
                size: 18,
              ),
              label: Text(isFollowing ? 'Siguiendo' : 'Seguir'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isFollowing 
                    ? NeoColors.card 
                    : NeoColors.accent,
                foregroundColor: isFollowing 
                    ? NeoColors.textPrimary 
                    : Colors.white,
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

  Widget _buildFriendshipAwareButtons(
    BuildContext context,
    WidgetRef ref,
    FriendshipStatusInfo status,
  ) {
    // Case 3: Already friends
    if (status.areFriends) {
      return Row(
        children: [
          // Friends badge
          Expanded(
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
                    'Amigos',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
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

    // Case 2: Mutual follow - show friendship options
    if (status.haveMutualFollow) {
      return _buildMutualFollowButtons(context, ref, status);
    }

    // Case 1: No mutual follow - default buttons
    return _buildDefaultOtherButtons();
  }

  Widget _buildMutualFollowButtons(
    BuildContext context,
    WidgetRef ref,
    FriendshipStatusInfo status,
  ) {
    // I sent a pending request
    if (status.iSentRequest) {
      return Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: NeoColors.card,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: NeoColors.border),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.schedule, size: 18, color: NeoColors.textSecondary),
                  SizedBox(width: 8),
                  Text(
                    'Solicitud enviada',
                    style: TextStyle(
                      color: NeoColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
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

    // I received a pending request - show accept/reject
    if (status.iReceivedRequest) {
      return Row(
        children: [
          // Accept button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _handleAcceptRequest(context, ref, status),
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Aceptar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Reject button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _handleRejectRequest(context, ref, status),
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Rechazar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: NeoColors.error,
                side: const BorderSide(color: NeoColors.error),
              ),
            ),
          ),
        ],
      );
    }

    // Can send friendship request
    if (status.canSendRequest) {
      return Row(
        children: [
          // Create friendship button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _handleSendFriendRequest(context, ref),
              icon: const Icon(Icons.favorite_outline, size: 18),
              label: const Text('Crear Amistad'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEC4899), // Pink
                foregroundColor: Colors.white,
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
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

    // Fallback: default buttons
    return _buildDefaultOtherButtons();
  }

  Future<void> _handleSendFriendRequest(BuildContext context, WidgetRef ref) async {
    if (otherUserId == null || communityId == null) return;

    final repo = ref.read(friendshipRepositoryProvider);
    final result = await repo.sendRequest(communityId!, otherUserId!);

    if (result != null) {
      // Invalidate to refresh
      ref.invalidate(friendshipStatusProvider(FriendshipCheckParams(
        communityId: communityId!,
        otherUserId: otherUserId!,
      )));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solicitud de amistad enviada'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al enviar solicitud'),
            backgroundColor: NeoColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleAcceptRequest(
    BuildContext context,
    WidgetRef ref,
    FriendshipStatusInfo status,
  ) async {
    if (status.pendingRequest == null) return;

    final repo = ref.read(friendshipRepositoryProvider);
    final success = await repo.acceptRequest(status.pendingRequest!.id);

    if (success) {
      // Invalidate to refresh
      ref.invalidate(friendshipStatusProvider(FriendshipCheckParams(
        communityId: communityId!,
        otherUserId: otherUserId!,
      )));
      ref.invalidate(pendingFriendshipRequestsProvider(communityId!));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Ahora son amigos!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _handleRejectRequest(
    BuildContext context,
    WidgetRef ref,
    FriendshipStatusInfo status,
  ) async {
    if (status.pendingRequest == null) return;

    final repo = ref.read(friendshipRepositoryProvider);
    final success = await repo.rejectRequest(status.pendingRequest!.id);

    if (success) {
      // Invalidate to refresh
      ref.invalidate(friendshipStatusProvider(FriendshipCheckParams(
        communityId: communityId!,
        otherUserId: otherUserId!,
      )));
      ref.invalidate(pendingFriendshipRequestsProvider(communityId!));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solicitud rechazada'),
            backgroundColor: NeoColors.textSecondary,
          ),
        );
      }
    }
  }
}
