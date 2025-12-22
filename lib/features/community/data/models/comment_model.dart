/// Project Neo - Comment Model
///
/// Supabase data model for post comments.
library;

import '../../domain/entities/comment_entity.dart';

/// Comment data model for Supabase
class CommentModel extends CommentEntity {
  const CommentModel({
    required super.id,
    required super.postId,
    required super.authorId,
    super.authorUsername,
    super.authorAvatarUrl,
    super.parentId,
    required super.content,
    super.isEdited,
    required super.createdAt,
    required super.updatedAt,
    super.replies,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    // Parse author info if joined
    final author = json['author'] as Map<String, dynamic>?;
    
    // Parse replies if present
    List<CommentEntity>? replies;
    if (json['replies'] != null) {
      final repliesJson = json['replies'] as List<dynamic>;
      replies = repliesJson
          .map((r) => CommentModel.fromJson(r as Map<String, dynamic>))
          .toList();
    }

    return CommentModel(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      authorId: json['author_id'] as String,
      authorUsername: author?['username'] as String?,
      authorAvatarUrl: author?['avatar_global_url'] as String?,
      parentId: json['parent_id'] as String?,
      content: json['content'] as String,
      isEdited: json['is_edited'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String? ?? json['created_at'] as String),
      replies: replies,
    );
  }

  Map<String, dynamic> toJson() => {
    'post_id': postId,
    'author_id': authorId,
    'parent_id': parentId,
    'content': content,
    'is_edited': isEdited,
  };

  /// For creating new comment
  Map<String, dynamic> toInsertJson() => {
    'post_id': postId,
    'author_id': authorId,
    'parent_id': parentId,
    'content': content,
  };
}
