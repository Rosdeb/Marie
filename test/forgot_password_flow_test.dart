import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:marie_nirva/core/constants/api_constants.dart';
import 'package:marie_nirva/core/network/api_client.dart';
import 'package:marie_nirva/core/storage/local_storage.dart';
import 'package:marie_nirva/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:marie_nirva/features/auth/data/repositories/auth_repository_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Forgot Password & Refresh Token Flow Tests', () {
    const dummyResetToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbWFpbCI6InJvc2RlYkB5b3BtYWlsLmNvbSIsImlhdCI6MTc5MzA5MzExMCwiZXhwIjoxNzkzMDk0MDEwfQ.VTwkd9gOTLgsyKfHCvlatQ7aFTNmKWGrwhTPpEtKhJA';
    const dummyNewToken = 'new_reset_token_after_otp_verify';
    const dummyAccessToken = 'dummy_access_token_abc';
    const dummyRefreshToken = 'dummy_refresh_token_xyz';

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('forgotPassword returns token and saves to LocalStorage', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith(ApiConstants.forgotPassword));
        expect(request.method, 'POST');
        final body = jsonDecode(request.body);
        expect(body['email'], 'rosdeb@yopmail.com');

        return http.Response(
          jsonEncode({
            "success": true,
            "statusCode": 201,
            "message": "Otp send successfully. Please check your email to reset password.",
            "data": {
              "token": dummyResetToken,
            }
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final storage = LocalStorage();
      final apiClient = ApiClient(client: mockClient, localStorage: storage);
      final remoteDataSource = AuthRemoteDataSourceImpl(apiClient: apiClient);
      final repository = AuthRepositoryImpl(
        remoteDataSource: remoteDataSource,
        localStorage: storage,
      );

      final token = await repository.forgotPassword(email: 'rosdeb@yopmail.com');

      expect(token, dummyResetToken);
      expect(await storage.getTempToken(), dummyResetToken);
    });

    test('forgotOtpVerify sends otp in body and reset token as Bearer token in header', () async {
      String? capturedAuthHeader;
      Map<String, dynamic>? capturedBody;

      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith(ApiConstants.forgotOtpVerify)) {
          expect(request.method, 'POST');
          capturedAuthHeader = request.headers['Authorization'];
          capturedBody = jsonDecode(request.body);

          return http.Response(
            jsonEncode({
              "success": true,
              "statusCode": 200,
              "message": "OTP verified successfully.",
              "data": {
                "token": dummyNewToken,
              }
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not found', 404);
      });

      final storage = LocalStorage();
      await storage.saveTempToken(dummyResetToken);

      final apiClient = ApiClient(client: mockClient, localStorage: storage);
      final remoteDataSource = AuthRemoteDataSourceImpl(apiClient: apiClient);
      final repository = AuthRepositoryImpl(
        remoteDataSource: remoteDataSource,
        localStorage: storage,
      );

      // Call without explicit resetToken to ensure it automatically pulls from LocalStorage
      final success = await repository.forgotOtpVerify(otp: '123456');

      expect(success, isTrue);
      expect(capturedAuthHeader, 'Bearer $dummyResetToken');
      expect(capturedBody?['otp'], '123456');

      // LocalStorage tempToken should be updated with the new token
      expect(await storage.getTempToken(), dummyNewToken);
    });

    test('resetPassword passes Authorization Bearer token and clears tempToken on success', () async {
      String? capturedAuthHeader;
      Map<String, dynamic>? capturedBody;

      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith(ApiConstants.resetPassword)) {
          expect(request.method, 'POST');
          capturedAuthHeader = request.headers['Authorization'];
          capturedBody = jsonDecode(request.body);

          return http.Response(
            jsonEncode({
              "success": true,
              "statusCode": 200,
              "message": "Password reset successfully.",
              "data": {}
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not found', 404);
      });

      final storage = LocalStorage();
      await storage.saveTempToken(dummyNewToken);

      final apiClient = ApiClient(client: mockClient, localStorage: storage);
      final remoteDataSource = AuthRemoteDataSourceImpl(apiClient: apiClient);
      final repository = AuthRepositoryImpl(
        remoteDataSource: remoteDataSource,
        localStorage: storage,
      );

      final success = await repository.resetPassword(
        newPassword: 'NewPassword123',
        confirmPassword: 'NewPassword123',
      );

      expect(success, isTrue);
      expect(capturedAuthHeader, 'Bearer $dummyNewToken');
      expect(capturedBody?['newPassword'], 'NewPassword123');
      expect(capturedBody?['confirmPassword'], 'NewPassword123');

      // Temp token should be cleared after password reset
      expect(await storage.getTempToken(), isNull);
    });

    test('refreshToken sends Bearer token and updates tokens in LocalStorage', () async {
      String? capturedAuthHeader;

      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith(ApiConstants.refreshToken)) {
          expect(request.method, 'POST');
          capturedAuthHeader = request.headers['Authorization'];

          return http.Response(
            jsonEncode({
              "success": true,
              "statusCode": 200,
              "message": "Token refreshed.",
              "data": {
                "accessToken": "fresh_access_token_999",
                "refreshToken": "fresh_refresh_token_999",
              }
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not found', 404);
      });

      final storage = LocalStorage();
      await storage.saveAccessToken(dummyAccessToken);
      await storage.saveRefreshToken(dummyRefreshToken);

      final apiClient = ApiClient(client: mockClient, localStorage: storage);
      final remoteDataSource = AuthRemoteDataSourceImpl(apiClient: apiClient);
      final repository = AuthRepositoryImpl(
        remoteDataSource: remoteDataSource,
        localStorage: storage,
      );

      await repository.refreshToken();

      expect(capturedAuthHeader, 'Bearer $dummyAccessToken');
      expect(await storage.getAccessToken(), 'fresh_access_token_999');
      expect(await storage.getRefreshToken(), 'fresh_refresh_token_999');
    });
  });
}
