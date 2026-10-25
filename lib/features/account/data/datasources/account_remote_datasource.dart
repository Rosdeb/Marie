import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/privacy_settings_model.dart';
import '../models/profile_model.dart';

abstract class AccountRemoteDataSource {
  Future<ProfileModel> getMyProfile();
  Future<ProfileModel> updateMyProfile({
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
  Future<PrivacySettingsModel> getPrivacySettings();
  Future<PrivacySettingsModel> updatePrivacySettings({
    required bool showFirstName,
    required bool showProfession,
  });
  Future<bool> deleteAccount();
}

class AccountRemoteDataSourceImpl implements AccountRemoteDataSource {
  final ApiClient apiClient;

  AccountRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<ProfileModel> getMyProfile() async {
    final response = await apiClient.get(
      ApiConstants.myProfile,
      requiresAuth: true,
    );
    return ProfileModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<ProfileModel> updateMyProfile({
    String? name,
    String? firstName,
    String? lastName,
    String? profession,
    String? email,
    String? phoneNumber,
    String? bio,
    String? profileFilePath,
  }) async {
    final fields = <String, String>{};
    if (name != null && name.trim().isNotEmpty) fields['name'] = name.trim();
    if (firstName != null && firstName.trim().isNotEmpty) fields['firstName'] = firstName.trim();
    if (lastName != null && lastName.trim().isNotEmpty) fields['lastName'] = lastName.trim();
    if (profession != null && profession.trim().isNotEmpty) fields['profession'] = profession.trim();
    if (email != null && email.trim().isNotEmpty) fields['email'] = email.trim();
    if (phoneNumber != null && phoneNumber.trim().isNotEmpty) fields['phoneNumber'] = phoneNumber.trim();
    if (bio != null && bio.trim().isNotEmpty) fields['bio'] = bio.trim();

    final response = await apiClient.multipartPatch(
      ApiConstants.updateMyProfile,
      fields: fields,
      fileField: 'profile',
      filePath: profileFilePath,
      requiresAuth: true,
    );
    return ProfileModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<bool> setProfileType(String profileType) async {
    final response = await apiClient.patch(
      ApiConstants.profileType,
      body: {'profileType': profileType},
      requiresAuth: true,
    );
    return response['success'] == true;
  }

  @override
  Future<PrivacySettingsModel> getPrivacySettings() async {
    final response = await apiClient.get(
      ApiConstants.privacySettings,
      requiresAuth: true,
    );
    return PrivacySettingsModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<PrivacySettingsModel> updatePrivacySettings({
    required bool showFirstName,
    required bool showProfession,
  }) async {
    final response = await apiClient.patch(
      ApiConstants.privacySettings,
      body: {
        'showFirstName': showFirstName,
        'showProfession': showProfession,
      },
      requiresAuth: true,
    );
    return PrivacySettingsModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<bool> deleteAccount() async {
    final response = await apiClient.delete(
      ApiConstants.deleteAccount,
      requiresAuth: true,
    );
    return response['success'] == true;
  }
}

final accountRemoteDataSourceProvider = Provider<AccountRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AccountRemoteDataSourceImpl(apiClient: apiClient);
});
