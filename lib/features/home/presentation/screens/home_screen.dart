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
import 'package:go_router/go_router.dart';
import '../../../../features/chat/presentation/screens/chats_screen.dart';
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
            // Shared Header
            _buildHeader().animate().fadeIn(duration: 400.ms),
            
            // Body Content
            Expanded(
              child: _currentNavIndex == 2 
                  ? const ChatsScreen().animate().fadeIn(duration: 300.ms)
                  : _buildHomeBody(), 
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHomeBody() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 100), // Space for bottom nav
      child: Column(
        children: [
           // Search Bar
           _buildSearchBar().animate().fadeIn(duration: 400.ms, delay: 100.ms),
           
           // Categories (Always visible)
           _buildCategoryChips().animate().fadeIn(duration: 400.ms, delay: 150.ms),
           
           const SizedBox(height: NeoSpacing.md),

           // My Communities
           _buildMyCommunities().animate().fadeIn(duration: 400.ms, delay: 200.ms),
           
           const SizedBox(height: NeoSpacing.lg),
           
           // Recommended
           _buildRecommendedSection().animate().fadeIn(duration: 400.ms, delay: 300.ms),
           
           const SizedBox(height: NeoSpacing.lg),
           
           // Recent
           _buildRecentSection().animate().fadeIn(duration: 400.ms, delay: 400.ms),
        ],
      ),
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
        vertical: NeoSpacing.md, // More balanced padding
      ),
      color: Colors.grey[900],
      child: Row(
        children: [
          // Avatar
          GestureDetector(
            onTap: () => _showProfileMenu(),
            child: Container(
              width: 40, // Slightly smaller to be elegant
              height: 40,
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
          
          // Greeting (Single line)
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Hola, ',
                    style: NeoTextStyles.bodyLarge.copyWith(
                      color: NeoColors.textSecondary,
                    ),
                  ),
                  TextSpan(
                    text: username,
                    style: NeoTextStyles.bodyLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Coins & Notifications
          Row(
            children: [
               // NeoCoins Pill
              GestureDetector(
                onTap: () => _goToMarket(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: NeoSpacing.md,
                    vertical: 6,
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
                        width: 16,
                        height: 16,
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
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatNumber(neoCoins),
                        style: NeoTextStyles.labelMedium.copyWith(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(width: NeoSpacing.sm),
              
              // Notifications Icon
              IconButton(
                onPressed: () => context.push('/notifications'),
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: NeoColors.card,
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
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
      child: Container(
        height: 50,
        decoration: BoxDecoration(
           boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
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
              size: 24,
            ),
            filled: true,
            fillColor: Colors.grey[850],
            contentPadding: const EdgeInsets.symmetric(
              horizontal: NeoSpacing.md,
              vertical: 0, // Centered vertically by Container height
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(
                color: Colors.transparent,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
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
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CATEGORY CHIPS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCategoryChips() {
    final categories = ref.watch(categoryChipsProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    
    return Container(
      height: 60, // Fixed height, always visible
      color: Colors.black, // Match body background to blend in
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: NeoSpacing.md,
          vertical: NeoSpacing.sm,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category.id == selectedCategory;
          
          return Padding(
            padding: const EdgeInsets.only(right: NeoSpacing.sm),
            child: ActionChip(
              avatar: isSelected ? null : Text(category.emoji, style: const TextStyle(fontSize: 14)),
              label: Text(
                category.label,
                style: NeoTextStyles.labelMedium.copyWith(
                  color: isSelected ? Colors.white : NeoColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              backgroundColor: isSelected ? NeoColors.accent : NeoColors.card,
              side: BorderSide(
                color: isSelected ? NeoColors.accent : NeoColors.border,
                width: NeoSpacing.borderWidth,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              onPressed: () {
                if (isSelected) {
                  ref.read(selectedCategoryProvider.notifier).state = null;
                } else {
                  ref.read(selectedCategoryProvider.notifier).state = category.id;
                  // Clear search when selecting a category to avoid confusion
                  if (_searchController.text.isNotEmpty) {
                    _searchController.clear();
                    ref.read(searchQueryProvider.notifier).state = '';
                  }
                }
              },
            ),
          );
        },
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1A1A),
            Colors.black,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white10,
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: NeoColors.accent.withValues(alpha:0.1),
            ),
            child: const Icon(
              Icons.group_add_rounded,
              size: 28,
              color: NeoColors.accent,
            ),
          ),
          const SizedBox(height: NeoSpacing.md),
          Text(
            '¡Comienza tu viaje!',
            style: NeoTextStyles.headlineSmall.copyWith(
               fontWeight: FontWeight.bold,
               letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: NeoSpacing.xs),
          Text(
            'Únete a comunidades o crea la tuya',
            style: NeoTextStyles.bodyMedium.copyWith(
              color: NeoColors.textSecondary.withValues(alpha:0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: NeoSpacing.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.push('/discovery'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: Colors.white10,
                      width: 1,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 4,
                    shadowColor: NeoColors.accent.withValues(alpha:0.4),
                     shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
            horizontal: NeoSpacing.xl,
            vertical: NeoSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                index: 0,
              ),
              _buildNavItem(
                icon: Icons.add_rounded,
                label: 'Crear',
                index: 1,
                isCenter: true,
              ),
              _buildNavItem(
                icon: Icons.chat_bubble_rounded,
                label: 'Chats',
                index: 2,
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
              SizedBox(
                width: 56,
                height: 56,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [NeoColors.accent, Color(0xFF8B5CF6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: NeoColors.accent.withValues(alpha: 0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              )
            else ...[
               Icon(
                 icon, 
                 color: color, 
                 size: 28,
               ),
               if (isSelected) ...[
                 const SizedBox(height: 4),
                 SizedBox(
                   width: 4, 
                   height: 4, 
                   child: DecoratedBox(
                     decoration: const BoxDecoration(
                       color: NeoColors.accent, 
                       shape: BoxShape.circle,
                     ),
                   ),
                 ),
               ],
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
            SizedBox(
              width: 40,
              height: 4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: NeoColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
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
