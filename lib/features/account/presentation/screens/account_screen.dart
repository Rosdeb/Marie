import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/custom_shimmer.dart';
import '../../../../core/widgets/floating_success_bar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../subscription/presentation/providers/entitlement_provider.dart';
import '../providers/account_provider.dart';
import '../../../../core/services/legal_links_service.dart';
import '../../../../core/widgets/floating_error_bar.dart';
import '../providers/preferences_provider.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  await ref.read(authProvider.notifier).logout();
                } catch (e) {
                  debugPrint('Logout error: $e');
                }
                if (context.mounted) {
                  FloatingSuccessBar.show(
                    context,
                    message: 'Logged out successfully',
                  );
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(accountProvider);
    final isAuth = ref.watch(authProvider).isAuthenticated;
    final entitlement = ref.watch(entitlementProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 22,
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            if (isAuth) {
              await ref.read(accountProvider.notifier).fetchProfile();
            }
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              const SizedBox(height: 12),

              // Profile Card (Modern Borderless Shadow)
              if (!isAuth)
                _buildGuestProfileCard(context)
              else if (profile.isLoading)
                const ProfileCardShimmer()
              else
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => context.push('/edit-profile'),
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            AppAvatar(
                              radius: 30,
                              imageUrl: profile.avatarUrl,
                              name: profile.name,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    profile.name.isNotEmpty
                                        ? profile.name
                                        : 'IP Law Scholar',
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    profile.email,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  if (profile.profession.isNotEmpty ||
                                      profile.profileType.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            profile.profession.isNotEmpty
                                                ? profile.profession
                                                : profile.profileType,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
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
                ),

              const SizedBox(height: 30),
              // Notifications Toggle Tile (Single-line)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                      spreadRadius: 0,
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
                      child: const Icon(
                        Icons.notifications,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'Push Notifications',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Transform.scale(
                      scaleX: 0.7,
                      scaleY: 0.7,
                      child: CupertinoSwitch(
                        value: profile.notificationsEnabled,
                        activeTrackColor: AppColors.primary,
                        onChanged: (val) async {
                          final enabled = await ref
                              .read(accountProvider.notifier)
                              .toggleNotifications(val);
                          if (!context.mounted) return;
                          FloatingSuccessBar.show(
                            context,
                            message: enabled
                                ? 'Notifications turned ON'
                                : val
                                ? 'Notification permission was not granted'
                                : 'Notifications turned OFF',
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // There is no "Referral Setting - Earn $5" row.
              //
              // Marie, 11 November 2026, Part 2, Account, point 3:
              // "'Referral Setting - Earn $5' is not in my mock-up: please
              //  remove it."
              //
              // The referral itself stays and is reached from "Share & Save",
              // which is what her mock-up shows. The $5 was never a real
              // offer either - the only reward agreed is 10% off the first paid
              // period - so the row was a statement the app could not keep,
              // which her point 6.2 rules out on its own.

              // ---------------- Preferences ----------------
              _buildSectionHeading('Preferences'),

              // The daily reminder, switched here rather than only inside
              // Settings: it is the one preference people change often, and
              // the mock-up puts it on this screen.
              _buildReminderTile(ref),
              const SizedBox(height: 10),

              _buildSingleLineTile(
                icon: Icons.settings_outlined,
                title: 'Settings',
                onTap: () => context.push('/settings'),
              ),

              // ---------------- Plan ----------------
              _buildSectionHeading('Plan'),

              _buildSingleLineTile(
                icon: Icons.add_card_outlined,
                title: 'My subscriptions',
                badge: entitlement.isActive
                    ? '${entitlement.planId.displayName} Active'
                    : null,
                onTap: () => context.push('/subscription'),
              ),
              const SizedBox(height: 10),

              _buildSingleLineTile(
                icon: Icons.workspace_premium_outlined,
                title: 'My badges',
                onTap: () => context.push('/account/badges'),
              ),
              const SizedBox(height: 10),

              // "Share & Save", which is where the referral now lives; the
              // "Referral Setting - Earn $5" row it replaces is gone.
              _buildSingleLineTile(
                icon: Icons.ios_share_rounded,
                title: 'Share & Save',
                onTap: () => context.push('/referral'),
              ),

              // ---------------- Help ----------------
              _buildSectionHeading('Help'),

              _buildSingleLineTile(
                icon: Icons.help_outline,
                title: 'Help & Support',
                onTap: () => context.push('/support'),
              ),
              const SizedBox(height: 10),

              // The three legal documents, which Apple also expects to be
              // reachable without hunting. They open the pages Marie publishes,
              // so the app never carries a stale copy of a legal text.
              ..._buildLegalTiles(context, ref),

              const SizedBox(height: 32),

              // Log Out Button (Authenticated) or Sign In Button (Guest)
              if (isAuth)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(
                        color: Color(0xFFFFCDD2),
                        width: 1.4,
                      ),
                      //backgroundColor: const Color(0xFFFFF5F5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => _showLogoutDialog(context, ref),
                    icon: const Icon(
                      Icons.logout_rounded,
                      size: 20,
                      color: Colors.redAccent,
                    ),
                    label: const Text(
                      'Log Out',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => context.push('/sign-in'),
                    icon: const Icon(
                      Icons.login_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Sign In to Account',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuestProfileCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                size: 30,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Guest User',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Sign in to save your progress & settings',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => context.push('/sign-in'),
              child: const Text(
                'Sign In',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The small upper-case heading above each of the three sections.
  Widget _buildSectionHeading(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  /// The daily reminder, as a switch.
  ///
  /// It moves at once and goes back on its own if the save failed - a switch
  /// that waits for the network feels broken, and one that stays moved after a
  /// failed save is a lie.
  Widget _buildReminderTile(WidgetRef ref) {
    final prefs = ref.watch(preferencesProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.notifications_none_rounded,
            size: 21,
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Daily reminder',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Switch.adaptive(
            value: prefs.dailyReminder,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.success,
            onChanged: (on) => ref
                .read(preferencesProvider.notifier)
                .save(dailyReminder: on),
          ),
        ],
      ),
    );
  }

  /// Privacy Policy, Terms of Use and Legal Notice.
  ///
  /// While the links are loading the rows are shown but not tappable, so the
  /// list does not jump about; a document whose link is missing says so rather
  /// than opening nothing.
  List<Widget> _buildLegalTiles(BuildContext context, WidgetRef ref) {
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
    for (final doc in documents) {
      final url = links.maybeWhen(
        data: (l) => doc.url(l),
        orElse: () => '',
      );
      rows.add(const SizedBox(height: 10));
      rows.add(
        _buildSingleLineTile(
          icon: doc.icon,
          title: doc.title,
          onTap: url.isEmpty
              ? () {}
              : () async {
                  final opened = await openLegalDocument(url);
                  if (!opened && context.mounted) {
                    FloatingErrorBar.show(
                      context,
                      message: 'Could not open ${doc.title}. '
                          'Please check your connection and try again.',
                    );
                  }
                },
        ),
      );
    }
    return rows;
  }

  Widget _buildSingleLineTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? badge,
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
            spreadRadius: 0,
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
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              color: AppColors.success,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
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
