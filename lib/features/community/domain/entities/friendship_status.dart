/// Project Neo - Friendship Status
///
/// Defines the relationship status between two users
library;

/// Friendship status based on mutual following
enum FriendshipStatus {
  /// User is not following the other user
  notFollowing,
  
  /// User is following them, but they don't follow back
  followingThem,
  
  /// Mutual following - they are friends
  friends,
}

extension FriendshipStatusExtension on FriendshipStatus {
  /// Get button text for this status
  String get buttonText {
    switch (this) {
      case FriendshipStatus.notFollowing:
        return 'Seguir';
      case FriendshipStatus.followingThem:
        return 'Siguiendo';
      case FriendshipStatus.friends:
        return 'Amig@s';
    }
  }
  
  /// Whether this status represents a friendship
  bool get isFriend => this == FriendshipStatus.friends;
}
