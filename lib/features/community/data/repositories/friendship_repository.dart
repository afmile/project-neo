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
          .select('''
            *,
            requester:users_global!friendship_requests_requester_id_fkey(username, avatar_global_url)
          ''')
          .eq('community_id', communityId)
          .eq('recipient_id', _currentUserId!)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return (response as List<dynamic>).map((json) {
        final requester = json['requester'] as Map<String, dynamic>?;
        return _fromJson(json, requesterData: requester);
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
          .select('''
            *,
            requester:users_global!friendship_requests_requester_id_fkey(username, avatar_global_url),
            recipient:users_global!friendship_requests_recipient_id_fkey(username, avatar_global_url)
          ''')
          .eq('community_id', communityId)
          .eq('status', 'accepted')
          .or('requester_id.eq.$userId,recipient_id.eq.$userId');

      return (response as List<dynamic>).map((json) {
        final requester = json['requester'] as Map<String, dynamic>?;
        final recipient = json['recipient'] as Map<String, dynamic>?;
        return _fromJson(json, requesterData: requester, recipientData: recipient);
      }).toList();
    } catch (e) {
      print('❌ ERROR getFriends: $e');
      return [];
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
