/// Project Neo - Auth Repository Implementation
///
/// Implements AuthRepository using the remote datasource.
library;

import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

/// Implementation of AuthRepository
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  
  AuthRepositoryImpl({required AuthRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;
  
  @override
  Stream<UserEntity?> get authStateChanges => _remoteDataSource.authStateChanges;
  
  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    try {
      final user = await _remoteDataSource.getCurrentUser();
      return Right(user);
    } on NeoAuthException catch (e) {
      return Left(AuthFailure(e.message, code: e.code));
    } on NetworkException {
      return const Left(NetworkFailure());
    } catch (e) {
      return Left(AuthFailure.unknown(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, UserEntity>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _remoteDataSource.signInWithEmail(email, password);
      return Right(user);
    } on NeoAuthException catch (e) {
      return Left(AuthFailure(e.message, code: e.code));
    } on NetworkException {
      return const Left(NetworkFailure());
    } catch (e) {
      return Left(AuthFailure.unknown(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, UserEntity>> signUpWithEmail({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final user = await _remoteDataSource.signUpWithEmail(email, password, username);
      return Right(user);
    } on NeoAuthException catch (e) {
      return Left(AuthFailure(e.message, code: e.code));
    } on NetworkException {
      return const Left(NetworkFailure());
    } catch (e) {
      return Left(AuthFailure.unknown(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, UserEntity>> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    try {
      final user = await _remoteDataSource.verifyEmailOtp(email, token);
      return Right(user);
    } on NeoAuthException catch (e) {
      return Left(AuthFailure(e.message, code: e.code));
    } on NetworkException {
      return const Left(NetworkFailure());
    } catch (e) {
      return Left(AuthFailure.unknown(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, void>> resendVerificationEmail(String email) async {
    try {
      await _remoteDataSource.resendVerificationEmail(email);
      return const Right(null);
    } on NeoAuthException catch (e) {
      return Left(AuthFailure(e.message, code: e.code));
    } on NetworkException {
      return const Left(NetworkFailure());
    } catch (e) {
      return Left(AuthFailure.unknown(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, UserEntity>> signInWithGoogle() async {
    try {
      final user = await _remoteDataSource.signInWithGoogle();
      return Right(user);
    } on NeoAuthException catch (e) {
      return Left(AuthFailure(e.message, code: e.code));
    } on NetworkException {
      return const Left(NetworkFailure());
    } catch (e) {
      return Left(AuthFailure.unknown(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, UserEntity>> signInWithApple() async {
    try {
      final user = await _remoteDataSource.signInWithApple();
      return Right(user);
    } on NeoAuthException catch (e) {
      return Left(AuthFailure(e.message, code: e.code));
    } on NetworkException {
      return const Left(NetworkFailure());
    } catch (e) {
      return Left(AuthFailure.unknown(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _remoteDataSource.signOut();
      return const Right(null);
    } on NeoAuthException catch (e) {
      return Left(AuthFailure(e.message, code: e.code));
    } catch (e) {
      return Left(AuthFailure.unknown(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, void>> sendPasswordResetEmail(String email) async {
    try {
      await _remoteDataSource.sendPasswordResetEmail(email);
      return const Right(null);
    } on NeoAuthException catch (e) {
      return Left(AuthFailure(e.message, code: e.code));
    } on NetworkException {
      return const Left(NetworkFailure());
    } catch (e) {
      return Left(AuthFailure.unknown(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, void>> updatePassword(String newPassword) async {
    try {
      await _remoteDataSource.updatePassword(newPassword);
      return const Right(null);
    } on NeoAuthException catch (e) {
      return Left(AuthFailure(e.message, code: e.code));
    } on NetworkException {
      return const Left(NetworkFailure());
    } catch (e) {
      return Left(AuthFailure.unknown(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, UserEntity>> updateProfile({
    String? username,
    String? displayName,
    String? avatarUrl,
    String? bio,
  }) async {
    try {
      final user = await _remoteDataSource.updateProfile(
        username: username,
        displayName: displayName,
        avatarUrl: avatarUrl,
        bio: bio,
      );
      return Right(user);
    } on NeoAuthException catch (e) {
      return Left(AuthFailure(e.message, code: e.code));
    } on NetworkException {
      return const Left(NetworkFailure());
    } catch (e) {
      return Left(AuthFailure.unknown(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, void>> deleteAccount() async {
    try {
      await _remoteDataSource.deleteAccount();
      return const Right(null);
    } on NeoAuthException catch (e) {
      return Left(AuthFailure(e.message, code: e.code));
    } catch (e) {
      return Left(AuthFailure.unknown(e.toString()));
    }
  }
}
