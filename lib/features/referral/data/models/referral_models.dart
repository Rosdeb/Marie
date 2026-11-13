class ReferralInfo {
  final String code;
  final String url;

  /// Where a shared referral link points when the server has not said.
  ///
  /// ipro.legal is not a domain IPro owns and nothing answers on it, so it
  /// must never appear in a post.
  ///
  /// Marie, 3 November 2026, point 8.12: the share link belongs on
  /// iprospace.com, not ipro-law.com. ipro-law.com is the dashboard; the
  /// public site a reader lands on is iprospace.com.
  /// The path she gave on 1 November is /ipro/app, not /app.
  static const String fallbackUrl = 'https://iprospace.com/ipro/app';

  const ReferralInfo({
    this.code = '',
    this.url = fallbackUrl,
  });

  factory ReferralInfo.fromJson(
    Map<String, dynamic>? json, [
    Map<String, dynamic>? rootJson,
  ]) {
    final code = json?['code'] as String? ??
        rootJson?['referralCode'] as String? ??
        rootJson?['code'] as String? ??
        '';
    final url = json?['url'] as String? ??
        rootJson?['referralUrl'] as String? ??
        rootJson?['url'] as String? ??
        fallbackUrl;
    return ReferralInfo(
      code: code,
      url: url,
    );
  }
}

class RewardInfo {
  final int discountPercentage;
  final int validityDays;
  final bool oneTimePerUser;
  final String appliesTo;

  /// Which period the discount comes off, in one sentence, as the dashboard
  /// shows it. Neither store can reduce a subscription that is already
  /// running, so the first paid period is the only shape it can take.
  final String termsNote;

  const RewardInfo({
    this.discountPercentage = 10,
    // No expiry, which is what the codes are set to. Thirty days was the old
    // default and would have been shown on a code that never expires.
    this.validityDays = 0,
    this.oneTimePerUser = true,
    this.appliesTo = 'standard IPro plans',
    this.termsNote =
        'Applies to the first paid period only - the first month on a monthly '
        'plan, the first year on a yearly plan. One discount per user.',
  });

  factory RewardInfo.fromJson(
    Map<String, dynamic>? json, [
    Map<String, dynamic>? rootJson,
  ]) {
    final discount = (json?['discountPercentage'] as num?)?.toInt() ??
        (rootJson?['discountPercentage'] as num?)?.toInt() ??
        10;
    final validity = (json?['validityDays'] as num?)?.toInt() ??
        (rootJson?['validityDays'] as num?)?.toInt() ??
        0;
    final oneTime = json?['oneTimePerUser'] as bool? ??
        rootJson?['oneTimePerUser'] as bool? ??
        true;
    final applies = json?['appliesTo'] as String? ??
        rootJson?['appliesTo'] as String? ??
        'standard IPro plans';
    final terms = (json?['termsNote'] as String?)?.trim().isNotEmpty == true
        ? json!['termsNote'] as String
        : (rootJson?['termsNote'] as String?)?.trim().isNotEmpty == true
            ? rootJson!['termsNote'] as String
            : null;
    return RewardInfo(
      discountPercentage: discount,
      validityDays: validity,
      oneTimePerUser: oneTime,
      appliesTo: applies,
      termsNote: terms ?? const RewardInfo().termsNote,
    );
  }
}

class ReferralVideoInfo {
  final bool comingSoon;
  final String? title;
  final String? videoUrl;
  final String? thumbnailUrl;
  final String? captionsUrl;

  const ReferralVideoInfo({
    this.comingSoon = true,
    this.title,
    this.videoUrl,
    this.thumbnailUrl,
    this.captionsUrl,
  });

