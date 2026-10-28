import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/floating_error_bar.dart';
import '../providers/auth_provider.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final authNotifier = ref.read(authProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom -
                  32,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(flex: 1),

                  // Hero Illustration Section
                  SizedBox(
                    height: 240,
                    width: 240,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Scribble background accent
                        Positioned(
                          top: 10,
                          right: 10,
                          child: CustomPaint(
                            size: const Size(90, 90),
                            painter: ScribblePainter(),
                          ),
                        ),
                        // Circular avatar frame
                        Container(
                          width: 260,
                          height: 260,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: AssetImage("assets/image/splash_image.png",),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Title Header
                  const Text(
                    'The best way to study\nSign up for free',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.25,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Subtitle
                  const Text(
                    'An account is required to access paid content\nand manage your subscription.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),

                  const Spacer(flex: 2),
                  const SizedBox(height: 24),

                  // Google Auth Button
                  AuthButton(
                    text: 'Continue with Google',
                    textColor: Colors.black87,
                    backgroundColor: Colors.white,
                    isLoading: authState.authMode == AuthMode.loadingGoogle,
                    icon: Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        'G',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    onPressed: () async {
                      final success = await authNotifier.loginWithGoogle();
                      if (!context.mounted) return;
                      if (success) {
                        context.go('/main');
                      } else {
                        final error = ref.read(authProvider).errorMessage;
                        if (error != null && error.isNotEmpty) {
                          FloatingErrorBar.show(context, message: error);
                        }
                      }
                    },
                  ),

                  const SizedBox(height: 12),

                  // Apple Auth Button
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
                    onPressed: () async {
                      final success = await authNotifier.loginWithApple();
                      if (!context.mounted) return;
                      if (success) {
                        context.go('/main');
                      } else {
                        final error = ref.read(authProvider).errorMessage;
                        if (error != null && error.isNotEmpty) {
                          FloatingErrorBar.show(context, message: error);
                        }
                      }
                    },
                  ),

                  const SizedBox(height: 12),

                  // Email Auth Button
                  AuthButton(
                    text: 'Continue with Email',
                    textColor: Colors.white,
                    backgroundColor: AppColors.primary,
                    isLoading: authState.authMode == AuthMode.loadingEmail,
                    icon: const Icon(
                      Icons.mail_outline,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () {
                      context.push('/create-account');
                    },
                  ),

                  const SizedBox(height: 24),

                  // Bottom Navigation Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Have an Account ? ',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          context.push('/sign-in');
                        },
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Explore as Guest Button
                  TextButton.icon(
                    onPressed: () => context.go('/main'),
                    icon: const Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    label: const Text(
                      'Explore Free Demo as Guest',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ScribblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF384E78)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height * 0.5);
    path.cubicTo(
      size.width * 0.3,
      size.height * 0.1,
      size.width * 0.7,
      size.height * 0.9,
      size.width,
      size.height * 0.2,
    );
    path.cubicTo(
      size.width * 0.8,
      size.height * 0.8,
      size.width * 0.2,
      size.height * 0.2,
      size.width * 0.5,
      size.height,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
