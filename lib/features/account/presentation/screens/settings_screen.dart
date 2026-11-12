import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/legal_links_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/floating_error_bar.dart';
import '../../../../core/widgets/floating_success_bar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/account_provider.dart';
import '../providers/preferences_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  /// Said under a row that leaves the app for a published page, so the
  /// browser opening is never a surprise.
  static const String _opensExternallyNote = 'Opens the published page';

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
            // Marie's wording, 3 November 2026, point 1.5. The old text claimed
            // subscriptions were erased too; deleting the IPro account does not
            // cancel an App Store or Google Play subscription, and saying so
            // would have left people being charged for something they thought
            // they had ended.
            'Are you sure you want to delete your account? Your study progress will be permanently erased. Deleting your account does not cancel your subscription: cancel it in your App Store or Google Play settings.',
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
    final prefs = ref.watch(preferencesProvider);

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
            const SizedBox(height: 10),

            // Daily Study Goal
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
                    child: const Icon(Icons.timer_outlined, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily Study Goal',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Target practice time per day',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  DropdownButton<int?>(
                    value: prefs.dailyGoalMinutes,
                    underline: const SizedBox(),
                    hint: const Text('Not set', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Off')),
                      DropdownMenuItem(value: 5, child: Text('5 min')),
                      DropdownMenuItem(value: 10, child: Text('10 min')),
                      DropdownMenuItem(value: 15, child: Text('15 min')),
                      DropdownMenuItem(value: 20, child: Text('20 min')),
                      DropdownMenuItem(value: 30, child: Text('30 min')),
                      DropdownMenuItem(value: 45, child: Text('45 min')),
                      DropdownMenuItem(value: 60, child: Text('60 min')),
                    ],
                    onChanged: (val) async {
                      final ok = await ref
                          .read(preferencesProvider.notifier)
                          .save(dailyGoalMinutes: val);
                      if (ok && context.mounted) {
                        FloatingSuccessBar.show(
                          context,
                          message: val != null
                              ? 'Daily goal set to $val minutes'
                              : 'Daily goal turned off',
                        );
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

            // The three published documents, opened on the site that
            // publishes them.
            //
            // Marie, 31 October 2026: the app is to open her Google Site
            // pages through the three links in App Settings, and to keep no
            // copy of its own - "only one version to update, and no risk of
            // the app showing an outdated text". A copy in the app was
            // exactly that risk: she could correct her Privacy Policy and the
            // app would quietly go on showing the old one.
            ..._buildLegalCards(context, ref),
            const SizedBox(height: 24),

            _buildSectionHeader('Account Actions'),
            const SizedBox(height: 8),

            // Log Out
            _buildSingleLineCard(
              icon: Icons.logout_rounded,
              title: 'Log Out',
              onTap: () => _showLogoutDialog(context, ref),
            ),
            const SizedBox(height: 24),

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

  /// The three legal rows, built from the links Marie maintains.
  ///
  /// While the links are loading the rows are shown but not tappable, so the
  /// list does not jump about. If a link is missing the row says so rather
  /// than opening nothing: a legal document the app cannot reach is worth
  /// stating plainly.
  List<Widget> _buildLegalCards(BuildContext context, WidgetRef ref) {
    final links = ref.watch(legalLinksProvider);

    final documents = <({IconData icon, String title, String Function(LegalLinks) url})>[
      (
        icon: Icons.privacy_tip_outlined,
        title: 'Privacy Policy',
        url: (l) => l.privacyPolicyUrl,
      ),
      (
        icon: Icons.description_outlined,
        title: 'Terms of Use',
        url: (l) => l.termsOfUseUrl,
      ),
      (
        icon: Icons.gavel_outlined,
        title: 'Legal Notice',
        url: (l) => l.legalNoticeUrl,
      ),
    ];

    final rows = <Widget>[];

    for (var i = 0; i < documents.length; i++) {
      final doc = documents[i];
      final url = links.maybeWhen(
        data: (value) => doc.url(value),
        orElse: () => '',
      );
      final loading = links.isLoading;

      rows.add(
        _buildSingleLineCard(
          icon: doc.icon,
          title: doc.title,
          note: loading
              ? 'Loading...'
              : url.isEmpty
                  ? 'Not published yet'
                  : _opensExternallyNote,
          onTap: url.isEmpty
              ? null
              : () async {
                  final opened = await openLegalDocument(url);
                  if (!opened && context.mounted) {
                    FloatingErrorBar.show(
                      context,
                      message:
                          'Could not open ${doc.title}. Please check your connection and try again.',
                    );
                  }
                },
        ),
      );

      if (i < documents.length - 1) rows.add(const SizedBox(height: 10));
    }

    return rows;
  }

  /// One row in the list.
  ///
  /// [onTap] is nullable so a row can be present but not yet usable - a legal
  /// document whose address has not been filled in, for instance. The row then
  /// greys out and explains itself in [note] instead of looking broken when
  /// tapped.
  Widget _buildSingleLineCard({
    required IconData icon,
    required String title,
    required VoidCallback? onTap,
    String? note,
  }) {
    final enabled = onTap != null;

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
                  child: Icon(
                    icon,
                    color: enabled
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: enabled
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                      if (note != null && note.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          note,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  // An outward arrow where the row leaves the app, so nobody
                  // is surprised by a browser opening.
                  enabled && note == _opensExternallyNote
                      ? Icons.open_in_new_rounded
                      : Icons.arrow_forward_ios,
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
