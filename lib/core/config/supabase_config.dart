/// Project Neo - Supabase Configuration
/// 
/// This file contains the Supabase connection configuration.
/// For production, consider using environment variables.
library;

class SupabaseConfig {
  SupabaseConfig._();
  
  /// Supabase project URL
  static const String url = 'https://gdyetkqconuvyqbqxdom.supabase.co';
  
  /// Supabase anon/public key
  static const String anonKey = 'sb_publishable_0r1KacQRiOQyNJzXUrp1jg_qeRVKuKW';
  
  /// Google OAuth Web Client ID (required for Google Sign In)
  /// You need to get this from Google Cloud Console
  static const String googleWebClientId = 'YOUR_GOOGLE_WEB_CLIENT_ID';
  
  /// Deep link scheme for OAuth redirects
  static const String deepLinkScheme = 'io.projectneo';
  
  /// OAuth redirect URL
  static String get redirectUrl => '$deepLinkScheme://login-callback/';
}
