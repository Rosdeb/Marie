import '../../domain/entities/privacy_settings_entity.dart';

class PrivacySettingsModel extends PrivacySettingsEntity {
  const PrivacySettingsModel({
    super.showFirstName = false,
    super.showProfession = false,
  });

  factory PrivacySettingsModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : json;
    return PrivacySettingsModel(
      showFirstName: data['showFirstName'] == true,
      showProfession: data['showProfession'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'showFirstName': showFirstName,
      'showProfession': showProfession,
    };
  }
}
