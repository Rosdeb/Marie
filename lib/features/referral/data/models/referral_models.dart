class SharePreviewModel {
  final String referralUrl;
  final String shareText;
  final String title;
  final String description;
  final String previewDomain;
  final String? previewImageUrl;
  final String referralCode;
  final bool linkedinConnected;
  final int discountPercentage;
  final int validityDays;
  final String bannerTag;
  final String bannerDiscountTag;
  final String bannerTitle;
  final String bannerDescription;
  final String buttonText;
  final String? publishEndpoint;

  const SharePreviewModel({
    this.referralUrl = 'https://ipro.legal/referral/join-now',
    this.shareText =
        "I've been using IPro to streamline my IP law practice — it's been a game changer! Use my referral link to sign up and we both get 10% off. Check it out 👇",
    this.title = 'Join IPro — Smart IP Law Practice',
    this.description =
        'Streamline your intellectual property practice with draft automation, smart analytics, and secure firm management.',
    this.previewDomain = 'ipro.legal/referral/join-now',
    this.previewImageUrl,
    this.referralCode = '',
    this.linkedinConnected = false,
    this.discountPercentage = 10,
    this.validityDays = 30,
    this.bannerTag = 'LINKEDIN EXCLUSIVE',
    this.bannerDiscountTag = '10% OFF',
    this.bannerTitle = 'Share IPro & Get 10% Off Your Plan',
    this.bannerDescription =
        'Invite your LinkedIn network to level up their IP law practice and unlock exclusive savings on premium access.',
    this.buttonText = 'Share on LinkedIn',
    this.publishEndpoint,
  });

  factory SharePreviewModel.fromJson(Map<String, dynamic> json) {
    final banner = json['banner'] as Map<String, dynamic>? ?? {};
    final actions = json['actions'] as Map<String, dynamic>? ?? {};

    return SharePreviewModel(
      referralUrl: json['referralUrl'] as String? ??
          'https://ipro.legal/referral/join-now',
      shareText: json['shareText'] as String? ?? '',
      title: json['title'] as String? ?? 'Join IPro — Smart IP Law Practice',
      description: json['description'] as String? ?? '',
      previewDomain:
          json['previewDomain'] as String? ?? 'ipro.legal/referral/join-now',
      previewImageUrl: json['previewImageUrl'] as String?,
      referralCode: json['referralCode'] as String? ?? '',
      linkedinConnected: json['linkedinConnected'] as bool? ?? false,
      discountPercentage:
          (json['discountPercentage'] as num?)?.toInt() ?? 10,
      validityDays: (json['validityDays'] as num?)?.toInt() ?? 30,
      bannerTag: banner['tag'] as String? ?? 'LINKEDIN EXCLUSIVE',
      bannerDiscountTag: banner['discountTag'] as String? ?? '10% OFF',
      bannerTitle:
          banner['title'] as String? ?? 'Share IPro & Get 10% Off Your Plan',
      bannerDescription: banner['description'] as String? ?? '',
      buttonText: banner['buttonText'] as String? ?? 'Share on LinkedIn',
      publishEndpoint: actions['publishEndpoint'] as String?,
    );
  }
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

  const LinkedInShareResult({
    required this.success,
    required this.message,
    this.requiresAuth = false,
    this.authorizationUrl,
    this.promoCode,
  });

  factory LinkedInShareResult.fromJson(Map<String, dynamic> json) {
    final success = json['success'] as bool? ?? false;
    final message = json['message'] as String? ?? '';
    final data = json['data'] as Map<String, dynamic>? ?? {};

    return LinkedInShareResult(
      success: success,
      message: message,
      requiresAuth: data['requiresAuth'] as bool? ?? false,
      authorizationUrl: data['authorizationUrl'] as String?,
      promoCode: data['promoCode'] as String?,
    );
  }
}
