import 'package:equatable/equatable.dart';

/// Source type for global chats
enum ChatSource {
  support,        // Chat with Neo support team
  moderator,      // Chat with app moderator
  communityFavorite, // Favorited chat from a community
}

/// Entity representing a chat in the global inbox
class GlobalChatEntity extends Equatable {
  final String id;
  final ChatSource source;
  final String title;
  final String? communityId;    // For community favorites
  final String? communityName;  // For community favorites
  final GlobalChatMessage? lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final String? avatarUrl;
  final bool isFavorite; // Always true in global inbox view

  const GlobalChatEntity({
    required this.id,
    required this.source,
    required this.title,
    this.communityId,
    this.communityName,
    this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.avatarUrl,
    this.isFavorite = true,
  });

  @override
  List<Object?> get props => [
        id,
        source,
        title,
        communityId,
        communityName,
        lastMessage,
        lastMessageTime,
        unreadCount,
        avatarUrl,
        isFavorite,
      ];
}

/// Message entity for global chats
class GlobalChatMessage extends Equatable {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final bool isRead;

  const GlobalChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    this.isRead = false,
  });

  @override
  List<Object?> get props => [
        id,
        senderId,
        senderName,
        content,
        timestamp,
        isRead,
      ];
}
