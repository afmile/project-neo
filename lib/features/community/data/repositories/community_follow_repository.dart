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

  /// Get list of followers with user data
  Future<List<Map<String, dynamic>>> getFollowersList({
    required String communityId,
    required String userId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('community_follows')
          .select('''
            follower_id,
            follower:users_global!community_follows_follower_id_fkey(username, avatar_global_url, bio)
          ''')
          .eq('community_id', communityId)
          .eq('followed_id', userId)
          .eq('is_active', true)
          .range(offset, offset + limit - 1); // Pagination

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ ERROR getFollowersList: $e');
      return [];
    }
  }

  /// Get list of following with user data
  Future<List<Map<String, dynamic>>> getFollowingList({
    required String communityId,
    required String userId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('community_follows')
          .select('''
            followed_id,
            followed:users_global!community_follows_followed_id_fkey(username, avatar_global_url, bio)
          ''')
          .eq('community_id', communityId)
          .eq('follower_id', userId)
          .eq('is_active', true)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(response);
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
