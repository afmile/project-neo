/// Project Neo - Wall Posts Paginated Provider
///
/// Provider for community-wide wall feed with infinite scroll pagination
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/wall_post_model.dart';
import '../../data/repositories/community_repository.dart';
import '../../domain/entities/paginated_wall_posts.dart';
import '../../domain/entities/wall_post.dart';
import 'community_providers.dart';

const int kWallPostsPageSize = 20;

/// Infinite scroll threshold (0.0 to 1.0)
/// 
/// Determines at what percentage of scroll the next page should load.
/// 0.8 = Load when user reaches 80% of current content.
/// 
/// Rationale: 80% provides good UX balance:
/// - Not too early (would waste bandwidth)
/// - Not too late (user won't see loading)
const double kInfiniteScrollThreshold = 0.8;

// ═══════════════════════════════════════════════════════════════════════════
// WALL POSTS PAGINATED PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

/// StateNotifier for paginated community wall posts
/// 
/// **IMPORTANT**: This provider is designed to be UI-agnostic and reusable.
/// It will be used by:
/// - Community Muro tab (current implementation)
/// - Home Vivo feed (future implementation)
/// 
/// The provider manages:
/// - Cursor-based pagination (created_at + id)
/// - Infinite scroll state (isLoadingMore, hasMore)
/// - Optimistic updates for likes
/// - Automatic deduplication by post ID
/// 
/// Do NOT couple this provider to specific UI widgets or screens.
class WallPostsPaginatedNotifier extends StateNotifier<AsyncValue<PaginatedWallPosts>> {
  final String communityId;
  final CommunityRepository repository;
  final Ref ref;

  WallPostsPaginatedNotifier({
    required this.communityId,
    required this.repository,
    required this.ref,
  }) : super(const AsyncValue.loading()) {
    loadFirstPage();
  }

