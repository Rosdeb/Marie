import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../account/presentation/providers/account_provider.dart';

/// Paralegal or Attorney, asked once, straight after the account is created.
///
/// Marie, 3 November 2026, point 1.3: "Just after the account is created, the
/// user chooses Paralegal or Attorney. A Paralegal only receives the
/// questions marked Paralegal; an Attorney receives all of them."
///
/// The e-mail sign-up form already asks it. Google and Apple sign-up did not:
/// they went straight to Home, and the account was left on the server's
/// default. This screen is that missing step, and it is shown only when the
/// account has no profile yet - never again afterwards.
class ChooseProfileScreen extends ConsumerStatefulWidget {
  const ChooseProfileScreen({super.key});

  @override
  ConsumerState<ChooseProfileScreen> createState() =>
      _ChooseProfileScreenState();
}

class _ChooseProfileScreenState extends ConsumerState<ChooseProfileScreen> {
  String _selected = 'Attorney';
  bool _saving = false;

  Future<void> _continue() async {
    setState(() => _saving = true);
    final saved =
        await ref.read(accountProvider.notifier).setProfileType(_selected);
    if (!mounted) return;
    setState(() => _saving = false);

    if (saved) {
      context.go('/main');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(accountProvider).errorMessage ??
                'Your profile could not be saved. Please try again.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // No back arrow and no skip: the profile decides which questions the
    // reader is served, so there is no sensible "later".
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                const Text(
                  'Which describes you?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This decides which questions you are given. You can change '
                  'it at any time in Settings.',
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 28),
                _ProfileOption(
                  title: 'Attorney',
                  subtitle:
                      'Patent or trade mark attorney, lawyer or trainee. You '
                      'receive every question, including those marked '
                      'Paralegal.',
                  icon: Icons.gavel_rounded,
                  selected: _selected == 'Attorney',
                  onTap: () => setState(() => _selected = 'Attorney'),
                ),
                const SizedBox(height: 14),
                _ProfileOption(
                  title: 'Paralegal',
                  subtitle:
                      'Patent and trade mark formalities. You receive the '
                      'questions marked Paralegal.',
                  icon: Icons.assignment_outlined,
                  selected: _selected == 'Paralegal',
                  onTap: () => setState(() => _selected = 'Paralegal'),
                ),
                const Spacer(),
                CustomButton(
                  text: 'Continue',
                  isLoading: _saving,
                  onPressed: _saving ? null : _continue,
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileOption extends StatelessWidget {
  const _ProfileOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary.withValues(alpha: 0.07) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.primary : const Color(0xFFE2E8F0),
              width: selected ? 1.4 : 0.8,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 21),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (selected)
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 19,
                            color: AppColors.primary,
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
