/// Supabase Schema Constants - Bug Reports Table
///
/// Constants for the bug_reports table schema.
/// Prevents typos and enables IDE autocomplete.
library;

class BugReportsSchema {
  BugReportsSchema._();
  
  // Table name
  static const String tableName = 'bug_reports';
  
  // Column names
  static const String id = 'id';
  static const String createdAt = 'created_at';
  static const String userId = 'user_id';
  static const String communityId = 'community_id';
  static const String route = 'route';
  static const String description = 'description';
  static const String appVersion = 'app_version';
  static const String buildNumber = 'build_number';
  static const String platform = 'platform';
  static const String deviceInfo = 'device_info';
  static const String sentryEventId = 'sentry_event_id';
  static const String feature = 'feature';
  static const String extra = 'extra';
}
