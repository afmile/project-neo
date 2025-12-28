/// Project Neo - Content Providers
///
/// Riverpod providers for content management with optimistic updates.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/draft_service.dart';
import '../../data/datasources/content_remote_datasource.dart';
import '../../data/repositories/content_repository_impl.dart';
import '../../domain/entities/post_entity.dart';
import '../../domain/entities/comment_entity.dart';
import '../../domain/repositories/content_repository.dart';

// ============================================================================
// INFRASTRUCTURE PROVIDERS
// ============================================================================

/// SharedPreferences provider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main.dart');
});

/// Content datasource provider
final contentDataSourceProvider = Provider<ContentRemoteDataSource>((ref) {
  return ContentRemoteDataSourceImpl();
});

/// Content repository provider
final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  return ContentRepositoryImpl(
    remoteDataSource: ref.watch(contentDataSourceProvider),
  );
});

/// Draft service provider
final draftServiceProvider = Provider<DraftService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return DraftService(prefs);
});

// ============================================================================
// FEED PROVIDERS
// ============================================================================

/// Feed state with cursor-based pagination support
class FeedState {
  final List<PostEntity> posts;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  
  // 3-field cursor for robust pagination (matches ORDER BY)
  final bool? lastIsPinned;
  final String? lastCreatedAt;
  final String? lastId;

  const FeedState({
    this.posts = const [],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.lastIsPinned,
    this.lastCreatedAt,
    this.lastId,
  });

  FeedState copyWith({
    List<PostEntity>? posts,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    bool? lastIsPinned,
    String? lastCreatedAt,
    String? lastId,
  }) {
    return FeedState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      lastIsPinned: lastIsPinned ?? this.lastIsPinned,
      lastCreatedAt: lastCreatedAt ?? this.lastCreatedAt,
      lastId: lastId ?? this.lastId,
    );
  }
}

/// Feed notifier for a community with optional type filter
class FeedNotifier extends StateNotifier<FeedState> {
  final ContentRepository repository;
  final String communityId;
  final PostType? typeFilter;
  
  static const _pageSize = 20;
  
