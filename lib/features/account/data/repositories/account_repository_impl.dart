import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/local_storage.dart';
import '../../domain/entities/privacy_settings_entity.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/account_repository.dart';
import '../datasources/account_remote_datasource.dart';

class AccountRepositoryImpl implements AccountRepository {
  final AccountRemoteDataSource remoteDataSource;
  final LocalStorage localStorage;

  AccountRepositoryImpl({
    required this.remoteDataSource,
    required this.localStorage,
  });

  @override
  Future<ProfileEntity> getMyProfile() async {
    final profile = await remoteDataSource.getMyProfile();
    await localStorage.saveUserData(profile.toJson());
    return profile;
  }

  @override
  Future<ProfileEntity> updateMyProfile({
    String? name,
    String? firstName,
    String? lastName,
    String? profession,
    String? email,
    String? phoneNumber,
    String? bio,
    String? profileFilePath,
  }) async {
    final updated = await remoteDataSource.updateMyProfile(
      name: name,
      firstName: firstName,
      lastName: lastName,
      profession: profession,
      email: email,
      phoneNumber: phoneNumber,
      bio: bio,
      profileFilePath: profileFilePath,
    );
    await localStorage.saveUserData(updated.toJson());
    return updated;
  }

  @override
  Future<bool> setProfileType(String profileType) async {
    return await remoteDataSource.setProfileType(profileType);
  }

  @override
  Future<PrivacySettingsEntity> getPrivacySettings() async {
    return await remoteDataSource.getPrivacySettings();
  }

  @override
  Future<PrivacySettingsEntity> updatePrivacySettings({
    required bool showFirstName,
    required bool showProfession,
    required bool marketingEmails,
  }) async {
    return await remoteDataSource.updatePrivacySettings(
      showFirstName: showFirstName,
      showProfession: showProfession,
      marketingEmails: marketingEmails,
    );
  }

  @override
  Future<bool> deleteAccount() async {
    final result = await remoteDataSource.deleteAccount();
    if (result) {
      await localStorage.clearAuth();
    }
    return result;
  }
}

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  final remoteDataSource = ref.watch(accountRemoteDataSourceProvider);
  final localStorage = ref.watch(localStorageProvider);
  return AccountRepositoryImpl(
    remoteDataSource: remoteDataSource,
    localStorage: localStorage,
  );
});
