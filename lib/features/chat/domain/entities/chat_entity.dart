import 'package:equatable/equatable.dart';

/// Enum representing different types of chats
enum ChatType {
  privateOneOnOne,
  privateGroup,
  publicRoomJoined,
}

/// Entity representing a chat conversation
class ChatEntity extends Equatable {
  final String id;
  final ChatType type;
  final String title;
  final List<ChatParticipant> participants;
  final ChatMessage? lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final String? avatarUrl;
  final bool isGroup;
  final String? communityId; // For public rooms
  final String? communityName; // For public rooms

  const ChatEntity({
    required this.id,
    required this.type,
    required this.title,
    required this.participants,
    this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.avatarUrl,
    required this.isGroup,
    this.communityId,
    this.communityName,
  });

  @override
  List<Object?> get props => [
        id,
        type,
        title,
        participants,
        lastMessage,
        lastMessageTime,
        unreadCount,
        avatarUrl,
        isGroup,
        communityId,
        communityName,
      ];
}

/// Entity representing a chat participant
class ChatParticipant extends Equatable {
  final String id;
  final String username;
  final String? avatarUrl;
  final bool isOnline;

  const ChatParticipant({
    required this.id,
    required this.username,
    this.avatarUrl,
    this.isOnline = false,
  });

  @override
  List<Object?> get props => [id, username, avatarUrl, isOnline];
}

/// Entity representing a chat message
class ChatMessage extends Equatable {
  final String id;
  final String senderId;
  final String senderUsername;
  final String content;
  final DateTime timestamp;
  final bool isRead;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderUsername,
    required this.content,
    required this.timestamp,
    this.isRead = false,
  });

  @override
  List<Object?> get props => [
        id,
        senderId,
        senderUsername,
        content,
        timestamp,
        isRead,
      ];
}
