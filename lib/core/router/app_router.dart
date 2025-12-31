/// Project Neo - Router Configuration
///
/// GoRouter setup with authentication redirect.
///
/// NAVIGATION ARCHITECTURE:
/// 
/// Level 0: Structural Navigation (Tabs)
/// - Context: Moving between Home, Discovery, Chats, Profile
/// - Animation: ZERO (Instant switching)
/// - Implementation: IndexedStack in HomeScreen with no transitions
/// - Rationale: These are "rooms in the same house" - you don't travel, you're simply there
/// 
/// Level 1: Hierarchical Navigation (Drill-Down)
/// - Context: Entering a Community, opening a Blog, viewing a Chat
/// - Animation: Native platform animations (Zoom on Android, Slide on iOS)
/// - Implementation: Inherits from ThemeData.pageTransitionsTheme
/// - Rationale: Provides clear visual feedback that you're "entering" content
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../config/env_config.dart';
import '../error/presentation/screens/report_issue_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/verify_email_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/home/presentation/providers/home_providers.dart';
import '../../features/community/domain/entities/community_entity.dart';
import '../../features/community/presentation/screens/community_screen.dart';
import '../../features/community/presentation/screens/community_home_screen.dart';
import '../../features/community/presentation/screens/community_preview_screen.dart';
import '../../features/community/presentation/screens/community_user_profile_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/discovery/presentation/screens/discovery_screen.dart';
import '../../features/blog/presentation/screens/blog_detail_screen.dart';
import '../../features/chat/domain/entities/chat_entity.dart';
import '../../features/chat/presentation/screens/chat_conversation_screen.dart';
import '../../features/chat/presentation/screens/create_private_room_screen.dart';
import '../../features/community/presentation/screens/community_settings_screen.dart';
import '../../features/community/presentation/screens/community_settings_hub_screen.dart';
import '../../features/community/presentation/screens/user_settings_screen.dart';
import '../../features/community/presentation/screens/local_edit_profile_screen.dart';
import '../../features/community/presentation/screens/user_community_titles_settings_screen.dart';
import '../../features/community/presentation/screens/request_title_screen.dart';
import '../../features/community/presentation/screens/title_requests_management_screen.dart';
import '../beta/beta.dart';

/// Global navigator key
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Auth state change notifier for router refresh
final _authChangeNotifierProvider = Provider<ValueNotifier<int>>((ref) {
  final notifier = ValueNotifier<int>(0);
  ref.listen<AuthState>(authProvider, (previous, next) {
    if (previous?.status != next.status) {
      notifier.value++;
    }
  });
  ref.onDispose(() => notifier.dispose());
  return notifier;
});

