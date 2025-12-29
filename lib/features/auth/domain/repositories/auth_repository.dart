/// Project Neo - Auth Repository Interface
///
/// Abstract contract for authentication operations.
library;

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';

/// Authentication repository interface
abstract class AuthRepository {
  /// Stream of authentication state changes
  Stream<UserEntity?> get authStateChanges;
  
  /// Get current user synchronously (from cache/memory)
  UserEntity? get currentUser;
  
  /// Get the currently authenticated user
  Future<Either<Failure, UserEntity?>> getCurrentUser();
  
  /// Sign in with email and password
  Future<Either<Failure, UserEntity>> signInWithEmail({
    required String email,
    required String password,
  });
  
  /// Sign up with email and password
  /// Returns the user without completing registration (email verification needed)
  Future<Either<Failure, UserEntity>> signUpWithEmail({
    required String email,
    required String password,
    required String username,
    String? captchaToken,
  });
  
  /// Verify email with OTP code
  Future<Either<Failure, UserEntity>> verifyEmailOtp({
    required String email,
    required String token,
  });
  
  /// Resend email verification code
  Future<Either<Failure, void>> resendVerificationEmail(String email);
  
  /// Sign in with Google
  Future<Either<Failure, UserEntity>> signInWithGoogle();
  
  /// Sign in with Apple
  Future<Either<Failure, UserEntity>> signInWithApple();
  
  /// Sign out
  Future<Either<Failure, void>> signOut();
  
  /// Send password reset email
  Future<Either<Failure, void>> sendPasswordResetEmail(String email);
  
  /// Update password
  Future<Either<Failure, void>> updatePassword(String newPassword);
  
  /// Update user profile
  Future<Either<Failure, UserEntity>> updateProfile({
    String? username,
    String? displayName,
    String? avatarUrl,
    String? bio,
  });
  
  /// Delete account
  Future<Either<Failure, void>> deleteAccount();
}
