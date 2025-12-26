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

/// Provider to fetch a user profile by ID
final userProfileProvider = FutureProvider.family<UserEntity?, String>((ref, userId) async {
  final supabase = Supabase.instance.client;

  try {
    // parallel fetch for performance
    final responses = await Future.wait([
      supabase.from('users_global').select().eq('id', userId).maybeSingle(),
      supabase.from('security_profile').select().eq('user_id', userId).maybeSingle(),
      // We don't fetch wallet for others for privacy usually, or maybe we do for public stats?
      // For now omitting wallet/neocoins for other users unless public.
    ]);

    final userGlobal = responses[0] as Map<String, dynamic>?;
    final securityProfile = responses[1] as Map<String, dynamic>?;
    
    if (userGlobal == null) return null;

    // Use UserModel factory
    // We pass null for wallet so neocoins might be 0, which is fine for other users.
    return UserModel.fromSupabase(
      id: userId,
      email: '', // Email is private usually, not returned in public select
      userGlobal: userGlobal,
      securityProfile: securityProfile,
      wallet: null,
    );
  } catch (e) {
    // If error (e.g. RLS), return null or rethrow
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
  final String userId;
  final Ref ref;
  
  UserWallPostsNotifier(this.userId, this.ref) : super(const AsyncValue.loading()) {
    refresh();
  }

  /// Refresh wall posts from database
  Future<void> refresh() async {
    print('🔄 MURO: Iniciando refresh para userId=$userId');
    state = const AsyncValue.loading();
    
    try {
      final supabase = Supabase.instance.client;
      final currentUser = ref.read(currentUserProvider);

      print('🔍 MURO: Buscando posts con profile_user_id=$userId');
      
      // Fetch posts with author info and user likes
      final response = await supabase
          .from('wall_posts')
          .select('''
            *,
            author:users_global!wall_posts_author_id_fkey(username, avatar_global_url),
            user_likes:wall_post_likes(user_id)
          ''')
          .eq('profile_user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);
      
      // Fetch comments count for each post
      final postIds = (response as List).map((p) => p['id'] as String).toList();
      final commentsCounts = <String, int>{};
      
      if (postIds.isNotEmpty) {
        final commentsResponse = await supabase
            .from('wall_post_comments')
            .select('post_id')
            .inFilter('post_id', postIds);
        
        // Count comments per post
        for (final comment in commentsResponse as List) {
          final postId = comment['post_id'] as String;
          commentsCounts[postId] = (commentsCounts[postId] ?? 0) + 1;
        }
      }
      
      // Add comments_count to each post
      for (final post in response as List) {
        post['comments_count'] = commentsCounts[post['id']] ?? 0;
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
        'profile_user_id': userId,
        'author_id': currentUser.id,
        'content': content.trim(),
      };
      
      print('📤 MURO: Insertando post -> $payload');
      
      await supabase.from('wall_posts').insert(payload);

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
          .from('wall_posts')
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
            .from('wall_post_likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', currentUser.id);
      } else {
        // Like: Insert a new like
        await supabase
            .from('wall_post_likes')
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
final userWallPostsProvider = StateNotifierProvider.family<
    UserWallPostsNotifier,
    AsyncValue<List<WallPost>>,
    String
>((ref, userId) {
  return UserWallPostsNotifier(userId, ref);
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
