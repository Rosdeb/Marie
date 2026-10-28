import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/auth_response_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponseModel> signIn(String email, String password);
  Future<AuthResponseModel> signUp({
    required String name,
    required String email,
    required String password,
    required String profileType,
  });
  Future<AuthResponseModel> verifyOtp({required String otp, String? signupToken});
  Future<AuthResponseModel> resendOtp(String email);
  Future<AuthResponseModel> forgotPassword(String email);
  Future<AuthResponseModel> forgotOtpVerify({required String otp, String? resetToken});
  Future<AuthResponseModel> resetPassword({
    required String newPassword,
    required String confirmPassword,
    String? resetToken,
  });
  Future<AuthResponseModel> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  });
  Future<AuthResponseModel> refreshToken();
  Future<AuthResponseModel> googleLogin(String idToken);
  Future<AuthResponseModel> appleLogin({
    required String identityToken,
    String? firstName,
    String? lastName,
    String? email,
  });
  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<AuthResponseModel> signIn(String email, String password) async {
    final response = await apiClient.post(
      ApiConstants.login,
      body: {
        'email': email,
        'password': password,
      },
      requiresAuth: false,
    );
    return AuthResponseModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<AuthResponseModel> signUp({
    required String name,
    required String email,
    required String password,
    required String profileType,
  }) async {
    final response = await apiClient.post(
      ApiConstants.register,
      body: {
        'name': name,
        'email': email,
        'password': password,
        'profileType': profileType,
      },
      requiresAuth: false,
    );
    return AuthResponseModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<AuthResponseModel> verifyOtp({required String otp, String? signupToken}) async {
    final response = await apiClient.post(
      ApiConstants.verifyOtp,
      body: {'otp': otp},
      customToken: signupToken,
      requiresAuth: signupToken == null,
    );
    return AuthResponseModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<AuthResponseModel> resendOtp(String email) async {
    final response = await apiClient.post(
      ApiConstants.resendOtp,
      body: {'email': email},
      requiresAuth: false,
    );
    return AuthResponseModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<AuthResponseModel> forgotPassword(String email) async {
    final response = await apiClient.post(
      ApiConstants.forgotPassword,
      body: {'email': email},
      requiresAuth: false,
    );
    return AuthResponseModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<AuthResponseModel> forgotOtpVerify({required String otp, String? resetToken}) async {
    final token = (resetToken != null && resetToken.isNotEmpty)
        ? resetToken
        : await apiClient.localStorage.getTempToken();
    final response = await apiClient.post(
      ApiConstants.forgotOtpVerify,
      body: {'otp': otp},
      customToken: token,
      requiresAuth: false,
    );
    return AuthResponseModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<AuthResponseModel> resetPassword({
    required String newPassword,
    required String confirmPassword,
    String? resetToken,
  }) async {
    final token = (resetToken != null && resetToken.isNotEmpty)
        ? resetToken
        : await apiClient.localStorage.getTempToken();
    final response = await apiClient.post(
      ApiConstants.resetPassword,
      body: {
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
      customToken: token,
      requiresAuth: false,
    );
    return AuthResponseModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<AuthResponseModel> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final response = await apiClient.post(
      ApiConstants.changePassword,
      body: {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
      requiresAuth: true,
    );
    return AuthResponseModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<AuthResponseModel> refreshToken() async {
    final response = await apiClient.post(
      ApiConstants.refreshToken,
      requiresAuth: true,
    );
    return AuthResponseModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<AuthResponseModel> googleLogin(String idToken) async {
    final response = await apiClient.post(
      ApiConstants.googleLogin,
      body: {
        'idToken': idToken,
      },
      requiresAuth: false,
    );
    return AuthResponseModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<AuthResponseModel> appleLogin({
    required String identityToken,
    String? firstName,
    String? lastName,
    String? email,
  }) async {
    final response = await apiClient.post(
      ApiConstants.appleLogin,
      body: {
        'identityToken': identityToken,
        'user': {
          'name': {
            'firstName': firstName ?? '',
            'lastName': lastName ?? '',
          },
          'email': email ?? '',
        },
      },
      requiresAuth: false,
    );
    return AuthResponseModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<void> logout() async {
    try {
      await apiClient.get(
        ApiConstants.logout,
        requiresAuth: true,
      );
    } catch (_) {
      // Local logout should still proceed even if server logout fails
    }
  }
}

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRemoteDataSourceImpl(apiClient: apiClient);
});
