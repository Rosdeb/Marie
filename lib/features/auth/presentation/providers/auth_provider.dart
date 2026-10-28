import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../domain/entities/user_entity.dart';
import '../../data/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/services/google_sign_in_service.dart';
import '../../data/services/apple_sign_in_service.dart';
import '../../../account/presentation/providers/account_provider.dart';
import '../../../bottom_nav/presentation/providers/bottom_nav_provider.dart';
import '../../../home/presentation/providers/notification_provider.dart';
import '../../../subscription/data/services/revenuecat_purchase_service.dart';

enum AuthMode {
  initial,
  loadingGoogle,
  loadingApple,
  loadingEmail,
  loadingSubmit,
}

class AuthState {
  final bool isLoading;
  final AuthMode authMode;
  final String selectedPlan;
  final String selectedPaymentMethod;
  final String? lastTransactionId;
  final DateTime? subscriptionDate;
  final String? email;
  final String? tempToken;
  final String? errorMessage;
  final bool isAuthenticated;
  final bool isSubscribed;
  final UserEntity? currentUser;

  AuthState({
    this.isLoading = false,
    this.authMode = AuthMode.initial,
    this.selectedPlan = 'yearly',
    this.selectedPaymentMethod = 'apple_pay',
    this.lastTransactionId,
    this.subscriptionDate,
    this.email,
    this.tempToken,
    this.errorMessage,
    this.isAuthenticated = false,
    this.isSubscribed = false,
    this.currentUser,
  });

