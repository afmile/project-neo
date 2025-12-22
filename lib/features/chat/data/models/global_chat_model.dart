import '../../domain/entities/global_chat_entity.dart';

/// Data model for GlobalChatEntity
class GlobalChatModel extends GlobalChatEntity {
  const GlobalChatModel({
    required super.id,
    required super.source,
    required super.title,
    super.communityId,
    super.communityName,
    super.lastMessage,
    required super.lastMessageTime,
    super.unreadCount,
    super.avatarUrl,
    super.isFavorite,
  });

  factory GlobalChatModel.fromJson(Map<String, dynamic> json) {
    return GlobalChatModel(
      id: json['id'] as String,
      source: ChatSource.values.firstWhere(
        (e) => e.toString() == 'ChatSource.${json['source']}',
      ),
      title: json['title'] as String,
      communityId: json['communityId'] as String?,
      communityName: json['communityName'] as String?,
      lastMessage: json['lastMessage'] != null
          ? GlobalChatMessageModel.fromJson(
              json['lastMessage'] as Map<String, dynamic>)
          : null,
      lastMessageTime: DateTime.parse(json['lastMessageTime'] as String),
      unreadCount: json['unreadCount'] as int? ?? 0,
      avatarUrl: json['avatarUrl'] as String?,
      isFavorite: json['isFavorite'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'source': source.toString().split('.').last,
      'title': title,
      'communityId': communityId,
      'communityName': communityName,
      'lastMessage': lastMessage != null
          ? (lastMessage as GlobalChatMessageModel).toJson()
          : null,
      'lastMessageTime': lastMessageTime.toIso8601String(),
      'unreadCount': unreadCount,
      'avatarUrl': avatarUrl,
      'isFavorite': isFavorite,
    };
  }
}

/// Data model for GlobalChatMessage
class GlobalChatMessageModel extends GlobalChatMessage {
  const GlobalChatMessageModel({
    required super.id,
    required super.senderId,
    required super.senderName,
    required super.content,
    required super.timestamp,
    super.isRead,
  });

  factory GlobalChatMessageModel.fromJson(Map<String, dynamic> json) {
    return GlobalChatMessageModel(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }
}
