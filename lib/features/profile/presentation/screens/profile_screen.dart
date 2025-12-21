import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/neo_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../home/presentation/providers/home_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final username = user?.username ?? 'Usuario';
    final neoCoins = ref.watch(neoCoinBalanceProvider);
    
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: CustomScrollView(
          slivers: [
            // App Bar - Balanced with coins and menu
            SliverAppBar(
              floating: false,
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
              toolbarHeight: 70, // Increased height for better spacing
              flexibleSpace: Padding(
                padding: const EdgeInsets.only(top: 8), // Add top padding
                child: Container(
                  alignment: Alignment.bottomCenter,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // NeoCoins Badge
                      Padding(
                        padding: const EdgeInsets.only(left: 16, bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
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
                                '$neoCoins',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Menu Button
                      Padding(
                        padding: const EdgeInsets.only(right: 8, bottom: 8),
                        child: IconButton(
                          icon: const Icon(Icons.menu_rounded, color: Colors.white),
                          onPressed: () => _showSettingsMenu(context, ref),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Profile Header
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: NeoSpacing.md), // Reduced spacing
                  
                  // Avatar
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: NeoColors.accent.withValues(alpha: 0.2),
                      border: Border.all(
                        color: NeoColors.accent,
                        width: 3,
                      ),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: NeoColors.accent,
                      size: 48,
                    ),
                  ),
                  
                  const SizedBox(height: NeoSpacing.md),
                  
                  // Username
                  Text(
                    username,
                    style: NeoTextStyles.headlineMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: NeoSpacing.xs),
                  
                  // Bio
                  Text(
                    'Amante de la tecnología y las comunidades',
                    style: NeoTextStyles.bodyMedium.copyWith(
                      color: NeoColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: NeoSpacing.lg),
                  
                  // Stats
                  _buildStats(),
                  
                  const SizedBox(height: NeoSpacing.lg),
                ],
              ),
            ),

            // Tabs
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverTabBarDelegate(
                TabBar(
                  labelColor: NeoColors.accent,
                  unselectedLabelColor: NeoColors.textSecondary,
                  indicatorColor: NeoColors.accent,
                  tabs: const [
                    Tab(text: 'Mis Blogs'),
                    Tab(text: 'Muro'),
                    Tab(text: 'Biografía'),
                  ],
                ),
              ),
            ),

            // Tab Content Placeholder
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.article_outlined,
                      size: 64,
                      color: NeoColors.textTertiary,
                    ),
                    const SizedBox(height: NeoSpacing.md),
                    Text(
                      'Contenido próximamente',
                      style: NeoTextStyles.bodyLarge.copyWith(
                        color: NeoColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: NeoSpacing.lg),
      padding: const EdgeInsets.all(NeoSpacing.lg),
      decoration: BoxDecoration(
        color: NeoColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: NeoColors.border,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Seguidores', '234'),
          Container(
            width: 1,
            height: 40,
            color: NeoColors.border,
          ),
          _buildStatItem('Siguiendo', '156'),
          Container(
            width: 1,
            height: 40,
            color: NeoColors.border,
          ),
          _buildStatItem('Reputación', '1.2K'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: NeoColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _showSettingsMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1F1F1F),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(NeoSpacing.lg),
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
            const SizedBox(height: NeoSpacing.lg),
            
            // Options
            _buildMenuOption(
              context,
              icon: Icons.edit_rounded,
              title: 'Editar Perfil',
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to edit profile
              },
            ),
            _buildMenuOption(
              context,
              icon: Icons.settings_rounded,
              title: 'Configuración',
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to settings
              },
            ),
            const Divider(color: NeoColors.border),
            _buildMenuOption(
              context,
              icon: Icons.logout_rounded,
              title: 'Cerrar Sesión',
              color: NeoColors.error,
              onTap: () {
                Navigator.pop(context);
                ref.read(authProvider.notifier).signOut();
              },
            ),
            const SizedBox(height: NeoSpacing.md),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    final itemColor = color ?? NeoColors.textPrimary;
    
    return ListTile(
      leading: Icon(icon, color: itemColor, size: 22),
      title: Text(
        title,
        style: NeoTextStyles.bodyLarge.copyWith(color: itemColor),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}

// Sliver Tab Bar Delegate
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.black,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
