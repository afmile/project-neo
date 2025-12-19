/// Project Neo - Home Providers
///
/// State management for the home screen.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../community/domain/entities/community_entity.dart';

// ═══════════════════════════════════════════════════════════════════════════
// NEOCOINS
// ═══════════════════════════════════════════════════════════════════════════

/// Provider for NeoCoins balance
final neoCoinBalanceProvider = Provider<int>((ref) => 1250);

// ═══════════════════════════════════════════════════════════════════════════
// COMMUNITIES
// ═══════════════════════════════════════════════════════════════════════════

/// Provider for user's communities (empty by default for empty state demo)
final myCommunitiesProvider = Provider<List<CommunityEntity>>((ref) => []);

/// Provider for recommended communities (mock data, filtered by category)
final recommendedCommunitiesProvider = Provider<List<CommunityEntity>>((ref) {
  final selectedCategory = ref.watch(selectedCategoryProvider);
  
  final allCommunities = [
    CommunityEntity(
      id: '1',
      ownerId: 'owner1',
      title: 'Anime & Manga',
      slug: 'anime-manga',
      description: 'La comunidad más grande de anime',
      iconUrl: null,
      bannerUrl: null,
      memberCount: 45230,
      categoryIds: ['anime', 'art', 'movies'],
      language: 'es',
      createdAt: DateTime.now().subtract(const Duration(days: 365)),
      updatedAt: DateTime.now(),
    ),
    CommunityEntity(
      id: '2',
      ownerId: 'owner2',
      title: 'Tech & Coding',
      slug: 'tech-coding',
      description: 'Desarrollo y tecnología',
      iconUrl: null,
      bannerUrl: null,
      memberCount: 23400,
      categoryIds: ['tech', 'gaming'],
      language: 'en',
      createdAt: DateTime.now().subtract(const Duration(days: 200)),
      updatedAt: DateTime.now(),
    ),
    CommunityEntity(
      id: '3',
      ownerId: 'owner3',
      title: 'Gaming Zone',
      slug: 'gaming-zone',
      description: 'Gamers unidos',
      iconUrl: null,
      bannerUrl: null,
      memberCount: 67800,
      categoryIds: ['gaming', 'tech'],
      language: 'en',
      createdAt: DateTime.now().subtract(const Duration(days: 150)),
      updatedAt: DateTime.now(),
    ),
    CommunityEntity(
      id: '4',
      ownerId: 'owner4',
      title: 'K-Pop Universe',
      slug: 'kpop-universe',
      description: 'Todo sobre K-Pop',
      iconUrl: null,
      bannerUrl: null,
      memberCount: 89200,
      categoryIds: ['kpop', 'music'],
      language: 'es',
      createdAt: DateTime.now().subtract(const Duration(days: 300)),
      updatedAt: DateTime.now(),
    ),
    CommunityEntity(
      id: '5',
      ownerId: 'owner5',
      title: 'Arte Digital',
      slug: 'arte-digital',
      description: 'Ilustración y diseño',
      iconUrl: null,
      bannerUrl: null,
      memberCount: 12340,
      categoryIds: ['art', 'anime'],
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
      updatedAt: DateTime.now(),
    ),
  ];

  if (selectedCategory == null) return allCommunities;
  
  return allCommunities.where((c) => c.categoryIds.contains(selectedCategory)).toList();
});

