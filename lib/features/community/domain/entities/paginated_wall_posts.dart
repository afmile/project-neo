/// Project Neo - Paginated Wall Posts Entity
///
/// Encapsulates wall posts list with pagination metadata
library;

import 'package:equatable/equatable.dart';
import 'wall_post.dart';

class PaginatedWallPosts extends Equatable {
  /// List of wall posts
  final List<WallPost> posts;
  
  /// Whether there are more posts to load
  final bool hasMore;
  
  /// Cursor: ISO8601 timestamp of last post
  final String? lastCreatedAt;
  
  /// Cursor: UUID of last post (for tie-breaking)
  final String? lastId;
  
  /// Whether currently loading next page
  final bool isLoadingMore;

  const PaginatedWallPosts({
    required this.posts,
    required this.hasMore,
    this.lastCreatedAt,
    this.lastId,
    this.isLoadingMore = false,
  });

  /// Empty initial state
  const PaginatedWallPosts.empty()
      : posts = const [],
        hasMore = true,
        lastCreatedAt = null,
        lastId = null,
        isLoadingMore = false;

  PaginatedWallPosts copyWith({
    List<WallPost>? posts,
    bool? hasMore,
    String? lastCreatedAt,
    String? lastId,
    bool? isLoadingMore,
  }) {
    return PaginatedWallPosts(
      posts: posts ?? this.posts,
      hasMore: hasMore ?? this.hasMore,
      lastCreatedAt: lastCreatedAt ?? this.lastCreatedAt,
      lastId: lastId ?? this.lastId,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [
        posts,
        hasMore,
        lastCreatedAt,
        lastId,
        isLoadingMore,
      ];
}
