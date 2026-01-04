/// Project Neo - Strike Entity
///
/// Represents a moderation strike assigned to a user
library;

import 'package:equatable/equatable.dart';

enum StrikeStatus {
  active,
  appealed,
  revoked,
}

class Strike extends Equatable {
  final String id;
  final String communityId;
  final String userId;
  final String moderatorId;
  final String reason;
  final String? contentType;
  final String? contentId;
  final StrikeStatus status;
  final DateTime createdAt;
  final DateTime? revokedAt;
  final String? revokedBy;
  final String? revokeReason;

  const Strike({
    required this.id,
    required this.communityId,
    required this.userId,
    required this.moderatorId,
    required this.reason,
    this.contentType,
    this.contentId,
    required this.status,
    required this.createdAt,
    this.revokedAt,
    this.revokedBy,
    this.revokeReason,
  });

  @override
  List<Object?> get props => [
        id,
        communityId,
        userId,
        moderatorId,
        reason,
        contentType,
        contentId,
        status,
        createdAt,
        revokedAt,
        revokedBy,
        revokeReason,
      ];

  Strike copyWith({
    String? id,
    String? communityId,
    String? userId,
    String? moderatorId,
    String? reason,
    String? contentType,
    String? contentId,
    StrikeStatus? status,
    DateTime? createdAt,
    DateTime? revokedAt,
    String? revokedBy,
    String? revokeReason,
  }) {
    return Strike(
      id: id ?? this.id,
      communityId: communityId ?? this.communityId,
      userId: userId ?? this.userId,
      moderatorId: moderatorId ?? this.moderatorId,
      reason: reason ?? this.reason,
      contentType: contentType ?? this.contentType,
      contentId: contentId ?? this.contentId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      revokedAt: revokedAt ?? this.revokedAt,
      revokedBy: revokedBy ?? this.revokedBy,
      revokeReason: revokeReason ?? this.revokeReason,
    );
  }
}
