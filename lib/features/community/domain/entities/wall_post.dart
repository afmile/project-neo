/// Project Neo - Wall Post Entity
///
/// Represents a post on a user's community wall
library;

import 'package:equatable/equatable.dart';

/// Privacy levels for wall posts
enum WallPrivacyLevel {
  /// Anyone can post
  public,
  
  /// Only mutual friends can post
  friendsOnly,
  
  /// Only the profile owner can post
  closed,
}

class WallPost extends Equatable {
  /// Unique post ID
  final String id;

  /// Community ID this post belongs to
  final String communityId;
  
  /// Author's user ID
  final String authorId;
  
  /// Author's display name
  final String authorName;
  
  /// Author's avatar URL
  final String? authorAvatar;
  
  /// Post content/message
  final String content;
  
  /// When the post was created
  final DateTime timestamp;
  
  /// Number of likes
  final int likes;
  
  /// Whether current user has liked this post
  final bool isLikedByCurrentUser;
  
  /// Number of comments on this post
  final int commentsCount;

  const WallPost({
    required this.id,
    required this.communityId,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.content,
    required this.timestamp,
    this.likes = 0,
    this.isLikedByCurrentUser = false,
    this.commentsCount = 0,
  });

  WallPost copyWith({
    String? id,
    String? communityId,
    String? authorId,
    String? authorName,
    String? authorAvatar,
    String? content,
    DateTime? timestamp,
    int? likes,
    bool? isLikedByCurrentUser,
    int? commentsCount,
  }) {
    return WallPost(
      id: id ?? this.id,
      communityId: communityId ?? this.communityId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      likes: likes ?? this.likes,
      isLikedByCurrentUser: isLikedByCurrentUser ?? this.isLikedByCurrentUser,
      commentsCount: commentsCount ?? this.commentsCount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        communityId,
        authorId,
        authorName,
        authorAvatar,
        content,
        timestamp,
        likes,
        isLikedByCurrentUser,
        commentsCount,
      ];
}
