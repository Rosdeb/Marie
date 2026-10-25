import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';

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
      selectedPaymentMethod: selectedPaymentMethod ?? this.selectedPaymentMethod,
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
      state = state.copyWith(
        isAuthenticated: true,
        currentUser: user,
        email: user?.email,
      );
    }
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
      final user = await _authRepository.signIn(email: email, password: password);
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        currentUser: user,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('ApiException: ', '').replaceFirst('Exception: ', ''),
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
      state = state.copyWith(
        isLoading: false,
        tempToken: tempToken,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('ApiException: ', '').replaceFirst('Exception: ', ''),
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
        errorMessage: e.toString().replaceFirst('ApiException: ', '').replaceFirst('Exception: ', ''),
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
        errorMessage: e.toString().replaceFirst('ApiException: ', '').replaceFirst('Exception: ', ''),
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
        errorMessage: e.toString().replaceFirst('ApiException: ', '').replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> verifyForgotOtp(String otp) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final success = await _authRepository.forgotOtpVerify(
        otp: otp,
        resetToken: state.tempToken,
      );
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('ApiException: ', '').replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> resetPassword(String newPassword, [String? confirmPassword]) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final success = await _authRepository.resetPassword(
        newPassword: newPassword,
        confirmPassword: confirmPassword ?? newPassword,
        resetToken: state.tempToken,
      );
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('ApiException: ', '').replaceFirst('Exception: ', ''),
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
        errorMessage: e.toString().replaceFirst('ApiException: ', '').replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> loginWithGoogle() async {
    state = state.copyWith(authMode: AuthMode.loadingGoogle, isLoading: true);
    await Future.delayed(const Duration(milliseconds: 1000));
    state = state.copyWith(authMode: AuthMode.initial, isLoading: false, isAuthenticated: true);
    return true;
  }

  Future<bool> loginWithApple() async {
    state = state.copyWith(authMode: AuthMode.loadingApple, isLoading: true);
    await Future.delayed(const Duration(milliseconds: 1000));
    state = state.copyWith(authMode: AuthMode.initial, isLoading: false, isAuthenticated: true);
    return true;
  }

  Future<bool> loginWithEmail() async {
    state = state.copyWith(authMode: AuthMode.loadingEmail, isLoading: true);
    await Future.delayed(const Duration(milliseconds: 1000));
    state = state.copyWith(authMode: AuthMode.initial, isLoading: false, isAuthenticated: true);
    return true;
  }

  Future<bool> confirmSubscription() async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 1200));
    final randomId = 'MN-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
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
    await _authRepository.signOut();
    state = AuthState();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
