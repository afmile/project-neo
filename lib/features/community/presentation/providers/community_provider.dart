/// Project Neo - Community Provider
///
/// Riverpod state management for communities.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/community_remote_datasource.dart';
import '../../data/models/post_model.dart';
import '../../domain/entities/community_entity.dart';
import '../../domain/entities/post_entity.dart';

/// Datasource provider
final communityDatasourceProvider = Provider<CommunityRemoteDataSource>((ref) {
  return CommunityRemoteDataSourceImpl();
});

/// Community state
class CommunityState {
  final CommunityEntity? community;
  final List<PostEntity> posts;
  final bool isLoading;
  final String? error;
  
  const CommunityState({
    this.community,
    this.posts = const [],
    this.isLoading = false,
    this.error,
  });
  
  CommunityState copyWith({
    CommunityEntity? community,
    List<PostEntity>? posts,
    bool? isLoading,
    String? error,
  }) {
    return CommunityState(
      community: community ?? this.community,
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Community notifier
class CommunityNotifier extends StateNotifier<CommunityState> {
  final CommunityRemoteDataSource _datasource;
  
  CommunityNotifier(this._datasource) : super(const CommunityState());
  
  /// Load community by slug
  Future<void> loadCommunity(String slug) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final community = await _datasource.getCommunityBySlug(slug);
      final posts = await _datasource.getCommunityPosts(community.id);
      
      state = state.copyWith(
        community: community,
        posts: posts,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
  
  /// Load more posts
  Future<void> loadMorePosts() async {
    if (state.community == null) return;
    
    try {
      final morePosts = await _datasource.getCommunityPosts(
        state.community!.id,
        offset: state.posts.length,
      );
      
      state = state.copyWith(
        posts: [...state.posts, ...morePosts],
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
  
  /// Create new post
  Future<void> createPost({
    required String title,
    required String content,
  }) async {
    if (state.community == null) return;
    
    try {
      final post = PostModel(
        id: '',
        communityId: state.community!.id,
        authorId: '', // Will be set by RLS
        title: title,
        content: content,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final newPost = await _datasource.createPost(post);
      
      state = state.copyWith(
        posts: [newPost, ...state.posts],
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
  
  /// Join community
  Future<void> joinCommunity() async {
    if (state.community == null) return;
    
    try {
      await _datasource.joinCommunity(state.community!.id);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
  
  /// Leave community
  Future<void> leaveCommunity() async {
    if (state.community == null) return;
    
    try {
      await _datasource.leaveCommunity(state.community!.id);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

/// Community provider family (by slug)
final communityProvider = StateNotifierProvider.family<CommunityNotifier, CommunityState, String>(
  (ref, slug) {
    final datasource = ref.watch(communityDatasourceProvider);
    final notifier = CommunityNotifier(datasource);
    notifier.loadCommunity(slug);
    return notifier;
  },
);

/// Get pinned posts for Bento display
final pinnedPostsProvider = FutureProvider.family<List<PostEntity>, String>(
  (ref, communityId) async {
    final datasource = ref.watch(communityDatasourceProvider);
    return datasource.getPinnedPosts(communityId);
  },
);
