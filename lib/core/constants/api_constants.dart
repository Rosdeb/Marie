class ApiConstants {
  /// Where the app talks to the server.
  ///
  /// Overridable at build time so one codebase serves the tunnel we develop
  /// against and the production host, without an edit here:
  ///
  ///   flutter build web --dart-define=API_BASE_URL=https://api.example.com/api/v1
  ///
  /// Left out, it stays the development tunnel - which is what every build
  /// used before this was configurable, so nothing changes by default.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://sabbir2004.ssh.bd/api/v1',
  );

  // Auth endpoints
  static const String login = '/auth/login';
  static const String googleLogin = '/auth/google-login';
  static const String appleLogin = '/auth/apple-login';
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

  /// The daily goal and the two reminders. Kept apart from the privacy
  /// settings: one is "what should the app do for me", the other is "what may
  /// be shown about me".
  static const String preferences = '/user/preferences';
  static String publicProfile(String userId) => '/user/public/$userId';
  static const String deleteAccount = '/user/delete/my-account';

  // Home
  //
  // The eight sections of the Home screen in one response, in the order
  // Marie set out on 11 November 2026. One call rather than eight, so the
  // screen draws once instead of filling in section by section.
  static const String home = '/home';
  static const String myBadges = '/home/badges';

  /// One answer to the question of the day, with the correction back.
  static const String questionOfTheDayAnswer =
      '/home/question-of-the-day/answer';

  // Notifications
  static const String notifications = '/notification/get-all';
  /// Where the app reports the FCM token of the device it is running on.
  static const String deviceToken = '/notification/device-token';
  static const String notificationUnreadCount = '/notification/unread-count';
  static const String notificationMarkAsRead = '/notification/mark-as-read';

  // Common & Legal
  //
  // The three legal documents live on Marie's own Google Site, and the app
  // opens those pages rather than carrying a copy. Her instruction of
  // 31 October 2026:
  //
  //   "I would prefer the app to simply open my Google Site pages, using the
  //    three links already in App Settings, and the copies to be removed.
  //    That way there is only one version to update, and no risk of the app
  //    showing an outdated text."
  //
  // So the app reads the addresses from here and never stores them: she can
  // change a link in the dashboard and every phone follows at once, with no
  // new release.
  static const String publicAppSettings = '/settings/app/public';
  static const String about = '/common/about';
  static const String supportContact = '/common/support';

  // Report a problem
  static const String reportProblem = '/report';

  // Practice & Demo endpoints
  static const String practiceOffices = '/practice/offices';
  static String practiceDisciplines(String office) => '/practice/offices/$office/disciplines';
  static String practiceThemes(String office, String subject) =>
      '/practice/offices/$office/disciplines/$subject/themes';
  static String practiceCrossOfficeThemes(String subject) =>
      '/practice/themes/cross-office?subject=$subject';
  /// The progress page: per office and discipline, by level and by theme.
  static const String practiceProgress = '/practice/progress';
  static const String practiceSession = '/practice/session';

  /// One session, with what was already answered and the clock it was on.
  /// What "Continue" on Home resumes from.
  static String practiceSessionById(String id) => '/practice/session/$id';
  /// One answer at a time. In practice mode the reply carries the verdict,
  /// the explanation and the legal basis, which the question payload never
  /// does - the app is not told which option is correct in advance.
  static String practiceSessionAnswer(String sessionId) => '/practice/session/$sessionId/answer';
  static String practiceSessionSubmit(String sessionId) => '/practice/session/$sessionId/submit';
  static String practiceSessionReview(String sessionId) => '/practice/session/$sessionId/review';
  static String practiceSessionResume(String sessionId) => '/practice/session/$sessionId';
  static const String practiceHistory = '/practice/history';
  static const String practiceLearningPath = '/practice/learning-path';
  static const String practiceMistakes = '/practice/mistakes';

  // Referral (LinkedIn)
  static const String sharePreview = '/referral/share-preview';
  static const String linkedinStatus = '/referral/linkedin/status';
  static const String linkedinConnect = '/referral/linkedin/connect';
  static const String linkedinCallback = '/referral/linkedin/callback';
  static const String linkedinShare = '/referral/linkedin/share';
  static const String validatePromoCode = '/referral/validate-code';
  static const String redeemPromoCode = '/referral/redeem';
  static const String contentVideos = '/content/videos?placement=referral_guide';
  // Any of the four placements of section 1.2: welcome, home,
  // referral_guide, help_support.
  static String contentVideosFor(String placement) =>
      '/content/videos?placement=$placement';
  static const String contentReferralCopy = '/content/referral-copy';
  static const String contentDiscountOffer = '/content/discount-offer';

  // Subscriptions & Entitlements
  static const String subscriptionPlans = '/subscription/plans';
  static const String subscriptionOffices = '/subscription/offices';
  static const String subscriptionMyAccess = '/subscription/my-access';
  static const String subscriptionSync = '/subscription/sync';
  static String subscriptionChooseOffices(String subscriptionId) =>
      '/subscription/$subscriptionId/offices';
}
