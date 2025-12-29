/// Project Neo - Sentry Context Helper
///
/// Utilities for setting Sentry contexts and tags throughout the app.
library;

import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env_config.dart';

class SentryContextHelper {
  SentryContextHelper._();
  
  /// Set user context from Supabase auth
  static Future<void> setSentryUser() async {
    if (!EnvConfig.isSentryEnabled) return;
    
    final user = Supabase.instance.client.auth.currentUser;
    
    if (user != null) {
      await Sentry.configureScope((scope) {
        scope.setUser(SentryUser(
          id: user.id,
          email: user.email,
        ));
      });
    } else {
      // Clear user context when logged out
      await Sentry.configureScope((scope) {
        scope.setUser(null);
      });
    }
  }
  
  /// Set community context tag
  static Future<void> setCommunityContext(String? communityId) async {
    if (!EnvConfig.isSentryEnabled) return;
    
    await Sentry.configureScope((scope) {
      if (communityId != null) {
        scope.setTag('community_id', communityId);
      } else {
        scope.removeTag('community_id');
      }
    });
  }
  
  /// Set feature context tag
  static Future<void> setFeatureContext(String feature) async {
    if (!EnvConfig.isSentryEnabled) return;
    
    await Sentry.configureScope((scope) {
      scope.setTag('feature', feature);
    });
  }
  
  /// Add custom breadcrumb
  static void addBreadcrumb({
    required String message,
    String? category,
    SentryLevel level = SentryLevel.info,
    Map<String, dynamic>? data,
  }) {
    if (!EnvConfig.isSentryEnabled) return;
    
    Sentry.addBreadcrumb(Breadcrumb(
      message: message,
      category: category,
      level: level,
      data: data,
    ));
  }
  
  /// Clear all context tags
  static Future<void> clearContext() async {
    if (!EnvConfig.isSentryEnabled) return;
    
    await Sentry.configureScope((scope) {
      scope.removeTag('community_id');
      scope.removeTag('feature');
    });
  }
}
