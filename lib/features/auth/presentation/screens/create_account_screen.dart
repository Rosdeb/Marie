import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/floating_error_bar.dart';
import '../../../../core/widgets/floating_success_bar.dart';
import '../providers/auth_provider.dart';

class CreateAccountScreen extends ConsumerStatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  ConsumerState<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends ConsumerState<CreateAccountScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedProfileType = 'Attorney';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onSignUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty) {
      FloatingErrorBar.show(context, message: 'Please enter your full name');
      return;
    }
    if (email.isEmpty) {
      FloatingErrorBar.show(context, message: 'Please enter your email address');
      return;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      FloatingErrorBar.show(context, message: 'Please enter a valid email address');
      return;
    }
    if (password.isEmpty) {
      FloatingErrorBar.show(context, message: 'Please create a password');
      return;
    }
    if (password.length < 6) {
      FloatingErrorBar.show(context, message: 'Password must be at least 6 characters');
      return;
    }

    final success = await ref.read(authProvider.notifier).signUp(
          name: name,
          email: email,
          password: password,
          profileType: _selectedProfileType,
        );
    if (!mounted) return;
    if (success) {
      FloatingSuccessBar.show(context, message: 'Verification code sent to your email');
      context.push('/otp-verification');
    } else {
      final error = ref.read(authProvider).errorMessage ?? 'Registration failed';
      FloatingErrorBar.show(context, message: error);
    }
  }

  Future<void> _onGoogleSignUp() async {
    final success = await ref.read(authProvider.notifier).loginWithGoogle();
    if (!mounted) return;
    if (success) {
      FloatingSuccessBar.show(context, message: 'Signed in with Google successfully');
      context.go('/main');
    } else {
      final err = ref.read(authProvider).errorMessage;
      if (err != null && err.isNotEmpty) {
        FloatingErrorBar.show(context, message: err);
      }
    }
  }

  Future<void> _onAppleSignUp() async {
    final success = await ref.read(authProvider.notifier).loginWithApple();
    if (!mounted) return;
    if (success) {
      FloatingSuccessBar.show(context, message: 'Signed in with Apple successfully');
      context.go('/main');
    } else {
      final err = ref.read(authProvider).errorMessage;
      if (err != null && err.isNotEmpty) {
        FloatingErrorBar.show(context, message: err);
      }
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
          'Create Account',
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
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Join Today',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Create an account to track your study progress and access premium materials.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              CustomTextField(
                label: 'Full Name',
                hint: 'Enter your name',
                controller: _nameController,
                prefixIcon: const Icon(Icons.person_outline, color: AppColors.textSecondary, size: 20),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'Email',
                hint: 'Enter your email',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textSecondary, size: 20),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'Password',
                hint: 'Create a Password',
                isPassword: true,
                controller: _passwordController,
                prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary, size: 20),
              ),
              const SizedBox(height: 16),
              const Text(
                'Profile Type',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildProfileTypeOption(
                      title: 'Attorney',
                      subtitle: 'Legal practitioner',
                      isSelected: _selectedProfileType == 'Attorney',
                      onTap: () => setState(() => _selectedProfileType = 'Attorney'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildProfileTypeOption(
                      title: 'Paralegal',
                      subtitle: 'Legal assistant',
                      isSelected: _selectedProfileType == 'Paralegal',
                      onTap: () => setState(() => _selectedProfileType = 'Paralegal'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              CustomButton(
                text: 'Sign Up',
                isLoading: authState.isLoading && authState.authMode != AuthMode.loadingGoogle,
                onPressed: authState.isLoading ? null : _onSignUp,
              ),
              const SizedBox(height: 16),
              Row(
                children: const [
                  Expanded(child: Divider(color: AppColors.border)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: AppColors.border)),
                ],
              ),
              const SizedBox(height: 16),
              AuthButton(
                text: 'Continue with Google',
                textColor: AppColors.textPrimary,
                backgroundColor: Colors.white,
                isLoading: authState.authMode == AuthMode.loadingGoogle,
                icon: Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Text(
                    'G',
                    style: TextStyle(
                      color: Color(0xFF4285F4),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                onPressed: authState.isLoading ? null : _onGoogleSignUp,
              ),
              if (Platform.isIOS) ...[
                const SizedBox(height: 12),
                AuthButton(
                  text: 'Continue with Apple',
                  textColor: Colors.black87,
                  backgroundColor: Colors.white,
                  isLoading: authState.authMode == AuthMode.loadingApple,
                  icon: const Icon(
                    Icons.apple,
                    color: Colors.black,
                    size: 22,
                  ),
                  onPressed: authState.isLoading ? null : _onAppleSignUp,
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already have an Account? ',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/sign-in'),
                    child: const Text(
                      'Sign In',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileTypeOption({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
