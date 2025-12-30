/// Project Neo - Notification Tile Widget
///
/// Displays a single notification with actionable buttons for friendship requests
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/theme/neo_theme.dart';
import '../../domain/entities/community_notification.dart';
import '../providers/notifications_provider.dart';
import '../providers/friendship_provider.dart';

class NotificationTile extends ConsumerStatefulWidget {
  final CommunityNotification notification;
  final VoidCallback? onTap;

  const NotificationTile({
    super.key,
    required this.notification,
    this.onTap,
  });

  @override
  ConsumerState<NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends ConsumerState<NotificationTile> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final n = widget.notification;

    return GestureDetector(
      onTap: () => _handleTap(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: n.isUnread
              ? NeoColors.accent.withValues(alpha: 0.08)
              : NeoColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: n.isUnread
                ? NeoColors.accent.withValues(alpha: 0.3)
                : NeoColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(n),
            
            if (n.isActionable && n.isFriendshipRequest)
              _buildActionButtons(n),
            
            if (!n.isActionable && n.actionStatus != null)
              _buildResolvedBadge(n),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(CommunityNotification n) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Actor avatar
        Stack(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: NeoColors.accent.withValues(alpha: 0.2),
              backgroundImage: n.actorAvatar != null
                  ? NetworkImage(n.actorAvatar!)
                  : null,
              child: n.actorAvatar == null
                  ? Icon(_getIconForType(n.type), size: 20, color: NeoColors.accent)
                  : null,
            ),
            // Unread dot
            if (n.isUnread)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: NeoColors.accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                ),
              ),
          ],
        ),
        
        const SizedBox(width: 12),
        
        // Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                n.title,
                style: NeoTextStyles.labelLarge.copyWith(
                  fontWeight: n.isUnread ? FontWeight.bold : FontWeight.w500,
                ),
              ),
              
              // Body
              if (n.body != null) ...[
                const SizedBox(height: 2),
                Text(
                  n.body!,
                  style: NeoTextStyles.bodySmall.copyWith(
                    color: NeoColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              // Timestamp
              const SizedBox(height: 4),
              Text(
                timeago.format(n.createdAt, locale: 'es'),
                style: NeoTextStyles.labelSmall.copyWith(
                  color: NeoColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
        
        // Type icon
        Icon(
          _getIconForType(n.type),
          size: 16,
          color: NeoColors.textTertiary,
        ),
      ],
    );
  }

  Widget _buildActionButtons(CommunityNotification n) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, left: 56),
      child: Row(
        children: [
          // Accept button
          Expanded(
            child: ElevatedButton(
              onPressed: _isProcessing ? null : () => _handleAction(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Aceptar'),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Reject button
          Expanded(
            child: OutlinedButton(
              onPressed: _isProcessing ? null : () => _handleAction(false),
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
    );
  }

  Widget _buildResolvedBadge(CommunityNotification n) {
    final isAccepted = n.actionStatus == NotificationActionStatus.accepted;
    
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 56),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isAccepted
              ? Colors.green.withValues(alpha: 0.1)
              : NeoColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isAccepted
                ? Colors.green.withValues(alpha: 0.3)
                : NeoColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isAccepted ? Icons.check_circle : Icons.cancel,
              size: 14,
              color: isAccepted ? Colors.green : NeoColors.textTertiary,
            ),
            const SizedBox(width: 4),
            Text(
              isAccepted ? 'Aceptada' : 'Rechazada',
              style: NeoTextStyles.labelSmall.copyWith(
                color: isAccepted ? Colors.green : NeoColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.friendshipRequest:
        return Icons.favorite;
      case NotificationType.follow:
        return Icons.person_add;
      case NotificationType.wallPostLike:
      case NotificationType.commentLike:
        return Icons.thumb_up;
      case NotificationType.comment:
        return Icons.chat_bubble;
      case NotificationType.mention:
        return Icons.alternate_email;
      case NotificationType.modAction:
        return Icons.shield;
      case NotificationType.announcement:
        return Icons.campaign;
      case NotificationType.system:
        return Icons.info;
    }
  }

  Future<void> _handleTap() async {
    final n = widget.notification;
    
    // Mark as read if unread
    if (n.isUnread) {
      await ref
          .read(notificationActionsProvider(n.communityId).notifier)
          .markAsRead(n.id);
    }
    
    widget.onTap?.call();
  }

  Future<void> _handleAction(bool accepted) async {
    if (_isProcessing) return;
    
    final n = widget.notification;
    if (n.entityType == null || n.entityId == null) return;

    setState(() => _isProcessing = true);

    final success = await ref
        .read(notificationActionsProvider(n.communityId).notifier)
        .resolveAction(
          notificationId: n.id,
          accepted: accepted,
          entityType: n.entityType!,
          entityId: n.entityId!,
        );

    if (mounted) {
      setState(() => _isProcessing = false);
    }

    if (success && mounted) {
      // Invalidate friendship status if needed
      if (n.entityType == 'friendship_request') {
        final actorId = n.data['requester_id'] as String?;
        if (actorId != null) {
          ref.invalidate(friendshipStatusProvider(FriendshipCheckParams(
            communityId: n.communityId,
            otherUserId: actorId,
          )));
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(accepted ? '¡Solicitud aceptada!' : 'Solicitud rechazada'),
          backgroundColor: accepted ? Colors.green : NeoColors.textSecondary,
        ),
      );
    }
  }
}