  factory ReferralVideoInfo.fromJson(
    Map<String, dynamic>? json, [
    Map<String, dynamic>? rootJson,
  ]) {
    final comingSoon = json?['comingSoon'] as bool? ??
        (json?['videoUrl'] == null && rootJson?['videoUrl'] == null);
    final title = json?['title'] as String? ?? rootJson?['title'] as String?;
    final videoUrl =
        json?['videoUrl'] as String? ?? rootJson?['videoUrl'] as String?;
    final thumbnailUrl = json?['thumbnailUrl'] as String? ??
        rootJson?['previewImageUrl'] as String?;
    final captionsUrl =
        json?['captionsUrl'] as String? ?? rootJson?['captionsUrl'] as String?;
    return ReferralVideoInfo(
      comingSoon: comingSoon,
      title: title,
      videoUrl: videoUrl,
      thumbnailUrl: thumbnailUrl,
      captionsUrl: captionsUrl,
    );
  }
}

class SharePreviewSection {
  static const String defaultPostMessage =
      "I've just downloaded IPro, the new app to practise IP procedure anywhere, anytime. Every answer comes with its explanation and legal basis. Download it and visit iprospace.com.";

  final String screenTitle;
  final String shareHint;
  final String postMessageLabel;
  final String postMessage;
  final String postMessageTemplate;
  final bool editable;
  final int maxLength;
  final String primaryButtonText;
  final String secondaryButtonText;
  final String? footerNote;

  const SharePreviewSection({
    this.screenTitle = 'Share Preview',
    this.shareHint = 'Share the video on LinkedIn to earn 10% off your plan.',
    this.postMessageLabel = 'LinkedIn Post Message',
    this.postMessage = defaultPostMessage,
    this.postMessageTemplate = '',
    this.editable = true,
    this.maxLength = 3000,
    this.primaryButtonText = 'Continue to Share',
    this.secondaryButtonText = 'How It Works',
    this.footerNote,
  });

  factory SharePreviewSection.fromJson(
    Map<String, dynamic>? json, [
    Map<String, dynamic>? rootJson,
  ]) {
    final banner = rootJson?['banner'] as Map<String, dynamic>?;
    final primaryBtn = json?['primaryButtonText'] as String? ??
        banner?['buttonText'] as String? ??
        rootJson?['buttonText'] as String? ??
        (rootJson?['actions'] as Map<String, dynamic>?)?['publishButtonText']
            as String? ??
        'Continue to Share';
    final rawPostMsg = json?['postMessage'] as String? ??
        rootJson?['shareText'] as String? ??
        rootJson?['postMessage'] as String?;
    final postMsg = (rawPostMsg != null &&
            rawPostMsg.trim().isNotEmpty &&
            rawPostMsg.contains("I've just downloaded"))
        ? rawPostMsg
        : defaultPostMessage;
    final hint = json?['shareHint'] as String? ??
        rootJson?['description'] as String? ??
        'Share the video on LinkedIn to earn 10% off your plan.';

    return SharePreviewSection(
      screenTitle: json?['screenTitle'] as String? ??
          rootJson?['screenTitle'] as String? ??
          'Share Preview',
      shareHint: hint,
      postMessageLabel:
          json?['postMessageLabel'] as String? ?? 'LinkedIn Post Message',
      postMessage: postMsg,
      postMessageTemplate: json?['postMessageTemplate'] as String? ?? '',
      editable: json?['editable'] as bool? ?? true,
      maxLength: (json?['maxLength'] as num?)?.toInt() ?? 3000,
      primaryButtonText: primaryBtn,
      secondaryButtonText:
          json?['secondaryButtonText'] as String? ?? 'How It Works',
      footerNote: json?['footerNote'] as String?,
    );
  }
}

class HowItWorksStep {
  final int step;
  final String title;
  final String body;

  const HowItWorksStep({
    required this.step,
    required this.title,
    required this.body,
  });

