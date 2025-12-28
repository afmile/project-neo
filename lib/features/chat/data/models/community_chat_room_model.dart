import '../../domain/entities/community_chat_room_entity.dart';
import '../../../../core/supabase/schema/schema.dart';

/// Data model for CommunityChatRoomEntity
class CommunityChatRoomModel extends CommunityChatRoomEntity {
  const CommunityChatRoomModel({
    required super.id,
    required super.communityId,
    super.ownerId,
    super.ownerAvatarUrl,
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

  // ═══════════════════════════════════════════════════════════════════════════
  // JSON PARSING - IMPORTANT: Use the correct method for your data source!
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Parse from INTERNAL app JSON (camelCase keys)
  /// 
  /// Use for: local storage, cache, tests, internal serialization
  /// Keys: ownerId, communityId, iconUrl, isPinned, etc.
  /// 
  /// Example:
  /// ```dart
  /// final room = CommunityChatRoomModel.fromJson(localCache);
  /// ```
  factory CommunityChatRoomModel.fromJson(Map<String, dynamic> json) {
    return CommunityChatRoomModel(
      id: json['id'] as String,
      communityId: json['communityId'] as String,
      ownerId: json['ownerId'] as String?,
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

  /// Parse from SUPABASE database response (snake_case keys via schema constants)
  /// 
  /// Use for: Direct Supabase queries, real-time subscriptions
  /// Keys: Use ChatChannelsSchema.* and UsersGlobalSchema.* constants ONLY
  ///       - ChatChannelsSchema.ownerId → 'owner_id'
  ///       - ChatChannelsSchema.communityId → 'community_id'
  ///       - etc.
  /// 
  /// CRITICAL: NEVER use string literals like 'owner_id' directly!
  /// Always use schema constants to prevent column name mismatches.
  /// 
  /// Example:
  /// ```dart
  /// final room = CommunityChatRoomModel.fromSupabaseJson(supabaseResponse);
  /// ```
  factory CommunityChatRoomModel.fromSupabaseJson(Map<String, dynamic> json) {
    // Extract owner avatar from joined data
    String? ownerAvatarUrl;
    if (json['owner'] != null && json['owner'] is Map) {
      ownerAvatarUrl = json['owner'][UsersGlobalSchema.avatarGlobalUrl] as String?;
    }

    return CommunityChatRoomModel(
      id: json[ChatChannelsSchema.id] as String,
      communityId: json[ChatChannelsSchema.communityId] as String,
      ownerId: json[ChatChannelsSchema.ownerId] as String?,
      ownerAvatarUrl: ownerAvatarUrl,
      type: RoomType.public, // All rooms from Supabase are public for now
      title: json[ChatChannelsSchema.title] as String,
      description: json[ChatChannelsSchema.description] as String?,
      iconUrl: json[ChatChannelsSchema.iconUrl] as String?,
      backgroundImageUrl: json[ChatChannelsSchema.backgroundImageUrl] as String?,
      memberCount: 0, // Column doesn't exist in DB
      lastMessage: null, // Will be populated separately if needed
      lastMessageTime: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      lastUserActivity: null,
      unreadCount: 0,
      isPinned: json[ChatChannelsSchema.isPinned] as bool? ?? false,
      pinnedOrder: json[ChatChannelsSchema.pinnedOrder] as int?,
      isFavorite: false,
      avatarUrl: json[ChatChannelsSchema.iconUrl] as String?, // Use icon as avatar for grid
      createdAt: json[ChatChannelsSchema.createdAt] != null
          ? DateTime.parse(json[ChatChannelsSchema.createdAt] as String)
          : null,
      voiceEnabled: json[ChatChannelsSchema.voiceEnabled] as bool? ?? false,
      videoEnabled: json[ChatChannelsSchema.videoEnabled] as bool? ?? false,
      projectionEnabled: json[ChatChannelsSchema.projectionEnabled] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'communityId': communityId,
      'ownerId': ownerId,
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

