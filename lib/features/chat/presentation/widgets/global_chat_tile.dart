import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/neo_theme.dart';
import '../../domain/entities/global_chat_entity.dart';

class GlobalChatTile extends StatelessWidget {
  final GlobalChatEntity chat;
  final VoidCallback onTap;

  const GlobalChatTile({
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
            // Leading: Avatar with source badge
            _buildAvatar(),
            const SizedBox(width: NeoSpacing.md),
            
            // Content
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
                  
                  // Community name for favorites
                  if (chat.source == ChatSource.communityFavorite &&
                      chat.communityName != null) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 14,
                          color: NeoColors.accent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          chat.communityName!,
                          style: NeoTextStyles.labelSmall.copyWith(
                            color: NeoColors.accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                  ],
                  
                  // Last message
                  if (chat.lastMessage != null)
                    Text(
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
                ],
              ),
            ),
            
            const SizedBox(width: NeoSpacing.sm),
            
            // Trailing: Time and unread badge
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
          
          // Source badge (bottom right)
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
    switch (chat.source) {
      case ChatSource.support:
        icon = Icons.support_agent_rounded;
        break;
      case ChatSource.moderator:
        icon = Icons.shield_rounded;
        break;
      case ChatSource.communityFavorite:
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
    switch (chat.source) {
      case ChatSource.support:
        return Icons.support_agent;
      case ChatSource.moderator:
        return Icons.shield;
      case ChatSource.communityFavorite:
        return Icons.star;
    }
  }

  Color _getBadgeColor() {
    switch (chat.source) {
      case ChatSource.support:
        return const Color(0xFF10B981); // Green
      case ChatSource.moderator:
        return const Color(0xFF3B82F6); // Blue
      case ChatSource.communityFavorite:
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
