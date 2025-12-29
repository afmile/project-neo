import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/env_config.dart';
import 'core/config/supabase_config.dart';
import 'core/error/sentry_context_helper.dart';
import 'core/router/app_router.dart';
import 'core/theme/neo_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/community/presentation/providers/content_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // OLED-optimized system UI
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: NeoColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
  // Initialize SharedPreferences for drafts
  final prefs = await SharedPreferences.getInstance();
  
  // Initialize Supabase with provided credentials
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );
  
  // Get app version for Sentry context
  final packageInfo = await PackageInfo.fromPlatform();
  
  // Run app with or without Sentry based on configuration
  if (EnvConfig.isSentryEnabled) {
    await _runWithSentry(prefs, packageInfo);
  } else {
    _runApp(prefs);
  }
}

/// Run app with Sentry error tracking
Future<void> _runWithSentry(
  SharedPreferences prefs,
  PackageInfo packageInfo,
) async {
  await SentryFlutter.init(
    (options) {
      options.dsn = EnvConfig.sentryDsn;
      options.environment = EnvConfig.environment;
      options.release = '${packageInfo.version}+${packageInfo.buildNumber}';
      options.dist = packageInfo.buildNumber;
      
      // Set app version context
      options.beforeSend = (event, hint) {
        event = event.copyWith(
          contexts: event.contexts.copyWith(
            app: SentryApp(
              name: packageInfo.appName,
              version: packageInfo.version,
              build: packageInfo.buildNumber,
            ),
          ),
        );
        return event;
      };
      
      // Performance monitoring (optional)
      options.tracesSampleRate = EnvConfig.isDebugMode ? 1.0 : 0.1;
      
      // Enable breadcrumbs
      options.enableAutoSessionTracking = true;
      options.attachScreenshot = true;
      options.screenshotQuality = SentryScreenshotQuality.low;
      options.attachViewHierarchy = true;
    },
    appRunner: () => runZonedGuarded(
      () async {
        // Set up Flutter error handling
        FlutterError.onError = (details) {
          Sentry.captureException(
            details.exception,
            stackTrace: details.stack,
          );
          FlutterError.presentError(details);
        };
        
        // Set initial user context from Supabase
        await SentryContextHelper.setSentryUser();
        
        // Run app
        _runApp(prefs);
      },
      (error, stackTrace) {
        // Catch async errors
        Sentry.captureException(error, stackTrace: stackTrace);
      },
    ),
  );
}

/// Run the app (with ProviderScope)
void _runApp(SharedPreferences prefs) {
  runApp(
    ProviderScope(
      overrides: [
        // Override SharedPreferences provider with initialized instance
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const ProjectNeoApp(),
    ),
  );
}

class ProjectNeoApp extends ConsumerWidget {
  const ProjectNeoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final theme = ref.watch(themeProvider);
    
    return MaterialApp.router(
      title: 'Project Neo',
      debugShowCheckedModeBanner: false,
      theme: theme,
      routerConfig: router,
    );
  }
}
