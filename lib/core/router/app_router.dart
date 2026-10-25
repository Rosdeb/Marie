import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/sign_in_screen.dart';
import '../../features/auth/presentation/screens/create_account_screen.dart';
import '../../features/auth/presentation/screens/subscription_screen.dart';
import '../../features/auth/presentation/screens/confirm_subscription_screen.dart';
import '../../features/auth/presentation/screens/subscription_success_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/otp_verification_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/bottom_nav/presentation/screens/bottom_nav_screen.dart';
import '../../features/account/presentation/screens/edit_profile_screen.dart';
import '../../features/account/presentation/screens/referral_screen.dart';
import '../../features/account/presentation/screens/settings_screen.dart';
import '../../features/account/presentation/screens/change_password_screen.dart';
import '../../features/account/presentation/screens/legal_content_screen.dart';
import '../../features/account/presentation/screens/support_report_screen.dart';
import '../../features/home/presentation/screens/demo_config_screen.dart';
import '../../features/home/presentation/screens/demo_offices_screen.dart';
import '../../features/home/presentation/screens/notification_screen.dart';
import '../../features/home/presentation/screens/share_preview_screen.dart';
import '../../features/home/presentation/screens/how_it_works_screen.dart';
import '../../features/practice/presentation/screens/choose_subdiscipline_screen.dart';
import '../../features/practice/presentation/screens/choose_jurisdiction_screen.dart';
import '../../features/practice/presentation/screens/choose_level_screen.dart';
import '../../features/practice/presentation/screens/exam_ready_screen.dart';
import '../../features/practice/presentation/screens/quiz_setup_screen.dart';
import '../../features/practice/presentation/screens/active_quiz_screen.dart';
import '../../features/practice/presentation/screens/quiz_result_screen.dart';
import '../../features/practice/presentation/screens/answer_review_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/sign-in',
        name: 'signIn',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/create-account',
        name: 'createAccount',
        builder: (context, state) => const CreateAccountScreen(),
      ),
      GoRoute(
        path: '/subscription',
        name: 'subscription',
        builder: (context, state) => const SubscriptionScreen(),
      ),
      GoRoute(
        path: '/confirm-subscription',
        name: 'confirmSubscription',
        builder: (context, state) => const ConfirmSubscriptionScreen(),
      ),
      GoRoute(
        path: '/subscription-success',
        name: 'subscriptionSuccess',
        builder: (context, state) => const SubscriptionSuccessScreen(),
      ),

      GoRoute(
        path: '/forgot-password',
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/otp-verification',
        name: 'otpVerification',
        builder: (context, state) {
          final isForgot = state.uri.queryParameters['mode'] == 'forgot' || state.extra == 'forgot';
          return OtpVerificationScreen(isForgotPassword: isForgot);
        },
      ),
      GoRoute(
        path: '/reset-password',
        name: 'resetPassword',
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: '/main',
        name: 'main',
        builder: (context, state) => const BottomNavScreen(),
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationScreen(),
      ),
      GoRoute(
        path: '/home/demo-offices',
        name: 'demoOffices',
        builder: (context, state) => const DemoOfficesScreen(),
      ),
      GoRoute(
        path: '/home/demo-config',
        name: 'demoConfig',
        builder: (context, state) => const DemoConfigScreen(),
      ),
      GoRoute(
        path: '/home/share-preview',
        name: 'sharePreview',
        builder: (context, state) => const SharePreviewScreen(),
      ),
      GoRoute(
        path: '/home/how-it-works',
        name: 'howItWorks',
        builder: (context, state) => const HowItWorksScreen(),
      ),
      GoRoute(
        path: '/edit-profile',
        name: 'editProfile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/referral',
        name: 'referral',
        builder: (context, state) => const ReferralScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/change-password',
        name: 'changePassword',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: '/privacy-policy',
        name: 'privacyPolicy',
        builder: (context, state) => const LegalContentScreen(type: LegalType.privacyPolicy),
      ),
      GoRoute(
        path: '/legal-notice',
        name: 'legalNotice',
        builder: (context, state) => const LegalContentScreen(type: LegalType.legalNotice),
      ),
      GoRoute(
        path: '/eula',
        name: 'eula',
        builder: (context, state) => const LegalContentScreen(type: LegalType.eula),
      ),
      GoRoute(
        path: '/support',
        name: 'support',
        builder: (context, state) => const SupportReportScreen(),
      ),
      // Practice Flow Routes
      GoRoute(
        path: '/practice/choose-subdiscipline',
        name: 'chooseSubdiscipline',
        builder: (context, state) => const ChooseSubdisciplineScreen(),
      ),
      GoRoute(
        path: '/practice/choose-jurisdiction',
        name: 'chooseJurisdiction',
        builder: (context, state) => const ChooseJurisdictionScreen(),
      ),
      GoRoute(
        path: '/practice/choose-level',
        name: 'chooseLevel',
        builder: (context, state) => const ChooseLevelScreen(),
      ),
      GoRoute(
        path: '/practice/exam-ready',
        name: 'examReady',
        builder: (context, state) => const ExamReadyScreen(),
      ),
      GoRoute(
        path: '/practice/quiz-setup',
        name: 'quizSetup',
        builder: (context, state) => const QuizSetupScreen(),
      ),
      GoRoute(
        path: '/practice/active-quiz',
        name: 'activeQuiz',
        builder: (context, state) => const ActiveQuizScreen(),
      ),
      GoRoute(
        path: '/practice/quiz-result',
        name: 'quizResult',
        builder: (context, state) => const QuizResultScreen(),
      ),
      GoRoute(
        path: '/practice/answer-review',
        name: 'answerReview',
        builder: (context, state) => const AnswerReviewScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
}
