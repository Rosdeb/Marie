import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/floating_error_bar.dart';
import '../../../../core/widgets/floating_success_bar.dart';
import '../../../account/presentation/providers/account_provider.dart';
import '../providers/auth_provider.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final bool isForgotPassword;

  const OtpVerificationScreen({
    super.key,
    this.isForgotPassword = false,
  });

  @override
  ConsumerState<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _onVerify() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty) {
      FloatingErrorBar.show(context, message: 'Please enter the verification code');
      return;
    }
    if (otp.length < 4) {
      FloatingErrorBar.show(context, message: 'Code must be at least 4-6 digits');
      return;
    }

    bool success;
    if (widget.isForgotPassword) {
      success = await ref.read(authProvider.notifier).verifyForgotOtp(otp);
      if (!mounted) return;
      if (success) {
        FloatingSuccessBar.show(context, message: 'OTP verified successfully');
        context.push('/reset-password');
      } else {
        final err = ref.read(authProvider).errorMessage ?? 'Invalid OTP code';
        FloatingErrorBar.show(context, message: err);
      }
    } else {
      success = await ref.read(authProvider.notifier).verifyOtp(otp);
      if (!mounted) return;
      if (success) {
        FloatingSuccessBar.show(context, message: 'Account activated successfully');
        ref.read(accountProvider.notifier).fetchProfile();
        context.push('/subscription');
      } else {
        final err = ref.read(authProvider).errorMessage ?? 'Invalid OTP code';
        FloatingErrorBar.show(context, message: err);
      }
    }
  }

  void _onResend() async {
    final authState = ref.read(authProvider);
    final email = authState.email;
    if (email == null || email.isEmpty) {
      FloatingErrorBar.show(context, message: 'Email address not found');
      return;
    }

    bool ok;
    if (widget.isForgotPassword) {
      ok = await ref.read(authProvider.notifier).sendOtp(email);
    } else {
      ok = await ref.read(authProvider.notifier).resendOtp(email);
    }

    if (!mounted) return;
    if (ok) {
      FloatingSuccessBar.show(context, message: 'A new verification code has been sent');
    } else {
      final err = ref.read(authProvider).errorMessage ?? 'Failed to resend code';
      FloatingErrorBar.show(context, message: err);
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
          'Enter OTP',
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
              Text(
                widget.isForgotPassword ? 'Reset Password OTP' : 'Verify Your Email',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'We have sent a verification code to ${authState.email ?? "your email"}.',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              CustomTextField(
                label: 'Enter OTP Code',
                hint: 'Enter 6-digit OTP code',
                controller: _otpController,
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.pin_outlined, color: AppColors.textSecondary, size: 20),
              ),
              const SizedBox(height: 28),
              CustomButton(
                text: 'Verify Code',
                isLoading: authState.isLoading,
                onPressed: _onVerify,
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: _onResend,
                  child: const Text(
                    'Resend Code',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
