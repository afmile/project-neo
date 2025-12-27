/// Project Neo - Community Providers
///
/// Riverpod providers for community management connected to Supabase.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/community_repository.dart';
import '../../domain/entities/community_entity.dart';

// ═══════════════════════════════════════════════════════════════════════════
// REPOSITORY PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

/// Provides the CommunityRepository instance
final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  return CommunityRepositoryImpl(Supabase.instance.client);
});

// ═══════════════════════════════════════════════════════════════════════════
// USER COMMUNITIES
// ═══════════════════════════════════════════════════════════════════════════

/// Provides the list of communities the current user owns or is member of
final userCommunitiesProvider = FutureProvider<List<CommunityEntity>>((ref) async {
  final repository = ref.watch(communityRepositoryProvider);
  final result = await repository.getUserCommunities();
  
  return result.fold(
    (failure) => throw Exception(failure.message),
    (communities) => communities,
  );
});

/// Provides a single community by ID (cached)
final communityByIdProvider = FutureProvider.family<CommunityEntity, String>((ref, id) async {
  final repository = ref.watch(communityRepositoryProvider);
  final result = await repository.getCommunityById(id);
  
  return result.fold(
    (failure) => throw Exception(failure.message),
    (community) => community,
  );
});

/// Provides a single community by slug (cached)
final communityBySlugProvider = FutureProvider.family<CommunityEntity, String>((ref, slug) async {
  final repository = ref.watch(communityRepositoryProvider);
  final result = await repository.getCommunityBySlug(slug);
  
  return result.fold(
    (failure) => throw Exception(failure.message),
    (community) => community,
  );
});

// ═══════════════════════════════════════════════════════════════════════════
// DISCOVERY
// ═══════════════════════════════════════════════════════════════════════════

/// Search query for discovery
final communitySearchQueryProvider = StateProvider<String>((ref) => '');

/// Category filter for discovery
final communityCategoryFilterProvider = StateProvider<String?>((ref) => null);

/// Provides public communities for discovery
final discoverCommunitiesProvider = FutureProvider<List<CommunityEntity>>((ref) async {
  final repository = ref.watch(communityRepositoryProvider);
  final searchQuery = ref.watch(communitySearchQueryProvider);
  final categoryFilter = ref.watch(communityCategoryFilterProvider);
  
  final result = await repository.discoverCommunities(
    searchQuery: searchQuery.isEmpty ? null : searchQuery,
    categoryFilter: categoryFilter,
  );
  
  return result.fold(
    (failure) => throw Exception(failure.message),
    (communities) => communities,
  );
});

// ═══════════════════════════════════════════════════════════════════════════
// STATE NOTIFIER FOR COMMUNITY ACTIONS
// ═══════════════════════════════════════════════════════════════════════════

/// State for community actions (join/leave)
class CommunityActionsState {
  final bool isLoading;
  final String? error;
  final Set<String> joinedCommunityIds;
  
  const CommunityActionsState({
    this.isLoading = false,
    this.error,
    this.joinedCommunityIds = const {},
  });
  
  CommunityActionsState copyWith({
    bool? isLoading,
    String? error,
    Set<String>? joinedCommunityIds,
  }) {
    return CommunityActionsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      joinedCommunityIds: joinedCommunityIds ?? this.joinedCommunityIds,
    );
  }
}

/// Notifier for community actions
class CommunityActionsNotifier extends StateNotifier<CommunityActionsState> {
  final CommunityRepository _repository;
  final Ref _ref;
  
  CommunityActionsNotifier(this._repository, this._ref)
      : super(const CommunityActionsState());
  
  /// Join a community
  Future<bool> joinCommunity(String communityId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await _repository.joinCommunity(communityId);
    
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
        return false;
      },
      (_) {
        state = state.copyWith(
          isLoading: false,
          joinedCommunityIds: {...state.joinedCommunityIds, communityId},
        );
        // Refresh user communities list
        _ref.invalidate(userCommunitiesProvider);
        return true;
      },
    );
  }
  
  /// Leave a community
  Future<bool> leaveCommunity(String communityId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await _repository.leaveCommunity(communityId);
    
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
        return false;
      },
      (_) {
        final newSet = Set<String>.from(state.joinedCommunityIds);
        newSet.remove(communityId);
        state = state.copyWith(
          isLoading: false,
          joinedCommunityIds: newSet,
        );
        // Refresh user communities list
        _ref.invalidate(userCommunitiesProvider);
        return true;
      },
    );
  }

  /// Update local profile
  Future<bool> updateLocalProfile({
    required String communityId,
    String? nickname,
    String? avatarUrl,
    String? bio,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await _repository.updateLocalProfile(
      communityId: communityId,
      nickname: nickname,
      avatarUrl: avatarUrl,
      bio: bio,
    );
    
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
        return false;
      },
      (_) {
        state = state.copyWith(isLoading: false);
        return true;
      },
    );
  }
  
  /// Check if user is member of a community
  bool isMember(String communityId) {
    return state.joinedCommunityIds.contains(communityId);
  }
}

/// Provider for community actions
final communityActionsProvider = StateNotifierProvider<CommunityActionsNotifier, CommunityActionsState>((ref) {
  final repository = ref.watch(communityRepositoryProvider);
  return CommunityActionsNotifier(repository, ref);
});