  FeedNotifier({
    required this.repository,
    required this.communityId,
    this.typeFilter,
  }) : super(const FeedState()) {
    loadInitial();
  }
  
  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await repository.getFeedPaginated(
      communityId: communityId,
      typeFilter: typeFilter,
      limit: _pageSize + 1,
      cursorIsPinned: null,  // No cursor for first page
      cursorCreatedAt: null,
      cursorId: null,
    );
    
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (posts) {
        final hasMore = posts.length > _pageSize;
        final displayPosts = hasMore ? posts.sublist(0, _pageSize) : posts;
        
        // Extract 3-field cursor from last post
        bool? lastIsPinned;
        String? lastCreatedAt;
        String? lastId;
        if (displayPosts.isNotEmpty) {
          final lastPost = displayPosts.last;
          lastIsPinned = lastPost.isPinned;  // NEW
          lastCreatedAt = lastPost.createdAt.toIso8601String();
          lastId = lastPost.id;
        }
        
        state = state.copyWith(
          posts: displayPosts,
          isLoading: false,
          isLoadingMore: false,
          hasMore: hasMore,
          lastIsPinned: lastIsPinned,  // NEW
          lastCreatedAt: lastCreatedAt,
          lastId: lastId,
        );
      },
    );
  }
  
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;
    
    state = state.copyWith(isLoadingMore: true);
    
    final result = await repository.getFeedPaginated(
      communityId: communityId,
      typeFilter: typeFilter,
      limit: _pageSize + 1,
      cursorIsPinned: state.lastIsPinned,  // NEW: 3-field cursor
      cursorCreatedAt: state.lastCreatedAt,
      cursorId: state.lastId,
    );
    
    result.fold(
      (failure) => state = state.copyWith(
        isLoadingMore: false,
        error: failure.message,
      ),
      (newPosts) {
        final hasMore = newPosts.length > _pageSize;
        final displayPosts = hasMore ? newPosts.sublist(0, _pageSize) : newPosts;
        
        // Deduplication by id
        final existingIds = state.posts.map((p) => p.id).toSet();
        final uniqueNewPosts = displayPosts
            .where((p) => !existingIds.contains(p.id))
            .toList();
        
        // Extract 3-field cursor from last new post
        bool? lastIsPinned = state.lastIsPinned;
        String? lastCreatedAt = state.lastCreatedAt;
        String? lastId = state.lastId;
        if (uniqueNewPosts.isNotEmpty) {
          final lastPost = uniqueNewPosts.last;
          lastIsPinned = lastPost.isPinned;  // NEW
          lastCreatedAt = lastPost.createdAt.toIso8601String();
          lastId = lastPost.id;
        }
        
        state = state.copyWith(
          posts: [...state.posts, ...uniqueNewPosts],
          isLoadingMore: false,
          hasMore: hasMore,
          lastIsPinned: lastIsPinned,  // NEW
          lastCreatedAt: lastCreatedAt,
          lastId: lastId,
        );
      },
    );
  }
  
  Future<void> refresh() async {
    state = const FeedState();
    await loadInitial();
  }
  
  /// Toggle reaction with optimistic update
  Future<void> toggleReaction(String postId) async {
    // Find the post
    final index = state.posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;
    
    final post = state.posts[index];
    
    // Optimistic update
    final newPosts = [...state.posts];
    newPosts[index] = post.copyWith(
      isLikedByCurrentUser: !post.isLikedByCurrentUser,
      reactionsCount: post.isLikedByCurrentUser 
          ? post.reactionsCount - 1 
          : post.reactionsCount + 1,
    );
    state = state.copyWith(posts: newPosts);
    
    // Actual API call
    final result = await repository.toggleReaction(postId: postId);
    
    result.fold(
      (failure) {
        // Revert on failure
        final revertedPosts = [...state.posts];
        revertedPosts[index] = post;
        state = state.copyWith(posts: revertedPosts, error: failure.message);
      },
      (_) {
        // Success - state already updated optimistically
      },
    );
  }
  
  /// Add a newly created post to the feed
  void addPost(PostEntity post) {
    state = state.copyWith(posts: [post, ...state.posts]);
  }
  
  /// Remove a post from the feed
  void removePost(String postId) {
    state = state.copyWith(
      posts: state.posts.where((p) => p.id != postId).toList(),
    );
  }
  
  /// Update a post in the feed
  void updatePost(PostEntity updatedPost) {
    final index = state.posts.indexWhere((p) => p.id == updatedPost.id);
    if (index != -1) {
      final newPosts = [...state.posts];
      newPosts[index] = updatedPost;
      state = state.copyWith(posts: newPosts);
    }
  }
}

/// Feed provider family - creates notifier per community + filter
final feedProvider = StateNotifierProvider.family<FeedNotifier, FeedState, ({String communityId, PostType? typeFilter})>(
  (ref, params) => FeedNotifier(
    repository: ref.watch(contentRepositoryProvider),
    communityId: params.communityId,
    typeFilter: params.typeFilter,
  ),
);

// ============================================================================
// POST DETAIL PROVIDERS
// ============================================================================

/// Single post detail provider
final postDetailProvider = FutureProvider.family<PostEntity?, String>((ref, postId) async {
  final repository = ref.watch(contentRepositoryProvider);
  final result = await repository.getPostById(postId);
  return result.fold((failure) => null, (post) => post);
});

// ============================================================================
// COMMENTS PROVIDERS
// ============================================================================

/// Comments state
class CommentsState {
  final List<CommentEntity> comments;
  final bool isLoading;
  final String? error;

  const CommentsState({
    this.comments = const [],
    this.isLoading = true,
    this.error,
  });

