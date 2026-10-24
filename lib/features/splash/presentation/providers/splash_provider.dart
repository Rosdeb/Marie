import 'package:flutter_riverpod/flutter_riverpod.dart';

final splashProvider = FutureProvider<bool>((ref) async {
  // Simulate initial app initialization / token verification
  await Future.delayed(const Duration(seconds: 2));
  return true;
});
