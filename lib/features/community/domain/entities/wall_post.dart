/// Project Neo - Wall Post Entity
///
/// Represents a post on a user's community wall
library;

import 'package:equatable/equatable.dart';
import '../../domain/entities/wall_post_comment.dart';

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

  /// Community ID this post belongs to (null if global profile post)
  final String? communityId;
  
  /// Author's user ID
  final String authorId;
  
  /// Author's display name (nickname in community)
  final String? authorDisplayName;

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

  /// First comment to display in feed (threaded visual)
  final WallPostComment? firstComment;
  
  /// Optional media URL (image or GIF)
  final String? mediaUrl;
  
  /// Media type ('image' or 'gif')
  final String? mediaType;

  const WallPost({
    required this.id,
    this.communityId,
    required this.authorId,
    required this.authorName,
    this.authorDisplayName,
    this.authorAvatar,
    required this.content,
    required this.timestamp,
    this.likes = 0,
    this.isLikedByCurrentUser = false,
    this.commentsCount = 0,
    this.firstComment,
    this.mediaUrl,
    this.mediaType,
  });

  WallPost copyWith({
    String? id,
    String? communityId,
    String? authorId,
    String? authorName,
    String? authorDisplayName,
    String? authorAvatar,
    String? content,
    DateTime? timestamp,
    int? likes,
    bool? isLikedByCurrentUser,
    int? commentsCount,
    WallPostComment? firstComment,
    String? mediaUrl,
    String? mediaType,
  }) {
    return WallPost(
      id: id ?? this.id,
      communityId: communityId ?? this.communityId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorDisplayName: authorDisplayName ?? this.authorDisplayName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      likes: likes ?? this.likes,
      isLikedByCurrentUser: isLikedByCurrentUser ?? this.isLikedByCurrentUser,
      commentsCount: commentsCount ?? this.commentsCount,
      firstComment: firstComment ?? this.firstComment,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
    );
  }

  @override
  List<Object?> get props => [
        id,
        communityId,
        authorId,
        authorName,
        authorDisplayName,
        authorAvatar,
        content,
        timestamp,
        likes,
        isLikedByCurrentUser,
        commentsCount,
        firstComment,
        mediaUrl,
        mediaType,
      ];
}
