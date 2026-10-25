import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class LocalStorage {
  SharedPreferences? _prefs;

  Future<SharedPreferences> get _instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<void> saveAccessToken(String token) async {
    final prefs = await _instance;
    await prefs.setString(AppConstants.accessTokenKey, token);
  }

  Future<String?> getAccessToken() async {
    final prefs = await _instance;
    return prefs.getString(AppConstants.accessTokenKey);
  }

  Future<void> saveRefreshToken(String token) async {
    final prefs = await _instance;
    await prefs.setString(AppConstants.refreshTokenKey, token);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await _instance;
    return prefs.getString(AppConstants.refreshTokenKey);
  }

  Future<void> saveTempToken(String token) async {
    final prefs = await _instance;
    await prefs.setString(AppConstants.tempTokenKey, token);
  }

  Future<String?> getTempToken() async {
    final prefs = await _instance;
    return prefs.getString(AppConstants.tempTokenKey);
  }

  Future<void> clearTempToken() async {
    final prefs = await _instance;
    await prefs.remove(AppConstants.tempTokenKey);
  }

  Future<void> saveUserData(Map<String, dynamic> userMap) async {
    final prefs = await _instance;
    await prefs.setString(AppConstants.userDataKey, jsonEncode(userMap));
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await _instance;
    final str = prefs.getString(AppConstants.userDataKey);
    if (str == null || str.isEmpty) return null;
    try {
      return jsonDecode(str) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearAuth() async {
    final prefs = await _instance;
    await prefs.remove(AppConstants.accessTokenKey);
    await prefs.remove(AppConstants.refreshTokenKey);
    await prefs.remove(AppConstants.userDataKey);
    await prefs.remove(AppConstants.tempTokenKey);
  }
}

final localStorageProvider = Provider<LocalStorage>((ref) {
  return LocalStorage();
});
