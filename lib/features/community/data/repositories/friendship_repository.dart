/// Project Neo - Friendship Repository
///
/// Handles friendship requests and status within communities
library;

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/friendship_request.dart';

class FriendshipRepository {
  final SupabaseClient _supabase;

  FriendshipRepository(this._supabase);

  String? get _currentUserId => _supabase.auth.currentUser?.id;

  // ═══════════════════════════════════════════════════════════════════════════
  // FETCH OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get pending friendship requests for current user
  Future<List<FriendshipRequest>> getPendingRequests(String communityId) async {
    try {
      final response = await _supabase
          .from('friendship_requests')
          .select('*')
          .eq('community_id', communityId)
          .eq('recipient_id', _currentUserId!)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      final requests = response as List<dynamic>;
      if (requests.isEmpty) return [];

      // Collect all requester IDs
      final requesterIds = requests.map((r) => r['requester_id'] as String).toSet();

      // Fetch local profiles from community_members
      final localProfiles = await _supabase
          .from('community_members')
          .select('user_id, nickname, avatar_url')
          .eq('community_id', communityId)
          .inFilter('user_id', requesterIds.toList());

      // Build lookup map
      final profileMap = <String, Map<String, dynamic>>{};
      for (final profile in localProfiles as List) {
        profileMap[profile['user_id'] as String] = profile;
      }

      return requests.map((json) {
        final requesterId = json['requester_id'] as String;
        final localProfile = profileMap[requesterId];
        return _fromJson(
          json,
          requesterData: localProfile != null
              ? {
                  'username': localProfile['nickname'],
                  'avatar_global_url': localProfile['avatar_url'],
                }
              : null,
        );
      }).toList();
    } catch (e) {
      print('❌ ERROR getPendingRequests: $e');
      return [];
    }
  }

  /// Get all friends (accepted requests) for a user in a community
  Future<List<FriendshipRequest>> getFriends(String communityId, String userId) async {
    try {
      final response = await _supabase
          .from('friendship_requests')
          .select('*')
          .eq('community_id', communityId)
          .eq('status', 'accepted')
          .or('requester_id.eq.$userId,recipient_id.eq.$userId');

      final requests = response as List<dynamic>;
      if (requests.isEmpty) return [];

      // Collect all user IDs (both requesters and recipients)
      final userIds = <String>{};
      for (final r in requests) {
        userIds.add(r['requester_id'] as String);
        userIds.add(r['recipient_id'] as String);
      }

      // Fetch local profiles from community_members
      final localProfiles = await _supabase
          .from('community_members')
          .select('user_id, nickname, avatar_url')
          .eq('community_id', communityId)
          .inFilter('user_id', userIds.toList());

      // Build lookup map
      final profileMap = <String, Map<String, dynamic>>{};
      for (final profile in localProfiles as List) {
        profileMap[profile['user_id'] as String] = profile;
      }

      return requests.map((json) {
        final requesterId = json['requester_id'] as String;
        final recipientId = json['recipient_id'] as String;
        final requesterProfile = profileMap[requesterId];
        final recipientProfile = profileMap[recipientId];
        
        return _fromJson(
          json,
          requesterData: requesterProfile != null
              ? {
                  'username': requesterProfile['nickname'],
                  'avatar_global_url': requesterProfile['avatar_url'],
                }
              : null,
          recipientData: recipientProfile != null
              ? {
                  'username': recipientProfile['nickname'],
                  'avatar_global_url': recipientProfile['avatar_url'],
                }
              : null,
        );
      }).toList();
    } catch (e) {
      print('❌ ERROR getFriends: $e');
      return [];
    }
  }

  /// Get ONLY IDs of friends for a user in a community (Optimized for badges)
  Future<Set<String>> getFriendIds(String communityId, String userId) async {
    try {
      final response = await _supabase
          .from('friendship_requests')
          .select('requester_id, recipient_id')
          .eq('community_id', communityId)
          .eq('status', 'accepted')
          .or('requester_id.eq.$userId,recipient_id.eq.$userId');

      final ids = <String>{};
      for (final item in response as List) {
        final reqId = item['requester_id'] as String;
        final recId = item['recipient_id'] as String;
        
        // Add the OTHER ID to the set
        if (reqId == userId) {
          ids.add(recId);
        } else {
          ids.add(reqId);
        }
      }
      return ids;
    } catch (e) {
      print('❌ ERROR getFriendIds: $e');
      return {};
    }
  }

