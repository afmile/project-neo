import 'package:equatable/equatable.dart';

/// Type of chat room in a community
enum RoomType {
  public,   // Public room visible to all community members
  private,  // Private room with invited members only
}

/// Entity representing a chat room within a community
class CommunityChatRoomEntity extends Equatable {
  final String id;
  final String communityId;
  final String? ownerId; // ID of user who owns the room
  final String? ownerAvatarUrl; // Creator's avatar URL
  final RoomType type;
  final String title;
  final String? description;
  final String? iconUrl; // Room icon (1:1 square)
  final String? backgroundImageUrl; // Background image (portrait)
  final int memberCount;
  final RoomMessage? lastMessage;
  final DateTime lastMessageTime;
  final DateTime? lastUserActivity; // Last time current user sent a message
  final int unreadCount;
  final bool isPinned;
  final int? pinnedOrder; // Order in pinned section (0-based)
  final bool isFavorite;  // Shown in global inbox
  final String? avatarUrl;
  final DateTime? createdAt;
  // LiveKit feature flags
  final bool voiceEnabled;
  final bool videoEnabled;
  final bool projectionEnabled;

  const CommunityChatRoomEntity({
    required this.id,
    required this.communityId,
    this.ownerId,
    this.ownerAvatarUrl,
    required this.type,
    required this.title,
    this.description,
    this.iconUrl,
    this.backgroundImageUrl,
    required this.memberCount,
    this.lastMessage,
    required this.lastMessageTime,
    this.lastUserActivity,
    this.unreadCount = 0,
    this.isPinned = false,
    this.pinnedOrder,
    this.isFavorite = false,
    this.avatarUrl,
    this.createdAt,
    this.voiceEnabled = false,
    this.videoEnabled = false,
    this.projectionEnabled = false,
  });

  CommunityChatRoomEntity copyWith({
    String? id,
    String? communityId,
    String? ownerId,
    String? ownerAvatarUrl,
    RoomType? type,
    String? title,
    String? description,
    String? iconUrl,
    String? backgroundImageUrl,
    int? memberCount,
    RoomMessage? lastMessage,
    DateTime? lastMessageTime,
    DateTime? lastUserActivity,
    int? unreadCount,
    bool? isPinned,
    int? pinnedOrder,
    bool? isFavorite,
    String? avatarUrl,
    DateTime? createdAt,
    bool? voiceEnabled,
    bool? videoEnabled,
    bool? projectionEnabled,
  }) {
    return CommunityChatRoomEntity(
      id: id ?? this.id,
      communityId: communityId ?? this.communityId,
      ownerId: ownerId ?? this.ownerId,
      ownerAvatarUrl: ownerAvatarUrl ?? this.ownerAvatarUrl,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      iconUrl: iconUrl ?? this.iconUrl,
      backgroundImageUrl: backgroundImageUrl ?? this.backgroundImageUrl,
      memberCount: memberCount ?? this.memberCount,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastUserActivity: lastUserActivity ?? this.lastUserActivity,
      unreadCount: unreadCount ?? this.unreadCount,
      isPinned: isPinned ?? this.isPinned,
      pinnedOrder: pinnedOrder ?? this.pinnedOrder,
      isFavorite: isFavorite ?? this.isFavorite,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      voiceEnabled: voiceEnabled ?? this.voiceEnabled,
      videoEnabled: videoEnabled ?? this.videoEnabled,
      projectionEnabled: projectionEnabled ?? this.projectionEnabled,
    );
  }

  @override
  List<Object?> get props => [
        id,
        communityId,
        ownerId,
        ownerAvatarUrl,
        type,
        title,
        description,
        iconUrl,
        backgroundImageUrl,
        memberCount,
        lastMessage,
        lastMessageTime,
        lastUserActivity,
        unreadCount,
        isPinned,
        pinnedOrder,
        isFavorite,
        avatarUrl,
        createdAt,
        voiceEnabled,
        videoEnabled,
        projectionEnabled,
      ];
}

/// Message entity for community chat rooms
class RoomMessage extends Equatable {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final bool isRead;

  const RoomMessage({
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
