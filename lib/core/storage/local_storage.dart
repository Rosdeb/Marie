import 'dart:convert';
import 'dart:typed_data';
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

  Future<void> saveFcmToken(String token) async {
    final prefs = await _instance;
    await prefs.setString(AppConstants.fcmTokenKey, token);
  }

  Future<String?> getFcmToken() async {
    final prefs = await _instance;
    return prefs.getString(AppConstants.fcmTokenKey);
  }

  Future<void> clearFcmToken() async {
    final prefs = await _instance;
    await prefs.remove(AppConstants.fcmTokenKey);
  }

  Future<void> saveNotificationsEnabled(bool enabled) async {
    final prefs = await _instance;
    await prefs.setBool(AppConstants.notificationsEnabledKey, enabled);
  }

  Future<bool> getNotificationsEnabled() async {
    final prefs = await _instance;
    return prefs.getBool(AppConstants.notificationsEnabledKey) ?? true;
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

  static const String _avatarCacheUrlKey = 'avatar_cache_url';
  static const String _avatarCacheBytesKey = 'avatar_cache_bytes';

  Future<void> saveCachedAvatar({
    required String url,
    required Uint8List bytes,
  }) async {
    final prefs = await _instance;
    await prefs.setString(_avatarCacheUrlKey, url);
    await prefs.setString(_avatarCacheBytesKey, base64Encode(bytes));
  }

  Future<Map<String, dynamic>?> getCachedAvatar() async {
    final prefs = await _instance;
    final url = prefs.getString(_avatarCacheUrlKey);
    final b64 = prefs.getString(_avatarCacheBytesKey);
    if (url == null || url.isEmpty || b64 == null || b64.isEmpty) {
      return null;
    }
    try {
      final bytes = base64Decode(b64);
      return {'url': url, 'bytes': bytes};
    } catch (_) {
      return null;
    }
  }

  Future<void> clearCachedAvatar() async {
    final prefs = await _instance;
    await prefs.remove(_avatarCacheUrlKey);
    await prefs.remove(_avatarCacheBytesKey);
  }

  static const String _homeDataKey = 'cached_home_data';

  Future<void> saveHomeData(Map<String, dynamic> data) async {
    final prefs = await _instance;
    await prefs.setString(_homeDataKey, jsonEncode(data));
  }

  Future<Map<String, dynamic>?> getHomeData() async {
    final prefs = await _instance;
    final str = prefs.getString(_homeDataKey);
    if (str == null || str.isEmpty) return null;
    try {
      final decoded = jsonDecode(str);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      } else if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearHomeData() async {
    final prefs = await _instance;
    await prefs.remove(_homeDataKey);
  }

  static const String _sessionRemainingPrefix = 'quiz_remaining_sec_';

  Future<void> saveSessionRemainingTime(String sessionId, int remainingSeconds) async {
    final prefs = await _instance;
    await prefs.setInt('$_sessionRemainingPrefix$sessionId', remainingSeconds);
  }

  Future<int?> getSessionRemainingTime(String sessionId) async {
    final prefs = await _instance;
    return prefs.getInt('$_sessionRemainingPrefix$sessionId');
  }

  Future<void> clearSessionRemainingTime(String sessionId) async {
    final prefs = await _instance;
    await prefs.remove('$_sessionRemainingPrefix$sessionId');
  }

  /// Sessions the phone knows are finished, so Home can drop a "Paused quiz"
  /// card the server still offers for one of them.
  static const String _finishedSessionsKey = 'finished_session_ids';
  static const int _finishedSessionsLimit = 50;

  Future<void> addFinishedSessionId(String sessionId) async {
    final prefs = await _instance;
    final ids = prefs.getStringList(_finishedSessionsKey) ?? <String>[];
    if (ids.contains(sessionId)) return;
    ids.add(sessionId);
    if (ids.length > _finishedSessionsLimit) {
      ids.removeRange(0, ids.length - _finishedSessionsLimit);
    }
    await prefs.setStringList(_finishedSessionsKey, ids);
  }

  Future<Set<String>> getFinishedSessionIds() async {
    final prefs = await _instance;
    return (prefs.getStringList(_finishedSessionsKey) ?? <String>[]).toSet();
  }

  Future<void> clearAuth() async {
    final prefs = await _instance;
    await prefs.remove(_finishedSessionsKey);
    await prefs.remove(AppConstants.accessTokenKey);
    await prefs.remove(AppConstants.refreshTokenKey);
    await prefs.remove(AppConstants.userDataKey);
    await prefs.remove(AppConstants.tempTokenKey);
    await clearCachedAvatar();
    await clearHomeData();
  }
}

final localStorageProvider = Provider<LocalStorage>((ref) {
  return LocalStorage();
});
