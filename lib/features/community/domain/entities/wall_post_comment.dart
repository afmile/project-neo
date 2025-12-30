/// Project Neo - Wall Post Comment Entity
///
/// Represents a comment on a wall post
library;

import 'package:equatable/equatable.dart';

class WallPostComment extends Equatable {
  /// Unique comment ID
  final String id;
  
  /// Post ID this comment belongs to
  final String postId;
  
  /// Author's user ID
  final String authorId;
  
  /// Author's display name
  final String authorName;
  
  /// Author's avatar URL
  final String? authorAvatar;
  
  /// Comment content
  final String content;
  
  /// When the comment was created
  final DateTime createdAt;
  
  /// Number of likes on this comment
  final int likesCount;
  
  /// Whether the current user has liked this comment
  final bool isLikedByCurrentUser;

  const WallPostComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.content,
    required this.createdAt,
    this.likesCount = 0,
    this.isLikedByCurrentUser = false,
  });

  WallPostComment copyWith({
    String? id,
    String? postId,
    String? authorId,
    String? authorName,
    String? authorAvatar,
    String? content,
    DateTime? createdAt,
    int? likesCount,
    bool? isLikedByCurrentUser,
  }) {
    return WallPostComment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      likesCount: likesCount ?? this.likesCount,
      isLikedByCurrentUser: isLikedByCurrentUser ?? this.isLikedByCurrentUser,
    );
  }

  @override
  List<Object?> get props => [
        id,
        postId,
        authorId,
        authorName,
        authorAvatar,
        content,
        createdAt,
        likesCount,
        isLikedByCurrentUser,
      ];
}

