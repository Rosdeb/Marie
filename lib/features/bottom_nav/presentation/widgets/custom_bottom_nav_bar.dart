import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/bottom_nav_provider.dart';
import 'nav_item.dart';

class CustomBottomNav extends ConsumerWidget {
  const CustomBottomNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(bottomNavProvider);
    final notifier = ref.read(bottomNavProvider.notifier);

    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          NavItem(
            icon: currentIndex == 0
                ? CupertinoIcons.home
                : CupertinoIcons.house,
            label: 'Home',
            index: 0,
            isSelected: currentIndex == 0,
            onTap: () => notifier.changeIndex(0),
          ),
          NavItem(
            icon: currentIndex == 1
                ? CupertinoIcons.book_fill
                : CupertinoIcons.book,
            label: 'Practice',
            index: 1,
            isSelected: currentIndex == 1,
            onTap: () => notifier.changeIndex(1),
          ),
          NavItem(
            icon: currentIndex == 2
                ? CupertinoIcons.checkmark_rectangle_fill
                : CupertinoIcons.checkmark_rectangle,
            label: 'Review',
            index: 2,
            isSelected: currentIndex == 2,
            onTap: () => notifier.changeIndex(2),
          ),
          NavItem(
            icon: currentIndex == 3
                ? CupertinoIcons.person_fill
                : CupertinoIcons.person,
            label: 'Account',
            index: 3,
            isSelected: currentIndex == 3,
            onTap: () => notifier.changeIndex(3),
          ),
        ],
      ),
    );
  }
}
