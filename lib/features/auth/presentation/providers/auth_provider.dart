import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  final String? errorMessage;
  final bool isAuthenticated;
  final bool isSubscribed;

  AuthState({
    this.isLoading = false,
    this.authMode = AuthMode.initial,
    this.selectedPlan = 'yearly',
    this.selectedPaymentMethod = 'apple_pay',
    this.lastTransactionId,
    this.subscriptionDate,
    this.email,
    this.errorMessage,
    this.isAuthenticated = false,
    this.isSubscribed = false,
  });

  AuthState copyWith({
    bool? isLoading,
    AuthMode? authMode,
    String? selectedPlan,
    String? selectedPaymentMethod,
    String? lastTransactionId,
    DateTime? subscriptionDate,
    String? email,
    String? errorMessage,
    bool? isAuthenticated,
    bool? isSubscribed,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      authMode: authMode ?? this.authMode,
      selectedPlan: selectedPlan ?? this.selectedPlan,
      selectedPaymentMethod: selectedPaymentMethod ?? this.selectedPaymentMethod,
      lastTransactionId: lastTransactionId ?? this.lastTransactionId,
      subscriptionDate: subscriptionDate ?? this.subscriptionDate,
      email: email ?? this.email,
      errorMessage: errorMessage,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isSubscribed: isSubscribed ?? this.isSubscribed,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    return AuthState();
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

  Future<bool> loginWithGoogle() async {
    state = state.copyWith(authMode: AuthMode.loadingGoogle, isLoading: true);
    await Future.delayed(const Duration(milliseconds: 1500));
    state = state.copyWith(
      authMode: AuthMode.initial,
      isLoading: false,
      isAuthenticated: true,
    );
    return true;
  }

  Future<bool> loginWithApple() async {
    state = state.copyWith(authMode: AuthMode.loadingApple, isLoading: true);
    await Future.delayed(const Duration(milliseconds: 1500));
    state = state.copyWith(
      authMode: AuthMode.initial,
      isLoading: false,
      isAuthenticated: true,
    );
    return true;
  }

  Future<bool> loginWithEmail() async {
    state = state.copyWith(authMode: AuthMode.loadingEmail, isLoading: true);
    await Future.delayed(const Duration(milliseconds: 1500));
    state = state.copyWith(
      authMode: AuthMode.initial,
      isLoading: false,
      isAuthenticated: true,
    );
    return true;
  }

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, email: email);
    await Future.delayed(const Duration(milliseconds: 1500));
    state = state.copyWith(isLoading: false, isAuthenticated: true);
    return true;
  }

  Future<bool> signUp(String name, String email, String password) async {
    state = state.copyWith(isLoading: true, email: email);
    await Future.delayed(const Duration(milliseconds: 1500));
    state = state.copyWith(isLoading: false);
    return true;
  }

  Future<bool> sendOtp(String email) async {
    state = state.copyWith(isLoading: true, email: email);
    await Future.delayed(const Duration(milliseconds: 1500));
    state = state.copyWith(isLoading: false);
    return true;
  }

  Future<bool> verifyOtp(String otp) async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 1500));
    state = state.copyWith(isLoading: false);
    return true;
  }

  Future<bool> resetPassword(String newPassword) async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 1500));
    state = state.copyWith(isLoading: false);
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

  void logout() {
    state = AuthState();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

