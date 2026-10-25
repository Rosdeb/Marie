import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/floating_error_bar.dart';
import '../../../../core/widgets/floating_success_bar.dart';
import '../../../../core/widgets/success_view.dart';
import '../providers/auth_provider.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSuccess = false;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onSavePassword() async {
    final newPass = _newPasswordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    if (newPass.isEmpty) {
      FloatingErrorBar.show(context, message: 'Please enter your new password');
      return;
    }
    if (newPass.length < 6) {
      FloatingErrorBar.show(context, message: 'Password must be at least 6 characters');
      return;
    }
    if (newPass != confirmPass) {
      FloatingErrorBar.show(context, message: 'Passwords do not match');
      return;
    }

    final success = await ref.read(authProvider.notifier).resetPassword(newPass, confirmPass);
    if (!mounted) return;
    if (success) {
      FloatingSuccessBar.show(context, message: 'Password reset successfully');
      setState(() {
        _isSuccess = true;
      });
    } else {
      final error = ref.read(authProvider).errorMessage ?? 'Failed to reset password';
      FloatingErrorBar.show(context, message: error);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSuccess) {
      return SuccessView(
        title: 'Password Updated',
        subtitle: 'Your password has been updated successfully. You can now sign in with your new credentials.',
        buttonText: 'Back to Sign In',
        onButtonPressed: () {
          context.go('/sign-in');
        },
      );
    }

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
          'Reset Password',
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
                'Create New Password',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your new password must be different from previous passwords.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              CustomTextField(
                label: 'Enter New Password',
                hint: 'Create a new password',
                isPassword: true,
                controller: _newPasswordController,
                prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary, size: 20),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'Re-enter Password',
                hint: 'Confirm new password',
                isPassword: true,
                controller: _confirmPasswordController,
                prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary, size: 20),
              ),
              const SizedBox(height: 28),
              CustomButton(
                text: 'Save New Password',
                isLoading: authState.isLoading,
                onPressed: _onSavePassword,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
