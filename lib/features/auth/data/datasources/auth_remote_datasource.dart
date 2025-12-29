/// Project Neo - Auth Remote Datasource
///
/// Handles all Supabase authentication API calls.
library;

import 'dart:async';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';

/// Remote data source for authentication
abstract class AuthRemoteDataSource {
  /// Stream of auth state changes
  Stream<UserModel?> get authStateChanges;
  
  /// Get current user synchronously (from Supabase session cache)
  UserModel? get currentUser;
  
  /// Get current user async (with profile fetch)
  Future<UserModel?> getCurrentUser();
  
  /// Sign in with email/password
  Future<UserModel> signInWithEmail(String email, String password);
  
  /// Sign up with email/password
  Future<UserModel> signUpWithEmail(String email, String password, String username, {String? captchaToken});
  
  /// Verify email OTP
  Future<UserModel> verifyEmailOtp(String email, String token);
  
  /// Resend verification email
  Future<void> resendVerificationEmail(String email);
  
  /// Sign in with Google
  Future<UserModel> signInWithGoogle();
  
  /// Sign in with Apple
  Future<UserModel> signInWithApple();
  
  /// Sign out
  Future<void> signOut();
  
  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email);
  
  /// Update password
  Future<void> updatePassword(String newPassword);
  
  /// Update profile
  Future<UserModel> updateProfile({
    String? username,
    String? displayName,
    String? avatarUrl,
    String? bio,
  });
  
  /// Delete account
  Future<void> deleteAccount();
}

