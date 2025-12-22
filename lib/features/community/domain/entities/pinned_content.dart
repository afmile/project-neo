/// Project Neo - Pinned Content Entity
///
/// Represents content pinned to a user's profile (blogs, wikis, quizzes)
library;

import 'package:equatable/equatable.dart';

/// Types of content that can be pinned
enum ContentType {
  blog,
  wiki,
  quiz,
}

class PinnedContent extends Equatable {
  /// Unique content ID
  final String id;
  
  /// Type of content
  final ContentType type;
  
  /// Content title
  final String title;
  
  /// Optional thumbnail/cover image URL
  final String? thumbnail;
  
  /// Order in pinned list (0 = first)
  final int pinnedOrder;
  
  /// When the content was created
  final DateTime createdAt;
  
  /// Number of views
  final int views;
  
  /// Number of likes
  final int likes;

  const PinnedContent({
    required this.id,
    required this.type,
    required this.title,
    this.thumbnail,
    this.pinnedOrder = 0,
    required this.createdAt,
    this.views = 0,
    this.likes = 0,
  });

  PinnedContent copyWith({
    String? id,
    ContentType? type,
    String? title,
    String? thumbnail,
    int? pinnedOrder,
    DateTime? createdAt,
    int? views,
    int? likes,
  }) {
    return PinnedContent(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      thumbnail: thumbnail ?? this.thumbnail,
      pinnedOrder: pinnedOrder ?? this.pinnedOrder,
      createdAt: createdAt ?? this.createdAt,
      views: views ?? this.views,
      likes: likes ?? this.likes,
    );
  }

  /// Get icon for content type
  String get typeIcon {
    switch (type) {
      case ContentType.blog:
        return '📝';
      case ContentType.wiki:
        return '📘';
      case ContentType.quiz:
        return '❓';
    }
  }

  /// Get label for content type
  String get typeLabel {
    switch (type) {
      case ContentType.blog:
        return 'Blog';
      case ContentType.wiki:
        return 'Wiki';
      case ContentType.quiz:
        return 'Quiz';
    }
  }

  @override
  List<Object?> get props => [
        id,
        type,
        title,
        thumbnail,
        pinnedOrder,
        createdAt,
        views,
        likes,
      ];
}
