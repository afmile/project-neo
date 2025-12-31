/// Project Neo - Moderation Repository Interface
///
/// Handles strikes and content moderation
library;

import '../../domain/entities/strike_entity.dart';

abstract class ModerationRepository {
  // ============================================================================
  // STRIKES
  // ============================================================================
  
  /// Get all strikes for a user in a community
  Future<List<Strike>> getUserStrikes(String userId, String communityId);
  
  /// Count active strikes for a user in a community
  Future<int> countActiveStrikes(String userId, String communityId);
  
  /// Assign a strike to a user
  Future<Strike> assignStrike({
    required String communityId,
    required String userId,
    required String reason,
    String? contentType,
    String? contentId,
  });
  
  /// Revoke a strike
  Future<void> revokeStrike({
    required String strikeId,
    required String reason,
  });
  
  /// Get strikes that need review (users with 3+ strikes)
  Future<Map<String, List<Strike>>> getStrikesNeedingReview(String communityId);
  
  // ============================================================================
  // CONTENT MODERATION
  // ============================================================================
  
  /// Hide a wall post (soft delete)
  Future<void> hideWallPost(String postId);
  
  /// Delete a wall post (hard delete)
  Future<void> deleteWallPost(String postId);
  
  /// Unhide a wall post
  Future<void> unhideWallPost(String postId);
}
