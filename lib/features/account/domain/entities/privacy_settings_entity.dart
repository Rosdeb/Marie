class PrivacySettingsEntity {
  final bool showFirstName;
  final bool showProfession;

  /// Consent to marketing e-mail. Off unless the user actively agreed, and
  /// withdrawable here at any time.
  final bool marketingEmails;

  const PrivacySettingsEntity({
    this.showFirstName = false,
    this.showProfession = false,
    this.marketingEmails = false,
  });

  PrivacySettingsEntity copyWith({
    bool? showFirstName,
    bool? showProfession,
    bool? marketingEmails,
  }) {
    return PrivacySettingsEntity(
      showFirstName: showFirstName ?? this.showFirstName,
      showProfession: showProfession ?? this.showProfession,
      marketingEmails: marketingEmails ?? this.marketingEmails,
    );
  }
}
