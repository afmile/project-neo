/// Project Neo - Community Follow Entity
///
/// Represents a follow relationship within a community
library;

import 'package:equatable/equatable.dart';

class CommunityFollow extends Equatable {
  final String id;
  final String communityId;
  final String followerId;
  final String followedId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CommunityFollow({
    required this.id,
    required this.communityId,
    required this.followerId,
    required this.followedId,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        communityId,
        followerId,
        followedId,
        isActive,
        createdAt,
        updatedAt,
      ];
}
