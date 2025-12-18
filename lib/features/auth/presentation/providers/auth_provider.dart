/// Project Neo - Auth Providers
///
/// Riverpod providers for authentication state management.
library;

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

// ═══════════════════════════════════════════════════════════════════════════
// DEPENDENCY PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// Provider for AuthRemoteDataSource
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl();
});

/// Provider for AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
  );
});

// ═══════════════════════════════════════════════════════════════════════════
// AUTH STATE
// ═══════════════════════════════════════════════════════════════════════════

/// Auth state enum
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  needsVerification,
  error,
}

/// Auth state class
class AuthState {
  final AuthStatus status;
  final UserEntity? user;
  final String? error;
  final String? pendingEmail;
  
  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error,
    this.pendingEmail,
  });
  
  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;
  bool get isLoading => status == AuthStatus.loading;
  
  AuthState copyWith({
    AuthStatus? status,
    UserEntity? user,
    String? error,
    String? pendingEmail,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
      pendingEmail: pendingEmail ?? this.pendingEmail,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// AUTH NOTIFIER
// ═══════════════════════════════════════════════════════════════════════════

/// Auth state notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  StreamSubscription? _authSubscription;
  
  AuthNotifier(this._repository) : super(const AuthState()) {
    _init();
  }
  
  void _init() {
    state = state.copyWith(status: AuthStatus.loading);
    
    // Listen to auth state changes
    _authSubscription = _repository.authStateChanges.listen(
      (user) {
        if (user != null) {
          state = AuthState(
            status: AuthStatus.authenticated,
            user: user,
          );
        } else {
          state = const AuthState(status: AuthStatus.unauthenticated);
        }
      },
      onError: (error) {
        state = AuthState(
          status: AuthStatus.error,
          error: error.toString(),
        );
      },
    );
    
    // Also check current user
    _checkCurrentUser();
  }
  
  Future<void> _checkCurrentUser() async {
    final result = await _repository.getCurrentUser();
    result.fold(
      (failure) {
        state = const AuthState(status: AuthStatus.unauthenticated);
      },
      (user) {
        if (user != null) {
          state = AuthState(
            status: AuthStatus.authenticated,
            user: user,
          );
        } else {
          state = const AuthState(status: AuthStatus.unauthenticated);
        }
      },
    );
  }
  
  /// Sign in with email and password
  Future<void> signInWithEmail(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    
    final result = await _repository.signInWithEmail(
      email: email,
      password: password,
    );
    
    result.fold(
      (failure) {
        if (failure.code == 'email_not_confirmed') {
          state = AuthState(
            status: AuthStatus.needsVerification,
            pendingEmail: email,
            error: failure.message,
          );
        } else {
          state = AuthState(
            status: AuthStatus.error,
            error: failure.message,
          );
        }
      },
      (user) {
        state = AuthState(
          status: AuthStatus.authenticated,
          user: user,
        );
      },
    );
  }
  
  /// Sign up with email and password
  Future<void> signUpWithEmail(String email, String password, String username) async {
    state = state.copyWith(status: AuthStatus.loading);
    
    final result = await _repository.signUpWithEmail(
      email: email,
      password: password,
      username: username,
    );
    
    result.fold(
      (failure) {
        state = AuthState(
          status: AuthStatus.error,
          error: failure.message,
        );
      },
      (user) {
        // After signup, user needs to verify email
        state = AuthState(
          status: AuthStatus.needsVerification,
          pendingEmail: email,
        );
      },
    );
  }
  
  /// Verify email with OTP
  Future<void> verifyEmailOtp(String token) async {
    if (state.pendingEmail == null) return;
    
    state = state.copyWith(status: AuthStatus.loading);
    
    final result = await _repository.verifyEmailOtp(
      email: state.pendingEmail!,
      token: token,
    );
    
    result.fold(
      (failure) {
        state = state.copyWith(
          status: AuthStatus.needsVerification,
          error: failure.message,
        );
      },
      (user) {
        state = AuthState(
          status: AuthStatus.authenticated,
          user: user,
        );
      },
    );
  }
  
  /// Resend verification email
  Future<void> resendVerificationEmail() async {
    if (state.pendingEmail == null) return;
    
    final result = await _repository.resendVerificationEmail(state.pendingEmail!);
    
    result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
      },
      (_) {
        // Success - email sent
        state = state.copyWith(error: null);
      },
    );
  }
  
  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading);
    
    final result = await _repository.signInWithGoogle();
    
    result.fold(
      (failure) {
        if (failure.code == 'oauth_cancelled') {
          state = const AuthState(status: AuthStatus.unauthenticated);
        } else {
          state = AuthState(
            status: AuthStatus.error,
            error: failure.message,
          );
        }
      },
      (user) {
        state = AuthState(
          status: AuthStatus.authenticated,
          user: user,
        );
      },
    );
  }
  
  /// Sign in with Apple
  Future<void> signInWithApple() async {
    state = state.copyWith(status: AuthStatus.loading);
    
    final result = await _repository.signInWithApple();
    
    result.fold(
      (failure) {
        if (failure.code == 'oauth_cancelled') {
          state = const AuthState(status: AuthStatus.unauthenticated);
        } else {
          state = AuthState(
            status: AuthStatus.error,
            error: failure.message,
          );
        }
      },
      (user) {
        state = AuthState(
          status: AuthStatus.authenticated,
          user: user,
        );
      },
    );
  }
  
  /// Sign out
  Future<void> signOut() async {
    state = state.copyWith(status: AuthStatus.loading);
    
    final result = await _repository.signOut();
    
    result.fold(
      (failure) {
        state = AuthState(
          status: AuthStatus.error,
          error: failure.message,
        );
      },
      (_) {
        state = const AuthState(status: AuthStatus.unauthenticated);
      },
    );
  }
  
  /// Send password reset email
  Future<bool> sendPasswordReset(String email) async {
    final result = await _repository.sendPasswordResetEmail(email);
    
    return result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
        return false;
      },
      (_) => true,
    );
  }
  
  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
  
  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MAIN PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

/// Main auth provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});

/// Convenience provider for current user
final currentUserProvider = Provider<UserEntity?>((ref) {
  return ref.watch(authProvider).user;
});

/// Convenience provider for auth status
final authStatusProvider = Provider<AuthStatus>((ref) {
  return ref.watch(authProvider).status;
});

/// Convenience provider for checking if authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});
