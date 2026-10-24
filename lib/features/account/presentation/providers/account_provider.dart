import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileState {
  final String name;
  final String email;
  final String phone;
  final String bio;
  final String avatarUrl;
  final bool notificationsEnabled;
  final String referralCode;
  final int totalReferrals;
  final double referralEarnings;
  final bool isLoading;

  ProfileState({
    this.name = 'Alex Morgan',
    this.email = 'alex.morgan@example.com',
    this.phone = '+1 (555) 234-5678',
    this.bio = 'Preparing for upcoming exams. Studying daily!',
    this.avatarUrl = 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=600',
    this.notificationsEnabled = true,
    this.referralCode = 'STUDY-ALEX99',
    this.totalReferrals = 5,
    this.referralEarnings = 25.0,
    this.isLoading = false,
  });

  ProfileState copyWith({
    String? name,
    String? email,
    String? phone,
    String? bio,
    String? avatarUrl,
    bool? notificationsEnabled,
    String? referralCode,
    int? totalReferrals,
    double? referralEarnings,
    bool? isLoading,
  }) {
    return ProfileState(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      referralCode: referralCode ?? this.referralCode,
      totalReferrals: totalReferrals ?? this.totalReferrals,
      referralEarnings: referralEarnings ?? this.referralEarnings,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AccountNotifier extends Notifier<ProfileState> {
  @override
  ProfileState build() {
    return ProfileState();
  }

  void toggleNotifications(bool value) {
    state = state.copyWith(notificationsEnabled: value);
  }

  Future<bool> updateProfile({
    required String name,
    required String email,
    required String phone,
    required String bio,
  }) async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 1000));
    state = state.copyWith(
      name: name,
      email: email,
      phone: phone,
      bio: bio,
      isLoading: false,
    );
    return true;
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 1000));
    state = state.copyWith(isLoading: false);
    return true;
  }

  Future<bool> deleteAccount() async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 1200));
    state = ProfileState();
    return true;
  }
}

final accountProvider = NotifierProvider<AccountNotifier, ProfileState>(AccountNotifier.new);
