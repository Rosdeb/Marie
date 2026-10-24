import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marie_nirva/features/auth/presentation/screens/confirm_subscription_screen.dart';
import 'package:marie_nirva/features/auth/presentation/screens/subscription_success_screen.dart';

void main() {
  testWidgets('ConfirmSubscriptionScreen displays review order and plan details', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ConfirmSubscriptionScreen(),
        ),
      ),
    );

    expect(find.text('Confirm Subscription'), findsOneWidget);
    expect(find.text('Review Your Order'), findsOneWidget);
    expect(find.text('Annual Premium'), findsOneWidget);
    expect(find.text('Payment Method'), findsOneWidget);
    expect(find.text('Apple Pay'), findsOneWidget);
  });

  testWidgets('SubscriptionSuccessScreen displays confirmation receipt', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SubscriptionSuccessScreen(),
        ),
      ),
    );

    expect(find.text('Subscription Confirmed!'), findsOneWidget);
    expect(find.text('Payment Receipt'), findsOneWidget);
    expect(find.text('Start Practicing Now'), findsOneWidget);
  });
}
