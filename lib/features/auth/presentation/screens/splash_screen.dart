/// Project Neo - Splash Screen
///
/// High-Tech Minimalista splash with auth check.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/neo_theme.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }
  
  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    
    if (!mounted) return;
    
    final authState = ref.read(authProvider);
    
    if (authState.status == AuthStatus.authenticated) {
      context.go('/home');
    } else if (authState.status == AuthStatus.needsVerification) {
      context.go('/verify-email');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated) {
        context.go('/home');
      } else if (next.status == AuthStatus.unauthenticated) {
        context.go('/login');
      }
    });
    
    return Scaffold(
      backgroundColor: NeoColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: NeoColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: NeoColors.border,
                  width: NeoSpacing.borderWidth,
                ),
              ),
              child: Icon(
                Icons.hub_rounded,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
            )
                .animate()
                .fadeIn(duration: 600.ms)
                .scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1, 1),
                  curve: Curves.easeOutBack,
                ),
            
            const SizedBox(height: NeoSpacing.lg),
            
            // Title
            Text(
              'PROJECT NEO',
              style: NeoTextStyles.displaySmall.copyWith(
                letterSpacing: 4,
              ),
            ).animate().fadeIn(duration: 600.ms, delay: 200.ms),
            
            const SizedBox(height: NeoSpacing.xxl),
            
            // Loading indicator
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
            ).animate().fadeIn(duration: 600.ms, delay: 400.ms),
          ],
        ),
      ),
    );
  }
}
