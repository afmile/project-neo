/// Project Neo - Custom Exceptions
///
/// Application-specific exceptions for error handling.
library;

/// Base exception class for all app exceptions
abstract class AppException implements Exception {
  final String message;
  final String? code;
  
  const AppException(this.message, {this.code});
  
  @override
  String toString() => 'AppException: $message (code: $code)';
}

/// Server/API related exceptions
class ServerException extends AppException {
  final int? statusCode;
  
  const ServerException(
    super.message, {
    this.statusCode,
    super.code,
  });
}

/// Authentication related exceptions
class NeoAuthException extends AppException {
  const NeoAuthException(super.message, {super.code});
  
  /// User not found
  factory NeoAuthException.userNotFound() => 
    const NeoAuthException('Usuario no encontrado', code: 'user_not_found');
  
  /// Invalid credentials
  factory NeoAuthException.invalidCredentials() => 
    const NeoAuthException('Credenciales inválidas', code: 'invalid_credentials');
  
  /// Email already in use
  factory NeoAuthException.emailInUse() => 
    const NeoAuthException('Este correo ya está registrado', code: 'email_in_use');
  
  /// Weak password
  factory NeoAuthException.weakPassword() => 
    const NeoAuthException('La contraseña es muy débil', code: 'weak_password');
  
  /// Email not confirmed
  factory NeoAuthException.emailNotConfirmed() => 
    const NeoAuthException('Por favor confirma tu correo electrónico', code: 'email_not_confirmed');
  
  /// Invalid OTP
  factory NeoAuthException.invalidOtp() => 
    const NeoAuthException('Código de verificación inválido', code: 'invalid_otp');
  
  /// Session expired
  factory NeoAuthException.sessionExpired() => 
    const NeoAuthException('Tu sesión ha expirado', code: 'session_expired');
  
  /// OAuth cancelled
  factory NeoAuthException.oauthCancelled() => 
    const NeoAuthException('Inicio de sesión cancelado', code: 'oauth_cancelled');
  
  /// Generic auth error
  factory NeoAuthException.unknown([String? message]) => 
    NeoAuthException(message ?? 'Error de autenticación desconocido', code: 'unknown');
}

/// Cache/local storage related exceptions
class CacheException extends AppException {
  const CacheException(super.message, {super.code});
}

/// Network related exceptions
class NetworkException extends AppException {
  const NetworkException([String message = 'Sin conexión a internet']) 
    : super(message, code: 'no_connection');
}

/// Validation exceptions
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;
  
  const ValidationException(
    super.message, {
    this.fieldErrors,
    super.code,
  });
}
