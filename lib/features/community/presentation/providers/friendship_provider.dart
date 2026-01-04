/// Project Neo - Friendship Providers
///
/// Riverpod providers for friendship system
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/friendship_request.dart';
import '../../data/repositories/friendship_repository.dart';

// ═══════════════════════════════════════════════════════════════════════════
// REPOSITORY PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

final friendshipRepositoryProvider = Provider<FriendshipRepository>((ref) {
  return FriendshipRepository(Supabase.instance.client);
});

// ═══════════════════════════════════════════════════════════════════════════
// PENDING REQUESTS PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

/// Get pending friendship requests for current user in a community
final pendingFriendshipRequestsProvider = FutureProvider.autoDispose.family<List<FriendshipRequest>, String>(
  (ref, communityId) async {
    final repo = ref.read(friendshipRepositoryProvider);
    return repo.getPendingRequests(communityId);
  },
);

// ═══════════════════════════════════════════════════════════════════════════
// FRIENDSHIP STATUS PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

class FriendshipCheckParams {
  final String communityId;
  final String otherUserId;

  const FriendshipCheckParams({
    required this.communityId,
    required this.otherUserId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FriendshipCheckParams &&
          runtimeType == other.runtimeType &&
          communityId == other.communityId &&
          otherUserId == other.otherUserId;

  @override
  int get hashCode => communityId.hashCode ^ otherUserId.hashCode;
}

/// Check friendship status with another user
final friendshipStatusProvider = FutureProvider.autoDispose.family<FriendshipStatusInfo, FriendshipCheckParams>(
  (ref, params) async {
    final repo = ref.read(friendshipRepositoryProvider);
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    if (currentUserId == null) {
      return const FriendshipStatusInfo(
        areFriends: false,
        haveMutualFollow: false,
        canSendRequest: false,
        pendingRequest: null,
      );
    }
    
    // Subscribe to realtime changes for this specific relationship (Optional but good for UX)
    // For now, autoDispose ensures we fetch fresh data every time we enter the screen.

    // Check if already friends
    final areFriends = await repo.areFriends(
      params.communityId,
      currentUserId,
      params.otherUserId,
    );

    if (areFriends) {
      return const FriendshipStatusInfo(
        areFriends: true,
        haveMutualFollow: true,
        canSendRequest: false,
        pendingRequest: null,
      );
    }

    // Check for existing request
    final existingRequest = await repo.getExistingRequest(
      params.communityId,
      currentUserId,
      params.otherUserId,
    );

    // Check mutual follow
    final mutualFollow = await repo.haveMutualFollow(
      params.communityId,
      currentUserId,
      params.otherUserId,
    );

    // Can send request only if mutual follow and no pending request exists
    final canSend = mutualFollow && existingRequest == null;

    // Determine if current user is the requester
    final iAmRequester = existingRequest?.requesterId == currentUserId;

    return FriendshipStatusInfo(
      areFriends: false,
      haveMutualFollow: mutualFollow,
      canSendRequest: canSend,
      pendingRequest: existingRequest?.isPending == true ? existingRequest : null,
      iAmRequester: iAmRequester,
    );
  },
);

/// Friendship status info
class FriendshipStatusInfo {
  final bool areFriends;
  final bool haveMutualFollow;
  final bool canSendRequest;
  final FriendshipRequest? pendingRequest;
  final bool iAmRequester; // True if current user sent the pending request

  const FriendshipStatusInfo({
    required this.areFriends,
    required this.haveMutualFollow,
    required this.canSendRequest,
    this.pendingRequest,
    this.iAmRequester = false,
  });

  /// True if there's a pending request (in either direction)
  bool get hasPendingRequest => pendingRequest != null;

  /// True if I sent the pending request
  bool get iSentRequest => hasPendingRequest && iAmRequester;

  /// True if I received the pending request  
  bool get iReceivedRequest => hasPendingRequest && !iAmRequester;
}

// ═══════════════════════════════════════════════════════════════════════════
// FRIENDS LIST PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

class FriendsListParams {
  final String communityId;
  final String userId;

  const FriendsListParams({
    required this.communityId,
    required this.userId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FriendsListParams &&
          runtimeType == other.runtimeType &&
          communityId == other.communityId &&
          userId == other.userId;

  @override
  int get hashCode => communityId.hashCode ^ userId.hashCode;
}

/// Get all friends for a user in a community
final friendsListProvider = FutureProvider.family<List<FriendshipRequest>, FriendsListParams>(
  (ref, params) async {
    final repo = ref.read(friendshipRepositoryProvider);
    return repo.getFriends(params.communityId, params.userId);
  },
);
