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
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdkeWV0a3Fjb251dnlxYnF4ZG9tIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjYwMTMxOTcsImV4cCI6MjA4MTU4OTE5N30.Fhy-dZAn6VuS_I84p0eoQA6nFS7QH0XOaGLCMrRQpdk';
  
  /// Google OAuth Web Client ID (required for Google Sign In)
  /// You need to get this from Google Cloud Console
  static const String googleWebClientId = 'YOUR_GOOGLE_WEB_CLIENT_ID';
  
  /// Deep link scheme for OAuth redirects
  static const String deepLinkScheme = 'io.projectneo';
  
  /// OAuth redirect URL
  static String get redirectUrl => '$deepLinkScheme://login-callback/';
}