  /// Check if a friendship request exists between two users
  Future<FriendshipRequest?> getExistingRequest(
    String communityId,
    String userA,
    String userB,
  ) async {
    try {
      final response = await _supabase
          .from('friendship_requests')
          .select()
          .eq('community_id', communityId)
          .or('and(requester_id.eq.$userA,recipient_id.eq.$userB),and(requester_id.eq.$userB,recipient_id.eq.$userA)')
          .maybeSingle();

      if (response == null) return null;
      return _fromJson(response);
    } catch (e) {
      print('❌ ERROR getExistingRequest: $e');
      return null;
    }
  }

  /// Check if two users are friends
  Future<bool> areFriends(String communityId, String userA, String userB) async {
    try {
      final response = await _supabase
          .rpc('are_friends', params: {
            'p_community_id': communityId,
            'p_user_a': userA,
            'p_user_b': userB,
          });
      return response as bool? ?? false;
    } catch (e) {
      print('❌ ERROR areFriends: $e');
      return false;
    }
  }

  /// Check if two users have mutual follow
  Future<bool> haveMutualFollow(String communityId, String userA, String userB) async {
    try {
      final response = await _supabase
          .rpc('have_mutual_follow', params: {
            'p_community_id': communityId,
            'p_user_a': userA,
            'p_user_b': userB,
          });
      return response as bool? ?? false;
    } catch (e) {
      print('❌ ERROR haveMutualFollow: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Send a friendship request
  Future<FriendshipRequest?> sendRequest(String communityId, String recipientId) async {
    try {
      final response = await _supabase
          .from('friendship_requests')
          .insert({
            'community_id': communityId,
            'requester_id': _currentUserId,
            'recipient_id': recipientId,
            'status': 'pending',
          })
          .select()
          .single();

      return _fromJson(response);
    } catch (e) {
      // Handle duplicate request (race condition or retrying rejected)
      if (e.toString().contains('23505') || e.toString().contains('friendship_requests_unique')) {
        print('⚠️ Friendship request already exists, fetching existing...');
        return getExistingRequest(communityId, _currentUserId!, recipientId);
      }

      print('❌ ERROR sendRequest: $e');
      return null;
    }
  }

  /// Accept a friendship request
  Future<bool> acceptRequest(String requestId) async {
    try {
      await _supabase
          .from('friendship_requests')
          .update({
            'status': 'accepted',
            'responded_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId)
          .eq('recipient_id', _currentUserId!);

      return true;
    } catch (e) {
      print('❌ ERROR acceptRequest: $e');
      return false;
    }
  }

  /// Reject a friendship request
  Future<bool> rejectRequest(String requestId) async {
    try {
      await _supabase
          .from('friendship_requests')
          .update({
            'status': 'rejected',
            'responded_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId)
          .eq('recipient_id', _currentUserId!);

      return true;
    } catch (e) {
      print('❌ ERROR rejectRequest: $e');
      return false;
    }
  }

  /// Cancel a pending request (by requester)
  Future<bool> cancelRequest(String requestId) async {
    try {
      await _supabase
          .from('friendship_requests')
          .delete()
          .eq('id', requestId)
          .eq('requester_id', _currentUserId!)
          .eq('status', 'pending');

      return true;
    } catch (e) {
      print('❌ ERROR cancelRequest: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  FriendshipRequest _fromJson(
    Map<String, dynamic> json, {
    Map<String, dynamic>? requesterData,
    Map<String, dynamic>? recipientData,
  }) {
    return FriendshipRequest(
      id: json['id'] as String,
      communityId: json['community_id'] as String,
      requesterId: json['requester_id'] as String,
      recipientId: json['recipient_id'] as String,
      status: _parseStatus(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      respondedAt: json['responded_at'] != null
          ? DateTime.parse(json['responded_at'] as String)
          : null,
      requesterName: requesterData?['username'] as String?,
      requesterAvatar: requesterData?['avatar_global_url'] as String?,
      recipientName: recipientData?['username'] as String?,
      recipientAvatar: recipientData?['avatar_global_url'] as String?,
    );
  }
  /// Remove friendship (delete request)
  Future<bool> removeFriendship(String communityId, String otherUserId) async {
    try {
      if (_currentUserId == null) return false;

      await _supabase
          .from('friendship_requests')
          .delete()
          .eq('community_id', communityId)
          .or('and(requester_id.eq.$_currentUserId,recipient_id.eq.$otherUserId),and(requester_id.eq.$otherUserId,recipient_id.eq.$_currentUserId)');
      
      return true;
    } catch (e) {
      print('❌ ERROR removeFriendship: $e');
      return false;
    }
  }


  FriendshipStatus _parseStatus(String status) {
    switch (status) {
      case 'accepted':
        return FriendshipStatus.accepted;
      case 'rejected':
        return FriendshipStatus.rejected;
      default:
        return FriendshipStatus.pending;
    }
  }
}
