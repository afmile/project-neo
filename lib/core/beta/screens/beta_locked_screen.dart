/// Project Neo - Beta Locked Screen
///
/// Shown to users who are not in the closed beta allowlist.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/neo_theme.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';

class BetaLockedScreen extends ConsumerWidget {
  const BetaLockedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: NeoColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              
              // Lock icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: NeoColors.accent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  size: 60,
                  color: NeoColors.accent,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Title
              Text(
                'Beta Cerrada',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: NeoColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Subtitle
              Text(
                'Gracias por tu interés en Neo.\nActualmente estás en lista de espera para acceder a la beta.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: NeoColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              // Info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: NeoColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: NeoColors.border),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: NeoColors.accent,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Te notificaremos cuando tu acceso esté listo.',
                        style: TextStyle(color: NeoColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Logout button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(authProvider.notifier).signOut();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Cerrar sesión'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: NeoColors.textSecondary,
                    side: const BorderSide(color: NeoColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
