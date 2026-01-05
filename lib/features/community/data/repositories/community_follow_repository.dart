/// Project Neo - Community Follow Repository
///
/// Handles follow/unfollow operations within communities
library;

import 'package:supabase_flutter/supabase_flutter.dart';

class CommunityFollowRepository {
  final SupabaseClient _supabase;

  CommunityFollowRepository(this._supabase);

  String? get _currentUserId => _supabase.auth.currentUser?.id;

  // ═══════════════════════════════════════════════════════════════════════════
  // QUERY OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Check if current user follows another user in a community
  Future<bool> isFollowing({
    required String communityId,
    required String targetUserId,
  }) async {
    if (_currentUserId == null) return false;

    try {
      final response = await _supabase.rpc('is_following', params: {
        'p_community_id': communityId,
        'p_follower_id': _currentUserId,
        'p_followed_id': targetUserId,
      });
      return response as bool? ?? false;
    } catch (e) {
      print('❌ ERROR isFollowing: $e');
      return false;
    }
  }

  /// Get follower count for a user in a community
  Future<int> getFollowerCount({
    required String communityId,
    required String userId,
  }) async {
    try {
      final response = await _supabase.rpc('count_followers', params: {
        'p_community_id': communityId,
        'p_user_id': userId,
      });
      return response as int? ?? 0;
    } catch (e) {
      print('❌ ERROR getFollowerCount: $e');
      return 0;
    }
  }

  /// Get following count for a user in a community
  Future<int> getFollowingCount({
    required String communityId,
    required String userId,
  }) async {
    try {
      final response = await _supabase.rpc('count_following', params: {
        'p_community_id': communityId,
        'p_user_id': userId,
      });
      return response as int? ?? 0;
    } catch (e) {
      print('❌ ERROR getFollowingCount: $e');
      return 0;
    }
  }

  /// Get list of followers with user data (using local nicknames)
  Future<List<Map<String, dynamic>>> getFollowersList({
    required String communityId,
    required String userId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('community_follows')
          .select('follower_id')
          .eq('community_id', communityId)
          .eq('followed_id', userId)
          .eq('is_active', true)
          .range(offset, offset + limit - 1);

      final follows = response as List;
      if (follows.isEmpty) return [];

      // Collect all follower IDs
      final followerIds = follows.map((f) => f['follower_id'] as String).toList();

      // Fetch local profiles from community_members
      final localProfiles = await _supabase
          .from('community_members')
          .select('user_id, nickname, avatar_url, bio')
          .eq('community_id', communityId)
          .inFilter('user_id', followerIds);

      // Build result with local profile data
      final profileMap = <String, Map<String, dynamic>>{};
      for (final profile in localProfiles as List) {
        profileMap[profile['user_id'] as String] = profile;
      }

      return follows.map((f) {
        final followerId = f['follower_id'] as String;
        final localProfile = profileMap[followerId];
        return {
          'follower_id': followerId,
          'follower': {
            'username': localProfile?['nickname'] ?? 'Usuario',
            'avatar_global_url': localProfile?['avatar_url'],
            'bio': localProfile?['bio'],
          },
        };
      }).toList();
    } catch (e) {
      print('❌ ERROR getFollowersList: $e');
      return [];
    }
  }

  /// Get list of following with user data (using local nicknames)
  Future<List<Map<String, dynamic>>> getFollowingList({
    required String communityId,
    required String userId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('community_follows')
          .select('followed_id')
          .eq('community_id', communityId)
          .eq('follower_id', userId)
          .eq('is_active', true)
          .range(offset, offset + limit - 1);

      final follows = response as List;
      if (follows.isEmpty) return [];

      // Collect all followed IDs
      final followedIds = follows.map((f) => f['followed_id'] as String).toList();

      // Fetch local profiles from community_members
      final localProfiles = await _supabase
          .from('community_members')
          .select('user_id, nickname, avatar_url, bio')
          .eq('community_id', communityId)
          .inFilter('user_id', followedIds);

      // Build result with local profile data
      final profileMap = <String, Map<String, dynamic>>{};
      for (final profile in localProfiles as List) {
        profileMap[profile['user_id'] as String] = profile;
      }

      return follows.map((f) {
        final followedId = f['followed_id'] as String;
        final localProfile = profileMap[followedId];
        return {
          'followed_id': followedId,
          'followed': {
            'username': localProfile?['nickname'] ?? 'Usuario',
            'avatar_global_url': localProfile?['avatar_url'],
            'bio': localProfile?['bio'],
          },
        };
      }).toList();
    } catch (e) {
      print('❌ ERROR getFollowingList: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MUTATION OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Follow a user in a community
  Future<bool> follow({
    required String communityId,
    required String targetUserId,
  }) async {
    // STEP 1: Check auth state
    if (_currentUserId == null) return false;

    // STEP 3: Build payload
    final payload = {
      'community_id': communityId,
      'follower_id': _currentUserId,
      'followed_id': targetUserId,
      'is_active': true,
    };
    
    // STEP 4: Attempt INSERT
    try {
      await _supabase
          .from('community_follows')
          .insert(payload)
          .select();

      return true;
    } catch (e) {
      print('❌ [ERROR] Follow INSERT failed: $e');
      
      // Check specific error types
      if (e is PostgrestException) {
        print('❌ [POSTGREST] Code: ${e.code}');
        print('❌ [POSTGREST] Message: ${e.message}');
        print('❌ [POSTGREST] Details: ${e.details}');
        print('❌ [POSTGREST] Hint: ${e.hint}');
      }
      
      // Check if already following (unique constraint violation)
      if (e.toString().contains('community_follows_unique') || 
          e.toString().contains('duplicate key')) {
        print('⚠️ [RETRY] Duplicate detected, attempting to reactivate...');
        try {
          final updateResponse = await _supabase
              .from('community_follows')
              .update({'is_active': true, 'updated_at': DateTime.now().toIso8601String()})
              .eq('community_id', communityId)
              .eq('follower_id', _currentUserId!)
              .eq('followed_id', targetUserId)
              .select();

          print('✅ [SUCCESS] Reactivated follow');
          print('✅ [RESPONSE] $updateResponse');
          return true;
        } catch (updateError) {
          print('❌ [ERROR] Reactivation failed: $updateError');
          return false;
        }
      }

      print('❌ [FINAL] Follow operation failed completely');
      print('═══════════════════════════════════════════════════════\n');
      return false;
    }
  }

  /// Unfollow a user in a community (soft delete)
  Future<bool> unfollow({
    required String communityId,
    required String targetUserId,
  }) async {
    if (_currentUserId == null) return false;

    try {
      await _supabase
          .from('community_follows')
          .update({'is_active': false, 'updated_at': DateTime.now().toIso8601String()})
          .eq('community_id', communityId)
          .eq('follower_id', _currentUserId!)
          .eq('followed_id', targetUserId);

      print('✅ Successfully unfollowed user $targetUserId');
      return true;
    } catch (e) {
      print('❌ ERROR unfollow: $e');
      return false;
    }
  }

  /// Toggle follow status
  Future<bool> toggleFollow({
    required String communityId,
    required String targetUserId,
    required bool currentlyFollowing,
  }) async {
    if (currentlyFollowing) {
      return await unfollow(communityId: communityId, targetUserId: targetUserId);
    } else {
      return await follow(communityId: communityId, targetUserId: targetUserId);
    }
  }
}
