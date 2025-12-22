import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/neo_theme.dart';
import '../../domain/entities/community_chat_room_entity.dart';
import '../providers/community_chat_room_provider.dart';

class PinnedRoomCard extends ConsumerWidget {
  final CommunityChatRoomEntity room;
  final String communityId;
  final VoidCallback onTap;

  const PinnedRoomCard({
    super.key,
    required this.room,
    required this.communityId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              NeoColors.card,
              NeoColors.card.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: room.unreadCount > 0
                ? NeoColors.accent.withValues(alpha: 0.5)
                : Colors.white10,
            width: room.unreadCount > 0 ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Room icon/avatar
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[800],
                    ),
                    child: Icon(
                      room.type == RoomType.public
                          ? Icons.people_outline
                          : Icons.lock_outline,
                      color: Colors.white54,
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  
                  // Room title
                  Text(
                    room.title,
                    style: NeoTextStyles.labelMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Member count
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 12,
                        color: NeoColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatMemberCount(room.memberCount),
                        style: NeoTextStyles.labelSmall.copyWith(
                          color: NeoColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Unpin button (top right) - More visible and tactile
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () {
                  // Direct unpin with feedback
                  ref
                      .read(communityChatRoomProvider(communityId).notifier)
                      .togglePin(room.id);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${room.title} despinneado'),
                      duration: const Duration(seconds: 2),
                      backgroundColor: Colors.grey[800],
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: NeoColors.accent.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.push_pin,
                    size: 16,
                    color: NeoColors.accent,
                  ),
                ),
              ),
            ),

            // Unread badge (top left)
            if (room.unreadCount > 0)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: NeoColors.accent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    room.unreadCount > 99 ? '99+' : room.unreadCount.toString(),
                    style: NeoTextStyles.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatMemberCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }
}
