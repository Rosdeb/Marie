import '../entities/privacy_settings_entity.dart';
import '../entities/profile_entity.dart';

abstract class AccountRepository {
  Future<ProfileEntity> getMyProfile();

  Future<ProfileEntity> updateMyProfile({
    String? name,
    String? firstName,
    String? lastName,
    String? profession,
    String? email,
    String? phoneNumber,
    String? bio,
    String? profileFilePath,
  });

  Future<bool> setProfileType(String profileType);

  Future<PrivacySettingsEntity> getPrivacySettings();

  Future<PrivacySettingsEntity> updatePrivacySettings({
    required bool showFirstName,
    required bool showProfession,
    required bool marketingEmails,
  });

  Future<bool> deleteAccount();
}