  AuthState copyWith({
    bool? isLoading,
    AuthMode? authMode,
    String? selectedPlan,
    String? selectedPaymentMethod,
    String? lastTransactionId,
    DateTime? subscriptionDate,
    String? email,
    String? tempToken,
    String? errorMessage,
    bool? isAuthenticated,
    bool? isSubscribed,
    UserEntity? currentUser,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      authMode: authMode ?? this.authMode,
      selectedPlan: selectedPlan ?? this.selectedPlan,
      selectedPaymentMethod:
          selectedPaymentMethod ?? this.selectedPaymentMethod,
      lastTransactionId: lastTransactionId ?? this.lastTransactionId,
      subscriptionDate: subscriptionDate ?? this.subscriptionDate,
      email: email ?? this.email,
      tempToken: tempToken ?? this.tempToken,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isSubscribed: isSubscribed ?? this.isSubscribed,
      currentUser: currentUser ?? this.currentUser,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  late final AuthRepository _authRepository;

  @override
  AuthState build() {
    _authRepository = ref.watch(authRepositoryProvider);
    Future.microtask(() => _initAuth());
    return AuthState();
  }

  Future<void> _initAuth() async {
    final isAuth = await _authRepository.isAuthenticated();
    if (isAuth) {
      final user = await _authRepository.getCurrentUser();
      if (user != null && user.id.isNotEmpty) {
        ref.read(revenueCatServiceProvider).logIn(user.id);
      }
      state = state.copyWith(
        isAuthenticated: true,
        currentUser: user,
        email: user?.email,
      );
      return;
    }

    final firebaseUser = GoogleSignInService.currentUser;
    if (firebaseUser != null) {
      final user = _userFromFirebase(firebaseUser);
      ref.read(revenueCatServiceProvider).logIn(user.id);
      state = state.copyWith(
        isAuthenticated: true,
        currentUser: user,
        email: user.email,
      );
    }
  }

  UserEntity _userFromFirebase(firebase_auth.User user) {
    return UserEntity(
      id: user.uid,
      name: user.displayName ?? user.email?.split('@').first ?? 'Google User',
      email: user.email ?? '',
      phoneNumber: user.phoneNumber,
      profileUrl: user.photoURL,
      role: 'user',
    );
  }

  void selectPlan(String plan) {
    state = state.copyWith(selectedPlan: plan);
  }

  void selectPaymentMethod(String method) {
    state = state.copyWith(selectedPaymentMethod: method);
  }

  void setEmail(String email) {
    state = state.copyWith(email: email);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, email: email, clearError: true);
    try {
      final user = await _authRepository.signIn(
        email: email,
        password: password,
      );
      if (user.id.isNotEmpty) {
        ref.read(revenueCatServiceProvider).logIn(user.id);
      }
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        currentUser: user,
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

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
    String profileType = 'Attorney',
  }) async {
    state = state.copyWith(isLoading: true, email: email, clearError: true);
    try {
      final tempToken = await _authRepository.signUp(
        name: name,
        email: email,
        password: password,
        profileType: profileType,
      );
      state = state.copyWith(isLoading: false, tempToken: tempToken);
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

  Future<bool> verifyOtp(String otp) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final success = await _authRepository.verifyOtp(
        otp: otp,
        signupToken: state.tempToken,
      );
      final user = await _authRepository.getCurrentUser();
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: success,
        currentUser: user,
      );
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

  Future<bool> resendOtp([String? email]) async {
    final targetEmail = email ?? state.email;
    if (targetEmail == null || targetEmail.isEmpty) return false;
    try {
      return await _authRepository.resendOtp(email: targetEmail);
    } catch (e) {
      state = state.copyWith(
        errorMessage: e
            .toString()
            .replaceFirst('ApiException: ', '')
            .replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> sendOtp(String email) async {
    state = state.copyWith(isLoading: true, email: email, clearError: true);
    try {
      final resetToken = await _authRepository.forgotPassword(email: email);
      state = state.copyWith(isLoading: false, tempToken: resetToken);
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

  Future<bool> verifyForgotOtp(String otp) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final token = state.tempToken ?? await _authRepository.getTempToken();
      final success = await _authRepository.forgotOtpVerify(
        otp: otp,
        resetToken: token,
      );
      final updatedToken = await _authRepository.getTempToken() ?? token;
      state = state.copyWith(isLoading: false, tempToken: updatedToken);
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

  Future<bool> resetPassword(
    String newPassword, [
    String? confirmPassword,
  ]) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final token = state.tempToken ?? await _authRepository.getTempToken();
      final success = await _authRepository.resetPassword(
        newPassword: newPassword,
        confirmPassword: confirmPassword ?? newPassword,
        resetToken: token,
      );
      state = state.copyWith(isLoading: false, tempToken: null);
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

  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final success = await _authRepository.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      state = state.copyWith(isLoading: false);
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

  String _cleanErrorMessage(Object error, {required String defaultMessage}) {
    if (error is firebase_auth.FirebaseAuthException) {
      switch (error.code) {
        case 'account-exists-with-different-credential':
          return 'An account already exists with this email using a different sign-in method.';
        case 'invalid-credential':
          return 'Invalid sign-in credentials. Please try again.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        case 'missing-google-id-token':
          return 'Google could not provide a valid ID token. Please try again.';
        case 'ERROR_INVALID_ID_TOKEN':
          return 'Apple could not provide a valid identity token. Please try again.';
        default:
          return error.message ?? defaultMessage;
      }
    }
    final raw = error
        .toString()
        .replaceFirst('ApiException: ', '')
        .replaceFirst('ServerException: ', '')
        .replaceFirst('AuthException: ', '')
        .replaceFirst('NetworkException: ', '')
        .replaceFirst('Exception: ', '')
        .trim();
    if (raw.isNotEmpty && raw != 'Something went wrong') {
      return raw;
    }
    return defaultMessage;
  }

  Future<bool> loginWithGoogle() async {
    state = state.copyWith(
      authMode: AuthMode.loadingGoogle,
      isLoading: true,
      clearError: true,
    );
    try {
      final result = await GoogleSignInService.signInWithGoogle();
      if (result == null) {
        state = state.copyWith(
          authMode: AuthMode.initial,
          isLoading: false,
          clearError: true,
        );
        return false;
      }

      final idToken = result['idToken'] as String?;
      if (idToken == null || idToken.isEmpty) {
        throw Exception('Google ID token is missing');
      }

      final user = await _authRepository.googleLogin(idToken);
      final finalUser = user.id.isNotEmpty
          ? user
          : UserModel(
              id: result['uid']?.toString() ?? '',
              name: result['displayName']?.toString() ?? 'Google User',
              email: result['email']?.toString() ?? '',
            );
      if (finalUser.id.isNotEmpty) {
        ref.read(revenueCatServiceProvider).logIn(finalUser.id);
      }
      state = state.copyWith(
        authMode: AuthMode.initial,
        isLoading: false,
        isAuthenticated: true,
        currentUser: finalUser,
        email: finalUser.email,
        clearError: true,
      );
      return true;
    } catch (error) {
      final message = _cleanErrorMessage(
        error,
        defaultMessage: 'Google sign-in could not be completed. Please try again.',
      );
      state = state.copyWith(
        authMode: AuthMode.initial,
        isLoading: false,
        errorMessage: message,
      );
      return false;
    }
  }

  Future<bool> loginWithApple() async {
    state = state.copyWith(
      authMode: AuthMode.loadingApple,
      isLoading: true,
      clearError: true,
    );
    try {
      final result = await AppleSignInService.signInWithApple();
      if (result == null) {
        state = state.copyWith(
          authMode: AuthMode.initial,
          isLoading: false,
          clearError: true,
        );
        return false;
      }

      final identityToken = result['identityToken'] as String?;
      if (identityToken == null || identityToken.isEmpty) {
        throw Exception('Apple identity token is missing');
      }

      final firstName = result['firstName'] as String?;
      final lastName = result['lastName'] as String?;
      final email = result['email'] as String?;

      final user = await _authRepository.appleLogin(
        identityToken: identityToken,
        firstName: firstName,
        lastName: lastName,
        email: email,
      );

      final finalUser = user.id.isNotEmpty
          ? user
          : UserModel(
              id: result['uid']?.toString() ?? '',
              name: [firstName, lastName]
                      .where((s) => s != null && s.isNotEmpty)
                      .join(' ')
                      .trim()
                      .isNotEmpty
                  ? [firstName, lastName].where((s) => s != null && s.isNotEmpty).join(' ')
                  : 'Apple User',
              email: email ?? '',
            );
      if (finalUser.id.isNotEmpty) {
        ref.read(revenueCatServiceProvider).logIn(finalUser.id);
      }
      state = state.copyWith(
        authMode: AuthMode.initial,
        isLoading: false,
        isAuthenticated: true,
        currentUser: finalUser,
        email: finalUser.email,
        clearError: true,
      );
      return true;
    } catch (error) {
      final message = _cleanErrorMessage(
        error,
        defaultMessage: 'Apple sign-in could not be completed. Please try again.',
      );
      state = state.copyWith(
        authMode: AuthMode.initial,
        isLoading: false,
        errorMessage: message,
      );
      return false;
    }
  }

  Future<bool> loginWithEmail() async {
    state = state.copyWith(authMode: AuthMode.loadingEmail, isLoading: true);
    await Future.delayed(const Duration(milliseconds: 1000));
    state = state.copyWith(
      authMode: AuthMode.initial,
      isLoading: false,
      isAuthenticated: true,
    );
    return true;
  }

  Future<bool> confirmSubscription() async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 1200));
    final randomId =
        'MN-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    state = state.copyWith(
      isLoading: false,
      isAuthenticated: true,
      isSubscribed: true,
      lastTransactionId: randomId,
      subscriptionDate: DateTime.now(),
    );
    return true;
  }

  Future<void> logout() async {
    try {
      await Future.wait([
        GoogleSignInService.signOut(),
        AppleSignInService.signOut(),
      ]);
    } catch (_) {}
    try {
      await _authRepository.signOut();
    } catch (_) {}
    try {
      ref.read(revenueCatServiceProvider).logOut();
    } catch (_) {}
    state = AuthState();
    try {
      ref.read(accountProvider.notifier).clear();
    } catch (_) {}
    try {
      ref.read(notificationProvider.notifier).clearAll();
    } catch (_) {}
    try {
      ref.read(bottomNavProvider.notifier).changeIndex(0);
    } catch (_) {}
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