/// Implementation of AuthRemoteDataSource using Supabase
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient _client;
  final GoogleSignIn _googleSignIn;
  
  AuthRemoteDataSourceImpl({
    SupabaseClient? client,
    GoogleSignIn? googleSignIn,
  }) : _client = client ?? Supabase.instance.client,
       _googleSignIn = googleSignIn ?? GoogleSignIn(
         scopes: ['email', 'profile'],
         serverClientId: SupabaseConfig.googleWebClientId,
       );
  
  @override
  Stream<UserModel?> get authStateChanges {
    return _client.auth.onAuthStateChange.asyncMap((event) async {
      if (event.session?.user == null) return null;
      
      try {
        return await _fetchUserProfile(event.session!.user);
      } catch (e) {
        // If profile fetch fails, return basic user from auth data
        final user = event.session!.user;
        return UserModel(
          id: user.id,
          email: user.email ?? '',
          username: user.userMetadata?['username'] ?? 
                    'user_${user.id.substring(0, 8)}',
          createdAt: DateTime.now(),
        );
      }
    });
  }
  
  @override
  UserModel? get currentUser {
    // Synchronous access to cached session
    final user = _client.auth.currentUser;
    if (user == null) return null;
    
    // Create minimal UserModel from cached user data
    return UserModel(
      id: user.id,
      email: user.email ?? '',
      username: user.userMetadata?['username'] as String? ?? 'user_${user.id.substring(0, 8)}',
      displayName: user.userMetadata?['display_name'] as String?,
      avatarUrl: user.userMetadata?['avatar_url'] as String?,
      createdAt: DateTime.now(), // Placeholder - will be updated by stream
    );
  }
  
  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;
      return await _fetchUserProfile(user);
    } catch (e) {
      throw NeoAuthException.unknown(e.toString());
    }
  }
  
  @override
  Future<UserModel> signInWithEmail(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user == null) {
        throw NeoAuthException.invalidCredentials();
      }
      
      return await _fetchUserProfile(response.user!);
    } on NeoAuthException {
      rethrow;
    } on AuthException catch (e) {
      throw _mapAuthError(e);
    } catch (e) {
      throw NeoAuthException.unknown(e.toString());
    }
  }
  
  @override
  Future<UserModel> signUpWithEmail(
    String email, 
    String password, 
    String username,
    {String? captchaToken}
  ) async {
    try {
      // Check if username is already taken
      final existing = await _client
          .from('users_global')
          .select('id')
          .eq('username', username)
          .maybeSingle();
      
      if (existing != null) {
        throw const NeoAuthException(
          'Este nombre de usuario ya está en uso',
          code: 'username_taken',
        );
      }
      
      // Sign up with email confirmation
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'username': username},
        captchaToken: captchaToken, // Pass CAPTCHA token if provided
      );
      
      if (response.user == null) {
        throw NeoAuthException.unknown();
      }
      
      // The trigger in Supabase will create users_global, security_profile, wallet
      // Wait briefly for trigger to complete
      await Future.delayed(const Duration(milliseconds: 500));
      
      return await _fetchUserProfile(response.user!);
    } on NeoAuthException {
      rethrow;
    } on AuthException catch (e) {
      throw _mapAuthError(e);
    } catch (e) {
      throw NeoAuthException.unknown(e.toString());
    }
  }
  
  @override
  Future<UserModel> verifyEmailOtp(String email, String token) async {
    try {
      final response = await _client.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.email,
      );
      
      if (response.user == null) {
        throw NeoAuthException.invalidOtp();
      }
      
      return await _fetchUserProfile(response.user!);
    } on NeoAuthException {
      rethrow;
    } on AuthException catch (e) {
      throw _mapAuthError(e);
    } catch (e) {
      throw NeoAuthException.unknown(e.toString());
    }
  }
  
  @override
  Future<void> resendVerificationEmail(String email) async {
    try {
      await _client.auth.resend(
        type: OtpType.email,
        email: email,
      );
    } on AuthException catch (e) {
      throw _mapAuthError(e);
    } catch (e) {
      throw NeoAuthException.unknown(e.toString());
    }
  }
  
  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        throw NeoAuthException.oauthCancelled();
      }
      
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;
      
      if (idToken == null) {
        throw const NeoAuthException(
          'No se pudo obtener el token de Google',
          code: 'google_token_error',
        );
      }
      
      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      
      if (response.user == null) {
        throw NeoAuthException.unknown();
      }
      
      // Wait for trigger to create profile
      await Future.delayed(const Duration(milliseconds: 500));
      
      return await _fetchUserProfile(response.user!);
    } on NeoAuthException {
      rethrow;
    } on AuthException catch (e) {
      throw _mapAuthError(e);
    } catch (e) {
      throw NeoAuthException.unknown(e.toString());
    }
  }
  
  @override
  Future<UserModel> signInWithApple() async {
    try {
      // Use OAuth flow for Apple Sign In
      // Note: signInWithApple native method is iOS only via sign_in_with_apple package
      // This uses the web OAuth flow which works on all platforms
      final response = await _client.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: SupabaseConfig.redirectUrl,
      );
      
      // OAuth flow is async - the auth state listener will handle the result
      if (!response) {
        throw NeoAuthException.oauthCancelled();
      }
      
      // Wait for auth state to update
      await Future.delayed(const Duration(seconds: 1));
      
      final user = _client.auth.currentUser;
      if (user == null) {
        throw NeoAuthException.unknown();
      }
      
      return await _fetchUserProfile(user);
    } on NeoAuthException {
      rethrow;
    } on AuthException catch (e) {
      throw _mapAuthError(e);
    } catch (e) {
      throw NeoAuthException.unknown(e.toString());
    }
  }
  
  @override
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _client.auth.signOut();
    } catch (e) {
      throw NeoAuthException.unknown(e.toString());
    }
  }
  
  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: SupabaseConfig.redirectUrl,
      );
    } on AuthException catch (e) {
      throw _mapAuthError(e);
    } catch (e) {
      throw NeoAuthException.unknown(e.toString());
    }
  }
  
  @override
  Future<void> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } on AuthException catch (e) {
      throw _mapAuthError(e);
    } catch (e) {
      throw NeoAuthException.unknown(e.toString());
    }
  }
  
  @override
  Future<UserModel> updateProfile({
    String? username,
    String? displayName,
    String? avatarUrl,
    String? bio,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw NeoAuthException.sessionExpired();
      }
      
      final updates = <String, dynamic>{};
      if (username != null) updates['username'] = username;
      if (displayName != null) updates['display_name'] = displayName;
      if (avatarUrl != null) updates['avatar_global_url'] = avatarUrl;
      if (bio != null) updates['bio'] = bio;
      
      if (updates.isNotEmpty) {
        await _client
            .from('users_global')
            .update(updates)
            .eq('id', userId);
      }
      
      return await _fetchUserProfile(_client.auth.currentUser!);
    } on NeoAuthException {
      rethrow;
    } catch (e) {
      throw NeoAuthException.unknown(e.toString());
    }
  }
  
  @override
  Future<void> deleteAccount() async {
    try {
      // Note: This requires a Supabase Edge Function or RPC for secure deletion
      // For now, just sign out
      await signOut();
      throw const NeoAuthException(
        'La eliminación de cuenta requiere contactar a soporte',
        code: 'deletion_not_implemented',
      );
    } catch (e) {
      throw NeoAuthException.unknown(e.toString());
    }
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Fetch complete user profile from multiple tables
  Future<UserModel> _fetchUserProfile(User authUser) async {
    try {
      // Fetch users_global
      final userGlobal = await _client
          .from('users_global')
          .select()
          .eq('id', authUser.id)
          .maybeSingle();
      
      // Fetch security_profile
      final securityProfile = await _client
          .from('security_profile')
          .select()
          .eq('user_id', authUser.id)
          .maybeSingle();
      
      // Fetch wallet
      final wallet = await _client
          .from('wallets')
          .select()
          .eq('user_id', authUser.id)
          .maybeSingle();
      
      return UserModel.fromSupabase(
        id: authUser.id,
        email: authUser.email ?? '',
        userGlobal: userGlobal,
        securityProfile: securityProfile,
        wallet: wallet,
      );
    } catch (e) {
      // If profile doesn't exist yet (first login), return basic user
      return UserModel(
        id: authUser.id,
        email: authUser.email ?? '',
        username: authUser.userMetadata?['username'] ?? 
                  'user_${authUser.id.substring(0, 8)}',
        createdAt: DateTime.now(),
      );
    }
  }
  
  /// Map Supabase auth errors to our exceptions
  NeoAuthException _mapAuthError(AuthException e) {
    final message = e.message.toLowerCase();
    
    if (message.contains('user not found')) {
      return NeoAuthException.userNotFound();
    }
    if (message.contains('invalid login credentials')) {
      return NeoAuthException.invalidCredentials();
    }
    if (message.contains('email already registered') || 
        message.contains('user already registered')) {
      return NeoAuthException.emailInUse();
    }
    if (message.contains('weak password') || 
        message.contains('password should be')) {
      return NeoAuthException.weakPassword();
    }
    if (message.contains('email not confirmed')) {
      return NeoAuthException.emailNotConfirmed();
    }
    if (message.contains('invalid otp') || message.contains('token has expired')) {
      return NeoAuthException.invalidOtp();
    }
    if (message.contains('session') || message.contains('refresh token')) {
      return NeoAuthException.sessionExpired();
    }
    
    return NeoAuthException.unknown(e.message);
  }
}
