import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';

class ServerAvailabilityController extends ChangeNotifier {
  ServerAvailabilityController._();

  static final ServerAvailabilityController instance =
      ServerAvailabilityController._();

  bool _isUnavailable = false;
  String _message =
      'We could not reach the server. Check your connection and try again.';

  bool get isUnavailable => _isUnavailable;
  String get message => _message;

  void reportUnavailable(String message) {
    final changed = !_isUnavailable || _message != message;
    _isUnavailable = true;
    _message = message;
    if (changed) notifyListeners();
  }

  void clear() {
    if (!_isUnavailable) return;
    _isUnavailable = false;
    notifyListeners();
  }

  Future<bool> retry() async {
    try {
      final response = await http
          .get(Uri.parse(ApiConstants.baseUrl))
          .timeout(const Duration(seconds: 10));
      final reachable = response.statusCode < 500;
      if (reachable) clear();
      return reachable;
    } catch (_) {
      return false;
    }
  }
}
