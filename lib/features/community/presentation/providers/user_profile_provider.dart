import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/user_stats.dart';
import '../../domain/entities/wall_post.dart';
import '../../domain/entities/user_title_tag.dart';
import '../../data/models/wall_post_model.dart';
import '../../data/models/user_tag_model.dart';

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
final userStatsProvider = FutureProvider.family<UserStats, String>((ref, userId) async {
  final supabase = Supabase.instance.client;

  try {
    // Run all count queries in parallel
    final results = await Future.wait<int>([
      // Count followers (users following this user)
      supabase
          .from('followers')
          .count(CountOption.exact)
          .eq('following_id', userId),
      
      // Count following (users this user is following)
      supabase
          .from('followers')
          .count(CountOption.exact)
          .eq('follower_id', userId),
      
      // Count wall posts
      supabase
          .from('wall_posts')
          .count(CountOption.exact)
          .eq('profile_user_id', userId),
    ]);

    return UserStats(
      followersCount: results[0],
      followingCount: results[1],
      wallPostsCount: results[2],
    );
  } catch (e) {
    // Return zeros on error
    return const UserStats();
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// WALL POSTS PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

/// StateNotifier for managing wall posts with create/refresh capabilities
class UserWallPostsNotifier extends StateNotifier<AsyncValue<List<WallPost>>> {
  final WallPostsFilter filter;
  final Ref ref;
  
  UserWallPostsNotifier(this.filter, this.ref) : super(const AsyncValue.loading()) {
    refresh();
  }

  /// Refresh wall posts from database
  Future<void> refresh() async {
    print('🔄 MURO: Iniciando refresh para userId=${filter.userId} en communityId=${filter.communityId}');
    state = const AsyncValue.loading();
    
    try {
      final supabase = Supabase.instance.client;
      final currentUser = ref.read(currentUserProvider);

      print('🔍 MURO: Buscando posts con profile_user_id=${filter.userId}');

      
      // Fetch posts with author info and user likes from PROFILE_WALL_POSTS table
      final response = await supabase
          .from('profile_wall_posts')
          .select('''
            *,
            author:users_global!profile_wall_posts_author_id_fkey(username, avatar_global_url),
            user_likes:profile_wall_post_likes(user_id)
          ''')
          .eq('profile_user_id', filter.userId)
          .eq('community_id', filter.communityId)
          .order('created_at', ascending: false)
          .limit(50);
      
      // Fetch comments count for each post
      final postIds = (response as List).map((p) => p['id'] as String).toList();
      final authorIds = (response as List).map((p) => p['author_id'] as String).toSet().toList();
      
      final commentsCounts = <String, int>{};
      final localProfiles = <String, Map<String, dynamic>>{};
      
      // Parallel fetch: Comments counts AND Local Profiles
      await Future.wait([
        // Fetch comments counts
        Future(() async {
          if (postIds.isNotEmpty) {
            final commentsResponse = await supabase
                .from('profile_wall_post_comments')
                .select('post_id')
                .inFilter('post_id', postIds);
            
            for (final comment in commentsResponse as List) {
              final postId = comment['post_id'] as String;
              commentsCounts[postId] = (commentsCounts[postId] ?? 0) + 1;
            }
          }
        }),
        // Fetch local profiles for authors in this community
        Future(() async {
          if (authorIds.isNotEmpty) {
             final profilesResponse = await supabase
                 .from('community_members')
                 .select('user_id, nickname, avatar_url')
                 .eq('community_id', filter.communityId)
                 .inFilter('user_id', authorIds);
                 
             for (final profile in profilesResponse as List) {
               localProfiles[profile['user_id']] = profile;
             }
          }
        }),
      ]);
      
      // Inject local profile data into post response (override global author)
      for (final post in response as List) {
        post['comments_count'] = commentsCounts[post['id']] ?? 0;
        
        final authorId = post['author_id'];
        final localProfile = localProfiles[authorId];
        
        if (localProfile != null) {
          // If local profile exists, inject it into the 'author' map
          // We modify the 'author' map which currently holds users_global data
          if (post['author'] == null) post['author'] = <String, dynamic>{};
          
          if (localProfile['nickname'] != null) {
            post['author']['username'] = localProfile['nickname'];
          }
          if (localProfile['avatar_url'] != null) {
            post['author']['avatar_global_url'] = localProfile['avatar_url'];
          }
        }
      }

      print('📦 MURO: Recibidos ${(response as List).length} posts');

      final posts = WallPostModel.listFromSupabase(
        response as List<dynamic>,
        currentUser?.id,
      );
      
      print('✅ MURO: Posts procesados exitosamente');
      state = AsyncValue.data(posts);
    } catch (e, stackTrace) {
      print('❌ ERROR REFRESH MURO: $e');
      print('📍 Stack trace: $stackTrace');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Create a new wall post
  Future<bool> createWallPost(String content) async {
    if (content.trim().isEmpty) {
      print('❌ MURO: Contenido vacío');
      return false;
    }

    try {
      final supabase = Supabase.instance.client;
      final currentUser = ref.read(currentUserProvider);
      
      if (currentUser == null) {
        print('❌ MURO: Usuario no autenticado');
        return false;
      }

      final payload = {
        'profile_user_id': filter.userId,
        'community_id': filter.communityId,
        'author_id': currentUser.id,
        'content': content.trim(),
      };
      
      print('📤 MURO: Insertando post -> $payload');
      
      await supabase.from('profile_wall_posts').insert(payload);

      print('✅ MURO: Post insertado exitosamente');
      
      // Refresh the list to show the new post
      await refresh();
      return true;
    } catch (e, stackTrace) {
      print('❌ ERROR MURO: $e');
      print('📍 Stack trace: $stackTrace');
      // Keep current state, don't overwrite with error
      return false;
    }
  }

  /// Delete a wall post
  Future<bool> deleteWallPost(String postId) async {
    try {
      final supabase = Supabase.instance.client;
      
      await supabase
          .from('profile_wall_posts')
          .delete()
          .eq('id', postId);

      // Refresh the list
      await refresh();
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Toggle like on a wall post (optimistic UI)
  Future<void> toggleLike(String postId) async {
    final currentState = state.value;
    if (currentState == null) return;
    
    // Find the post
    final postIndex = currentState.indexWhere((p) => p.id == postId);
    if (postIndex == -1) return;
    
    final post = currentState[postIndex];
    final wasLiked = post.isLikedByCurrentUser;
    
    // Optimistic update: Update UI immediately
    final updatedPost = post.copyWith(
      isLikedByCurrentUser: !wasLiked,
      likes: wasLiked ? post.likes - 1 : post.likes + 1,
    );
    
    final updatedPosts = List<WallPost>.from(currentState);
    updatedPosts[postIndex] = updatedPost;
    state = AsyncValue.data(updatedPosts);
    
    try {
      final supabase = Supabase.instance.client;
      final currentUser = ref.read(currentUserProvider);
      
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      if (wasLiked) {
        // Unlike: Delete the like
        await supabase
            .from('profile_wall_post_likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', currentUser.id);
      } else {
        // Like: Insert a new like
        await supabase
            .from('profile_wall_post_likes')
            .insert({
              'post_id': postId,
              'user_id': currentUser.id,
            });
      }
      
      print('✅ LIKE: Toggled successfully');
    } catch (e, stackTrace) {
      print('❌ ERROR TOGGLE LIKE: $e');
      print('📍 Stack trace: $stackTrace');
      
      // Rollback on error: Revert to original state
      final revertedPosts = List<WallPost>.from(currentState);
      revertedPosts[postIndex] = post;
      state = AsyncValue.data(revertedPosts);
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
