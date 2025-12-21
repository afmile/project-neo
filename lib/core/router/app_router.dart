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
import '../../features/community/domain/entities/community_entity.dart';
import '../../features/community/presentation/screens/community_screen.dart';
import '../../features/community/presentation/screens/community_home_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/discovery/presentation/screens/discovery_screen.dart';

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
      final hasError = authState.status == AuthStatus.error;
      
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
      
      // If on verify screen and has pending email, stay there
      if (isOnVerify && authState.pendingEmail != null) {
        return null; // Stay on verify
      }
      
      // Authenticated - redirect away from auth screens
      if (isAuthenticated && (isOnAuth || isOnSplash || isOnVerify)) {
        return '/home';
      }
      
      // If there's an error on auth screens, stay there
      if (hasError && isOnAuth) {
        return null; // Stay to show error
      }
      
      // Not authenticated - redirect to login (but not if on auth screens already)
      if (!isAuthenticated && !isOnAuth && !isOnSplash && !needsVerification && !isOnVerify) {
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

      // Community home route with entity object
      GoRoute(
        path: '/community_home',
        name: 'community_home',
        builder: (context, state) {
          final community = state.extra as CommunityEntity;
          return CommunityHomeScreen(community: community);
        },
      ),

      // Notifications
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),

      // Discovery
      GoRoute(
        path: '/discovery',
        name: 'discovery',
        builder: (context, state) => const DiscoveryScreen(),
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
