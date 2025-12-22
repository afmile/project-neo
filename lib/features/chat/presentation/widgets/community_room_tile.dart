import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/neo_theme.dart';
import '../../domain/entities/community_chat_room_entity.dart';
import '../providers/community_chat_room_provider.dart';

class CommunityRoomTile extends ConsumerWidget {
  final CommunityChatRoomEntity room;
  final String communityId;
  final VoidCallback onTap;

  const CommunityRoomTile({
    super.key,
    required this.room,
    required this.communityId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key('room_${room.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        // Pin the room
        ref
            .read(communityChatRoomProvider(communityId).notifier)
            .togglePin(room.id);
        
        // Show feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${room.title} pinneado'),
            duration: const Duration(seconds: 2),
            backgroundColor: NeoColors.accent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // Don't actually dismiss (we're moving it to pinned section)
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: NeoSpacing.lg),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Colors.transparent,
              NeoColors.accent,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.push_pin,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(height: 4),
            Text(
              'Pinnear',
              style: NeoTextStyles.labelSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(NeoSpacing.md),
          decoration: BoxDecoration(
            color: NeoColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              // Leading: Room icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[800],
                  border: Border.all(color: Colors.white10, width: 1),
                ),
                child: Icon(
                  room.type == RoomType.public
                      ? Icons.people_outline
                      : Icons.lock_outline,
                  color: Colors.white54,
                  size: 28,
                ),
              ),
              
              const SizedBox(width: NeoSpacing.md),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            room.title,
                            style: NeoTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (room.type == RoomType.private)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF8B5CF6),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'PRIVADO',
                              style: NeoTextStyles.labelSmall.copyWith(
                                color: const Color(0xFF8B5CF6),
                                fontWeight: FontWeight.bold,
                                fontSize: 9,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    // Last message
                    if (room.lastMessage != null)
                      Text(
                        '${room.lastMessage!.senderName}: ${room.lastMessage!.content}',
                        style: NeoTextStyles.bodySmall.copyWith(
                          color: room.unreadCount > 0
                              ? NeoColors.textPrimary
                              : NeoColors.textTertiary,
                          fontWeight: room.unreadCount > 0
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              
              const SizedBox(width: NeoSpacing.sm),
              
              // Trailing: time, unread
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Time
                  Text(
                    _formatTime(room.lastMessageTime),
                    style: NeoTextStyles.labelSmall.copyWith(
                      color: room.unreadCount > 0
                          ? NeoColors.accent
                          : NeoColors.textTertiary,
                      fontWeight: room.unreadCount > 0
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  
                  // Unread badge
                  if (room.unreadCount > 0) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: NeoColors.accent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        room.unreadCount > 99 ? '99+' : room.unreadCount.toString(),
                        style: NeoTextStyles.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return DateFormat('dd/MM').format(time);
    }
  }
}