/// Router provider
final routerProvider = Provider<GoRouter>((ref) {
  final authChangeNotifier = ref.watch(_authChangeNotifierProvider);
  
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: false,
    refreshListenable: authChangeNotifier,
    
    // Sentry navigation tracking (if enabled)
    observers: EnvConfig.isSentryEnabled
        ? [SentryNavigatorObserver()]
        : [],
    
    // Redirect based on auth state - HARDENED
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final currentLocation = state.matchedLocation;
      final isAuthenticated = authState.status == AuthStatus.authenticated;
      final needsVerification = authState.status == AuthStatus.needsVerification;
      
      final isOnSplash = currentLocation == '/';
      final isOnVerify = currentLocation == '/verify-email';
      const publicAuthRoutes = ['/login', '/register', '/forgot-password', '/verify-email'];
      final isOnPublicAuth = publicAuthRoutes.contains(currentLocation);
      
      String? redirectTo;
      
      // RULE 1: Splash is NEVER a final destination
      if (isOnSplash) {
        if (isAuthenticated) {
          redirectTo = '/home';
        } else if (needsVerification) {
          redirectTo = '/verify-email';
        } else {
          redirectTo = '/login';
        }
      }
      // RULE 2: Needs email verification
      else if (needsVerification && !isOnVerify) {
        redirectTo = '/verify-email';
      }
      // RULE 3: Authenticated on auth screens -> home
      else if (isAuthenticated && isOnPublicAuth) {
        redirectTo = '/home';
      }
      // RULE 4: Not authenticated on private routes -> login
      else if (!isAuthenticated && !needsVerification && !isOnPublicAuth) {
        redirectTo = '/login';
      }
      
      // IDEMPOTENCY: Never redirect to current location
      if (redirectTo == currentLocation) {
        redirectTo = null;
      }
      
      // ═══════════════════════════════════════════════════════════════════════
      // BETA GUARDS (after auth is resolved)
      // ═══════════════════════════════════════════════════════════════════════
      
      // Only check beta guards for authenticated users going to private routes
      if (redirectTo == null && isAuthenticated && !isOnPublicAuth && !isOnSplash) {
        final isOnBetaScreen = currentLocation == '/beta-locked';
        final isOnUpdateScreen = currentLocation == '/force-update';
        
        // Check version first (higher priority)
        final isVersionBlocked = ref.read(isVersionBlockedProvider);
        if (isVersionBlocked && !isOnUpdateScreen) {
          return '/force-update';
        }
        
        // Check beta access
        final betaAccess = ref.read(betaAccessStateProvider);
        if (betaAccess == BetaAccessState.denied && !isOnBetaScreen && !isOnUpdateScreen) {
          return '/beta-locked';
        }
      }
      
      return redirectTo;
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
      
      // Beta routes
      GoRoute(
        path: '/beta-locked',
        name: 'beta-locked',
        builder: (context, state) => const BetaLockedScreen(),
      ),
      GoRoute(
        path: '/force-update',
        name: 'force-update',
        builder: (context, state) => const ForceUpdateScreen(),
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

      // Community home route - Level 1: Hierarchical Navigation
      // Uses native platform animations (Zoom on Android, Slide on iOS)
      // Hero animations work independently of page transitions
      // Uses root navigator to hide global bottom navigation
      GoRoute(
        path: '/community_home',
        name: 'community_home',
        parentNavigatorKey: rootNavigatorKey, // Hide global nav
        builder: (context, state) {
          final extra = state.extra;
          
          // Handle both old format (CommunityEntity) and new format (Map with isGuest/isLive)
          if (extra is Map<String, dynamic>) {
            final community = extra['community'] as CommunityEntity;
            final isGuest = extra['isGuest'] as bool? ?? false;
            final isLive = extra['isLive'] as bool? ?? false;
            return CommunityHomeScreen(
              community: community,
              isGuest: isGuest,
              isLive: isLive,
            );
          } else {
            final community = extra as CommunityEntity;
            return CommunityHomeScreen(community: community);
          }
        },
      ),

      // Community preview route - "El Portal"
      // Shown before joining a community
      GoRoute(
        path: '/community_preview',
        name: 'community_preview',
        builder: (context, state) {
          final community = state.extra as CommunityEntity;
          return CommunityPreviewScreen(community: community);
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

      // Blog Detail
      GoRoute(
        path: '/blog_detail',
        name: 'blog_detail',
        builder: (context, state) {
          final post = state.extra as FeedPost;
          return BlogDetailScreen(post: post);
        },
      ),

      // Chat Conversation
      GoRoute(
        path: '/chat/:chatId',
        name: 'chat_conversation',
        parentNavigatorKey: rootNavigatorKey, // Hide global nav
        builder: (context, state) {
          final chat = state.extra as ChatEntity;
          return ChatConversationScreen(chat: chat);
        },
      ),

      // Create Private Room
      GoRoute(
        path: '/create-private-room',
        name: 'create-private-room',
        parentNavigatorKey: rootNavigatorKey, // Hide global nav
        builder: (context, state) {
          final communityId = state.extra as String;
          return CreatePrivateRoomScreen(communityId: communityId);
        },
      ),

      // Community User Profile
      GoRoute(
        path: '/community-user-profile',
        name: 'community-user-profile',
        parentNavigatorKey: rootNavigatorKey, // Hide global nav
        builder: (context, state) {
          final params = state.extra as Map<String, String>;
          return CommunityUserProfileScreen(
            userId: params['userId']!,
            communityId: params['communityId']!,
          );
        },
      ),

      // Local Identity - "My identity in this community"
      GoRoute(
        path: '/community/:communityId/me',
        name: 'local-identity',
        parentNavigatorKey: rootNavigatorKey, // Hide global nav
        builder: (context, state) {
          final communityId = state.pathParameters['communityId']!;
          return LocalEditProfileScreen(communityId: communityId);
        },
      ),

      // User Settings (personal config from profile)
      GoRoute(
        path: '/community/:id/user-settings',
        name: 'user-settings',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>;
          return UserSettingsScreen(
            communityId: state.pathParameters['id']!,
            communityName: extras['name'] as String,
            themeColor: extras['color'] as Color,
          );
        },
      ),

      // Community Management (admin from home gear)
      GoRoute(
        path: '/community/:id/management',
        name: 'community-management',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>;
          return CommunityManagementScreen(
            community: extras['community'] as CommunityEntity,
          );
        },
      ),

      // Community Settings Hub (deprecated - redirect to management)
      GoRoute(
        path: '/community/:id/settings-hub',
        name: 'community-settings-hub',
        parentNavigatorKey: rootNavigatorKey,
        redirect: (context, state) => '/community/${state.pathParameters['id']}/management',
      ),

      // Community Settings (notifications only - kept for backward compat)
      GoRoute(
        path: '/community/:id/settings',
        name: 'community-settings',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>;
          return CommunitySettingsScreen(
            communityId: state.pathParameters['id']!,
            communityName: extras['name'] as String,
            themeColor: extras['color'] as Color,
          );
        },
      ),

      // Edit Community (owners only)
      GoRoute(
        path: '/community/:id/edit',
        name: 'edit-community',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>;
          // TODO: Create EditCommunityScreen
          return Scaffold(
            appBar: AppBar(title: const Text('Editar Comunidad')),
            body: const Center(child: Text('Próximamente')),
          );
        },
      ),

      // User Titles Settings
      GoRoute(
        path: '/community/:communityId/titles-settings',
        name: 'user-titles-settings',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>;
          return UserCommunityTitlesSettingsScreen(
            communityId: state.pathParameters['communityId']!,
            communityName: extras['name'] as String,
            themeColor: extras['color'] as Color,
          );
        },
      ),

        // Request title route (member creates custom title request)
        GoRoute(
          path: '/community/:communityId/request-title',
          name: 'request-title',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) {
            final communityId = state.pathParameters['communityId']!;
            final extra = state.extra as Map<String, dynamic>;
            
            return RequestTitleScreen(
              communityId: communityId,
              communityName: extra['name'] as String,
              themeColor: extra['color'] as Color,
            );
          },
        ),

        // Title requests management route (leaders approve/reject)
        GoRoute(
          path: '/community/:communityId/manage-title-requests',
          name: 'manage-title-requests',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) {
            final communityId = state.pathParameters['communityId']!;
            final extra = state.extra as Map<String, dynamic>;
            
            return TitleRequestsManagementScreen(
              communityId: communityId,
              communityName: extra['name'] as String,
              themeColor: extra['color'] as Color,
            );
          },
        ),
      
      // Report Issue
      GoRoute(
        path: '/report-issue',
        name: 'report-issue',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ReportIssueScreen(
            route: extra?['route'] as String?,
            communityId: extra?['community_id'] as String?,
            feature: extra?['feature'] as String?,
            errorMessage: extra?['error_message'] as String?,
            error: extra?['error'] as String?,
            stackTrace: extra?['stack_trace'] as String?,
          );
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
