/// Project Neo - Friendship Request Entity
///
/// Represents a friendship request between two users in a community
library;

import 'package:equatable/equatable.dart';

enum FriendshipStatus { pending, accepted, rejected }

class FriendshipRequest extends Equatable {
  final String id;
  final String communityId;
  final String requesterId;
  final String recipientId;
  final FriendshipStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  // Requester info (from join)
  final String? requesterName;
  final String? requesterAvatar;

  // Recipient info (from join)
  final String? recipientName;
  final String? recipientAvatar;

  const FriendshipRequest({
    required this.id,
    required this.communityId,
    required this.requesterId,
    required this.recipientId,
    required this.status,
    required this.createdAt,
    this.respondedAt,
    this.requesterName,
    this.requesterAvatar,
    this.recipientName,
    this.recipientAvatar,
  });

  bool get isPending => status == FriendshipStatus.pending;
  bool get isAccepted => status == FriendshipStatus.accepted;
  bool get isRejected => status == FriendshipStatus.rejected;

  @override
  List<Object?> get props => [
    id, communityId, requesterId, recipientId, 
    status, createdAt, respondedAt,
  ];
}
