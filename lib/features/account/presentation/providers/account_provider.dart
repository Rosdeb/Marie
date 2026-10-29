import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../data/models/profile_model.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/account_repository.dart';
import '../../data/repositories/account_repository_impl.dart';

class ProfileState {
  final String id;
  final String name;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String bio;
  final String avatarUrl;
  final String profileType;
  final String profession;
  final bool showFirstName;
  final bool showProfession;

  /// Consent to marketing e-mail. Off unless the subscriber agreed.
  final bool marketingEmails;
  final bool notificationsEnabled;
  final String referralCode;
  final int totalReferrals;
  final double referralEarnings;
  final bool isLoading;
  final String? errorMessage;

  ProfileState({
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
    this.referralCode = 'STUDY-PRO99',
    this.totalReferrals = 5,
    this.referralEarnings = 25.0,
    this.isLoading = false,
    this.errorMessage,
  });

  ProfileState copyWith({
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
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProfileState(
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
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AccountNotifier extends Notifier<ProfileState> {
  late final AccountRepository _repository;

  @override
  ProfileState build() {
    _repository = ref.watch(accountRepositoryProvider);
    Future.microtask(() => _initProfile());
    return ProfileState();
  }

  Future<void> _initProfile() async {
    try {
      final storage = ref.read(localStorageProvider);
      final localData = await storage.getUserData();
      final notificationsEnabled = await storage.getNotificationsEnabled();
      state = state.copyWith(notificationsEnabled: notificationsEnabled);
      if (localData != null) {
        _syncEntityToState(ProfileModel.fromJson(localData));
      }
    } catch (_) {}
    await fetchProfile();
  }

  Future<void> fetchProfile() async {
    try {
      final profile = await _repository.getMyProfile();
      _syncEntityToState(profile);
    } catch (_) {
      // Profile fetch may fail if not authenticated yet or offline
    }
  }

  void _syncEntityToState(ProfileEntity profile) {
    state = state.copyWith(
      id: profile.id,
      name: profile.name.isNotEmpty ? profile.name : state.name,
      firstName: profile.firstName,
      lastName: profile.lastName,
      email: profile.email.isNotEmpty ? profile.email : state.email,
      phone: profile.phone.isNotEmpty ? profile.phone : state.phone,
      bio: profile.bio.isNotEmpty ? profile.bio : state.bio,
      avatarUrl: profile.avatarUrl.isNotEmpty
          ? profile.avatarUrl
          : state.avatarUrl,
      profileType: profile.profileType,
      profession: profile.profession,
      showFirstName: profile.showFirstName,
      showProfession: profile.showProfession,
      marketingEmails: profile.marketingEmails,
      clearError: true,
    );
  }

  Future<bool> toggleNotifications(bool value) async {
    final enabled = await PushNotificationService.instance.setEnabled(value);
    state = state.copyWith(notificationsEnabled: enabled);
    return enabled;
  }

  void clear() {
    state = ProfileState();
  }

  Future<bool> updateProfile({
    required String name,
    required String email,
    required String phone,
    required String bio,
    String? firstName,
    String? lastName,
    String? profession,
    String? profileFilePath,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updated = await _repository.updateMyProfile(
        name: name,
        email: email,
        phoneNumber: phone,
        bio: bio,
        firstName: firstName,
        lastName: lastName,
        profession: profession,
        profileFilePath: profileFilePath,
      );
      _syncEntityToState(updated);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e
            .toString()
            .replaceFirst('ApiException: ', '')
            .replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> setProfileType(String profileType) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final success = await _repository.setProfileType(profileType);
      if (success) {
        state = state.copyWith(profileType: profileType, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
      return success;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e
            .toString()
            .replaceFirst('ApiException: ', '')
            .replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> updatePrivacySettings({
    required bool showFirstName,
    required bool showProfession,
    required bool marketingEmails,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updated = await _repository.updatePrivacySettings(
        showFirstName: showFirstName,
        showProfession: showProfession,
        marketingEmails: marketingEmails,
      );
      state = state.copyWith(
        showFirstName: updated.showFirstName,
        showProfession: updated.showProfession,
        marketingEmails: updated.marketingEmails,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e
            .toString()
            .replaceFirst('ApiException: ', '')
            .replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final success = await _repository.deleteAccount();
      if (success) {
        state = ProfileState();
      } else {
        state = state.copyWith(isLoading: false);
      }
      return success;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e
            .toString()
            .replaceFirst('ApiException: ', '')
            .replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }
}

final accountProvider = NotifierProvider<AccountNotifier, ProfileState>(
  AccountNotifier.new,
);
