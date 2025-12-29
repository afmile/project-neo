import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/neo_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../community/presentation/providers/community_providers.dart';
import '../../../community/presentation/screens/create_community_screen.dart'; // CommunityWizardScreen
import '../../../auth/presentation/screens/global_edit_profile_screen.dart';
import '../providers/home_providers.dart';
import 'package:go_router/go_router.dart';
import '../../../../features/chat/presentation/screens/global_chats_screen.dart';
import '../../../../features/discovery/presentation/screens/discovery_screen.dart';
import '../../../../features/profile/presentation/screens/profile_screen.dart';
import '../widgets/community_card.dart';
import '../widgets/neo_feed_card.dart';
import '../../../chat/presentation/widgets/new_chat_modal.dart';

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
            // Shared Header (ONLY on Home tab)
            if (_currentNavIndex == 0)
              _buildHeader().animate().fadeIn(duration: 400.ms),
            
            // Body Content - Instant tab switching (Level 0: Structural Navigation)
            Expanded(
              child: IndexedStack(
                index: _currentNavIndex,
                children: [
                  _buildHomeBody(),           // 0: Home
                  const DiscoveryScreen(),    // 1: Discovery
                  const GlobalChatsScreen(),  // 2: Chats
                  const ProfileScreen(),      // 3: Profile
                ],
              ),
            ),
          ],
        ),
      ),
      // Central docked FAB setup
      floatingActionButton: _buildCentralFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomAppBar(),
    );
  }

  Widget _buildHomeBody() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(
        top: NeoSpacing.lg, // Add breathing room from header
        bottom: 100, // Space for bottom nav
      ),
      child: Column(
        children: [
           // My Communities
           _buildMyCommunities().animate().fadeIn(duration: 400.ms, delay: 100.ms),
           
           const SizedBox(height: NeoSpacing.lg),
           
           // Global Feed
           _buildGlobalFeed().animate().fadeIn(duration: 400.ms, delay: 200.ms),
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
    // Use real Supabase data via userCommunitiesProvider
    final communitiesAsync = ref.watch(userCommunitiesProvider);
    
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
              // "Ver todas" button - only visible when data is loaded and not empty
              ...communitiesAsync.whenOrNull(
                data: (communities) => communities.isNotEmpty ? [
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'Ver todas',
                      style: NeoTextStyles.labelMedium.copyWith(
                        color: NeoColors.accent,
                      ),
                    ),
                  ),
                ] : null,
              ) ?? [],
            ],
          ),
        ),
        const SizedBox(height: NeoSpacing.sm),
        
        communitiesAsync.when(
          loading: () => _buildCommunitiesLoading(),
          error: (error, _) => _buildCommunitiesError(error.toString()),
          data: (communities) => communities.isEmpty
              ? _buildEmptyState()
              : _buildCommunityList(communities),
        ),
      ],
    );
  }
  
  Widget _buildCommunitiesLoading() {
    return SizedBox(
      height: 180,
      child: Center(
        child: CircularProgressIndicator(
          color: NeoColors.accent,
        ),
      ),
    );
  }
  
  Widget _buildCommunitiesError(String error) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: NeoSpacing.md),
      padding: const EdgeInsets.all(NeoSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 8),
          Text(
            error,
            style: NeoTextStyles.bodySmall.copyWith(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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
                  onPressed: () => _navigateToCreateCommunity(),
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
            communityId: community.id,
            onTap: () => _goToCommunity(community),
          );
        },
      ),
    );
  }

  Widget _buildRecommendedSection() {
    final communitiesAsync = ref.watch(recommendedCommunitiesProvider);
    
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
                    'Descubrir',
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
        communitiesAsync.when(
          loading: () => _buildCommunitiesLoading(),
          error: (error, _) => _buildCommunitiesError('Error'),
          data: (communities) => communities.isEmpty
              ? _buildDiscoverEmptyState()
              : _buildCommunityList(communities),
        ),
      ],
    );
  }

  /// Empty state widget for Discover section
  Widget _buildDiscoverEmptyState() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: NeoSpacing.md),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: NeoColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NeoColors.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.explore_off_outlined,
            size: 48,
            color: NeoColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay comunidades aún',
            style: NeoTextStyles.headlineSmall.copyWith(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '¡Sé el primero en crear una!',
            style: NeoTextStyles.bodyMedium.copyWith(color: NeoColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
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
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GLOBAL FEED
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildGlobalFeed() {
    final feedPosts = ref.watch(globalFeedProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: NeoSpacing.md),
          child: Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                size: 20,
                color: NeoColors.accent,
              ),
              const SizedBox(width: NeoSpacing.sm),
              Text(
                'Para Ti',
                style: NeoTextStyles.headlineMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: NeoSpacing.md),
        
        // Feed posts
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: NeoSpacing.md),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: feedPosts.length,
            itemBuilder: (context, index) {
              final post = feedPosts[index];
              return NeoFeedCard(post: post);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentSection() {
    final communitiesAsync = ref.watch(recentCommunitiesProvider);
    
    return communitiesAsync.when(
      loading: () => const SizedBox.shrink(), // Don't show loading for this section
      error: (_, __) => const SizedBox.shrink(), // Don't show errors for this section
      data: (communities) {
        if (communities.isEmpty) {
          return const SizedBox.shrink(); // Hide section if no communities
        }
        
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
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CENTRAL DOCKED FAB (AMINO STYLE)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCentralFAB() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [
            Color(0xFF8B5CF6), // Violet
            Color(0xFFEC4899), // Pink
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showCreationOptions,
          customBorder: const CircleBorder(),
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomAppBar() {
    return BottomAppBar(
      color: Colors.grey[900],
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Left side - 2 icons
            _buildNavIconButton(
              icon: Icons.home_rounded,
              index: 0,
            ),
            _buildNavIconButton(
              icon: Icons.explore_rounded,
              index: 1,
            ),
            
            // Center spacer for FAB
            const SizedBox(width: 48),
            
            // Right side - 2 icons
            _buildNavIconButton(
              icon: Icons.chat_bubble_rounded,
              index: 2,
            ),
            _buildNavIconButton(
              icon: Icons.person_rounded,
              index: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavIconButton({
    required IconData icon,
    required int index,
  }) {
    final isSelected = _currentNavIndex == index;
    final color = isSelected ? NeoColors.accent : NeoColors.textTertiary;
    
    return IconButton(
      icon: Icon(icon, color: color, size: 28),
      onPressed: () => _onNavTap(index),
      padding: EdgeInsets.zero,
    );
  }

  Widget _buildProfilePlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_rounded,
            size: 64,
            color: NeoColors.textTertiary,
          ),
          const SizedBox(height: NeoSpacing.md),
          Text(
            'Perfil',
            style: NeoTextStyles.headlineMedium,
          ),
          const SizedBox(height: NeoSpacing.sm),
          Text(
            'Próximamente',
            style: NeoTextStyles.bodyMedium.copyWith(
              color: NeoColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CREATION OPTIONS MODAL
  // ═══════════════════════════════════════════════════════════════════════════

  void _showCreationOptions() {
    // If on Chats tab (index 2), show chat creation modal
    if (_currentNavIndex == 2) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => const NewChatModal(),
      );
      return;
    }

    // Otherwise, show community creation options
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1F1F1F),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            const Text(
              'Crear',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Options Grid
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildCreationOption(
                  icon: Icons.add_circle_rounded,
                  label: 'Crear Comunidad',
                  color: const Color(0xFF8B5CF6), // Purple
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToCreateCommunity();
                  },
                ),
                _buildCreationOption(
                  icon: Icons.vpn_key_rounded,
                  label: 'Código de Invitación',
                  color: const Color(0xFFF59E0B), // Amber
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Show invitation code dialog
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCreationOption({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap ?? () {
        Navigator.pop(context);
        // TODO: Implement creation action based on type
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
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
  }

  void _goToMarket() {
    // TODO: Navigate to NeoCoins market
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

  void _goToCommunity(dynamic communityOrId) {
    // Navigate to community home screen with entity
    if (communityOrId is String) {
      // If it's just an ID, we need to find the entity
      // For now, this shouldn't happen as we'll pass the full entity
      return;
    }
    context.push('/community_home', extra: communityOrId);
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
              // Navigate to global generic profile view if exists, or edit screen?
              // User said "Edit global profile... enter general settings".
              // Let's make "Mi Perfil" go to a read-only view or just add "Editar Pasaporte".
            }),
            _menuItem(Icons.edit_document, 'Editar Pasaporte (Global)', () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const GlobalEditProfileScreen(),
                ),
              ).then((_) {
                 // Refresh home to show new avatar if changed
                 setState(() {});
              });
            }),
            _menuItem(Icons.bug_report_outlined, 'Reportar problema', () {
              Navigator.pop(context);
              context.push('/report-issue', extra: <String, dynamic>{
                'route': '/home',
                'feature': 'profile_menu',
              });
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
