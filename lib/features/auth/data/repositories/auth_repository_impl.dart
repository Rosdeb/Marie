import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/storage/local_storage.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final LocalStorage localStorage;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localStorage,
  });

  @override
  Future<UserEntity> signIn({
    required String email,
    required String password,
  }) async {
    final response = await remoteDataSource.signIn(email, password);
    if (response.accessToken != null) {
      await localStorage.saveAccessToken(response.accessToken!);
    }
    if (response.refreshToken != null) {
      await localStorage.saveRefreshToken(response.refreshToken!);
    }
    if (response.user != null) {
      await localStorage.saveUserData(response.user!.toJson());
      return response.user!;
    }
    throw ServerException(message: response.message.isNotEmpty ? response.message : 'Sign in failed');
  }

  @override
  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
    required String profileType,
  }) async {
    final response = await remoteDataSource.signUp(
      name: name,
      email: email,
      password: password,
      profileType: profileType,
    );
    if (response.tempToken != null) {
      await localStorage.saveTempToken(response.tempToken!);
    }
    return response.tempToken;
  }

  @override
  Future<bool> verifyOtp({
    required String otp,
    String? signupToken,
  }) async {
    final token = signupToken ?? await localStorage.getTempToken();
    final response = await remoteDataSource.verifyOtp(otp: otp, signupToken: token);
    await localStorage.clearTempToken();
    final authToken = response.accessToken ?? response.tempToken;
    if (authToken != null && authToken.isNotEmpty) {
      await localStorage.saveAccessToken(authToken);
    }
    if (response.refreshToken != null && response.refreshToken!.isNotEmpty) {
      await localStorage.saveRefreshToken(response.refreshToken!);
    }
    if (response.user != null) {
      await localStorage.saveUserData(response.user!.toJson());
    }
    return response.success;
  }

  @override
  Future<bool> resendOtp({
    required String email,
  }) async {
    final response = await remoteDataSource.resendOtp(email);
    return response.success;
  }

  @override
  Future<String?> forgotPassword({
    required String email,
  }) async {
    final response = await remoteDataSource.forgotPassword(email);
    if (response.tempToken != null && response.tempToken!.isNotEmpty) {
      await localStorage.saveTempToken(response.tempToken!);
    }
    return response.tempToken;
  }

  @override
  Future<bool> forgotOtpVerify({
    required String otp,
    String? resetToken,
  }) async {
    final token = (resetToken != null && resetToken.isNotEmpty)
        ? resetToken
        : await localStorage.getTempToken();
    final response = await remoteDataSource.forgotOtpVerify(otp: otp, resetToken: token);
    if (response.tempToken != null && response.tempToken!.isNotEmpty) {
      await localStorage.saveTempToken(response.tempToken!);
    }
    return response.success;
  }

  @override
  Future<bool> resetPassword({
    required String newPassword,
    required String confirmPassword,
    String? resetToken,
  }) async {
    final token = (resetToken != null && resetToken.isNotEmpty)
        ? resetToken
        : await localStorage.getTempToken();
    final response = await remoteDataSource.resetPassword(
      newPassword: newPassword,
      confirmPassword: confirmPassword,
      resetToken: token,
    );
    await localStorage.clearTempToken();
    return response.success;
  }

  @override
  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final response = await remoteDataSource.changePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );
    return response.success;
  }

  @override
  Future<void> refreshToken() async {
    final response = await remoteDataSource.refreshToken();
    if (response.accessToken != null && response.accessToken!.isNotEmpty) {
      await localStorage.saveAccessToken(response.accessToken!);
    }
    if (response.refreshToken != null && response.refreshToken!.isNotEmpty) {
      await localStorage.saveRefreshToken(response.refreshToken!);
    }
  }

  @override
  Future<String?> getTempToken() => localStorage.getTempToken();

  @override
  Future<void> saveTempToken(String token) => localStorage.saveTempToken(token);

  @override
  Future<void> clearTempToken() => localStorage.clearTempToken();

  @override
  Future<void> signOut() async {
    await remoteDataSource.logout();
    await localStorage.clearAuth();
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final userData = await localStorage.getUserData();
    if (userData != null) {
      return UserModel.fromJson(userData);
    }
    return null;
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await localStorage.getAccessToken();
    return token != null && token.isNotEmpty;
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  final localStorage = ref.watch(localStorageProvider);
  return AuthRepositoryImpl(
    remoteDataSource: remoteDataSource,
    localStorage: localStorage,
  );
});
