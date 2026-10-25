import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../error/exceptions.dart';
import '../storage/local_storage.dart';

class ApiClient {
  final http.Client _client;
  final LocalStorage localStorage;

  ApiClient({
    http.Client? client,
    required this.localStorage,
  }) : _client = client ?? http.Client();

  Uri _buildUri(String path, [Map<String, dynamic>? queryParams]) {
    final fullUrl = path.startsWith('http') ? path : '${ApiConstants.baseUrl}$path';
    final uri = Uri.parse(fullUrl);
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(
        queryParameters: {
          ...uri.queryParameters,
          ...queryParams.map((k, v) => MapEntry(k, v.toString())),
        },
      );
    }
    return uri;
  }

  Future<Map<String, String>> _headers({
    String? customToken,
    bool requiresAuth = true,
    Map<String, String>? extraHeaders,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (customToken != null && customToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $customToken';
    } else if (requiresAuth) {
      final token = await localStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }
    return headers;
  }

  void _logRequest(String method, Uri uri, {Map<String, String>? headers, dynamic body}) {
    if (kDebugMode) {
      debugPrint('┌─── [HTTP REQUEST] $method $uri ───');
      if (headers != null) debugPrint('│ Headers: $headers');
      if (body != null) debugPrint('│ Body: $body');
      debugPrint('└──────────────────────────────────────────────');
    }
  }

  void _logResponse(String method, Uri uri, http.Response response) {
    if (kDebugMode) {
      final isSuccess = response.statusCode >= 200 && response.statusCode < 300;
      debugPrint('┌─── [HTTP RESPONSE ${response.statusCode}] $method $uri ${isSuccess ? '✅' : '❌'} ───');
      debugPrint('│ Body: ${response.body}');
      debugPrint('└──────────────────────────────────────────────');
    }
  }

  dynamic _processResponse(http.Response response) {
    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      decoded = null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded ?? {'statusCode': response.statusCode};
    }

    String errorMessage = 'Something went wrong';
    if (decoded is Map<String, dynamic>) {
      if (decoded['message'] != null && decoded['message'].toString().isNotEmpty) {
        errorMessage = decoded['message'].toString();
      } else if (decoded['errorMessages'] is List && (decoded['errorMessages'] as List).isNotEmpty) {
        final first = (decoded['errorMessages'] as List).first;
        if (first is Map && first['message'] != null) {
          errorMessage = first['message'].toString();
        }
      } else if (decoded['error'] != null) {
        errorMessage = decoded['error'].toString();
      }
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw AuthException(message: errorMessage, statusCode: response.statusCode);
    } else {
      throw ServerException(message: errorMessage, statusCode: response.statusCode);
    }
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParams,
    String? customToken,
    bool requiresAuth = true,
  }) async {
    final uri = _buildUri(path, queryParams);
    try {
      final headers = await _headers(customToken: customToken, requiresAuth: requiresAuth);
      _logRequest('GET', uri, headers: headers);
      final response = await _client.get(uri, headers: headers);
      _logResponse('GET', uri, response);
      return _processResponse(response);
    } on SocketException {
      throw NetworkException(message: 'No internet connection. Please check your network.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<dynamic> post(
    String path, {
    dynamic body,
    String? customToken,
    bool requiresAuth = true,
  }) async {
    final uri = _buildUri(path);
    try {
      final headers = await _headers(customToken: customToken, requiresAuth: requiresAuth);
      final jsonBody = body != null ? jsonEncode(body) : null;
      _logRequest('POST', uri, headers: headers, body: jsonBody);
      final response = await _client.post(
        uri,
        headers: headers,
        body: jsonBody,
      );
      _logResponse('POST', uri, response);
      return _processResponse(response);
    } on SocketException {
      throw NetworkException(message: 'No internet connection. Please check your network.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<dynamic> patch(
    String path, {
    dynamic body,
    String? customToken,
    bool requiresAuth = true,
  }) async {
    final uri = _buildUri(path);
    try {
      final headers = await _headers(customToken: customToken, requiresAuth: requiresAuth);
      final jsonBody = body != null ? jsonEncode(body) : null;
      _logRequest('PATCH', uri, headers: headers, body: jsonBody);
      final response = await _client.patch(
        uri,
        headers: headers,
        body: jsonBody,
      );
      _logResponse('PATCH', uri, response);
      return _processResponse(response);
    } on SocketException {
      throw NetworkException(message: 'No internet connection. Please check your network.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<dynamic> delete(
    String path, {
    String? customToken,
    bool requiresAuth = true,
  }) async {
    final uri = _buildUri(path);
    try {
      final headers = await _headers(customToken: customToken, requiresAuth: requiresAuth);
      _logRequest('DELETE', uri, headers: headers);
      final response = await _client.delete(uri, headers: headers);
      _logResponse('DELETE', uri, response);
      return _processResponse(response);
    } on SocketException {
      throw NetworkException(message: 'No internet connection. Please check your network.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<dynamic> multipartPatch(
    String path, {
    Map<String, String>? fields,
    String? fileField,
    String? filePath,
    String? customToken,
    bool requiresAuth = true,
  }) async {
    final uri = _buildUri(path);
    try {
      final request = http.MultipartRequest('PATCH', uri);

      if (customToken != null && customToken.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $customToken';
      } else if (requiresAuth) {
        final token = await localStorage.getAccessToken();
        if (token != null && token.isNotEmpty) {
          request.headers['Authorization'] = 'Bearer $token';
        }
      }
      request.headers['Accept'] = 'application/json';

      if (fields != null) {
        request.fields.addAll(fields);
      }

      if (fileField != null && filePath != null && filePath.isNotEmpty) {
        final file = File(filePath);
        if (await file.exists()) {
          request.files.add(await http.MultipartFile.fromPath(fileField, filePath));
        }
      }

      _logRequest('PATCH (Multipart)', uri, headers: request.headers, body: request.fields);
      final streamedResponse = await _client.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      _logResponse('PATCH (Multipart)', uri, response);
      return _processResponse(response);
    } on SocketException {
      throw NetworkException(message: 'No internet connection. Please check your network.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  final localStorage = ref.watch(localStorageProvider);
  return ApiClient(localStorage: localStorage);
});
