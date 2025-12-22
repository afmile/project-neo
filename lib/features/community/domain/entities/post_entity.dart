/// Project Neo - Post Entity
///
/// Community feed post with pinning support and polymorphic content types.
library;

import 'package:equatable/equatable.dart';

/// Pin size for featured posts in Bento grid
enum PinSize { normal, large, hero }

/// Post types for polymorphic content
enum PostType { 
  blog, 
  wiki, 
  poll, 
  quiz, 
  wallPost;
  
  String get displayName {
    switch (this) {
      case PostType.blog: return 'Blog';
      case PostType.wiki: return 'Wiki';
      case PostType.poll: return 'Encuesta';
      case PostType.quiz: return 'Quiz';
      case PostType.wallPost: return 'Muro';
    }
  }
  
  String get dbValue {
    switch (this) {
      case PostType.blog: return 'blog';
      case PostType.wiki: return 'wiki';
      case PostType.poll: return 'poll';
      case PostType.quiz: return 'quiz';
      case PostType.wallPost: return 'wall_post';
    }
  }
  
  static PostType fromString(String? value) {
    switch (value) {
      case 'wiki': return PostType.wiki;
      case 'poll': return PostType.poll;
      case 'quiz': return PostType.quiz;
      case 'wall_post': return PostType.wallPost;
      default: return PostType.blog;
    }
  }
}

/// Moderation status for AI content filtering
enum ModerationStatus {
  pending,
  approved,
  rejected;
  
  String get dbValue {
    switch (this) {
      case ModerationStatus.pending: return 'pending';
      case ModerationStatus.approved: return 'approved';
      case ModerationStatus.rejected: return 'rejected';
    }
  }
  
  static ModerationStatus fromString(String? value) {
    switch (value) {
      case 'pending': return ModerationStatus.pending;
      case 'rejected': return ModerationStatus.rejected;
      default: return ModerationStatus.approved;
    }
  }
  
  bool get isVisible => this == ModerationStatus.approved;
}

/// Poll option for poll-type posts
class PollOption extends Equatable {
  final String id;
  final String text;
  final int position;
  final int votesCount;

  const PollOption({
    required this.id,
    required this.text,
    this.position = 0,
    this.votesCount = 0,
  });