/// Provider for recent communities (mock data, filtered by category)
final recentCommunitiesProvider = Provider<List<CommunityEntity>>((ref) {
  final selectedCategory = ref.watch(selectedCategoryProvider);
  
  final allCommunities = [
    CommunityEntity(
      id: '10',
      ownerId: 'owner10',
      title: 'Música Latina',
      slug: 'musica-latina',
      description: 'Reggaeton, salsa, cumbia y más',
      iconUrl: null,
      bannerUrl: null,
      memberCount: 3450,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: DateTime.now(),
    ),
    CommunityEntity(
      id: '11',
      ownerId: 'owner11',
      title: 'Crypto & Web3',
      slug: 'crypto-web3',
      description: 'Blockchain y criptomonedas',
      iconUrl: null,
      bannerUrl: null,
      memberCount: 1200,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      updatedAt: DateTime.now(),
    ),
    CommunityEntity(
      id: '12',
      ownerId: 'owner12',
      title: 'Fotografía',
      slug: 'fotografia',
      description: 'Captura momentos únicos',
      iconUrl: null,
      bannerUrl: null,
      memberCount: 2100,
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      updatedAt: DateTime.now(),
    ),
    CommunityEntity(
      id: '13',
      ownerId: 'owner13',
      title: 'Fitness & Gym',
      slug: 'fitness-gym',
      description: 'Entrena con la comunidad',
      iconUrl: null,
      bannerUrl: null,
      memberCount: 890,
      categoryIds: ['sports', 'fitness'],
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      updatedAt: DateTime.now(),
    ),
    CommunityEntity(
      id: '14',
      ownerId: 'owner14',
      title: 'Historias de Terror',
      slug: 'historias-terror',
      description: 'Creepy pastas y leyendas',
      iconUrl: null,
      bannerUrl: null,
      memberCount: 5666,
      categoryIds: ['horror', 'movies'],
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now(),
    ),
  ];

  if (selectedCategory == null) return allCommunities;

  return allCommunities.where((c) => c.categoryIds.contains(selectedCategory)).toList();
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
// DISCOVERY - NEW
// ═══════════════════════════════════════════════════════════════════════════

// Discovery Filters
final discoverySearchProvider = StateProvider<String>((ref) => '');
final discoveryCategoryProvider = StateProvider<String?>((ref) => null);
final discoveryLanguageProvider = StateProvider<String>((ref) => 'es'); // 'es', 'en', 'all'

/// Provider for ALL communities (Mock) plus language field
final allCommunitiesProvider = Provider<List<CommunityEntity>>((ref) {
  // Combine recommended and recent for a full list demo, making sure ID uniqueness or just reuse logic
  // For simplicity, we just declare a master list here that includes everything above + more
  return [
    CommunityEntity(
      id: '1', title: 'Anime & Manga', slug: 'anime-manga', 
      memberCount: 45230, categoryIds: ['anime', 'art'], language: 'es', 
      ownerId: 'o1', createdAt: DateTime.now(), updatedAt: DateTime.now()),
    CommunityEntity(
      id: '2', title: 'Tech & Coding', slug: 'tech-coding', 
      memberCount: 23400, categoryIds: ['tech'], language: 'en', 
      ownerId: 'o2', createdAt: DateTime.now(), updatedAt: DateTime.now()),
    CommunityEntity(
      id: '3', title: 'Gaming Zone', slug: 'gaming-zone', 
      memberCount: 67800, categoryIds: ['gaming'], language: 'en', 
      ownerId: 'o3', createdAt: DateTime.now(), updatedAt: DateTime.now()),
    CommunityEntity(
      id: '10', title: 'Música Latina', slug: 'musica-latina', 
      memberCount: 3450, categoryIds: ['music'], language: 'es', 
      ownerId: 'o10', createdAt: DateTime.now(), updatedAt: DateTime.now()),
     CommunityEntity(
      id: '14', title: 'Historias de Terror', slug: 'historias-terror', 
      memberCount: 5666, categoryIds: ['horror'], language: 'es', 
      ownerId: '14', createdAt: DateTime.now(), updatedAt: DateTime.now()),
     CommunityEntity(
      id: '99', title: 'Global News', slug: 'global-news', 
      memberCount: 120000, categoryIds: ['tech', 'music'], language: 'en', 
      ownerId: '99', createdAt: DateTime.now(), updatedAt: DateTime.now()),
  ];
});

/// Discovery Filtered Provider
final discoveryFilteredCommunitiesProvider = Provider<List<CommunityEntity>>((ref) {
  final all = ref.watch(allCommunitiesProvider);
  final search = ref.watch(discoverySearchProvider).toLowerCase();
  final category = ref.watch(discoveryCategoryProvider);
  final language = ref.watch(discoveryLanguageProvider); // 'es', 'en', 'all'

  return all.where((c) {
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
      // final matchesTag = c.categoryIds.any((t) => t.contains(search));
      if (!matchesTitle) return false;
    }
    
    return true;
  }).toList();
});
