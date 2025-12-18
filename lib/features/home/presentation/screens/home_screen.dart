/// Project Neo - Home Screen
///
/// High-Tech Minimalista home with Bento Grid layout.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/neo_theme.dart';
import '../../../../core/theme/neo_widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    
    return Scaffold(
      backgroundColor: NeoColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(NeoSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(context, ref, user?.username ?? 'Usuario')
                  .animate()
                  .fadeIn(duration: 500.ms),
              
              const SizedBox(height: NeoSpacing.lg),
              
              // Bento Grid
              Expanded(
                child: _buildBentoGrid(context, ref)
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 150.ms),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context, WidgetRef ref, String username) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¡Hola, $username!',
                style: NeoTextStyles.headlineLarge,
              ),
              const SizedBox(height: 2),
              Text(
                'Explora tus comunidades',
                style: NeoTextStyles.bodyMedium,
              ),
            ],
          ),
        ),
        
        // Profile button
        GestureDetector(
          onTap: () => _showProfileMenu(context, ref),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: NeoColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: NeoColors.border,
                width: NeoSpacing.borderWidth,
              ),
            ),
            child: Icon(
              Icons.person_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }
  
  void _showProfileMenu(BuildContext context, WidgetRef ref) {
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
            _menuItem(context, Icons.person_outline_rounded, 'Mi Perfil', () {
              Navigator.pop(context);
            }),
            _menuItem(context, Icons.settings_outlined, 'Configuración', () {
              Navigator.pop(context);
            }),
            const Divider(color: NeoColors.border, height: NeoSpacing.lg),
            _menuItem(context, Icons.logout_rounded, 'Cerrar Sesión', () {
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
    BuildContext context,
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
  
  Widget _buildBentoGrid(BuildContext context, WidgetRef ref) {
    final accent = Theme.of(context).colorScheme.primary;
    
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: NeoSpacing.md,
      crossAxisSpacing: NeoSpacing.md,
      children: [
        BentoCell(
          icon: Icons.groups_rounded,
          title: 'Comunidades',
          subtitle: 'Explora y únete',
          accentColor: accent,
          onTap: () {},
        ),
        BentoCell(
          icon: Icons.account_balance_wallet_rounded,
          title: 'Wallet',
          subtitle: '0 NEO',
          accentColor: NeoColors.success,
          onTap: () {},
        ),
        BentoCell(
          icon: Icons.chat_bubble_rounded,
          title: 'Mensajes',
          subtitle: 'Chats privados',
          accentColor: const Color(0xFFE91E63),
          onTap: () {},
        ),
        BentoCell(
          icon: Icons.explore_rounded,
          title: 'Descubrir',
          subtitle: 'Nuevas comunidades',
          accentColor: const Color(0xFF00BCD4),
          onTap: () {},
        ),
      ],
    );
  }
}
