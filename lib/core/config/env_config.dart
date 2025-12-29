/// Project Neo - Environment Configuration
///
/// Configuration for environment-specific settings using dart-define.
/// Sentry is safely disabled if DSN is not provided.
library;

import 'dart:io';
import 'package:flutter/foundation.dart';

class EnvConfig {
  EnvConfig._();
  
  /// Sentry DSN from --dart-define=SENTRY_DSN=...
  /// If not provided, Sentry will be disabled
  static const String sentryDsn = String.fromEnvironment('SENTRY_DSN', defaultValue: '');
  
  /// Check if Sentry is enabled (DSN is not empty)
  static bool get isSentryEnabled => sentryDsn.isNotEmpty;
  
  /// Check if running in debug mode
  static bool get isDebugMode => kDebugMode;
  
  /// Check if running in release mode
  static bool get isReleaseMode => kReleaseMode;
  
  /// Get current platform name
  static String get platformName {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }
  
  /// Environment name (dev/prod based on build mode)
  static String get environment => isReleaseMode ? 'production' : 'development';
  
  // ═══════════════════════════════════════════════════════════════════════════
  // AUTH CONFIGURATION
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// hCaptcha site key from --dart-define=HCAPTCHA_SITE_KEY=...
  /// If not provided, CAPTCHA will be disabled (graceful degradation)
  static const String hCaptchaSiteKey = String.fromEnvironment(
    'HCAPTCHA_SITE_KEY',
    defaultValue: '',
  );
  
  /// Check if CAPTCHA is enabled (site key is not empty)
  static bool get isCaptchaEnabled => hCaptchaSiteKey.isNotEmpty;
  
  /// Enable OAuth providers (Google/Apple)
  /// Set to false for beta - OAuth is disabled
  static const bool enableOAuth = false;
  
  // ═══════════════════════════════════════════════════════════════════════════
  // APP VERSION
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// App version from --dart-define=APP_VERSION=...
  static const String appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '0.5.0',
  );
  
  /// Build number from --dart-define=BUILD_NUMBER=...
  static const int buildNumber = int.fromEnvironment(
    'BUILD_NUMBER',
    defaultValue: 1,
  );
  
  /// Full version string for display
  static String get fullVersion => '$appVersion+$buildNumber';
}
