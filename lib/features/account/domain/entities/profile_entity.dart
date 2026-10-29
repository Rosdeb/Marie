class ProfileEntity {
  final String id;
  final String name;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String bio;
  final String avatarUrl;
  final String profileType; // 'Attorney' | 'Paralegal'
  final String profession;
  final bool showFirstName;
  final bool showProfession;
  /// Consent to marketing e-mail; off unless the user agreed.
  final bool marketingEmails;
  final bool notificationsEnabled;
  final String referralCode;
  final int totalReferrals;
  final double referralEarnings;

  const ProfileEntity({
    this.id = '',
    this.name = '',
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.phone = '',
    this.bio = '',
    this.avatarUrl = '',
    this.profileType = 'Attorney',
    this.profession = '',
    this.showFirstName = false,
    this.showProfession = false,
    this.marketingEmails = false,
    this.notificationsEnabled = true,
    this.referralCode = '',
    this.totalReferrals = 0,
    this.referralEarnings = 0.0,
  });

  ProfileEntity copyWith({
    String? id,
    String? name,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? bio,
    String? avatarUrl,
    String? profileType,
    String? profession,
    bool? showFirstName,
    bool? showProfession,
    bool? marketingEmails,
    bool? notificationsEnabled,
    String? referralCode,
    int? totalReferrals,
    double? referralEarnings,
  }) {
    return ProfileEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      profileType: profileType ?? this.profileType,
      profession: profession ?? this.profession,
      showFirstName: showFirstName ?? this.showFirstName,
      showProfession: showProfession ?? this.showProfession,
      marketingEmails: marketingEmails ?? this.marketingEmails,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      referralCode: referralCode ?? this.referralCode,
      totalReferrals: totalReferrals ?? this.totalReferrals,
      referralEarnings: referralEarnings ?? this.referralEarnings,
    );
  }
}
