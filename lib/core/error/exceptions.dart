class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException({required this.message, this.statusCode});

  @override
  String toString() => message;
}

class ServerException extends ApiException {
  ServerException({required super.message, super.statusCode});
}

class AuthException extends ApiException {
  AuthException({required super.message, super.statusCode});
}

class NetworkException extends ApiException {
  NetworkException({required super.message, super.statusCode});
}

class CacheException extends ApiException {
  CacheException({required super.message, super.statusCode});
}
