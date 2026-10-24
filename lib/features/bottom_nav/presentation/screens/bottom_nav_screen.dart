import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../practice/presentation/screens/practice_screen.dart';
import '../../../review/presentation/screens/review_screen.dart';
import '../../../account/presentation/screens/account_screen.dart';
import '../providers/bottom_nav_provider.dart';
import '../widgets/custom_bottom_nav_bar.dart';

class BottomNavScreen extends ConsumerWidget {
  const BottomNavScreen({super.key});

  final List<Widget> _pages = const [
    HomeScreen(),
    PracticeScreen(),
    ReviewScreen(),
    AccountScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(bottomNavProvider);
    final safeIndex = currentIndex < _pages.length ? currentIndex : 0;

    return Scaffold(
      body: IndexedStack(
        index: safeIndex,
        children: _pages,
      ),
      bottomNavigationBar: const CustomBottomNav(),
    );
  }
}
