/// Project Neo - Failure Classes
///
/// Failure classes for domain layer error handling using Either pattern.
library;

import 'package:equatable/equatable.dart';

/// Base failure class
abstract class Failure extends Equatable {
  final String message;
  final String? code;
  
  const Failure(this.message, {this.code});
  
  @override
  List<Object?> get props => [message, code];
}

/// Server/API failures
class ServerFailure extends Failure {
  final int? statusCode;
  
  const ServerFailure(super.message, {this.statusCode, super.code});
  
  @override
  List<Object?> get props => [message, statusCode, code];
}

/// Authentication failures
class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code});
  
  factory AuthFailure.userNotFound() => 
    const AuthFailure('Usuario no encontrado', code: 'user_not_found');
  
  factory AuthFailure.invalidCredentials() => 
    const AuthFailure('Credenciales inválidas', code: 'invalid_credentials');
  
  factory AuthFailure.emailInUse() => 
    const AuthFailure('Este correo ya está registrado', code: 'email_in_use');
  
  factory AuthFailure.weakPassword() => 
    const AuthFailure('La contraseña es muy débil', code: 'weak_password');
  
  factory AuthFailure.emailNotConfirmed() => 
    const AuthFailure('Por favor confirma tu correo electrónico', code: 'email_not_confirmed');
  
  factory AuthFailure.invalidOtp() => 
    const AuthFailure('Código de verificación inválido', code: 'invalid_otp');
  
  factory AuthFailure.sessionExpired() => 
    const AuthFailure('Tu sesión ha expirado', code: 'session_expired');
  
  factory AuthFailure.oauthCancelled() => 
    const AuthFailure('Inicio de sesión cancelado', code: 'oauth_cancelled');
  
  factory AuthFailure.unknown([String? message]) => 
    AuthFailure(message ?? 'Error de autenticación desconocido', code: 'unknown');
}

/// Cache failures
class CacheFailure extends Failure {
  const CacheFailure(super.message, {super.code});
}

/// Network failures
class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'Sin conexión a internet']) 
    : super(message, code: 'no_connection');
}

/// Validation failures
class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;
  
  const ValidationFailure(super.message, {this.fieldErrors, super.code});
  
  @override
  List<Object?> get props => [message, fieldErrors, code];
}