  /// Load first page of posts (no cursor)
  Future<void> loadFirstPage() async {
    print('🔄 Loading first page for community: $communityId');
    state = const AsyncValue.loading();

    try {
      final result = await repository.fetchWallPostsPaginated(
        communityId: communityId,
        limit: kWallPostsPageSize + 1, // +1 to detect hasMore
      );

      result.fold(
        (failure) {
          print('❌ Error loading first page: ${failure.message}');
          state = AsyncValue.error(failure.message, StackTrace.current);
        },
        (postsJson) {
          final currentUser = ref.read(currentUserProvider);
          final posts = WallPostModel.listFromSupabase(
            postsJson,
            currentUser?.id,
          );

          final hasMore = posts.length > kWallPostsPageSize;
          final displayPosts = hasMore ? posts.take(kWallPostsPageSize).toList() : posts;

          state = AsyncValue.data(PaginatedWallPosts(
            posts: displayPosts,
            hasMore: hasMore,
            lastCreatedAt:
                displayPosts.isNotEmpty ? displayPosts.last.timestamp.toIso8601String() : null,
            lastId: displayPosts.isNotEmpty ? displayPosts.last.id : null,
          ));

          print('✅ First page loaded: ${displayPosts.length} posts, hasMore: $hasMore');
        },
      );
    } catch (e, stackTrace) {
      print('❌ Exception loading first page: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Load next page using cursor from last post
  Future<void> loadNextPage() async {
    final currentState = state.valueOrNull;
    if (currentState == null || !currentState.hasMore || currentState.isLoadingMore) {
      print('⏭️ Skipping loadNextPage (no more or already loading)');
      return;
    }

    print('🔄 Loading next page...');

    // Set loading flag
    state = AsyncValue.data(currentState.copyWith(isLoadingMore: true));

    try {
      final result = await repository.fetchWallPostsPaginated(
        communityId: communityId,
        limit: kWallPostsPageSize + 1,
        cursorCreatedAt: currentState.lastCreatedAt!,
        cursorId: currentState.lastId!,
      );

      result.fold(
        (failure) {
          print('❌ Error loading next page: ${failure.message}');
          // Keep current posts, remove loading flag
          state = AsyncValue.data(currentState.copyWith(isLoadingMore: false));
        },
        (postsJson) {
          final currentUser = ref.read(currentUserProvider);
          final newPosts = WallPostModel.listFromSupabase(
            postsJson,
            currentUser?.id,
          );

          final hasMore = newPosts.length > kWallPostsPageSize;
          final displayPosts = hasMore ? newPosts.take(kWallPostsPageSize).toList() : newPosts;

          // Avoid duplicates (by id)
          final existingIds = currentState.posts.map((p) => p.id).toSet();
          final uniqueNewPosts = displayPosts.where((p) => !existingIds.contains(p.id)).toList();

          final allPosts = [...currentState.posts, ...uniqueNewPosts];

          state = AsyncValue.data(PaginatedWallPosts(
            posts: allPosts,
            hasMore: hasMore,
            lastCreatedAt: displayPosts.isNotEmpty
                ? displayPosts.last.timestamp.toIso8601String()
                : currentState.lastCreatedAt,
            lastId: displayPosts.isNotEmpty ? displayPosts.last.id : currentState.lastId,
            isLoadingMore: false,
          ));

          print('✅ Next page loaded: ${uniqueNewPosts.length} new posts, total: ${allPosts.length}');
        },
      );
    } catch (e, stackTrace) {
      print('❌ Exception loading next page: $e');
      // Keep current posts, remove loading flag
      state = AsyncValue.data(currentState.copyWith(isLoadingMore: false));
    }
  }

  /// Refresh feed (pull-to-refresh)
  Future<void> refresh() async {
    print('🔄 Refreshing wall feed');
    await loadFirstPage();
  }

  /// Create a new wall post (optimistic update + persist)
  Future<bool> createPost(String content) async {
    if (content.trim().isEmpty) {
      print('❌ Cannot create empty post');
      return false;
    }

    print('📝 Creating wall post...');
    
    final result = await repository.createWallPost(
      communityId: communityId,
      content: content,
    );
    
    return result.fold(
      (failure) {
        print('❌ Failed to create post: ${failure.message}');
        return false;
      },
      (postJson) {
        print('✅ Post created, refreshing feed');
        // Refresh to show the new post
        loadFirstPage();
        return true;
      },
    );
  }

  /// Toggle like on a post (optimistic update + persist)
  Future<void> toggleLike(String postId) async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final postIndex = currentState.posts.indexWhere((p) => p.id == postId);
    if (postIndex == -1) return;

    final post = currentState.posts[postIndex];
    final wasLiked = post.isLikedByCurrentUser;

    // Optimistic update
    final updatedPost = post.copyWith(
      isLikedByCurrentUser: !wasLiked,
      likes: wasLiked ? post.likes - 1 : post.likes + 1,
    );

    final updatedPosts = List<WallPost>.from(currentState.posts);
    updatedPosts[postIndex] = updatedPost;
    state = AsyncValue.data(currentState.copyWith(posts: updatedPosts));

    // Persist to database
    final result = await repository.toggleWallPostLike(postId);
    
    result.fold(
      (failure) {
        print('❌ Failed to toggle like, rolling back: ${failure.message}');
        // Rollback on failure
        final rollbackPosts = List<WallPost>.from(currentState.posts);
        rollbackPosts[postIndex] = post; // Restore original
        state = AsyncValue.data(currentState.copyWith(posts: rollbackPosts));
      },
      (isLiked) {
        print('✅ Like persisted: $isLiked');
      },
    );
  }
  
  /// Delete a wall post
  Future<bool> deletePost(String postId) async {
    final currentState = state.valueOrNull;
    if (currentState == null) return false;

    final postIndex = currentState.posts.indexWhere((p) => p.id == postId);
    if (postIndex == -1) return false;

    final post = currentState.posts[postIndex];
    
    // Optimistic removal
    final updatedPosts = List<WallPost>.from(currentState.posts);
    updatedPosts.removeAt(postIndex);
    state = AsyncValue.data(currentState.copyWith(posts: updatedPosts));

    // Persist deletion
    final result = await repository.deleteWallPost(postId);
    
    return result.fold(
      (failure) {
        print('❌ Failed to delete post, rolling back: ${failure.message}');
        // Rollback: re-insert at original position
        final rollbackPosts = List<WallPost>.from(updatedPosts);
        rollbackPosts.insert(postIndex, post);
        state = AsyncValue.data(currentState.copyWith(posts: rollbackPosts));
        return false;
      },
      (_) {
        print('✅ Post deleted successfully');
        return true;
      },
    );
  }
}

/// Provider for paginated wall posts by community
final wallPostsPaginatedProvider = StateNotifierProvider.family<WallPostsPaginatedNotifier,
    AsyncValue<PaginatedWallPosts>, String>((ref, communityId) {
  final repository = ref.watch(communityRepositoryProvider);
  return WallPostsPaginatedNotifier(
    communityId: communityId,
    repository: repository,
    ref: ref,
  );
});

