import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
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
  final Uint8List? avatarBytes;
  final String profileType;
  final String profession;
  // Point 1.4: the firm and the city, typed and optional; the country
  // chosen from a list. Shown on the dashboard profile (8.6).
  final String company;
  final String city;
  final String country;

  /// The offices the person works on, by code.
  ///
  /// Point 1.4, and Marie's Part 2 Profile section: "the offices I work on
  /// chosen from a list". Not a purchase - it personalises Home and Practice.
  final List<String> worksOnOffices;
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
    this.avatarBytes,
    this.profileType = 'Attorney',
    this.profession = '',
    this.company = '',
    this.city = '',
    this.country = '',
    this.worksOnOffices = const [],
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
    Uint8List? avatarBytes,
    bool clearAvatarBytes = false,
    String? profileType,
    String? profession,
    String? company,
    String? city,
    String? country,
    List<String>? worksOnOffices,
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
      avatarBytes: clearAvatarBytes ? null : (avatarBytes ?? this.avatarBytes),
      profileType: profileType ?? this.profileType,
      profession: profession ?? this.profession,
      company: company ?? this.company,
      city: city ?? this.city,
      country: country ?? this.country,
      worksOnOffices: worksOnOffices ?? this.worksOnOffices,
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
  late AccountRepository _repository;

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
      final cachedAvatar = await storage.getCachedAvatar();

      Uint8List? avatarBytes;
      String? cachedUrl;
      if (cachedAvatar != null) {
        cachedUrl = cachedAvatar['url'] as String?;
        avatarBytes = cachedAvatar['bytes'] as Uint8List?;
      }

      state = state.copyWith(
        notificationsEnabled: notificationsEnabled,
        avatarUrl: cachedUrl,
        avatarBytes: avatarBytes,
      );

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
    final newAvatarUrl = profile.avatarUrl.trim();
    final urlChanged = newAvatarUrl.isNotEmpty && newAvatarUrl != state.avatarUrl;
    final needsDownload = newAvatarUrl.isNotEmpty && (urlChanged || state.avatarBytes == null);

    state = state.copyWith(
      id: profile.id,
      name: profile.name.isNotEmpty ? profile.name : state.name,
      firstName: profile.firstName,
      lastName: profile.lastName,
      email: profile.email.isNotEmpty ? profile.email : state.email,
      phone: profile.phone.isNotEmpty ? profile.phone : state.phone,
      bio: profile.bio.isNotEmpty ? profile.bio : state.bio,
      avatarUrl: newAvatarUrl.isNotEmpty ? newAvatarUrl : state.avatarUrl,
      // If URL has not changed, existing avatarBytes are preserved
      profileType: profile.profileType,
      profession: profile.profession,
      company: profile.company,
      city: profile.city,
      country: profile.country,
      showFirstName: profile.showFirstName,
      showProfession: profile.showProfession,
      marketingEmails: profile.marketingEmails,
      clearError: true,
    );

    // Only download if the avatar picture actually changed or isn't cached yet
    if (needsDownload) {
      _downloadAndCacheAvatar(newAvatarUrl);
    }
  }

  Future<void> _downloadAndCacheAvatar(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        final storage = ref.read(localStorageProvider);
        await storage.saveCachedAvatar(url: url, bytes: response.bodyBytes);
        // Only update state if this is still the active avatar URL
        if (state.avatarUrl == url) {
          state = state.copyWith(avatarBytes: response.bodyBytes);
        }
      }
    } catch (_) {
      // Offline or network error; keep existing state
    }
  }

  Future<bool> toggleNotifications(bool value) async {
    final enabled = await PushNotificationService.instance.setEnabled(value);
    state = state.copyWith(notificationsEnabled: enabled);
    return enabled;
  }

  void clear() {
    try {
      ref.read(localStorageProvider).clearCachedAvatar();
    } catch (_) {}
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
    String? company,
    String? city,
    String? country,
    /// The offices the person works on - "chosen from a list", point 1.4 and
    /// Marie's Part 2 Profile section. Not what they have paid for: this
    /// personalises Home and Practice and buys nothing.
    List<String>? worksOnOffices,
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
        company: company,
        city: city,
        country: country,
        profileFilePath: profileFilePath,
      );

      // If a local image file was uploaded, cache its bytes immediately
      if (profileFilePath != null && profileFilePath.isNotEmpty) {
        try {
          final file = File(profileFilePath);
          if (file.existsSync()) {
            final bytes = await file.readAsBytes();
            final storage = ref.read(localStorageProvider);
            await storage.saveCachedAvatar(url: updated.avatarUrl, bytes: bytes);
            state = state.copyWith(avatarBytes: bytes);
          }
        } catch (_) {}
      }

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
