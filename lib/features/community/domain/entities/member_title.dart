/// Project Neo - Member Title Entity
///
/// Represents a title assigned to a specific member in a community
library;

import 'package:equatable/equatable.dart';
import 'community_title.dart';

/// Member Title (assignment of a title to a user)
class MemberTitle extends Equatable {
  final String id;
  final String communityId;
  final String memberUserId;
  final CommunityTitle title;
  final String assignedBy;
  final DateTime assignedAt;
  final DateTime? expiresAt;
  final bool isActive;
  final int sortOrder;
  final bool isVisible;

  const MemberTitle({
    required this.id,
    required this.communityId,
    required this.memberUserId,
    required this.title,
    required this.assignedBy,
    required this.assignedAt,
    this.expiresAt,
    this.isActive = true,
    this.sortOrder = 0,
    this.isVisible = true,
  });

  /// Check if this title is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Check if this title should be displayed
  bool get shouldDisplay => isActive && !isExpired && isVisible;

  @override
  List<Object?> get props => [
        id,
        communityId,
        memberUserId,
        title,
        assignedBy,
        assignedAt,
        expiresAt,
        isActive,
        sortOrder,
        isVisible,
      ];
}
