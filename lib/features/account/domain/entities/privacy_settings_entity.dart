class PrivacySettingsEntity {
  final bool showFirstName;
  final bool showProfession;

  const PrivacySettingsEntity({
    this.showFirstName = false,
    this.showProfession = false,
  });

  PrivacySettingsEntity copyWith({
    bool? showFirstName,
    bool? showProfession,
  }) {
    return PrivacySettingsEntity(
      showFirstName: showFirstName ?? this.showFirstName,
      showProfession: showProfession ?? this.showProfession,
    );
  }
}
