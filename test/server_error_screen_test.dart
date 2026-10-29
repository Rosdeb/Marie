import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marie_nirva/core/network/server_availability_controller.dart';
import 'package:marie_nirva/core/screens/server_error_screen.dart';

void main() {
  testWidgets('shows the server unavailable state and retry action', (
    tester,
  ) async {
    final controller = ServerAvailabilityController.instance;
    controller.reportUnavailable('Test outage message');
    addTearDown(controller.clear);

    await tester.pumpWidget(const MaterialApp(home: ServerErrorScreen()));

    expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
    expect(find.text('Server unavailable'), findsOneWidget);
    expect(find.text('Test outage message'), findsOneWidget);
    expect(find.text('Try Again'), findsOneWidget);
  });
}
