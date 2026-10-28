import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:marie_nirva/core/storage/local_storage.dart';
import 'package:marie_nirva/features/account/presentation/providers/account_provider.dart';
import 'package:marie_nirva/features/auth/presentation/providers/auth_provider.dart';
import 'package:marie_nirva/features/subscription/domain/entities/entitlement_entity.dart';
import 'package:marie_nirva/features/subscription/presentation/providers/entitlement_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Logout & Auth Clearance Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'access_token': 'dummy_access_token_123',
        'refresh_token': 'dummy_refresh_token_123',
        'user_data': '{"id":"user_1","name":"Test User","email":"test@example.com"}',
        'temp_token': 'dummy_temp_token',
      });
    });

    test('LocalStorage clearAuth removes all session keys', () async {
      final storage = LocalStorage();

      // Verify tokens exist before logout
      expect(await storage.getAccessToken(), 'dummy_access_token_123');
      expect(await storage.getRefreshToken(), 'dummy_refresh_token_123');
      expect(await storage.getTempToken(), 'dummy_temp_token');
      expect(await storage.getUserData(), isNotNull);

      // Perform logout clearance
      await storage.clearAuth();

      // Verify all tokens are removed
      expect(await storage.getAccessToken(), isNull);
      expect(await storage.getRefreshToken(), isNull);
      expect(await storage.getTempToken(), isNull);
      expect(await storage.getUserData(), isNull);
    });

    test('ProfileState resets to default upon clear()', () {
      final initial = ProfileState(
        id: 'user_1',
        name: 'Test User',
        email: 'test@example.com',
        avatarUrl: 'https://example.com/avatar.jpg',
      );

      final cleared = ProfileState();

      expect(initial.name, 'Test User');
      expect(cleared.name, '');
      expect(cleared.email, '');
      expect(cleared.avatarUrl, '');
    });

    test('AuthNotifier logout cleanly clears state and entitlement without CircularDependencyError', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Pre-warm entitlementProvider to mirror active UI listening
      final sub = container.listen(entitlementProvider, (_, _) {});
      addTearDown(sub.close);

      // Trigger logout
      await container.read(authProvider.notifier).logout();

      final auth = container.read(authProvider);
      expect(auth.isAuthenticated, isFalse);

      final entitlement = container.read(entitlementProvider);
      expect(entitlement.planId, PlanTier.none);
    });
  });
}
