/// Project Neo - Title Request Entity
///
/// Represents a member's request for a custom title
library;

import 'package:equatable/equatable.dart';

/// Status of a title request
enum TitleRequestStatus {
  pending,
  approved,
  rejected;

  String toJson() => name;

  static TitleRequestStatus fromJson(String value) {
    return TitleRequestStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TitleRequestStatus.pending,
    );
  }
}

/// Title Request Entity
class TitleRequest extends Equatable {
  final String id;
  final String communityId;
  final String memberUserId;
  final String titleText;
  final String textColor;
  final String backgroundColor;
  final TitleRequestStatus status;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TitleRequest({
    required this.id,
    required this.communityId,
    required this.memberUserId,
    required this.titleText,
    required this.textColor,
    required this.backgroundColor,
    required this.status,
    this.reviewedBy,
    this.reviewedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if request is pending
  bool get isPending => status == TitleRequestStatus.pending;

  /// Check if request is approved
  bool get isApproved => status == TitleRequestStatus.approved;

  /// Check if request is rejected
  bool get isRejected => status == TitleRequestStatus.rejected;

  /// Check if request has been reviewed
  bool get isReviewed => reviewedBy != null && reviewedAt != null;

  @override
  List<Object?> get props => [
        id,
        communityId,
        memberUserId,
        titleText,
        textColor,
        backgroundColor,
        status,
        reviewedBy,
        reviewedAt,
        createdAt,
        updatedAt,
      ];
}
