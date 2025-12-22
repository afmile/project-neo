/// Project Neo - Post Model
///
/// Supabase data model for community posts with full type support.
library;

import '../../domain/entities/post_entity.dart';

class PostModel extends PostEntity {
  const PostModel({
    required super.id,
    required super.communityId,
    required super.authorId,
    super.authorUsername,
    super.authorAvatarUrl,
    super.postType,
    super.title,
    super.content,
    super.richContent,
    super.coverImageUrl,
    super.isPinned,
    super.pinSize,
    super.mediaUrls,
    super.reactionsCount,
    super.commentsCount,
    super.isLikedByCurrentUser,
    required super.createdAt,
    required super.updatedAt,
    super.pollOptions,
    super.selectedOptionId,
    super.moderationStatus,
    super.aiFlaggedReason,
  });

  /// Parse from Supabase JSON with user reaction status
  factory PostModel.fromJson(
    Map<String, dynamic> json, {
    String? currentUserId,
    List<Map<String, dynamic>>? userReactions,
    Map<String, dynamic>? pollVote,
  }) {
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
    
    // Parse poll options if present
    List<PollOption>? pollOptions;
    if (json['poll_options'] != null) {
      final optionsJson = json['poll_options'] as List<dynamic>;
      pollOptions = optionsJson
          .map((o) => PollOption.fromJson(o as Map<String, dynamic>))
          .toList();
    }
    
    // Check if current user has reacted
    bool isLiked = false;
    if (currentUserId != null && userReactions != null) {
      isLiked = userReactions.any((r) => 
        r['post_id'] == json['id'] && r['user_id'] == currentUserId);
    }
    // Also check if reaction data is embedded in the response
    if (json['user_reaction'] != null) {
      isLiked = true;
    }
    
    // Check poll vote
    String? selectedOptionId;
    if (pollVote != null) {
      selectedOptionId = pollVote['option_id'] as String?;
    }
    if (json['user_poll_vote'] != null) {
      selectedOptionId = json['user_poll_vote']['option_id'] as String?;
    }

    return PostModel(
      id: json['id'] as String,
      communityId: json['community_id'] as String,
      authorId: json['author_id'] as String,
      authorUsername: author?['username'] as String?,
      authorAvatarUrl: author?['avatar_global_url'] as String?,
      postType: PostType.fromString(json['post_type'] as String?),
      title: json['title'] as String?,
      content: json['content'] as String?,
      richContent: richContent,
      coverImageUrl: json['cover_image_url'] as String?,
      isPinned: json['is_pinned'] as bool? ?? false,
      pinSize: _parsePinSize(json['pin_size'] as String?),
      mediaUrls: (json['media_urls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      reactionsCount: json['reactions_count'] as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? 0,
      isLikedByCurrentUser: isLiked,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String? ?? json['created_at'] as String),
      pollOptions: pollOptions,
      selectedOptionId: selectedOptionId,
      moderationStatus: ModerationStatus.fromString(json['moderation_status'] as String?),
      aiFlaggedReason: json['ai_flagged_reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'community_id': communityId,
    'author_id': authorId,
    'post_type': postType.dbValue,
    'title': title,
    'content': content,
    'content_rich': richContent?.map((b) => b.toJson()).toList(),
    'cover_image_url': coverImageUrl,
    'is_pinned': isPinned,
    'pin_size': pinSize.name,
    'media_urls': mediaUrls,
  };

  /// For creating new post
  Map<String, dynamic> toInsertJson() => {
    'community_id': communityId,
    'author_id': authorId,
    'post_type': postType.dbValue,
    'title': title,
    'content': content,
    'content_rich': richContent?.map((b) => b.toJson()).toList(),
    'cover_image_url': coverImageUrl,
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