  factory HowItWorksStep.fromJson(Map<String, dynamic> json) {
    return HowItWorksStep(
      step: (json['step'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
    );
  }
}

class HowItWorksSection {
  final String screenTitle;
  final String title;
  final List<HowItWorksStep> steps;
  final String? availabilityTitle;
  final String? availabilityNote;

  const HowItWorksSection({
    this.screenTitle = 'How it works',
    this.title = 'Share on LinkedIn. Get 10% off.',
    this.steps = const [],
    this.availabilityTitle,
    this.availabilityNote,
  });

  factory HowItWorksSection.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const HowItWorksSection();
    final rawSteps = json['steps'] as List<dynamic>? ?? [];
    return HowItWorksSection(
      screenTitle: json['screenTitle'] as String? ?? 'How it works',
      title: json['title'] as String? ?? 'Share on LinkedIn. Get 10% off.',
      steps: rawSteps
          .whereType<Map<String, dynamic>>()
          .map(HowItWorksStep.fromJson)
          .toList(),
      availabilityTitle: json['availabilityTitle'] as String?,
      availabilityNote: json['availabilityNote'] as String?,
    );
  }
}

class SharePreviewModel {
  final bool sharingAvailable;
  final String? unavailableReason;
  final ReferralInfo referral;
  final RewardInfo reward;
  final ReferralVideoInfo video;
  final SharePreviewSection sharePreview;
  final HowItWorksSection howItWorks;
  final bool linkedinConnected;
  final bool shareRewardClaimed;
  final String? promoCode;
  final String? connectEndpoint;
  final String? publishEndpoint;
  final String? statusEndpoint;
  final String? legacyBannerTag;
  final String? legacyBannerTitle;
  final String? legacyBannerDescription;
  final String? legacyPreviewDomain;

  const SharePreviewModel({
    this.sharingAvailable = true,
    this.unavailableReason,
    this.referral = const ReferralInfo(),
    this.reward = const RewardInfo(),
    this.video = const ReferralVideoInfo(),
    this.sharePreview = const SharePreviewSection(),
    this.howItWorks = const HowItWorksSection(),
    this.linkedinConnected = false,
    this.shareRewardClaimed = false,
    this.promoCode,
    this.connectEndpoint,
    this.publishEndpoint,
    this.statusEndpoint,
    this.legacyBannerTag,
    this.legacyBannerTitle,
    this.legacyBannerDescription,
    this.legacyPreviewDomain,
  });


  factory SharePreviewModel.fromJson(Map<String, dynamic> json) {
    final actions = json['actions'] as Map<String, dynamic>? ?? {};
    final banner = json['banner'] as Map<String, dynamic>?;

    return SharePreviewModel(
      sharingAvailable: json['sharingAvailable'] as bool? ?? true,
      unavailableReason: json['unavailableReason'] as String?,
      referral: ReferralInfo.fromJson(
        json['referral'] as Map<String, dynamic>?,
        json,
      ),
      reward: RewardInfo.fromJson(
        json['reward'] as Map<String, dynamic>?,
        json,
      ),
      video: ReferralVideoInfo.fromJson(
        json['video'] as Map<String, dynamic>?,
        json,
      ),
      sharePreview: SharePreviewSection.fromJson(
        json['sharePreview'] as Map<String, dynamic>?,
        json,
      ),
      howItWorks: HowItWorksSection.fromJson(
        json['howItWorks'] as Map<String, dynamic>?,
      ),
      linkedinConnected: json['linkedinConnected'] as bool? ?? false,
      shareRewardClaimed: json['shareRewardClaimed'] as bool? ?? false,
      promoCode: json['promoCode'] as String?,
      connectEndpoint: actions['connectEndpoint'] as String?,
      publishEndpoint: actions['publishEndpoint'] as String?,
      statusEndpoint: actions['statusEndpoint'] as String?,
      legacyBannerTag: banner?['tag'] as String?,
      legacyBannerTitle: banner?['title'] as String?,
      legacyBannerDescription: banner?['description'] as String?,
      legacyPreviewDomain: json['previewDomain'] as String?,
    );
  }

