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

/// Provider to fetch wall posts for a user with author information
final userWallPostsProvider = FutureProvider.family<List<WallPost>, String>((ref, userId) async {
  final supabase = Supabase.instance.client;
  final currentUser = ref.watch(currentUserProvider);

  try {
    final response = await supabase
        .from('wall_posts')
        .select('*, author:users_global!wall_posts_author_id_fkey(id, username, avatar_url)')
        .eq('profile_user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);

    return WallPostModel.listFromSupabase(
      response as List<dynamic>,
      currentUser?.id,
    );
  } catch (e) {
    // Return empty list on error
    return [];
  }
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
