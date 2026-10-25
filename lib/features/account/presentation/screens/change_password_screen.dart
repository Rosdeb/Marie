import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/floating_error_bar.dart';
import '../../../../core/widgets/floating_success_bar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onChangePassword() async {
    final currentPass = _currentPasswordController.text.trim();
    final newPass = _newPasswordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    if (currentPass.isEmpty) {
      FloatingErrorBar.show(context, message: 'Please enter your current password');
      return;
    }
    if (newPass.isEmpty) {
      FloatingErrorBar.show(context, message: 'Please enter your new password');
      return;
    }
    if (newPass.length < 6) {
      FloatingErrorBar.show(context, message: 'New password must be at least 6 characters');
      return;
    }
    if (newPass != confirmPass) {
      FloatingErrorBar.show(context, message: 'New passwords do not match');
      return;
    }

    final success = await ref.read(authProvider.notifier).changePassword(
          oldPassword: currentPass,
          newPassword: newPass,
          confirmPassword: confirmPass,
        );

    if (!mounted) return;
    if (success) {
      FloatingSuccessBar.show(context, message: 'Password updated successfully!');
      context.pop();
    } else {
      final error = ref.read(authProvider).errorMessage ?? 'Failed to update password';
      FloatingErrorBar.show(context, message: error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Change Password',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Update Your Password',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Enter your current password and choose a strong new password.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 28),

              CustomTextField(
                label: 'Current Password',
                hint: 'Enter current password',
                isPassword: true,
                controller: _currentPasswordController,
                prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary, size: 20),
              ),
              const SizedBox(height: 14),

              CustomTextField(
                label: 'New Password',
                hint: 'Enter new password',
                isPassword: true,
                controller: _newPasswordController,
                prefixIcon: const Icon(Icons.lock_reset_outlined, color: AppColors.textSecondary, size: 20),
              ),
              const SizedBox(height: 14),

              CustomTextField(
                label: 'Confirm New Password',
                hint: 'Re-enter new password',
                isPassword: true,
                controller: _confirmPasswordController,
                prefixIcon: const Icon(Icons.lock_reset_outlined, color: AppColors.textSecondary, size: 20),
              ),
              const SizedBox(height: 32),

              CustomButton(
                text: 'Update Password',
                isLoading: authState.isLoading,
                onPressed: _onChangePassword,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