  // Backward compatibility getters
  String get referralUrl => referral.url;
  String get shareText => sharePreview.postMessage;
  String get referralCode => referral.code;
  int get discountPercentage => reward.discountPercentage;
  int get validityDays => reward.validityDays;
  String get discountTerms => reward.termsNote;
  String get buttonText => sharePreview.primaryButtonText;
  String? get previewImageUrl => video.thumbnailUrl;
  // "Trust your excellence" is the only slogan IPro uses.
  String get title => video.title ?? 'IPro — Trust your excellence';
  String get description => sharePreview.shareHint;
  String get previewDomain =>
      legacyPreviewDomain ??
      Uri.tryParse(referral.url)?.host ??
      'iprospace.com';
  // Neutral wording, never anything that reads as LinkedIn's own offer
  // (Marie, 1 November 2026, LinkedIn brand guidelines).
  String get bannerTag => legacyBannerTag ?? 'SHARE & SAVE';
  String get bannerDiscountTag => '${reward.discountPercentage}% OFF';
  String get bannerTitle =>
      legacyBannerTitle ??
      'Share IPro & Get ${reward.discountPercentage}% Off Your Plan';
  String get bannerDescription =>
      legacyBannerDescription ??
      'Share IPro on LinkedIn and your discount is unlocked straight away. '
          'Nobody else has to sign up.';
}

class LinkedInStatusModel {
  final bool connected;
  final String? memberUrn;
  final bool shareRewardClaimed;
  final String? promoCode;

  const LinkedInStatusModel({
    this.connected = false,
    this.memberUrn,
    this.shareRewardClaimed = false,
    this.promoCode,
  });

  factory LinkedInStatusModel.fromJson(Map<String, dynamic> json) {
    return LinkedInStatusModel(
      connected: json['connected'] as bool? ?? false,
      memberUrn: json['memberUrn'] as String?,
      shareRewardClaimed: json['shareRewardClaimed'] as bool? ?? false,
      promoCode: json['promoCode'] as String?,
    );
  }
}

class LinkedInShareResult {
  final bool success;
  final String message;
  final bool requiresAuth;
  final String? authorizationUrl;
  final String? promoCode;
  final int? discountPercentage;
  final int? validityDays;
  final DateTime? expiresAt;
  final String? linkedinPostId;
  final String? appliesTo;

  const LinkedInShareResult({
    required this.success,
    required this.message,
    this.requiresAuth = false,
    this.authorizationUrl,
    this.promoCode,
    this.discountPercentage,
    this.validityDays,
    this.expiresAt,
    this.linkedinPostId,
    this.appliesTo,
  });

  factory LinkedInShareResult.fromJson(Map<String, dynamic> json) {
    final success = json['success'] as bool? ?? false;
    final message = (json['message'] ?? '').toString();
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final discountDetails =
        data['discountDetails'] as Map<String, dynamic>? ?? {};

    return LinkedInShareResult(
      success: success,
      message: message.isNotEmpty
          ? message
          : (data['message']?.toString() ??
              (success ? 'Post published to LinkedIn!' : 'Failed to share to LinkedIn')),
      requiresAuth: data['requiresAuth'] as bool? ?? false,
      authorizationUrl: data['authorizationUrl'] as String?,
      promoCode: (data['promoCode'] ?? json['promoCode'])?.toString(),
      discountPercentage: (data['discountPercentage'] as num?)?.toInt(),
      validityDays: (data['validityDays'] as num?)?.toInt(),
      expiresAt: data['expiresAt'] != null
          ? DateTime.tryParse(data['expiresAt'].toString())
          : null,
      linkedinPostId: data['linkedinPostId'] as String?,
      appliesTo: discountDetails['appliesTo'] as String?,
    );
  }
}

class RedeemRequestModel {
  final String code;
  final String tier;
  final String billingPeriod;
  final double discountAmount;
  final String currency;

  const RedeemRequestModel({
    required this.code,
    required this.tier,
    required this.billingPeriod,
    required this.discountAmount,
    required this.currency,
  });

  /// Only the code is required. The stores do not always tell the app what
  /// was actually charged, and an empty amount or currency sent as "" or 0
  /// would be recorded as a real figure - so anything unknown is left out and
  /// the server stores null instead.
  Map<String, dynamic> toJson() => {
        'code': code,
        if (tier.isNotEmpty) 'tier': tier,
        if (billingPeriod.isNotEmpty) 'billingPeriod': billingPeriod,
        if (discountAmount > 0) 'discountAmount': discountAmount,
        if (currency.isNotEmpty) 'currency': currency,
      };
}
