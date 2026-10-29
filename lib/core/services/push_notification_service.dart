import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../firebase_options.dart';
import '../constants/api_constants.dart';
import '../network/api_client.dart';
import '../router/app_router.dart';
import '../storage/local_storage.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (message.notification == null) {
    await PushNotificationService.showBackgroundMessage(message);
  }
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  static const String channelId = 'high_importance_channel';
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    channelId,
    'Important notifications',
    description: 'Practice reminders, account updates and important alerts.',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final StreamController<RemoteMessage> _messageController =
      StreamController<RemoteMessage>.broadcast();

  bool _initialized = false;
  LocalStorage? _localStorage;

  Stream<RemoteMessage> get messages => _messageController.stream;

  static Future<void> showBackgroundMessage(RemoteMessage message) async {
    final title = message.data['title']?.toString();
    final body = message.data['body']?.toString();
    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      return;
    }

    final notifications = FlutterLocalNotificationsPlugin();
    await notifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
      ),
    );
    await notifications.show(
      id: (message.messageId?.hashCode ?? message.hashCode) & 0x7fffffff,
      title: title ?? 'IPRO',
      body: body ?? '',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          'Important notifications',
          channelDescription:
              'Practice reminders, account updates and important alerts.',
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_notification',
          color: Color(0xFF384E78),
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  Future<void> initialize({required LocalStorage localStorage}) async {
    if (_initialized ||
        kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    _initialized = true;
    _localStorage = localStorage;

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('ic_notification'),
    );
    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _handleLocalNotificationTap,
    );

    final androidNotifications = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidNotifications?.createNotificationChannel(_channel);

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleRemoteMessageTap);
    _messaging.onTokenRefresh.listen(_saveToken);

    final enabled = await localStorage.getNotificationsEnabled();
    if (enabled) {
      await setEnabled(true);
    } else {
      await _messaging.setAutoInitEnabled(false);
    }

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _scheduleRemoteMessageTap(initialMessage);
    }

    final launchDetails = await _localNotifications
        .getNotificationAppLaunchDetails();
    final initialPayload = launchDetails?.notificationResponse?.payload;
    if ((launchDetails?.didNotificationLaunchApp ?? false) &&
        initialPayload != null) {
      _schedulePayloadTap(initialPayload);
    }
  }

  Future<bool> setEnabled(bool enabled) async {
    final storage = _localStorage;
    if (storage == null) return false;

    if (!enabled) {
      await _messaging.setAutoInitEnabled(false);
      await _messaging.deleteToken();
      await _localNotifications.cancelAll();
      await storage.clearFcmToken();
      await storage.saveNotificationsEnabled(false);
      return false;
    }

    final cachedToken = await storage.getFcmToken();
    final hasCachedToken = cachedToken != null && cachedToken.trim().isNotEmpty;
    if (hasCachedToken && kDebugMode) {
      debugPrint('[FCM] Cached token: ${cachedToken.trim()}');
    }

    var settings = await _messaging.getNotificationSettings();
    if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
      settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }
    final granted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
    if (!granted) {
      await storage.saveNotificationsEnabled(false);
      return false;
    }

    await _messaging.setAutoInitEnabled(true);
    if (!hasCachedToken) {
      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await _saveToken(token);
      }
    }
    await storage.saveNotificationsEnabled(true);
    return true;
  }

  String get _platform {
    if (kIsWeb) return 'web';
    if (Platform.isIOS || Platform.isMacOS) return 'ios';
    return 'android';
  }

  /// Keeps the token on the device and tells the server about it.
  ///
  /// Storing it locally is not enough: the server decides who to push to, and
  /// it can only do that if it knows which devices belong to this account.
  /// Without this call the token stayed on the phone and every push had
  /// nowhere to go.
  ///
  /// The token is re-sent whenever Firebase rotates it and after each
  /// sign-in, because a token belongs to a device and the account using it
  /// can change.
  Future<void> _saveToken(String token, {bool force = false}) async {
    final storage = _localStorage;
    final normalizedToken = token.trim();
    if (storage == null || normalizedToken.isEmpty) return;

    final cachedToken = await storage.getFcmToken();
    final isNew = cachedToken != normalizedToken;

    if (kDebugMode) {
      final source = isNew ? 'New or refreshed' : 'Cached';
      debugPrint('[FCM] $source token: $normalizedToken');
    }

    if (isNew) await storage.saveFcmToken(normalizedToken);
    if (!isNew && !force) return;

    await _registerTokenWithServer(normalizedToken);
  }

  Future<void> _registerTokenWithServer(String token) async {
    final storage = _localStorage;
    if (storage == null) return;

    // Nobody is signed in yet; registerCurrentDevice() runs again after login.
    final accessToken = await storage.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) return;

    try {
      await ApiClient(localStorage: storage).post(
        ApiConstants.deviceToken,
        body: {'token': token, 'platform': _platform},
        requiresAuth: true,
      );
    } catch (e) {
      // Never surfaced: failing to register a device must not interrupt
      // anything the person is doing. The next refresh or sign-in retries.
      debugPrint('[Push] could not register device token: $e');
    }
  }

  /// Called after sign-in, so the device is attached to the account that has
  /// just taken it over.
  Future<void> registerCurrentDevice() async {
    final cachedToken = await _localStorage?.getFcmToken();
    final token = cachedToken != null && cachedToken.trim().isNotEmpty
        ? cachedToken.trim()
        : await _messaging.getToken();
    if (token != null && token.isNotEmpty) {
      await _saveToken(token, force: true);
    }
  }

  /// Called on sign-out, so the next person to use this phone does not
  /// receive the previous account's notifications.
  Future<void> unregisterCurrentDevice() async {
    final storage = _localStorage;
    if (storage == null) return;

    final token = await storage.getFcmToken();
    if (token == null || token.isEmpty) return;

    try {
      // delete() carries no body, so the token travels as a query parameter.
      await ApiClient(localStorage: storage).delete(
        '${ApiConstants.deviceToken}?token=${Uri.encodeComponent(token)}',
        requiresAuth: true,
      );
    } catch (e) {
      debugPrint('[Push] could not remove device token: $e');
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    _messageController.add(message);

    final title =
        message.notification?.title ?? message.data['title']?.toString();
    final body = message.notification?.body ?? message.data['body']?.toString();
    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      return;
    }

    await _localNotifications.show(
      id: (message.messageId?.hashCode ?? message.hashCode) & 0x7fffffff,
      title: title ?? 'IPRO',
      body: body ?? '',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          'Important notifications',
          channelDescription:
              'Practice reminders, account updates and important alerts.',
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_notification',
          color: Color(0xFF384E78),
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _handleRemoteMessageTap(RemoteMessage message) {
    _messageController.add(message);
    _openData(message.data);
  }

  void _handleLocalNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) {
      _openData(const {});
      return;
    }
    _openPayload(payload);
  }

  void _scheduleRemoteMessageTap(RemoteMessage message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleRemoteMessageTap(message);
    });
  }

  void _schedulePayloadTap(String payload) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openPayload(payload);
    });
  }

  void _openPayload(String payload) {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map) {
        _openData(decoded.map((key, value) => MapEntry('$key', value)));
        return;
      }
    } catch (_) {}
    _openData(const {});
  }

  void _openData(Map<String, dynamic> data) {
    final requestedRoute = data['route']?.toString();
    final route = requestedRoute != null && requestedRoute.startsWith('/')
        ? requestedRoute
        : '/notifications';
    AppRouter.router.go(route);
  }
}
