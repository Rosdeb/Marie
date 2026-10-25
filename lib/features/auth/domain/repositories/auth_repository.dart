import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> signIn({
    required String email,
    required String password,
  });

  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
    required String profileType,
  });

  Future<bool> verifyOtp({
    required String otp,
    String? signupToken,
  });

  Future<bool> resendOtp({
    required String email,
  });

  Future<String?> forgotPassword({
    required String email,
  });

  Future<bool> forgotOtpVerify({
    required String otp,
    String? resetToken,
  });

  Future<bool> resetPassword({
    required String newPassword,
    required String confirmPassword,
    String? resetToken,
  });

  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  });

  Future<void> refreshToken();

  Future<void> signOut();

  Future<UserEntity?> getCurrentUser();

  Future<bool> isAuthenticated();
}
