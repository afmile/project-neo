/// Project Neo - Friendship Request Notification Tile
///
/// Widget for displaying friendship requests in notification list
/// with Accept/Reject action buttons
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/theme/neo_theme.dart';
import '../../domain/entities/friendship_request.dart';
import '../providers/friendship_provider.dart';

class FriendshipRequestTile extends ConsumerWidget {
  final FriendshipRequest request;
  final VoidCallback? onAccepted;
  final VoidCallback? onRejected;

  const FriendshipRequestTile({
    super.key,
    required this.request,
    this.onAccepted,
    this.onRejected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: NeoColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFEC4899).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar + Name + Time
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: NeoColors.accent,
                backgroundImage: request.requesterAvatar != null
                    ? NetworkImage(request.requesterAvatar!)
                    : null,
                child: request.requesterAvatar == null
                    ? const Icon(Icons.person, size: 20, color: Colors.white)
                    : null,
              ),
              
              const SizedBox(width: 12),
              
              // Name + Message
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.requesterName ?? 'Usuario',
                      style: NeoTextStyles.labelLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'quiere ser tu amigo',
                      style: NeoTextStyles.bodySmall.copyWith(
                        color: NeoColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Time
              Text(
                timeago.format(request.createdAt, locale: 'es'),
                style: NeoTextStyles.labelSmall.copyWith(
                  color: NeoColors.textTertiary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Action buttons
          Row(
            children: [
              // Accept button
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _handleAccept(context, ref),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Aceptar'),
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Reject button
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _handleReject(context, ref),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: NeoColors.textSecondary,
                    side: const BorderSide(color: NeoColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Rechazar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleAccept(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(friendshipRepositoryProvider);
    final success = await repo.acceptRequest(request.id);

    if (success) {
      ref.invalidate(pendingFriendshipRequestsProvider(request.communityId));
      onAccepted?.call();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Ahora eres amigo de ${request.requesterName ?? 'este usuario'}!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _handleReject(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(friendshipRepositoryProvider);
    final success = await repo.rejectRequest(request.id);

    if (success) {
      ref.invalidate(pendingFriendshipRequestsProvider(request.communityId));
      onRejected?.call();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solicitud rechazada'),
          ),
        );
      }
    }
  }
}
