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

  const WallPostComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.content,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        postId,
        authorId,
        authorName,
        authorAvatar,
        content,
        createdAt,
      ];
}
