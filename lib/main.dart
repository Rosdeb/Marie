import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/network/api_client.dart';
import 'core/router/app_router.dart';
import 'core/services/push_notification_service.dart';
import 'core/storage/local_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    try {
      final messaging = FirebaseMessaging.instance;
      // Request notification permissions (required on iOS before retrieving APNs/FCM token)
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      final fcmToken = await messaging.getToken();
      debugPrint('\n=================== 🔥 FCM TOKEN ===================');
      debugPrint(fcmToken ?? 'Failed to retrieve FCM token (null)');
      debugPrint('====================================================\n');

      messaging.onTokenRefresh.listen((newToken) {
        debugPrint('\n================ 🔥 FCM TOKEN REFRESHED ================');
        debugPrint(newToken);
        debugPrint('========================================================\n');
      });
    } catch (e) {
      debugPrint('⚠️ [FCM Token Error]: $e');
    }
  }

  SystemChrome.setSystemUIOverlayStyle(AppTheme.lightSystemOverlayStyle);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    ApiClient.onUnauthorized = () {
      ref.read(authProvider.notifier).logout();
      AppRouter.router.go('/onboarding');
    };
    if (!kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        PushNotificationService.instance.initialize(
          localStorage: ref.read(localStorageProvider),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'IPro',
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
    );
  }
}
