import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'community_follow_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/user_stats.dart';
import '../../domain/entities/wall_post.dart';
import '../../domain/entities/user_title_tag.dart';
import '../../data/models/wall_post_model.dart';
import '../../data/models/user_tag_model.dart';
import '../../data/repositories/profile_repository.dart';

/// Filter for wall posts provider
class WallPostsFilter {
  final String userId;
  final String communityId;

  const WallPostsFilter({
    required this.userId,
    required this.communityId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WallPostsFilter &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          communityId == other.communityId;

  @override
  int get hashCode => userId.hashCode ^ communityId.hashCode;
}

/// Parameter class for fetching user profile
class UserProfileParams {
  final String userId;
  final String? communityId;

  const UserProfileParams({required this.userId, this.communityId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfileParams &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          communityId == other.communityId;

  @override
  int get hashCode => userId.hashCode ^ communityId.hashCode;
}

/// Provider to fetch a user profile, optionally scoped to a community
final userProfileProvider = FutureProvider.family<UserEntity?, UserProfileParams>((ref, params) async {
  final supabase = Supabase.instance.client;
  final userId = params.userId;
  final communityId = params.communityId;

  try {
    // 1. Fetch Global Data
    final globalResponse = await supabase.from('users_global').select().eq('id', userId).maybeSingle();
    
    if (globalResponse == null) return null;

    // 2. Fetch Security Profile
    final securityResponse = await supabase.from('security_profile').select().eq('user_id', userId).maybeSingle();
    
    // 3. (Optional) Fetch Local Community Profile
    Map<String, dynamic>? localMember;
    if (communityId != null) {
      localMember = await supabase
          .from('community_members')
          .select('nickname, avatar_url, bio')
          .eq('user_id', userId)
          .eq('community_id', communityId)
          .maybeSingle();
    }

    // 4. Construct Base User
    UserEntity user = UserModel.fromSupabase(
      id: userId,
      email: '', 
      userGlobal: globalResponse,
      securityProfile: securityResponse,
      wallet: null,
    );

    // 5. Apply Local Overrides if available
    if (localMember != null) {
      user = user.copyWith(
        username: localMember['nickname'] as String?,
        avatarUrl: localMember['avatar_url'] as String?,
        bio: localMember['bio'] as String?,
      );
    }

    return user;
  } catch (e) {
    return null;
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// USER STATS PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

/// Provider to fetch user statistics (followers, following, wall posts count)
// ═══════════════════════════════════════════════════════════════════════════
// USER STATS PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

/// Provider to fetch user statistics (followers, following, wall posts count)
/// Scoped to community and reactive to follow changes
final userStatsProvider = FutureProvider.autoDispose.family<UserStats, UserProfileParams>((ref, params) async {
  final supabase = Supabase.instance.client;
  final communityId = params.communityId;
  final userId = params.userId;

  if (communityId == null) {
    // Fallback for global context (should not happen in current flow)
    return const UserStats();
  }

  // 1. Get reactive follow counts
  // We use ref.watch on the specific count providers so this provider rebuilds
  // automatically when they are invalidated by FollowActionsNotifier
  final followParams = FollowStatusParams(
    communityId: communityId,
    targetUserId: userId,
  );

  final followersCount = await ref.watch(communityFollowerCountProvider(followParams).future);
  final followingCount = await ref.watch(communityFollowingCountProvider(followParams).future);

  // 2. Get wall posts count (scoped to availability in profile wall)
  // TODO: Create a separate provider for this if we want realtime/invalidation support for posts count
  final postsCount = await supabase
      .from('profile_wall_posts')
      .count(CountOption.exact)
      .eq('profile_user_id', userId)
      .eq('community_id', communityId);

  return UserStats(
    followersCount: followersCount,
    followingCount: followingCount,
    wallPostsCount: postsCount,
  );
});

// ═══════════════════════════════════════════════════════════════════════════
// WALL POSTS PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(Supabase.instance.client);
});

/// StateNotifier for managing wall posts with create/refresh capabilities
class UserWallPostsNotifier extends StateNotifier<AsyncValue<List<WallPost>>> {
  final WallPostsFilter filter;
  final Ref ref;
  late final ProfileRepository _repository;
  
  UserWallPostsNotifier(this.filter, this.ref) : super(const AsyncValue.loading()) {
    _repository = ref.read(profileRepositoryProvider);
    refresh();
  }

  Future<void> refresh() async {
    try {
      state = const AsyncValue.loading();
      final posts = await _repository.getProfilePosts(filter.userId, filter.communityId);
      state = AsyncValue.data(posts);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> createWallPost(String content) async {
    try {
      await _repository.createPost(filter.userId, filter.communityId, content);
      await refresh();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteWallPost(String postId) async {
    try {
      await _repository.deletePost(postId);
      await refresh();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> toggleLike(String postId) async {
    final currentState = state.value;
    if (currentState == null) return;

    // Optimistic Update (UI Inmediata)
    final postIndex = currentState.indexWhere((p) => p.id == postId);
    if (postIndex == -1) return;
    
    final post = currentState[postIndex];
    final updatedPost = post.copyWith(
      isLikedByCurrentUser: !post.isLikedByCurrentUser,
      likes: post.isLikedByCurrentUser ? post.likes - 1 : post.likes + 1,
    );
    
    final updatedList = List<WallPost>.from(currentState);
    updatedList[postIndex] = updatedPost;
    state = AsyncValue.data(updatedList);

    try {
      // Llamada real al repo
      await _repository.toggleLike(postId);
    } catch (e) {
      // Rollback si falla
      state = AsyncValue.data(currentState);
    }
  }
}

/// Provider to manage wall posts for a specific user
/// Provider to manage wall posts for a specific user in a community
final userWallPostsProvider = StateNotifierProvider.family<
    UserWallPostsNotifier,
    AsyncValue<List<WallPost>>,
    WallPostsFilter
>((ref, filter) {
  return UserWallPostsNotifier(filter, ref);
});

// ═══════════════════════════════════════════════════════════════════════════
// USER TAGS PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

/// Provider to fetch user title tags
final userTagsProvider = FutureProvider.family<List<UserTitleTag>, String>((ref, userId) async {
  final supabase = Supabase.instance.client;

  try {
    final response = await supabase
        .from('user_tags')
        .select()
        .eq('user_id', userId)
        .order('display_order', ascending: true);

    return UserTagModel.listFromSupabase(response as List<dynamic>);
  } catch (e) {
    // Return empty list on error
    return [];
  }
});
