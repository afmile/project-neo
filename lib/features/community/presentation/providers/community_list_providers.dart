import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/domain/entities/user_entity.dart';
import 'friendship_provider.dart';
import 'community_follow_provider.dart';

// ═══════════════════════════════════════════════════════════════════════════
// FRIENDS LIST PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// Provider to fetch the list of friends for the current user in a community
/// Returns a list of UserEntity representing the friends
final communityFriendsListProvider = FutureProvider.autoDispose.family<List<UserEntity>, String>((ref, communityId) async {
  final repo = ref.read(friendshipRepositoryProvider);
  final currentUserId = Supabase.instance.client.auth.currentUser?.id;
  
  if (currentUserId == null) return [];

  // Pass currentUserId to get friends where I am requester OR recipient
  final requests = await repo.getFriends(communityId, currentUserId);

  return requests.map((req) {
    // Determine which user is the "friend" (the other person)
    final isMeRequester = req.requesterId == currentUserId;
    
    return UserEntity(
      id: isMeRequester ? req.recipientId : req.requesterId,
      username: (isMeRequester ? req.recipientName : req.requesterName) ?? 'Usuario',
      email: '', // Not needed for list
      avatarUrl: isMeRequester ? req.recipientAvatar : req.requesterAvatar,
      bio: '', // Bio not fetched in FriendshipRequest, generic view
      createdAt: DateTime.now(), // Fallback
    );
  }).toList();
});

/// Provider to fetch JUST the IDs of friends (optimized for checking badges)
final myFriendIdsProvider = FutureProvider.autoDispose.family<Set<String>, String>((ref, communityId) async {
  final repo = ref.read(friendshipRepositoryProvider);
  final currentUserId = Supabase.instance.client.auth.currentUser?.id;
  
  if (currentUserId == null) return {};

  return await repo.getFriendIds(communityId, currentUserId);
});

// ═══════════════════════════════════════════════════════════════════════════
// FOLLOW LIST PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// Provider to fetch list of followers for a user
final followersListProvider = FutureProvider.autoDispose.family<List<UserEntity>, FollowStatusParams>((ref, params) async {
  final repo = ref.read(communityFollowRepositoryProvider);
  
  final rawList = await repo.getFollowersList(
    communityId: params.communityId,
    userId: params.targetUserId,
    limit: 100, // Reasonable limit for now
  );

  return rawList.map((item) {
    final userMap = item['follower'] as Map<String, dynamic>? ?? {};
    
    return UserEntity(
      id: item['follower_id'] as String,
      username: userMap['username'] as String? ?? 'Usuario',
      email: '',
      avatarUrl: userMap['avatar_global_url'] as String?,
      bio: userMap['bio'] as String?,
      createdAt: DateTime.now(), // Fallback
    );
  }).toList();
});

/// Provider to fetch list of users being followed by a user
final followingListProvider = FutureProvider.autoDispose.family<List<UserEntity>, FollowStatusParams>((ref, params) async {
  final repo = ref.read(communityFollowRepositoryProvider);
  
  final rawList = await repo.getFollowingList(
    communityId: params.communityId,
    userId: params.targetUserId,
    limit: 100,
  );

  return rawList.map((item) {
    final userMap = item['followed'] as Map<String, dynamic>? ?? {};
    
    return UserEntity(
      id: item['followed_id'] as String,
      username: userMap['username'] as String? ?? 'Usuario',
      email: '',
      avatarUrl: userMap['avatar_global_url'] as String?,
      bio: userMap['bio'] as String?,
      createdAt: DateTime.now(), // Fallback
    );
  }).toList();
});
