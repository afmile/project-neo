/// Project Neo - Strike Model
///
/// Data model for strikes with JSON serialization
library;

import '../../domain/entities/strike_entity.dart';

class StrikeModel {
  final String id;
  final String communityId;
  final String userId;
  final String moderatorId;
  final String reason;
  final String? contentType;
  final String? contentId;
  final String status;
  final DateTime createdAt;
  final DateTime? revokedAt;
  final String? revokedBy;
  final String? revokeReason;

  const StrikeModel({
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

  factory StrikeModel.fromJson(Map<String, dynamic> json) {
    return StrikeModel(
      id: json['id'] as String,
      communityId: json['community_id'] as String,
      userId: json['user_id'] as String,
      moderatorId: json['moderator_id'] as String,
      reason: json['reason'] as String,
      contentType: json['content_type'] as String?,
      contentId: json['content_id'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      revokedAt: json['revoked_at'] != null
          ? DateTime.parse(json['revoked_at'] as String)
          : null,
      revokedBy: json['revoked_by'] as String?,
      revokeReason: json['revoke_reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'community_id': communityId,
      'user_id': userId,
      'moderator_id': moderatorId,
      'reason': reason,
      'content_type': contentType,
      'content_id': contentId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'revoked_at': revokedAt?.toIso8601String(),
      'revoked_by': revokedBy,
      'revoke_reason': revokeReason,
    };
  }

  Strike toEntity() {
    return Strike(
      id: id,
      communityId: communityId,
      userId: userId,
      moderatorId: moderatorId,
      reason: reason,
      contentType: contentType,
      contentId: contentId,
      status: _parseStatus(status),
      createdAt: createdAt,
      revokedAt: revokedAt,
      revokedBy: revokedBy,
      revokeReason: revokeReason,
    );
  }

  factory StrikeModel.fromEntity(Strike strike) {
    return StrikeModel(
      id: strike.id,
      communityId: strike.communityId,
      userId: strike.userId,
      moderatorId: strike.moderatorId,
      reason: strike.reason,
      contentType: strike.contentType,
      contentId: strike.contentId,
      status: _statusToString(strike.status),
      createdAt: strike.createdAt,
      revokedAt: strike.revokedAt,
      revokedBy: strike.revokedBy,
      revokeReason: strike.revokeReason,
    );
  }

  static StrikeStatus _parseStatus(String status) {
    switch (status) {
      case 'active':
        return StrikeStatus.active;
      case 'appealed':
        return StrikeStatus.appealed;
      case 'revoked':
        return StrikeStatus.revoked;
      default:
        return StrikeStatus.active;
    }
  }

  static String _statusToString(StrikeStatus status) {
    switch (status) {
      case StrikeStatus.active:
        return 'active';
      case StrikeStatus.appealed:
        return 'appealed';
      case StrikeStatus.revoked:
        return 'revoked';
    }
  }
}
