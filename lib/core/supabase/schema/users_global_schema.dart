/// Supabase schema constants for users_global table
/// 
/// VERIFIED SCHEMA - These are the ACTUAL columns that exist in production.
/// DO NOT use string literals for column names - always use these constants.
class UsersGlobalSchema {
  UsersGlobalSchema._(); // Private constructor to prevent instantiation

  // Table name
  static const String table = 'users_global';

  // Column names (verified against actual DB schema)
  static const String id = 'id';
  static const String username = 'username';
  static const String email = 'email';
  static const String avatarGlobalUrl = 'avatar_global_url';  // NOT avatar_url!
  static const String bio = 'bio';
  static const String createdAt = 'created_at';

  // Common select fragments
  
  /// Basic user info (for avatars, names)
  static const String selectBasic = '$id, $username, $avatarGlobalUrl';
  
  /// Profile info (includes bio)
  static const String selectProfile = '$selectBasic, $bio';
}
