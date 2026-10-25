import 'user_model.dart';

class AuthResponseModel {
  final bool success;
  final int statusCode;
  final String message;
  final UserModel? user;
  final String? accessToken;
  final String? refreshToken;
  final String? tempToken;

  AuthResponseModel({
    required this.success,
    required this.statusCode,
    required this.message,
    this.user,
    this.accessToken,
    this.refreshToken,
    this.tempToken,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    final success = json['success'] == true;
    final statusCode = json['statusCode'] is int ? json['statusCode'] as int : 200;
    final message = (json['message'] ?? '').toString();

    UserModel? user;
    String? accessToken;
    String? refreshToken;
    String? tempToken;

    final data = json['data'];
    if (data is Map<String, dynamic>) {
      if (data['results'] is Map<String, dynamic>) {
        user = UserModel.fromJson(data['results'] as Map<String, dynamic>);
      } else if (data['user'] is Map<String, dynamic>) {
        user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      }
      accessToken = (data['accessToken'] ?? data['token'])?.toString();
      refreshToken = data['refreshToken']?.toString();
      tempToken = (data['token'] ?? data['resetToken'] ?? data['signupToken'])?.toString();
    }

    return AuthResponseModel(
      success: success,
      statusCode: statusCode,
      message: message,
      user: user,
      accessToken: accessToken,
      refreshToken: refreshToken,
      tempToken: tempToken,
    );
  }
}