  factory PollOption.fromJson(Map<String, dynamic> json) {
    return PollOption(
      id: json['id'] as String,
      text: json['text'] as String,
      position: json['position'] as int? ?? 0,
      votesCount: json['votes_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'position': position,
    'votes_count': votesCount,
  };

  @override
  List<Object?> get props => [id, text, position, votesCount];
}

/// Post entity for community feed
class PostEntity extends Equatable {
  final String id;
  final String communityId;
  final String authorId;
  final String? authorUsername;
  final String? authorAvatarUrl;
  final PostType postType;
  final String? title;
  final String? content;
  final List<RichTextBlock>? richContent;
  final String? coverImageUrl;
  final bool isPinned;
  final PinSize pinSize;
  final List<String> mediaUrls;
  final int reactionsCount;
  final int commentsCount;
  final bool isLikedByCurrentUser;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Poll-specific fields
  final List<PollOption>? pollOptions;
  final String? selectedOptionId; // Option voted by current user
  
  // Moderation fields (AI Filter)
  final ModerationStatus moderationStatus;
  final String? aiFlaggedReason;

  const PostEntity({
    required this.id,
    required this.communityId,
    required this.authorId,
    this.authorUsername,
    this.authorAvatarUrl,
    this.postType = PostType.blog,
    this.title,
    this.content,
    this.richContent,
    this.coverImageUrl,
    this.isPinned = false,
    this.pinSize = PinSize.normal,
    this.mediaUrls = const [],
    this.reactionsCount = 0,
    this.commentsCount = 0,
    this.isLikedByCurrentUser = false,
    required this.createdAt,
    required this.updatedAt,
    this.pollOptions,
    this.selectedOptionId,
    this.moderationStatus = ModerationStatus.approved,
    this.aiFlaggedReason,
  });
  
  /// Get total votes for polls
  int get totalVotes {
    if (pollOptions == null) return 0;
    return pollOptions!.fold(0, (sum, option) => sum + option.votesCount);
  }
  
  /// Check if user has voted on this poll
  bool get hasVoted => selectedOptionId != null;
  
  PostEntity copyWith({
    String? id,
    String? communityId,
    String? authorId,
    String? authorUsername,
    String? authorAvatarUrl,
    PostType? postType,
    String? title,
    String? content,
    List<RichTextBlock>? richContent,
    String? coverImageUrl,
    bool? isPinned,
    PinSize? pinSize,
    List<String>? mediaUrls,
    int? reactionsCount,
    int? commentsCount,
    bool? isLikedByCurrentUser,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<PollOption>? pollOptions,
    String? selectedOptionId,
    ModerationStatus? moderationStatus,
    String? aiFlaggedReason,
  }) {
    return PostEntity(
      id: id ?? this.id,
      communityId: communityId ?? this.communityId,
      authorId: authorId ?? this.authorId,
      authorUsername: authorUsername ?? this.authorUsername,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      postType: postType ?? this.postType,
      title: title ?? this.title,
      content: content ?? this.content,
      richContent: richContent ?? this.richContent,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      isPinned: isPinned ?? this.isPinned,
      pinSize: pinSize ?? this.pinSize,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      reactionsCount: reactionsCount ?? this.reactionsCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLikedByCurrentUser: isLikedByCurrentUser ?? this.isLikedByCurrentUser,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pollOptions: pollOptions ?? this.pollOptions,
      selectedOptionId: selectedOptionId ?? this.selectedOptionId,
      moderationStatus: moderationStatus ?? this.moderationStatus,
      aiFlaggedReason: aiFlaggedReason ?? this.aiFlaggedReason,
    );
  }

  /// Get grid span for Bento layout
  int get gridSpan {
    if (!isPinned) return 1;
    switch (pinSize) {
      case PinSize.normal:
        return 1;
      case PinSize.large:
        return 2;
      case PinSize.hero:
        return 4; // Full width
    }
  }

  /// Check if post has media
  bool get hasMedia => mediaUrls.isNotEmpty;

  /// Check if post has rich content
  bool get hasRichContent => richContent != null && richContent!.isNotEmpty;

  @override
  List<Object?> get props => [
    id, communityId, authorId, postType, title, content, richContent,
    coverImageUrl, isPinned, pinSize, mediaUrls, reactionsCount, commentsCount,
    isLikedByCurrentUser, createdAt, updatedAt, pollOptions, selectedOptionId,
    moderationStatus, aiFlaggedReason,
  ];
}

/// Rich text block types
enum RichTextBlockType {
  paragraph,
  heading,
  quote,
  code,
  image,
  divider,
}

/// Rich text block for advanced content
class RichTextBlock extends Equatable {
  final RichTextBlockType type;
  final String? text;
  final String? imageUrl;
  final int? level; // For headings (1-3)
  final String? language; // For code blocks

  const RichTextBlock({
    required this.type,
    this.text,
    this.imageUrl,
    this.level,
    this.language,
  });

  factory RichTextBlock.fromJson(Map<String, dynamic> json) {
    return RichTextBlock(
      type: RichTextBlockType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => RichTextBlockType.paragraph,
      ),
      text: json['text'] as String?,
      imageUrl: json['image_url'] as String?,
      level: json['level'] as int?,
      language: json['language'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type.name,
    if (text != null) 'text': text,
    if (imageUrl != null) 'image_url': imageUrl,
    if (level != null) 'level': level,
    if (language != null) 'language': language,
  };

  @override
  List<Object?> get props => [type, text, imageUrl, level, language];
}
