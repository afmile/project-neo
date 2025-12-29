/// Project Neo - Feedback Repository
///
/// Handles saving user feedback to Supabase.
library;

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/env_config.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// FEEDBACK MODEL
// ═══════════════════════════════════════════════════════════════════════════════

/// Types of feedback
enum FeedbackType {
  bug('bug'),
  suggestion('suggestion'),
  other('other');
  
  final String value;
  const FeedbackType(this.value);
}

/// Feedback context data
class FeedbackContext {
  final String route;
  final String appVersion;
  final String platform;
  final String? deviceInfo;
  
  const FeedbackContext({
    required this.route,
    required this.appVersion,
    required this.platform,
    this.deviceInfo,
  });
  
  Map<String, dynamic> toJson() => {
    'route': route,
    'appVersion': appVersion,
    'platform': platform,
    if (deviceInfo != null) 'deviceInfo': deviceInfo,
  };
}

// ═══════════════════════════════════════════════════════════════════════════════
// REPOSITORY
// ═══════════════════════════════════════════════════════════════════════════════

class FeedbackRepository {
  final SupabaseClient _client;
  
  FeedbackRepository(this._client);
  
  /// Submit feedback to Supabase
  Future<void> submitFeedback({
    required String userId,
    required FeedbackType type,
    required String message,
    required FeedbackContext context,
  }) async {
    await _client.from('feedback_reports').insert({
      'user_id': userId,
      'feedback_type': type.value,
      'message': message,
      'context': context.toJson(),
    });
  }
  
  /// Create context with current route
  FeedbackContext createContext(String currentRoute) {
    return FeedbackContext(
      route: currentRoute,
      appVersion: EnvConfig.fullVersion,
      platform: EnvConfig.platformName,
    );
  }
}