  CommentsState copyWith({
    List<CommentEntity>? comments,
    bool? isLoading,
    String? error,
  }) {
    return CommentsState(
      comments: comments ?? this.comments,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Comments notifier for a post
class CommentsNotifier extends StateNotifier<CommentsState> {
  final ContentRepository repository;
  final String postId;
  
  CommentsNotifier({
    required this.repository,
    required this.postId,
  }) : super(const CommentsState()) {
    loadComments();
  }
  
  Future<void> loadComments() async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await repository.getComments(postId: postId);
    
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (comments) => state = state.copyWith(
        comments: comments,
        isLoading: false,
      ),
    );
  }
  
  Future<bool> addComment(String content, {String? parentId}) async {
    final result = await repository.addComment(
      postId: postId,
      content: content,
      parentId: parentId,
    );
    
    return result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
        return false;
      },
      (comment) {
        if (parentId == null) {
          // Top-level comment
          state = state.copyWith(comments: [...state.comments, comment]);
        } else {
          // Reply - need to update parent
          final newComments = state.comments.map((c) {
            if (c.id == parentId) {
              return c.copyWith(
                replies: [...(c.replies ?? []), comment],
              );
            }
            return c;
          }).toList();
          state = state.copyWith(comments: newComments);
        }
        return true;
      },
    );
  }
  
  Future<bool> deleteComment(String commentId) async {
    final result = await repository.deleteComment(commentId);
    
    return result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
        return false;
      },
      (_) {
        // Remove from list (including nested)
        final newComments = _removeCommentRecursive(state.comments, commentId);
        state = state.copyWith(comments: newComments);
        return true;
      },
    );
  }
  
  List<CommentEntity> _removeCommentRecursive(List<CommentEntity> comments, String id) {
    return comments
        .where((c) => c.id != id)
        .map((c) => c.copyWith(
          replies: c.replies != null 
              ? _removeCommentRecursive(c.replies!, id) 
              : null,
        ))
        .toList();
  }
}

/// Comments provider family - creates notifier per post
final commentsProvider = StateNotifierProvider.family<CommentsNotifier, CommentsState, String>(
  (ref, postId) => CommentsNotifier(
    repository: ref.watch(contentRepositoryProvider),
    postId: postId,
  ),
);

// ============================================================================
// DRAFT PROVIDERS
// ============================================================================

/// Draft recovery provider - checks if draft exists
final draftExistsProvider = FutureProvider.family<bool, ({String userId, String communityId, PostType type})>(
  (ref, params) async {
    final service = ref.watch(draftServiceProvider);
    return service.hasDraft(
      userId: params.userId,
      communityId: params.communityId,
      type: params.type,
    );
  },
);

/// Get draft data provider
final draftDataProvider = FutureProvider.family<DraftData?, ({String userId, String communityId, PostType type})>(
  (ref, params) async {
    final service = ref.watch(draftServiceProvider);
    return service.getDraft(
      userId: params.userId,
      communityId: params.communityId,
      type: params.type,
    );
  },
);

// ============================================================================
// POLL VOTE PROVIDER
// ============================================================================

/// Poll vote notifier for optimistic updates
class PollVoteNotifier extends StateNotifier<String?> {
  final ContentRepository repository;
  final String postId;
  
  PollVoteNotifier({
    required this.repository,
    required this.postId,
    String? initialVote,
  }) : super(initialVote);
  
  Future<bool> vote(String optionId) async {
    final previousVote = state;
    
    // Optimistic update
    state = optionId;
    
    final result = await repository.votePoll(optionId: optionId);
    
    return result.fold(
      (failure) {
        // Revert on failure
        state = previousVote;
        return false;
      },
      (_) => true,
    );
  }
}

final pollVoteProvider = StateNotifierProvider.family<PollVoteNotifier, String?, String>(
  (ref, postId) {
    final repository = ref.watch(contentRepositoryProvider);
    return PollVoteNotifier(
      repository: repository,
      postId: postId,
    );
  },
);
