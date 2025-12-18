/// Project Neo - Home Screen
///
/// Amino-style home screen with custom AppBar, search, and community sections.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/neo_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/home_providers.dart';
import '../widgets/community_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_onSearchFocusChange);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.removeListener(_onSearchFocusChange);
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchFocusChange() {
    ref.read(isSearchFocusedProvider.notifier).state = _searchFocusNode.hasFocus;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Custom Header
            _buildHeader().animate().fadeIn(duration: 400.ms),
            
            // Search Bar
            _buildSearchBar().animate().fadeIn(duration: 400.ms, delay: 100.ms),
            
            // Category Chips (expandable)
            _buildCategoryChips(),
            
            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: NeoSpacing.md),
                    
                    // Mis Comunidades
                    _buildMyCommunities()
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 200.ms),
                    
                    const SizedBox(height: NeoSpacing.lg),
                    
                    // Recomendadas
                    _buildRecommendedSection()
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 300.ms),
                    
                    const SizedBox(height: NeoSpacing.lg),
                    
                    // Recientes
                    _buildRecentSection()
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 400.ms),
                    
                    const SizedBox(height: NeoSpacing.lg),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildHeader() {
    final user = ref.watch(currentUserProvider);
    final neoCoins = ref.watch(neoCoinBalanceProvider);
    final username = user?.username ?? 'Usuario';
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: NeoSpacing.md,
        vertical: NeoSpacing.sm,
      ),
      color: Colors.grey[900],
      child: Row(
        children: [
          // Avatar
          GestureDetector(
            onTap: () => _showProfileMenu(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: NeoColors.accent.withValues(alpha: 0.2),
                border: Border.all(
                  color: NeoColors.accent,
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: user?.avatarUrl != null
                    ? Image.network(
                        user!.avatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(),
                      )
                    : _buildAvatarPlaceholder(),
              ),
            ),
          ),
          
          const SizedBox(width: NeoSpacing.md),
          
          // Greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hola,',
                  style: NeoTextStyles.bodySmall.copyWith(
                    color: NeoColors.textSecondary,
                  ),
                ),
                Text(
                  username,
                  style: NeoTextStyles.headlineSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // NeoCoins Pill
          GestureDetector(
            onTap: () => _goToMarket(),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: NeoSpacing.md,
                vertical: NeoSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: NeoColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: NeoColors.border,
                  width: NeoSpacing.borderWidth,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Colors.amber,
                          Colors.orange.shade700,
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.monetization_on_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: NeoSpacing.sm),
                  Text(
                    _formatNumber(neoCoins),
                    style: NeoTextStyles.labelLarge.copyWith(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      color: NeoColors.accent.withValues(alpha: 0.2),
      child: const Icon(
        Icons.person_rounded,
        color: NeoColors.accent,
        size: 24,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SEARCH BAR
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(NeoSpacing.md),
      color: Colors.grey[900],
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        style: NeoTextStyles.bodyMedium.copyWith(
          color: NeoColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Buscar comunidades...',
          hintStyle: NeoTextStyles.bodyMedium.copyWith(
            color: NeoColors.textTertiary,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: NeoColors.textTertiary,
            size: 22,
          ),
          filled: true,
          fillColor: NeoColors.inputFill,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: NeoSpacing.md,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: NeoColors.border,
              width: NeoSpacing.borderWidth,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: NeoColors.accent,
              width: 1,
            ),
          ),
        ),
        onChanged: (value) {
          ref.read(searchQueryProvider.notifier).state = value;
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CATEGORY CHIPS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCategoryChips() {
    final isExpanded = ref.watch(isSearchFocusedProvider);
    final categories = ref.watch(categoryChipsProvider);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: isExpanded ? 56 : 0,
      color: Colors.grey[900],
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isExpanded ? 1.0 : 0.0,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: NeoSpacing.md,
            vertical: NeoSpacing.sm,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return Padding(
              padding: const EdgeInsets.only(right: NeoSpacing.sm),
              child: ActionChip(
                avatar: Text(category.emoji, style: const TextStyle(fontSize: 14)),
                label: Text(
                  category.label,
                  style: NeoTextStyles.labelMedium.copyWith(
                    color: NeoColors.textPrimary,
                  ),
                ),
                backgroundColor: NeoColors.card,
                side: const BorderSide(
                  color: NeoColors.border,
                  width: NeoSpacing.borderWidth,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                onPressed: () {
                  _searchController.text = category.label;
                  ref.read(searchQueryProvider.notifier).state = category.label;
                },
              ),
            );
          },
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MIS COMUNIDADES
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildMyCommunities() {
    final communities = ref.watch(myCommunitiesProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: NeoSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mis Comunidades',
                style: NeoTextStyles.headlineMedium,
              ),
              if (communities.isNotEmpty)
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'Ver todas',
                    style: NeoTextStyles.labelMedium.copyWith(
                      color: NeoColors.accent,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: NeoSpacing.sm),
        
        if (communities.isEmpty)
          _buildEmptyState()
        else
          _buildCommunityList(communities),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: NeoSpacing.md),
      padding: const EdgeInsets.all(NeoSpacing.lg),
      decoration: BoxDecoration(
        color: NeoColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: NeoColors.border,
          width: NeoSpacing.borderWidth,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: NeoColors.accent.withValues(alpha: 0.15),
            ),
            child: const Icon(
              Icons.groups_rounded,
              size: 32,
              color: NeoColors.accent,
            ),
          ),
          const SizedBox(height: NeoSpacing.md),
          Text(
            '¡Aún no tienes comunidades!',
            style: NeoTextStyles.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: NeoSpacing.sm),
          Text(
            'Únete a una comunidad existente o crea la tuya propia',
            style: NeoTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: NeoSpacing.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: NeoColors.border,
                      width: NeoSpacing.borderWidth,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    'Explorar',
                    style: NeoTextStyles.button.copyWith(
                      color: NeoColors.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: NeoSpacing.md),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NeoColors.accent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    'Crear',
                    style: NeoTextStyles.button,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COMMUNITY LISTS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCommunityList(List communities) {
    return SizedBox(
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
            onTap: () => _goToCommunity(community.id),
          );
        },
      ),
    );
  }

  Widget _buildRecommendedSection() {
    final communities = ref.watch(recommendedCommunitiesProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: NeoSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
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
              TextButton(
                onPressed: () {},
                child: Text(
                  'Ver más',
                  style: NeoTextStyles.labelMedium.copyWith(
                    color: NeoColors.accent,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: NeoSpacing.sm),
        _buildCommunityList(communities),
      ],
    );
  }

  Widget _buildRecentSection() {
    final communities = ref.watch(recentCommunitiesProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: NeoSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 20,
                    color: NeoColors.success,
                  ),
                  const SizedBox(width: NeoSpacing.sm),
                  Text(
                    'Recientes',
                    style: NeoTextStyles.headlineMedium,
                  ),
                ],
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Ver más',
                  style: NeoTextStyles.labelMedium.copyWith(
                    color: NeoColors.accent,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: NeoSpacing.sm),
        _buildCommunityList(communities),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BOTTOM NAVIGATION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: const Border(
          top: BorderSide(
            color: NeoColors.border,
            width: NeoSpacing.borderWidth,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: NeoSpacing.md,
            vertical: NeoSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                index: 0,
              ),
              _buildNavItem(
                icon: Icons.add_circle,
                label: 'Crear',
                index: 1,
                isCenter: true,
              ),
              _buildNavItem(
                icon: Icons.chat_bubble_rounded,
                label: 'Chats',
                index: 2,
              ),
              _buildNavItem(
                icon: Icons.person_rounded,
                label: 'Perfil',
                index: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    bool isCenter = false,
  }) {
    final isSelected = _currentNavIndex == index;
    final color = isSelected ? NeoColors.accent : NeoColors.textTertiary;
    
    return GestureDetector(
      onTap: () => _onNavTap(index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: NeoSpacing.sm,
          vertical: NeoSpacing.xs,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCenter)
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [NeoColors.accent, Color(0xFF8B5CF6)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: NeoColors.accent.withValues(alpha: 0.4),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              )
            else
              Icon(icon, color: color, size: 26),
            if (!isCenter) ...[
              const SizedBox(height: 4),
              Text(
                label,
                style: NeoTextStyles.labelSmall.copyWith(
                  color: color,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  void _onNavTap(int index) {
    setState(() => _currentNavIndex = index);
    
    switch (index) {
      case 1:
        // TODO: Navigate to create community
        break;
      case 2:
        // TODO: Navigate to chats
        break;
      case 3:
        _showProfileMenu();
        break;
    }
  }

  void _goToMarket() {
    // TODO: Navigate to NeoCoins market
  }

  void _goToCommunity(String id) {
    // TODO: Navigate to community screen
  }

  void _showProfileMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: NeoColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(NeoSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: NeoColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: NeoSpacing.lg),
            _menuItem(Icons.person_outline_rounded, 'Mi Perfil', () {
              Navigator.pop(context);
            }),
            _menuItem(Icons.settings_outlined, 'Configuración', () {
              Navigator.pop(context);
            }),
            const Divider(color: NeoColors.border, height: NeoSpacing.lg),
            _menuItem(Icons.logout_rounded, 'Cerrar Sesión', () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).signOut();
            }, isDestructive: true),
            const SizedBox(height: NeoSpacing.md),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    final color = isDestructive ? NeoColors.error : NeoColors.textPrimary;
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(title, style: NeoTextStyles.bodyLarge.copyWith(color: color)),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
