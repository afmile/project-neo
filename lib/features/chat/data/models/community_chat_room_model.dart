import '../../domain/entities/community_chat_room_entity.dart';

/// Data model for CommunityChatRoomEntity
class CommunityChatRoomModel extends CommunityChatRoomEntity {
  const CommunityChatRoomModel({
    required super.id,
    required super.communityId,
    super.creatorId,
    super.creatorAvatarUrl,
    required super.type,
    required super.title,
    super.description,
    super.iconUrl,
    super.backgroundImageUrl,
    required super.memberCount,
    super.lastMessage,
    required super.lastMessageTime,
    super.lastUserActivity,
    super.unreadCount,
    super.isPinned,
    super.pinnedOrder,
    super.isFavorite,
    super.avatarUrl,
    super.createdAt,
    super.voiceEnabled,
    super.videoEnabled,
    super.projectionEnabled,
  });

  /// Factory to parse from legacy JSON format (camelCase)
  factory CommunityChatRoomModel.fromJson(Map<String, dynamic> json) {
    return CommunityChatRoomModel(
      id: json['id'] as String,
      communityId: json['communityId'] as String,
      creatorId: json['creatorId'] as String?,
      type: RoomType.values.firstWhere(
        (e) => e.toString() == 'RoomType.${json['type']}',
        orElse: () => RoomType.public,
      ),
      title: json['title'] as String,
      description: json['description'] as String?,
      iconUrl: json['iconUrl'] as String?,
      backgroundImageUrl: json['backgroundImageUrl'] as String?,
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
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      voiceEnabled: json['voiceEnabled'] as bool? ?? false,
      videoEnabled: json['videoEnabled'] as bool? ?? false,
      projectionEnabled: json['projectionEnabled'] as bool? ?? false,
    );
  }

  /// Factory to parse from Supabase response (snake_case)
  factory CommunityChatRoomModel.fromSupabaseJson(Map<String, dynamic> json) {
    // Extract creator avatar from joined data
    String? creatorAvatarUrl;
    if (json['creator'] != null && json['creator'] is Map) {
      creatorAvatarUrl = json['creator']['avatar_url'] as String?;
    }

    return CommunityChatRoomModel(
      id: json['id'] as String,
      communityId: json['community_id'] as String,
      creatorId: json['creator_id'] as String?,
      creatorAvatarUrl: creatorAvatarUrl,
      type: RoomType.public, // All rooms from Supabase are public for now
      title: json['title'] as String,
      description: json['description'] as String?,
      iconUrl: json['icon_url'] as String?,
      backgroundImageUrl: json['background_image_url'] as String?,
      memberCount: json['member_count'] as int? ?? 0,
      lastMessage: null, // Will be populated separately if needed
      lastMessageTime: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      lastUserActivity: null,
      unreadCount: 0,
      isPinned: json['is_pinned'] as bool? ?? false,
      pinnedOrder: json['pinned_order'] as int?,
      isFavorite: false,
      avatarUrl: json['icon_url'] as String?, // Use icon as avatar for grid
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      voiceEnabled: json['voice_enabled'] as bool? ?? false,
      videoEnabled: json['video_enabled'] as bool? ?? false,
      projectionEnabled: json['projection_enabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'communityId': communityId,
      'creatorId': creatorId,
      'type': type.toString().split('.').last,
      'title': title,
      'description': description,
      'iconUrl': iconUrl,
      'backgroundImageUrl': backgroundImageUrl,
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
      'createdAt': createdAt?.toIso8601String(),
      'voiceEnabled': voiceEnabled,
      'videoEnabled': videoEnabled,
      'projectionEnabled': projectionEnabled,
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

