/// Project Neo - Comment Entity
///
/// Represents a comment on a community post with nested reply support.
library;

import 'package:equatable/equatable.dart';

/// Comment entity for post discussions
class CommentEntity extends Equatable {
  final String id;
  final String postId;
  final String authorId;
  final String? authorUsername;
  final String? authorAvatarUrl;
  final String? parentId;
  final String content;
  final bool isEdited;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  /// Nested replies (loaded separately)
  final List<CommentEntity>? replies;

  const CommentEntity({
    required this.id,
    required this.postId,
    required this.authorId,
    this.authorUsername,
    this.authorAvatarUrl,
    this.parentId,
    required this.content,
    this.isEdited = false,
    required this.createdAt,
    required this.updatedAt,
    this.replies,
  });
  
  /// Check if this is a reply to another comment
  bool get isReply => parentId != null;
  
  /// CopyWith for updates
  CommentEntity copyWith({
    String? id,
    String? postId,
    String? authorId,
    String? authorUsername,
    String? authorAvatarUrl,
    String? parentId,
    String? content,
    bool? isEdited,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<CommentEntity>? replies,
  }) {
    return CommentEntity(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      authorId: authorId ?? this.authorId,
      authorUsername: authorUsername ?? this.authorUsername,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      parentId: parentId ?? this.parentId,
      content: content ?? this.content,
      isEdited: isEdited ?? this.isEdited,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      replies: replies ?? this.replies,
    );
  }

  @override
  List<Object?> get props => [
    id, postId, authorId, parentId, content, 
    isEdited, createdAt, updatedAt, replies,
  ];
}
