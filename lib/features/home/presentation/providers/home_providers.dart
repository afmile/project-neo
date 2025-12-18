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

/// Provider for recommended communities (mock data)
final recommendedCommunitiesProvider = Provider<List<CommunityEntity>>((ref) {
  return [
    CommunityEntity(
      id: '1',
      ownerId: 'owner1',
      title: 'Anime & Manga',
      slug: 'anime-manga',
      description: 'La comunidad más grande de anime',
      iconUrl: null,
      bannerUrl: null,
      memberCount: 45230,
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
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
      updatedAt: DateTime.now(),
    ),
  ];
});

/// Provider for recent communities (mock data, sorted by creation)
final recentCommunitiesProvider = Provider<List<CommunityEntity>>((ref) {
  return [
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
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      updatedAt: DateTime.now(),
    ),
  ];
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
  ];
});

/// Provider for search query
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Provider for search focus state
final isSearchFocusedProvider = StateProvider<bool>((ref) => false);
