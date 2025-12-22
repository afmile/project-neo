import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/neo_theme.dart';
import '../../domain/entities/chat_entity.dart';

class ChatTile extends StatelessWidget {
  final ChatEntity chat;
  final VoidCallback onTap;

  const ChatTile({
    super.key,
    required this.chat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
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
            // Leading: Avatar
            _buildAvatar(),
            const SizedBox(width: NeoSpacing.md),
            
            // Content: Title and Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    chat.title,
                    style: NeoTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  
                  // Subtitle: Last message
                  if (chat.lastMessage != null)
                    Row(
                      children: [
                        // Show community name for public rooms
                        if (chat.type == ChatType.publicRoomJoined && chat.communityName != null) ...[
                          Text(
                            chat.communityName!,
                            style: NeoTextStyles.labelSmall.copyWith(
                              color: NeoColors.accent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '•',
                            style: NeoTextStyles.bodySmall.copyWith(
                              color: NeoColors.textTertiary,
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        // Show sender name for group chats
                        if (chat.isGroup && chat.type != ChatType.publicRoomJoined) ...[
                          Text(
                            '${chat.lastMessage!.senderUsername}: ',
                            style: NeoTextStyles.bodySmall.copyWith(
                              color: NeoColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        // Message content
                        Expanded(
                          child: Text(
                            chat.lastMessage!.content,
                            style: NeoTextStyles.bodySmall.copyWith(
                              color: chat.unreadCount > 0
                                  ? NeoColors.textPrimary
                                  : NeoColors.textTertiary,
                              fontWeight: chat.unreadCount > 0
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            
            const SizedBox(width: NeoSpacing.sm),
            
            // Trailing: Time and Unread Badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Time
                Text(
                  _formatTime(chat.lastMessageTime),
                  style: NeoTextStyles.labelSmall.copyWith(
                    color: chat.unreadCount > 0
                        ? NeoColors.accent
                        : NeoColors.textTertiary,
                    fontWeight: chat.unreadCount > 0
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                
                // Unread badge
                if (chat.unreadCount > 0) ...[
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
                      chat.unreadCount > 99 ? '99+' : chat.unreadCount.toString(),
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
    );
  }

  Widget _buildAvatar() {
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        children: [
          // Main avatar
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[800],
              border: Border.all(color: Colors.white10, width: 1),
            ),
            child: ClipOval(
              child: chat.avatarUrl != null
                  ? Image.network(
                      chat.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(),
                    )
                  : _buildAvatarPlaceholder(),
            ),
          ),
          
          // Type indicator badge (bottom right)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: NeoColors.card,
                border: Border.all(color: NeoColors.card, width: 2),
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getBadgeColor(),
                ),
                child: Icon(
                  _getBadgeIcon(),
                  size: 10,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    IconData icon;
    switch (chat.type) {
      case ChatType.privateOneOnOne:
        icon = Icons.person;
        break;
      case ChatType.privateGroup:
        icon = Icons.group;
        break;
      case ChatType.publicRoomJoined:
        icon = Icons.people_outline;
        break;
    }

    return Icon(
      icon,
      color: Colors.white54,
      size: 28,
    );
  }

  IconData _getBadgeIcon() {
    switch (chat.type) {
      case ChatType.privateOneOnOne:
        return Icons.person;
      case ChatType.privateGroup:
        return Icons.group;
      case ChatType.publicRoomJoined:
        return Icons.tag;
    }
  }

  Color _getBadgeColor() {
    switch (chat.type) {
      case ChatType.privateOneOnOne:
        return NeoColors.accent;
      case ChatType.privateGroup:
        return const Color(0xFF8B5CF6); // Purple
      case ChatType.publicRoomJoined:
        return const Color(0xFFF59E0B); // Amber
    }
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
