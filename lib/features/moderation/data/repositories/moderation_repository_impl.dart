/// Project Neo - Moderation Repository Implementation
///
/// Supabase implementation for moderation operations
library;

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/strike_entity.dart';
import '../../domain/repositories/moderation_repository.dart';
import '../models/strike_model.dart';

class ModerationRepositoryImpl implements ModerationRepository {
  final SupabaseClient _supabase;

  ModerationRepositoryImpl(this._supabase);

  @override
  Future<List<Strike>> getUserStrikes(String userId, String communityId) async {
    try {
      final response = await _supabase
          .from('community_strikes')
          .select()
          .eq('user_id', userId)
          .eq('community_id', communityId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => StrikeModel.fromJson(json).toEntity())
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch user strikes: $e');
    }
  }

  @override
  Future<int> countActiveStrikes(String userId, String communityId) async {
    try {
      final response = await _supabase.rpc(
        'count_active_strikes',
        params: {
          'p_user_id': userId,
          'p_community_id': communityId,
        },
      );

      return response as int;
    } catch (e) {
      throw Exception('Failed to count active strikes: $e');
    }
  }

  @override
  Future<Strike> assignStrike({
    required String communityId,
    required String userId,
    required String reason,
    String? contentType,
    String? contentId,
  }) async {
    try {
      final response = await _supabase
          .from('community_strikes')
          .insert({
            'community_id': communityId,
            'user_id': userId,
            'moderator_id': _supabase.auth.currentUser!.id,
            'reason': reason,
            'content_type': contentType,
            'content_id': contentId,
            'status': 'active',
          })
          .select()
          .single();

      return StrikeModel.fromJson(response).toEntity();
    } catch (e) {
      throw Exception('Failed to assign strike: $e');
    }
  }

  @override
  Future<void> revokeStrike({
    required String strikeId,
    required String reason,
  }) async {
    try {
      await _supabase
          .from('community_strikes')
          .update({
            'status': 'revoked',
            'revoked_at': DateTime.now().toIso8601String(),
            'revoked_by': _supabase.auth.currentUser!.id,
            'revoke_reason': reason,
          })
          .eq('id', strikeId);
    } catch (e) {
      throw Exception('Failed to revoke strike: $e');
    }
  }

  @override
  Future<Map<String, List<Strike>>> getStrikesNeedingReview(
    String communityId,
  ) async {
    try {
      // Get all active strikes in the community
      final response = await _supabase
          .from('community_strikes')
          .select()
          .eq('community_id', communityId)
          .eq('status', 'active')
          .order('created_at', ascending: false);

      final strikes = (response as List)
          .map((json) => StrikeModel.fromJson(json).toEntity())
          .toList();

      // Group by user and filter users with 3+ strikes
      final Map<String, List<Strike>> grouped = {};
      for (final strike in strikes) {
        grouped.putIfAbsent(strike.userId, () => []).add(strike);
      }

      // Filter only users with 3+ strikes
      grouped.removeWhere((userId, userStrikes) => userStrikes.length < 3);

      return grouped;
    } catch (e) {
      throw Exception('Failed to fetch strikes needing review: $e');
    }
  }

  @override
  Future<void> hideWallPost(String postId) async {
    try {
      await _supabase
          .from('wall_posts')
          .update({'is_hidden': true})
          .eq('id', postId);
    } catch (e) {
      throw Exception('Failed to hide wall post: $e');
    }
  }

  @override
  Future<void> deleteWallPost(String postId) async {
    try {
      await _supabase.from('wall_posts').delete().eq('id', postId);
    } catch (e) {
      throw Exception('Failed to delete wall post: $e');
    }
  }

  @override
  Future<void> unhideWallPost(String postId) async {
    try {
      await _supabase
          .from('wall_posts')
          .update({'is_hidden': false})
          .eq('id', postId);
    } catch (e) {
      throw Exception('Failed to unhide wall post: $e');
    }
  }
}
