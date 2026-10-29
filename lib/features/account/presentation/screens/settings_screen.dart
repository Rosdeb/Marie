import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/floating_error_bar.dart';
import '../../../../core/widgets/floating_success_bar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/account_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.logout_rounded, color: Colors.redAccent, size: 24),
              SizedBox(width: 10),
              Text(
                'Log Out',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to log out of your account?',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) {
                  FloatingSuccessBar.show(context, message: 'Logged out successfully');
                  context.go('/onboarding');
                }
              },
              child: const Text(
                'Log Out',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.redAccent,
                size: 28,
              ),
              SizedBox(width: 8),
              Text(
                'Delete Account',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to delete your account? All your study progress, bookmarks, and subscriptions will be permanently erased. This action cannot be undone.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);
                final success = await ref
                    .read(accountProvider.notifier)
                    .deleteAccount();
                if (success && context.mounted) {
                  await ref.read(authProvider.notifier).logout();
                  if (!context.mounted) return;
                  FloatingErrorBar.show(
                    context,
                    message: 'Your account has been deleted.',
                  );
                  context.go('/onboarding');
                } else if (context.mounted) {
                  final err = ref.read(accountProvider).errorMessage ?? 'Failed to delete account';
                  FloatingErrorBar.show(context, message: err);
                }
              },
              child: const Text(
                'Delete Permanently',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(accountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            size: 18,
            color: AppColors.textPrimary,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            _buildSectionHeader('Profile & Track'),
            const SizedBox(height: 8),

            // Profile Type Selector (Attorney / Paralegal)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.badge_outlined, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Profile Type',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  DropdownButton<String>(
                    value: profile.profileType.isNotEmpty ? profile.profileType : 'Attorney',
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'Attorney', child: Text('Attorney')),
                      DropdownMenuItem(value: 'Paralegal', child: Text('Paralegal')),
                    ],
                    onChanged: (val) async {
                      if (val != null) {
                        final ok = await ref.read(accountProvider.notifier).setProfileType(val);
                        if (ok && context.mounted) {
                          FloatingSuccessBar.show(context, message: 'Profile type updated to $val');
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildSectionHeader('Privacy Controls'),
            const SizedBox(height: 8),

            // Show First Name Switch
            _buildSwitchTile(
              icon: Icons.visibility_outlined,
              title: 'Show First Name Publicly',
              value: profile.showFirstName,
              onChanged: (val) async {
                final ok = await ref.read(accountProvider.notifier).updatePrivacySettings(
                      showFirstName: val,
                      showProfession: profile.showProfession,
                      marketingEmails: profile.marketingEmails,
                    );
                if (ok && context.mounted) {
                  FloatingSuccessBar.show(context, message: 'Privacy setting updated');
                }
              },
            ),
            const SizedBox(height: 10),

            // Show Profession Switch
            _buildSwitchTile(
              icon: Icons.work_outline,
              title: 'Show Profession Publicly',
              value: profile.showProfession,
              onChanged: (val) async {
                final ok = await ref.read(accountProvider.notifier).updatePrivacySettings(
                      showFirstName: profile.showFirstName,
                      showProfession: val,
                      marketingEmails: profile.marketingEmails,
                    );
                if (ok && context.mounted) {
                  FloatingSuccessBar.show(context, message: 'Privacy setting updated');
                }
              },
            ),
            const SizedBox(height: 10),

            // Marketing e-mail. Opt-in: off unless the subscriber agreed at
            // sign-up, and withdrawable here at any time.
            _buildSwitchTile(
              icon: Icons.mark_email_read_outlined,
              title: 'Receive news and offers by e-mail',
              value: profile.marketingEmails,
              onChanged: (val) async {
                final ok = await ref.read(accountProvider.notifier).updatePrivacySettings(
                      showFirstName: profile.showFirstName,
                      showProfession: profile.showProfession,
                      marketingEmails: val,
                    );
                if (ok && context.mounted) {
                  FloatingSuccessBar.show(
                    context,
                    message: val
                        ? 'You will receive news and offers by e-mail'
                        : 'You will no longer receive marketing e-mail',
                  );
                }
              },
            ),
            const SizedBox(height: 20),

            _buildSectionHeader('Security'),
            const SizedBox(height: 8),

            // Change Password
            _buildSingleLineCard(
              icon: Icons.lock_outline,
              title: 'Change Password',
              onTap: () => context.push('/change-password'),
            ),
            const SizedBox(height: 20),

            _buildSectionHeader('Legal & Policies'),
            const SizedBox(height: 8),

            // The three legal documents, each on its own screen and in the
            // order they are published.
            _buildSingleLineCard(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              onTap: () => context.push('/privacy-policy'),
            ),
            const SizedBox(height: 10),

            _buildSingleLineCard(
              icon: Icons.description_outlined,
              title: 'Terms of Use',
              onTap: () => context.push('/terms-of-use'),
            ),
            const SizedBox(height: 10),

            _buildSingleLineCard(
              icon: Icons.gavel_outlined,
              title: 'Legal Notice',
              onTap: () => context.push('/legal-notice'),
            ),
            const SizedBox(height: 24),

            _buildSectionHeader('Account Actions'),
            const SizedBox(height: 8),

            // Log Out
            _buildSingleLineCard(
              icon: Icons.logout_rounded,
              title: 'Log Out',
              onTap: () => _showLogoutDialog(context, ref),
            ),
            const SizedBox(height: 28),

            _buildSectionHeader('Danger Zone'),
            const SizedBox(height: 10),

            // Delete Account Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: const Color(0xFFE53935).withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => _showDeleteAccountDialog(context, ref),
                child: const Text(
                  'Delete Account',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Transform.scale(
            scaleX: 0.7,
            scaleY: 0.7,
            child: CupertinoSwitch(
              value: value,
              activeTrackColor: AppColors.primary,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleLineCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
