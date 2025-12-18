/// Project Neo - Post Entity
///
/// Community feed post with pinning support.
library;

import 'package:equatable/equatable.dart';

/// Pin size for featured posts in Bento grid
enum PinSize { normal, large, hero }

/// Post entity for community feed
class PostEntity extends Equatable {
  final String id;
  final String communityId;
  final String authorId;
  final String? authorUsername;
  final String? authorAvatarUrl;
  final String? title;
  final String? content;
  final List<RichTextBlock>? richContent;
  final bool isPinned;
  final PinSize pinSize;
  final List<String> mediaUrls;
  final int reactionsCount;
  final int commentsCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PostEntity({
    required this.id,
    required this.communityId,
    required this.authorId,
    this.authorUsername,
    this.authorAvatarUrl,
    this.title,
    this.content,
    this.richContent,
    this.isPinned = false,
    this.pinSize = PinSize.normal,
    this.mediaUrls = const [],
    this.reactionsCount = 0,
    this.commentsCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

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
    id, communityId, authorId, title, content, richContent,
    isPinned, pinSize, mediaUrls, reactionsCount, commentsCount,
    createdAt, updatedAt,
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
