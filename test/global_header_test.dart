import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marie_nirva/core/widgets/global_header.dart';
import 'package:marie_nirva/features/account/presentation/providers/account_provider.dart';
import 'package:marie_nirva/features/auth/presentation/providers/auth_provider.dart';
import 'package:marie_nirva/features/bottom_nav/presentation/providers/bottom_nav_provider.dart';
import 'package:marie_nirva/features/home/presentation/providers/notification_provider.dart';

class MockAuthNotifier extends AuthNotifier {
  final bool isAuth;
  MockAuthNotifier({this.isAuth = false});

  @override
  AuthState build() => AuthState(isAuthenticated: isAuth);
}

class MockAccountNotifier extends AccountNotifier {
  final String avatar;
  MockAccountNotifier({this.avatar = ''});

  @override
  ProfileState build() => ProfileState(avatarUrl: avatar);
}

void main() {
  testWidgets('GlobalHeader displays person icon when profile avatar is null/empty', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          unreadNotificationCountProvider.overrideWithValue(0),
          authProvider.overrideWith(() => MockAuthNotifier(isAuth: false)),
          accountProvider.overrideWith(() => MockAccountNotifier(avatar: '')),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: GlobalHeader(),
          ),
        ),
      ),
    );

    await tester.pump();

    // Verify Icons.person is rendered
    expect(find.byIcon(Icons.person), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('GlobalHeader displays profile image when avatarUrl is available', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          unreadNotificationCountProvider.overrideWithValue(0),
          authProvider.overrideWith(() => MockAuthNotifier(isAuth: true)),
          accountProvider.overrideWith(() => MockAccountNotifier(avatar: 'https://example.com/avatar.png')),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: GlobalHeader(),
          ),
        ),
      ),
    );

    await tester.pump();

    // Verify Image.network is rendered
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('Tapping profile button switches bottomNavProvider to index 3 (Account tab)', (tester) async {
    final container = ProviderContainer(
      overrides: [
        unreadNotificationCountProvider.overrideWithValue(0),
        authProvider.overrideWith(() => MockAuthNotifier(isAuth: true)),
        accountProvider.overrideWith(() => MockAccountNotifier(avatar: '')),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: GlobalHeader(),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(container.read(bottomNavProvider), 0);

    // Tap profile button
    await tester.tap(find.byIcon(Icons.person));
    await tester.pump();

    // Verify index switched to 3
    expect(container.read(bottomNavProvider), 3);
  });
}
