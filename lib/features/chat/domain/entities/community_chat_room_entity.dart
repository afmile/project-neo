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
  final RoomType type;
  final String title;
  final String? description;
  final int memberCount;
  final RoomMessage? lastMessage;
  final DateTime lastMessageTime;
  final DateTime? lastUserActivity; // Last time current user sent a message
  final int unreadCount;
  final bool isPinned;
  final int? pinnedOrder; // Order in pinned section (0-based)
  final bool isFavorite;  // Shown in global inbox
  final String? avatarUrl;

  const CommunityChatRoomEntity({
    required this.id,
    required this.communityId,
    required this.type,
    required this.title,
    this.description,
    required this.memberCount,
    this.lastMessage,
    required this.lastMessageTime,
    this.lastUserActivity,
    this.unreadCount = 0,
    this.isPinned = false,
    this.pinnedOrder,
    this.isFavorite = false,
    this.avatarUrl,
  });

  CommunityChatRoomEntity copyWith({
    String? id,
    String? communityId,
    RoomType? type,
    String? title,
    String? description,
    int? memberCount,
    RoomMessage? lastMessage,
    DateTime? lastMessageTime,
    DateTime? lastUserActivity,
    int? unreadCount,
    bool? isPinned,
    int? pinnedOrder,
    bool? isFavorite,
    String? avatarUrl,
  }) {
    return CommunityChatRoomEntity(
      id: id ?? this.id,
      communityId: communityId ?? this.communityId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      memberCount: memberCount ?? this.memberCount,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastUserActivity: lastUserActivity ?? this.lastUserActivity,
      unreadCount: unreadCount ?? this.unreadCount,
      isPinned: isPinned ?? this.isPinned,
      pinnedOrder: pinnedOrder ?? this.pinnedOrder,
      isFavorite: isFavorite ?? this.isFavorite,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  @override
  List<Object?> get props => [
        id,
        communityId,
        type,
        title,
        description,
        memberCount,
        lastMessage,
        lastMessageTime,
        lastUserActivity,
        unreadCount,
        isPinned,
        pinnedOrder,
        isFavorite,
        avatarUrl,
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
