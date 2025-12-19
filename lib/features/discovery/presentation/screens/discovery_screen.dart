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
    final communities = ref.watch(discoveryFilteredCommunitiesProvider);
    final language = ref.watch(discoveryLanguageProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
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
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
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
          ),

          // Categories
          SizedBox(
            height: 50,
            child: _buildCategoryList(),
          ),
          
          const SizedBox(height: NeoSpacing.md),

          // Results List
          Expanded(
            child: communities.isEmpty
              ? _buildEmptyResults()
              : GridView.builder(
                  padding: const EdgeInsets.all(NeoSpacing.md),
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
                      imageUrl: community.bannerUrl, // Might be null, Card handles it
                      memberCount: community.memberCount,
                      onTap: () {
                          // Standard route to community details
                          context.push('/community/${community.slug}');
                      },
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList() {
    final categories = ref.watch(categoryChipsProvider);
    final selected = ref.watch(discoveryCategoryProvider);

    return ListView.separated(
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
    );
  }

  Widget _buildEmptyResults() {
    return Center(
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
    );
  }
}
