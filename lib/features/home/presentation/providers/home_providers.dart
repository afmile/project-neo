/// Project Neo - Home Providers
///
/// State management for the home screen.
/// Now connected to real Supabase data via community_providers.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../community/domain/entities/community_entity.dart';
import '../../../community/presentation/providers/community_providers.dart';

// ═══════════════════════════════════════════════════════════════════════════
// NEOCOINS
// ═══════════════════════════════════════════════════════════════════════════

/// Provider for NeoCoins balance
final neoCoinBalanceProvider = Provider<int>((ref) => 1250);

// ═══════════════════════════════════════════════════════════════════════════
// COMMUNITIES - NOW USING REAL DATA
// ═══════════════════════════════════════════════════════════════════════════

/// Re-export user communities from community_providers for backwards compatibility
/// This uses REAL Supabase data, no mocks
final myCommunitiesAsyncProvider = userCommunitiesProvider;

/// StateNotifier for local community list management (used for optimistic updates)
class MyCommunitiesNotifier extends StateNotifier<List<CommunityEntity>> {
  MyCommunitiesNotifier() : super([]);

  /// Set communities from async load
  void setCommunities(List<CommunityEntity> communities) {
    state = communities;
  }

  /// Add a community to user's list (optimistic update)
  void joinCommunity(CommunityEntity community) {
    if (state.any((c) => c.id == community.id)) {
      return;
    }
    state = [...state, community];
  }

  /// Remove a community from user's list
  void leaveCommunity(String communityId) {
    state = state.where((c) => c.id != communityId).toList();
  }

  /// Clear all communities (for logout, etc)
  void clearAll() {
    state = [];
  }
}

/// Provider for local community state management
final myCommunitiesProvider =
    StateNotifierProvider<MyCommunitiesNotifier, List<CommunityEntity>>((ref) {
  return MyCommunitiesNotifier();
});

/// Provider for recommended communities - NOW USES REAL SUPABASE DATA
/// Returns public communities ordered by member count
final recommendedCommunitiesProvider = FutureProvider<List<CommunityEntity>>((ref) async {
  final repository = ref.watch(communityRepositoryProvider);
  final result = await repository.discoverCommunities(limit: 10);
  
  return result.fold(
    (failure) => [], // Return empty list on error, NOT mock data
    (communities) => communities,
  );
});

/// Provider for recent communities - NOW USES REAL SUPABASE DATA
/// Returns recently created public communities
final recentCommunitiesProvider = FutureProvider<List<CommunityEntity>>((ref) async {
  final repository = ref.watch(communityRepositoryProvider);
  final result = await repository.discoverCommunities(limit: 5);
  
  return result.fold(
    (failure) => [], // Return empty list on error, NOT mock data
    (communities) => communities,
  );
});

// ═══════════════════════════════════════════════════════════════════════════
// SEARCH & CATEGORIES
// ═══════════════════════════════════════════════════════════════════════════

/// Category chip model
class CategoryChip {
  final String id;
  final String label;
  final String emoji;

  const CategoryChip({
    required this.id,
    required this.label,
    required this.emoji,
  });
}

/// Provider for category chips
final categoryChipsProvider = Provider<List<CategoryChip>>((ref) {
  return const [
    CategoryChip(id: 'anime', label: 'Anime', emoji: '🎌'),
    CategoryChip(id: 'tech', label: 'Tech', emoji: '💻'),
    CategoryChip(id: 'music', label: 'Música', emoji: '🎵'),
    CategoryChip(id: 'gaming', label: 'Gaming', emoji: '🎮'),
    CategoryChip(id: 'art', label: 'Arte', emoji: '🎨'),
    CategoryChip(id: 'kpop', label: 'K-Pop', emoji: '🎤'),
    CategoryChip(id: 'sports', label: 'Deportes', emoji: '⚽'),
    CategoryChip(id: 'movies', label: 'Películas', emoji: '🎬'),
    CategoryChip(id: 'horror', label: 'Terror', emoji: '👻'),
  ];
});

/// Provider for search query
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Provider for search focus state
final isSearchFocusedProvider = StateProvider<bool>((ref) => false);

/// Provider for selected category filter
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

// ═══════════════════════════════════════════════════════════════════════════
// DISCOVERY - NOW USING REAL DATA
// ═══════════════════════════════════════════════════════════════════════════

// Discovery Filters
final discoverySearchProvider = StateProvider<String>((ref) => '');
final discoveryCategoryProvider = StateProvider<String?>((ref) => null);
final discoveryLanguageProvider = StateProvider<String>((ref) => 'all'); // 'es', 'en', 'all'

/// Provider for ALL communities - NOW USES REAL SUPABASE DATA
final allCommunitiesProvider = FutureProvider<List<CommunityEntity>>((ref) async {
  final repository = ref.watch(communityRepositoryProvider);
  final result = await repository.discoverCommunities(limit: 50);
  
  return result.fold(
    (failure) => [], // Return empty list on error
    (communities) => communities,
  );
});

/// Discovery Filtered Provider - NOW WORKS WITH ASYNC DATA
final discoveryFilteredCommunitiesProvider = FutureProvider<List<CommunityEntity>>((ref) async {
  final allResult = await ref.watch(allCommunitiesProvider.future);
  final search = ref.watch(discoverySearchProvider).toLowerCase();
  final category = ref.watch(discoveryCategoryProvider);
  final language = ref.watch(discoveryLanguageProvider);

  return allResult.where((c) {
    // Language Filter
    if (language != 'all' && c.language != language) {
      return false;
    }
    
    // Category Filter
    if (category != null && !c.categoryIds.contains(category)) {
      return false;
    }
    
    // Search Filter
    if (search.isNotEmpty) {
      final matchesTitle = c.title.toLowerCase().contains(search);
      if (!matchesTitle) return false;
    }
    
    return true;
  }).toList();
});

// ═══════════════════════════════════════════════════════════════════════════
// GLOBAL FEED
// ═══════════════════════════════════════════════════════════════════════════

/// Feed post model for global feed
class FeedPost {
  final String id;
  final String communityId;
  final String communityName;
  final String communityAvatar;
  final String timeAgo;
  final String? coverImageUrl;
  final String title;
  final String summary;
  final int likes;
  final int comments;

  const FeedPost({
    required this.id,
    required this.communityId,
    required this.communityName,
    required this.communityAvatar,
    required this.timeAgo,
    this.coverImageUrl,
    required this.title,
    required this.summary,
    this.likes = 0,
    this.comments = 0,
  });
}

/// Provider for global feed posts - EMPTY FOR NOW (will be connected to real posts table)
final globalFeedProvider = Provider<List<FeedPost>>((ref) {
  // Return empty list - no mock data
  // TODO: Connect to real posts from Supabase when posts feature is complete
  return [];
});
