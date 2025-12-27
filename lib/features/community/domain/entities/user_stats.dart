/// Project Neo - User Stats Entity
///
/// Represents aggregated statistics for a user profile
library;

import 'package:equatable/equatable.dart';

class UserStats extends Equatable {
  /// Number of users following this user
  final int followersCount;
  
  /// Number of users this user is following
  final int followingCount;
  
  /// Number of wall posts on this user's profile
  final int wallPostsCount;

  const UserStats({
    this.followersCount = 0,
    this.followingCount = 0,
    this.wallPostsCount = 0,
  });

  @override
  List<Object?> get props => [followersCount, followingCount, wallPostsCount];
}
