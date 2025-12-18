/// Project Neo - Post Model
///
/// Supabase data model for community posts.
library;

import '../../domain/entities/post_entity.dart';

/// Post data model for Supabase
class PostModel extends PostEntity {
  const PostModel({
    required super.id,
    required super.communityId,
    required super.authorId,
    super.authorUsername,
    super.authorAvatarUrl,
    super.title,
    super.content,
    super.richContent,
    super.isPinned,
    super.pinSize,
    super.mediaUrls,
    super.reactionsCount,
    super.commentsCount,
    required super.createdAt,
    required super.updatedAt,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    // Parse rich content if present
    List<RichTextBlock>? richContent;
    if (json['content_rich'] != null) {
      final richJson = json['content_rich'] as List<dynamic>;
      richContent = richJson
          .map((b) => RichTextBlock.fromJson(b as Map<String, dynamic>))
          .toList();
    }

    // Parse author info if joined
    final author = json['author'] as Map<String, dynamic>?;

    return PostModel(
      id: json['id'] as String,
      communityId: json['community_id'] as String,
      authorId: json['author_id'] as String,
      authorUsername: author?['username'] as String?,
      authorAvatarUrl: author?['avatar_global_url'] as String?,
      title: json['title'] as String?,
      content: json['content'] as String?,
      richContent: richContent,
      isPinned: json['is_pinned'] as bool? ?? false,
      pinSize: _parsePinSize(json['pin_size'] as String?),
      mediaUrls: (json['media_urls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      reactionsCount: json['reactions_count'] as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String? ?? json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'community_id': communityId,
    'author_id': authorId,
    'title': title,
    'content': content,
    'content_rich': richContent?.map((b) => b.toJson()).toList(),
    'is_pinned': isPinned,
    'pin_size': pinSize.name,
    'media_urls': mediaUrls,
  };

  /// For creating new post
  Map<String, dynamic> toInsertJson() => {
    'community_id': communityId,
    'author_id': authorId,
    'title': title,
    'content': content,
    'content_rich': richContent?.map((b) => b.toJson()).toList(),
    'media_urls': mediaUrls,
  };

  static PinSize _parsePinSize(String? size) {
    switch (size) {
      case 'large':
        return PinSize.large;
      case 'hero':
        return PinSize.hero;
      default:
        return PinSize.normal;
    }
  }
}
