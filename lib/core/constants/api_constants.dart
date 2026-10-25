class ApiConstants {
  static const String baseUrl = 'https://sabbir2004.ssh.bd/api/v1';

  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String verifyOtp = '/auth/verify-otp';
  static const String resendOtp = '/auth/resend-otp';
  static const String forgotPassword = '/auth/forgot-password';
  static const String forgotOtpVerify = '/auth/forgot-otp-verify';
  static const String resetPassword = '/auth/reset-password';
  static const String changePassword = '/auth/change-password';
  static const String refreshToken = '/auth/refresh-token';
  static const String logout = '/auth/logout';

  // Profile & Privacy endpoints
  static const String myProfile = '/user/get-my-profile';
  static const String updateMyProfile = '/user/update-my-profile';
  static const String profileType = '/practice/profile-type';
  static const String privacySettings = '/user/privacy-settings';
  static String publicProfile(String userId) => '/user/public/$userId';
  static const String deleteAccount = '/user/delete/my-account';

  // Notifications
  static const String notifications = '/notification/get-all';
  static const String notificationUnreadCount = '/notification/unread-count';
  static const String notificationMarkAsRead = '/notification/mark-as-read';

  // Common & Legal
  static const String privacyPolicy = '/common/privacy-policy';
  static const String terms = '/common/terms';
  static const String about = '/common/about';
  static const String supportContact = '/common/support';

  // Report a problem
  static const String reportProblem = '/report';

  // Practice & Demo endpoints
  static const String practiceOffices = '/practice/offices';
  static const String practiceSession = '/practice/session';
  static String practiceSessionSubmit(String sessionId) => '/practice/session/$sessionId/submit';
  static String practiceSessionReview(String sessionId) => '/practice/session/$sessionId/review';
  static String practiceSessionResume(String sessionId) => '/practice/session/$sessionId';

  // Referral (LinkedIn)
  static const String sharePreview = '/referral/share-preview';
  static const String linkedinStatus = '/referral/linkedin/status';
  static const String linkedinConnect = '/referral/linkedin/connect';
  static const String linkedinShare = '/referral/linkedin/share';
  static const String claimDiscount = '/referral/claim-discount';
  static const String validatePromoCode = '/referral/validate-code';
}
