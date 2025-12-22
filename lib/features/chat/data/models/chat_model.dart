import '../../domain/entities/chat_entity.dart';

/// Data model for ChatEntity with JSON serialization
class ChatModel extends ChatEntity {
  const ChatModel({
    required super.id,
    required super.type,
    required super.title,
    required super.participants,
    super.lastMessage,
    required super.lastMessageTime,
    super.unreadCount,
    super.avatarUrl,
    required super.isGroup,
    super.communityId,
    super.communityName,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id'] as String,
      type: ChatType.values.firstWhere(
        (e) => e.toString() == 'ChatType.${json['type']}',
      ),
      title: json['title'] as String,
      participants: (json['participants'] as List)
          .map((p) => ChatParticipantModel.fromJson(p as Map<String, dynamic>))
          .toList(),
      lastMessage: json['lastMessage'] != null
          ? ChatMessageModel.fromJson(json['lastMessage'] as Map<String, dynamic>)
          : null,
      lastMessageTime: DateTime.parse(json['lastMessageTime'] as String),
      unreadCount: json['unreadCount'] as int? ?? 0,
      avatarUrl: json['avatarUrl'] as String?,
      isGroup: json['isGroup'] as bool,
      communityId: json['communityId'] as String?,
      communityName: json['communityName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'title': title,
      'participants': participants.map((p) => (p as ChatParticipantModel).toJson()).toList(),
      'lastMessage': lastMessage != null ? (lastMessage as ChatMessageModel).toJson() : null,
      'lastMessageTime': lastMessageTime.toIso8601String(),
      'unreadCount': unreadCount,
      'avatarUrl': avatarUrl,
      'isGroup': isGroup,
      'communityId': communityId,
      'communityName': communityName,
    };
  }
}

/// Data model for ChatParticipant with JSON serialization
class ChatParticipantModel extends ChatParticipant {
  const ChatParticipantModel({
    required super.id,
    required super.username,
    super.avatarUrl,
    super.isOnline,
  });

  factory ChatParticipantModel.fromJson(Map<String, dynamic> json) {
    return ChatParticipantModel(
      id: json['id'] as String,
      username: json['username'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      isOnline: json['isOnline'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'avatarUrl': avatarUrl,
      'isOnline': isOnline,
    };
  }
}

/// Data model for ChatMessage with JSON serialization
class ChatMessageModel extends ChatMessage {
  const ChatMessageModel({
    required super.id,
    required super.senderId,
    required super.senderUsername,
    required super.content,
    required super.timestamp,
    super.isRead,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      senderUsername: json['senderUsername'] as String,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderUsername': senderUsername,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }
}
