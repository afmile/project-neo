/// Project Neo - Router Configuration
///
/// GoRouter setup with authentication redirect.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/verify_email_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/community/presentation/screens/community_screen.dart';

/// Global navigator key
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Router provider
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: true,
    
    // Redirect based on auth state
    redirect: (context, state) {
      final isLoading = authState.status == AuthStatus.initial || 
                        authState.status == AuthStatus.loading;
      final isAuthenticated = authState.status == AuthStatus.authenticated;
      final needsVerification = authState.status == AuthStatus.needsVerification;
      
      final isOnSplash = state.matchedLocation == '/';
      final isOnAuth = state.matchedLocation == '/login' || 
                       state.matchedLocation == '/register' ||
                       state.matchedLocation == '/forgot-password';
      final isOnVerify = state.matchedLocation == '/verify-email';
      
      // Still loading - show splash
      if (isLoading && !isOnSplash) {
        return '/';
      }
      
      // Needs verification - go to verify screen
      if (needsVerification && !isOnVerify) {
        return '/verify-email';
      }
      
      // Authenticated - redirect away from auth screens
      if (isAuthenticated && (isOnAuth || isOnSplash || isOnVerify)) {
        return '/home';
      }
      
      // Not authenticated - redirect to login
      if (!isAuthenticated && !isOnAuth && !isOnSplash && !needsVerification) {
        return '/login';
      }
      
      return null; // No redirect
    },
    
    routes: [
      // Splash
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      
      // Auth routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        name: 'verify-email',
        builder: (context, state) => const VerifyEmailScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Forgot Password - TODO')),
        ),
      ),
      
      // Main app routes
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      
      // Community route with dynamic slug
      GoRoute(
        path: '/community/:slug',
        name: 'community',
        builder: (context, state) {
          final slug = state.pathParameters['slug']!;
          return CommunityScreen(slug: slug);
        },
      ),
    ],
    
    // Error page
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Página no encontrada: ${state.uri}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Volver al inicio'),
            ),
          ],
        ),
      ),
    ),
  );
});
