import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../../features/account/presentation/providers/account_provider.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/bottom_nav/presentation/providers/bottom_nav_provider.dart';
import '../../features/home/presentation/providers/notification_provider.dart';
import 'auth_gate_bottom_sheet.dart';

class GlobalHeader extends ConsumerWidget {
  final String title;
  final Widget? titleWidget;
  final bool showNotification;
  final bool showProfile;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;
  final List<Widget>? customActions;
  final EdgeInsetsGeometry padding;

  const GlobalHeader({
    super.key,
    this.title = 'IPro',
    this.titleWidget,
    this.showNotification = true,
    this.showProfile = true,
    this.onNotificationTap,
    this.onProfileTap,
    this.customActions,
    this.padding = const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 12.0),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadNotifications = showNotification
        ? ref.watch(unreadNotificationCountProvider)
        : 0;

    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          titleWidget ??
              Text(
                title,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
          Row(
            children: [
              ...?customActions,
              if (showNotification) ...[
                Stack(
                  children: [
                    _buildHeaderIconButton(
                      icon: Icons.notifications,
                      onTap:
                          onNotificationTap ??
                          () {
                            final isAuth = ref
                                .read(authProvider)
                                .isAuthenticated;
                            if (!isAuth) {
                              AuthGateBottomSheet.show(
                                context,
                                targetFeature: 'Notifications',
                              );
                              return;
                            }
                            context.push('/notifications');
                          },
                    ),
                    if (unreadNotifications > 0)
                      Positioned(
                        top: 2,
                        right: 2,
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                if (showProfile) const SizedBox(width: 10),
              ],
              if (showProfile)
                _buildProfileButton(
                  context: context,
                  ref: ref,
                  onTap:
                      onProfileTap ??
                      () {
                        ref.read(bottomNavProvider.notifier).changeIndex(3);
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                      },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileButton({
    required BuildContext context,
    required WidgetRef ref,
    required VoidCallback onTap,
  }) {
    final isAuth = ref.watch(authProvider).isAuthenticated;
    final profile = isAuth ? ref.watch(accountProvider) : null;

    final avatarUrl =
        (isAuth && profile != null && profile.avatarUrl.trim().isNotEmpty)
        ? profile.avatarUrl.trim()
        : null;

    final hasAvatar =
        avatarUrl != null &&
        avatarUrl.isNotEmpty &&
        avatarUrl != 'null' &&
        avatarUrl != 'undefined';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipOval(
          child: hasAvatar
              ? Image.network(
                  avatarUrl,
                  width: 38,
                  height: 38,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.person,
                    size: 20,
                    color: AppColors.textPrimary,
                  ),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    );
                  },
                )
              : const Icon(
                  Icons.person,
                  size: 20,
                  color: AppColors.textPrimary,
                ),
        ),
      ),
    );
  }

  Widget _buildHeaderIconButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isFilled = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isFilled ? AppColors.primary : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 20,
          color: isFilled ? Colors.white : AppColors.textPrimary,
        ),
      ),
    );
  }
}
