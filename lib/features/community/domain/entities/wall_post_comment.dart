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

  /// Author's display name (community nickname)
  final String? authorDisplayName;

  const WallPostComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    this.authorDisplayName,
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
    String? authorDisplayName,
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
      authorDisplayName: authorDisplayName ?? this.authorDisplayName,
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
        authorDisplayName,
        authorAvatar,
        content,
        createdAt,
        likesCount,
        isLikedByCurrentUser,
      ];

  factory WallPostComment.fromSupabase(Map<String, dynamic> json, String? currentUserId) {
    // Author data is merged from local/global profile by repository
    final author = json['author'] as Map<String, dynamic>?;
    
    // Check user likes
    final userLikes = json['user_likes'] as List<dynamic>?;
    final isLikedByMe = currentUserId != null &&
        userLikes != null &&
        userLikes.any((like) => like['user_id'] == currentUserId);

    // Prioritize local identity: display_name (nickname) over username
    final displayName = author?['display_name'] as String?;
    final username = author?['username'] as String? ?? 'Usuario';
    
    // Prioritize local avatar over global avatar
    final localAvatar = author?['avatar_url'] as String?;
    final globalAvatar = author?['avatar_global_url'] as String?;

    return WallPostComment(
      id: json['id'] as String,
      postId: json['post_id'] as String? ?? '', // Often not joined, but fallback
      authorId: json['author_id'] as String,
      authorName: displayName ?? username,  // ✅ Prioritize nickname
      authorDisplayName: displayName,
      authorAvatar: localAvatar ?? globalAvatar,  // ✅ Prioritize local avatar
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      likesCount: json['likes_count'] as int? ?? 0,
      isLikedByCurrentUser: isLikedByMe,
    );
  }
}

