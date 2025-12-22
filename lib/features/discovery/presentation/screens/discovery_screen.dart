import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:project_neo/core/theme/neo_theme.dart';
import 'package:project_neo/features/home/presentation/providers/home_providers.dart';
import 'package:project_neo/features/home/presentation/widgets/community_card.dart';
import 'package:project_neo/features/community/presentation/screens/create_community_screen.dart';

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
            
            // All Communities Catalog (main focus now)
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
  // ALL COMMUNITIES CATALOG - NOW WITH REAL DATA
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildAllCommunitiesSection() {
    final communitiesAsync = ref.watch(discoveryFilteredCommunitiesProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: NeoSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Comunidades',
                style: NeoTextStyles.headlineMedium,
              ),
              communitiesAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (communities) => Text(
                  '${communities.length} encontradas',
                  style: NeoTextStyles.labelMedium.copyWith(
                    color: NeoColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: NeoSpacing.sm),
        
        communitiesAsync.when(
          loading: () => _buildLoadingGrid(),
          error: (error, _) => _buildErrorState(error.toString()),
          data: (communities) => communities.isEmpty
              ? _buildEmptyState()
              : Padding(
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
                        communityId: community.id,
                        onTap: () => context.push('/community_preview', extra: community),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildLoadingGrid() {
    return Padding(
      padding: const EdgeInsets.all(NeoSpacing.xl),
      child: Center(
        child: CircularProgressIndicator(color: NeoColors.accent),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Padding(
      padding: const EdgeInsets.all(NeoSpacing.xl),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: NeoColors.error),
            const SizedBox(height: NeoSpacing.md),
            Text(
              'Error cargando comunidades',
              style: NeoTextStyles.bodyLarge.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(NeoSpacing.xl),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.explore_off_outlined,
              size: 64,
              color: NeoColors.textTertiary,
            ),
            const SizedBox(height: NeoSpacing.md),
            Text(
              'No hay comunidades aún',
              style: NeoTextStyles.headlineSmall.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: NeoSpacing.sm),
            Text(
              '¡Sé el primero en crear una!',
              style: NeoTextStyles.bodyMedium.copyWith(color: NeoColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: NeoSpacing.lg),
            ElevatedButton.icon(
              onPressed: _navigateToCreateCommunity,
              icon: const Icon(Icons.add),
              label: const Text('Crear Comunidad'),
              style: ElevatedButton.styleFrom(
                backgroundColor: NeoColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToCreateCommunity() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const CommunityWizardScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }
}
