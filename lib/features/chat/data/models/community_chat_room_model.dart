import '../../domain/entities/community_chat_room_entity.dart';

/// Data model for CommunityChatRoomEntity
class CommunityChatRoomModel extends CommunityChatRoomEntity {
  const CommunityChatRoomModel({
    required super.id,
    required super.communityId,
    required super.type,
    required super.title,
    super.description,
    required super.memberCount,
    super.lastMessage,
    required super.lastMessageTime,
    super.lastUserActivity,
    super.unreadCount,
    super.isPinned,
    super.pinnedOrder,
    super.isFavorite,
    super.avatarUrl,
  });

  factory CommunityChatRoomModel.fromJson(Map<String, dynamic> json) {
    return CommunityChatRoomModel(
      id: json['id'] as String,
      communityId: json['communityId'] as String,
      type: RoomType.values.firstWhere(
        (e) => e.toString() == 'RoomType.${json['type']}',
      ),
      title: json['title'] as String,
      description: json['description'] as String?,
      memberCount: json['memberCount'] as int,
      lastMessage: json['lastMessage'] != null
          ? RoomMessageModel.fromJson(
              json['lastMessage'] as Map<String, dynamic>)
          : null,
      lastMessageTime: DateTime.parse(json['lastMessageTime'] as String),
      lastUserActivity: json['lastUserActivity'] != null
          ? DateTime.parse(json['lastUserActivity'] as String)
          : null,
      unreadCount: json['unreadCount'] as int? ?? 0,
      isPinned: json['isPinned'] as bool? ?? false,
      pinnedOrder: json['pinnedOrder'] as int?,
      isFavorite: json['isFavorite'] as bool? ?? false,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'communityId': communityId,
      'type': type.toString().split('.').last,
      'title': title,
      'description': description,
      'memberCount': memberCount,
      'lastMessage': lastMessage != null
          ? (lastMessage as RoomMessageModel).toJson()
          : null,
      'lastMessageTime': lastMessageTime.toIso8601String(),
      'lastUserActivity': lastUserActivity?.toIso8601String(),
      'unreadCount': unreadCount,
      'isPinned': isPinned,
      'pinnedOrder': pinnedOrder,
      'isFavorite': isFavorite,
      'avatarUrl': avatarUrl,
    };
  }
}

/// Data model for RoomMessage
class RoomMessageModel extends RoomMessage {
  const RoomMessageModel({
    required super.id,
    required super.senderId,
    required super.senderName,
    required super.content,
    required super.timestamp,
    super.isRead,
  });

  factory RoomMessageModel.fromJson(Map<String, dynamic> json) {
    return RoomMessageModel(
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
