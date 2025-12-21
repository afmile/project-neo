import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:project_neo/core/theme/neo_theme.dart';
import 'package:project_neo/features/home/presentation/providers/home_providers.dart';
import 'package:project_neo/features/home/presentation/widgets/community_card.dart';

class DiscoveryScreen extends ConsumerStatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  ConsumerState<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends ConsumerState<DiscoveryScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            _buildSearchBar(),
            
            const SizedBox(height: NeoSpacing.md),
            
            // Categories
            _buildCategoriesSection(),
            
            const SizedBox(height: NeoSpacing.lg),
            
            // Featured Banner (Optional)
            _buildFeaturedBanner(),
            
            const SizedBox(height: NeoSpacing.lg),
            
            // Recommended Communities
            _buildRecommendedSection(),
            
            const SizedBox(height: NeoSpacing.lg),
            
            // Recent Communities
            _buildRecentSection(),
            
            const SizedBox(height: NeoSpacing.lg),
            
            // All Communities Catalog
            _buildAllCommunitiesSection(),
            
            const SizedBox(height: 100), // Bottom padding
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // APP BAR
  // ═══════════════════════════════════════════════════════════════════════════

  PreferredSizeWidget _buildAppBar() {
    final language = ref.watch(discoveryLanguageProvider);
    
    return AppBar(
      backgroundColor: Colors.grey[900],
      title: Text(
        'Descubrir',
        style: NeoTextStyles.headlineSmall.copyWith(fontWeight: FontWeight.bold),
      ),
      actions: [
        // Language Toggle
        Padding(
          padding: const EdgeInsets.only(right: NeoSpacing.md),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: language,
              dropdownColor: NeoColors.card,
              icon: const Icon(Icons.language, color: NeoColors.accent),
              style: NeoTextStyles.labelMedium.copyWith(color: Colors.white),
              items: const [
                DropdownMenuItem(value: 'es', child: Text('🇪🇸 ES')),
                DropdownMenuItem(value: 'en', child: Text('🇺🇸 EN')),
                DropdownMenuItem(value: 'all', child: Text('🌎 Todo')),
              ],
              onChanged: (val) {
                if (val != null) {
                  ref.read(discoveryLanguageProvider.notifier).state = val;
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SEARCH BAR
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(NeoSpacing.md),
      child: TextField(
        controller: _searchController,
        style: NeoTextStyles.bodyMedium.copyWith(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Buscar comunidades...',
          hintStyle: NeoTextStyles.bodyMedium.copyWith(color: NeoColors.textTertiary),
          prefixIcon: const Icon(Icons.search, color: NeoColors.textTertiary),
          filled: true,
          fillColor: NeoColors.card,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: NeoSpacing.md),
        ),
        onChanged: (val) {
          ref.read(discoverySearchProvider.notifier).state = val;
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CATEGORIES
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCategoriesSection() {
    final categories = ref.watch(categoryChipsProvider);
    final selected = ref.watch(discoveryCategoryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: NeoSpacing.md),
          child: Text(
            'Categorías',
            style: NeoTextStyles.headlineMedium,
          ),
        ),
        const SizedBox(height: NeoSpacing.sm),
        SizedBox(
          height: 50,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: NeoSpacing.md),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: NeoSpacing.sm),
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = category.id == selected;
              return FilterChip(
                selected: isSelected,
                label: Text(category.label),
                avatar: isSelected ? null : Text(category.emoji),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : NeoColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                backgroundColor: NeoColors.card,
                selectedColor: NeoColors.accent,
                checkmarkColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                side: BorderSide(
                  color: isSelected ? NeoColors.accent : Colors.white10,
                ),
                onSelected: (val) {
                  ref.read(discoveryCategoryProvider.notifier).state = val ? category.id : null;
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FEATURED BANNER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildFeaturedBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: NeoSpacing.md),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF8B5CF6), // Violet
              Color(0xFFEC4899), // Pink
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background pattern
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Opacity(
                  opacity: 0.1,
                  child: Image.asset(
                    'assets/images/pattern.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(),
                  ),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(NeoSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '⭐ DESTACADO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: NeoSpacing.sm),
                  const Text(
                    'Comunidad de la Semana',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  const Flexible(
                    child: Text(
                      'Únete a Gaming Zone y descubre miles de gamers',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RECOMMENDED SECTION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildRecommendedSection() {
    final communities = ref.watch(recommendedCommunitiesProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: NeoSpacing.md),
          child: Row(
            children: [
              const Icon(
                Icons.stars_rounded,
                size: 20,
                color: Colors.amber,
              ),
              const SizedBox(width: NeoSpacing.sm),
              Text(
                'Recomendadas',
                style: NeoTextStyles.headlineMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: NeoSpacing.sm),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: NeoSpacing.md),
            itemCount: communities.length,
            itemBuilder: (context, index) {
              final community = communities[index];
              return CommunityCard(
                title: community.title,
                imageUrl: community.bannerUrl,
                memberCount: community.memberCount,
                onTap: () => context.push('/community_home', extra: community),
              );
            },
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RECENT SECTION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildRecentSection() {
    final communities = ref.watch(recentCommunitiesProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: NeoSpacing.md),
          child: Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 20,
                color: NeoColors.success,
              ),
              const SizedBox(width: NeoSpacing.sm),
              Text(
                'Nuevas y Recientes',
                style: NeoTextStyles.headlineMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: NeoSpacing.sm),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: NeoSpacing.md),
            itemCount: communities.length,
            itemBuilder: (context, index) {
              final community = communities[index];
              return CommunityCard(
                title: community.title,
                imageUrl: community.bannerUrl,
                memberCount: community.memberCount,
                onTap: () => context.push('/community_home', extra: community),
              );
            },
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ALL COMMUNITIES CATALOG
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildAllCommunitiesSection() {
    final communities = ref.watch(discoveryFilteredCommunitiesProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: NeoSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Todo el Catálogo',
                style: NeoTextStyles.headlineMedium,
              ),
              Text(
                '${communities.length} comunidades',
                style: NeoTextStyles.labelMedium.copyWith(
                  color: NeoColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: NeoSpacing.sm),
        
        if (communities.isEmpty)
          _buildEmptyResults()
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: NeoSpacing.md),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: NeoSpacing.md,
                mainAxisSpacing: NeoSpacing.md,
              ),
              itemCount: communities.length,
              itemBuilder: (context, index) {
                final community = communities[index];
                return CommunityCard(
                  title: community.title,
                  imageUrl: community.bannerUrl,
                  memberCount: community.memberCount,
                  onTap: () => context.push('/community_home', extra: community),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyResults() {
    return Padding(
      padding: const EdgeInsets.all(NeoSpacing.xl),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 48, color: NeoColors.textTertiary),
            const SizedBox(height: NeoSpacing.md),
            Text(
              'No se encontraron comunidades',
              style: NeoTextStyles.bodyLarge.copyWith(color: NeoColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
