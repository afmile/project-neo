/// Project Neo - Community Notification Entity
///
/// Represents a notification in a community inbox
library;

import 'package:equatable/equatable.dart';

enum NotificationType {
  friendshipRequest,
  follow,
  wallPostLike,
  commentLike,
  comment,
  mention,
  modAction,
  system,
  announcement,
  roleInvitation, // ✅ New type
}

enum NotificationActionStatus {
  pending,
  accepted,
  rejected,
  revoked, // Added revoked status just in case
}

class CommunityNotification extends Equatable {
  final String id;
  final String communityId;
  final String recipientId;
  final String? actorId;
  final NotificationType type;
  final String? entityType;
  final String? entityId;
  final String title;
  final String? body;
  final Map<String, dynamic> data;
  final NotificationActionStatus? actionStatus;
  final DateTime createdAt;
  final DateTime? readAt;

  // Actor info (from join)
  final String? actorName;
  final String? actorAvatar;

  const CommunityNotification({
    required this.id,
    required this.communityId,
    required this.recipientId,
    this.actorId,
    required this.type,
    this.entityType,
    this.entityId,
    required this.title,
    this.body,
    required this.data,
    this.actionStatus,
    required this.createdAt,
    this.readAt,
    this.actorName,
    this.actorAvatar,
  });

  bool get isRead => readAt != null;
  bool get isUnread => readAt == null;
  bool get isActionable => actionStatus == NotificationActionStatus.pending;
  bool get isFriendshipRequest => type == NotificationType.friendshipRequest;
  bool get isRoleInvitation => type == NotificationType.roleInvitation; // ✅ New getter

  CommunityNotification copyWith({
    String? id,
    String? communityId,
    String? recipientId,
    String? actorId,
    NotificationType? type,
    String? entityType,
    String? entityId,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    NotificationActionStatus? actionStatus,
    DateTime? createdAt,
    DateTime? readAt,
    String? actorName,
    String? actorAvatar,
  }) {
    return CommunityNotification(
      id: id ?? this.id,
      communityId: communityId ?? this.communityId,
      recipientId: recipientId ?? this.recipientId,
      actorId: actorId ?? this.actorId,
      type: type ?? this.type,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      actionStatus: actionStatus ?? this.actionStatus,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      actorName: actorName ?? this.actorName,
      actorAvatar: actorAvatar ?? this.actorAvatar,
    );
  }

  @override
  List<Object?> get props => [
    id, communityId, recipientId, actorId, type, 
    entityType, entityId, title, body, createdAt, readAt,
  ];
}
