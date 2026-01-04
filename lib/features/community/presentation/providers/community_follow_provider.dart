/// Project Neo - Community Follow Providers
///
/// Riverpod providers for follow system
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/community_follow_repository.dart';

// ═══════════════════════════════════════════════════════════════════════════
// REPOSITORY PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

final communityFollowRepositoryProvider =
    Provider<CommunityFollowRepository>((ref) {
  return CommunityFollowRepository(Supabase.instance.client);
});

// ═══════════════════════════════════════════════════════════════════════════
// FOLLOW STATUS PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

class FollowStatusParams {
  final String communityId;
  final String targetUserId;

  const FollowStatusParams({
    required this.communityId,
    required this.targetUserId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FollowStatusParams &&
          runtimeType == other.runtimeType &&
          communityId == other.communityId &&
          targetUserId == other.targetUserId;

  @override
  int get hashCode => communityId.hashCode ^ targetUserId.hashCode;
}

/// Check if current user follows another user
final followStatusProvider =
    FutureProvider.family<bool, FollowStatusParams>((ref, params) async {
  final repo = ref.read(communityFollowRepositoryProvider);
  return repo.isFollowing(
    communityId: params.communityId,
    targetUserId: params.targetUserId,
  );
});

// ═══════════════════════════════════════════════════════════════════════════
// COUNT PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// Get follower count for a user in a community
final communityFollowerCountProvider =
    FutureProvider.autoDispose.family<int, FollowStatusParams>((ref, params) async {
  final repo = ref.read(communityFollowRepositoryProvider);
  return repo.getFollowerCount(
    communityId: params.communityId,
    userId: params.targetUserId,
  );
});

/// Get following count for a user in a community
final communityFollowingCountProvider =
    FutureProvider.autoDispose.family<int, FollowStatusParams>((ref, params) async {
  final repo = ref.read(communityFollowRepositoryProvider);
  return repo.getFollowingCount(
    communityId: params.communityId,
    userId: params.targetUserId,
  );
});

// ═══════════════════════════════════════════════════════════════════════════
// FOLLOW ACTIONS NOTIFIER
// ═══════════════════════════════════════════════════════════════════════════

class FollowActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final CommunityFollowRepository _repo;
  final Ref _ref;

  FollowActionsNotifier(this._repo, this._ref)
      : super(const AsyncValue.data(null));

  /// Toggle follow status
  Future<bool> toggleFollow({
    required String communityId,
    required String targetUserId,
    required bool currentlyFollowing,
  }) async {
    state = const AsyncValue.loading();

    final success = await _repo.toggleFollow(
      communityId: communityId,
      targetUserId: targetUserId,
      currentlyFollowing: currentlyFollowing,
    );

    state = const AsyncValue.data(null);

    if (success) {
      // 1. Invalidate follow status (am I following them?)
      _ref.invalidate(followStatusProvider(FollowStatusParams(
        communityId: communityId,
        targetUserId: targetUserId,
      )));

      // 2. Invalidate FOLLOWER count of the TARGET user (B)
      // Because I (A) just followed/unfollowed B
      _ref.invalidate(communityFollowerCountProvider(FollowStatusParams(
        communityId: communityId,
        targetUserId: targetUserId,
      )));

      // 3. Invalidate FOLLOWING count of CURRENT user (A)
      // Because I (A) just started/stopped following B
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      
      if (currentUserId != null) {
        _ref.invalidate(communityFollowingCountProvider(FollowStatusParams(
          communityId: communityId,
          targetUserId: currentUserId,
        )));
      }
    }

    return success;
  }
}

/// Provider for follow actions
final followActionsProvider =
    StateNotifierProvider<FollowActionsNotifier, AsyncValue<void>>((ref) {
  final repo = ref.read(communityFollowRepositoryProvider);
  return FollowActionsNotifier(repo, ref);
});
