import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/referral_models.dart';
import '../../data/repositories/referral_repository_impl.dart';
import '../../domain/repositories/referral_repository.dart';

class ReferralState {
  final SharePreviewModel sharePreview;
  final LinkedInStatusModel status;
  final bool isLoading;
  final bool isSharing;
  final bool isConnecting;
  final String? errorMessage;
  final String? activePromoCode;

  const ReferralState({
    this.sharePreview = const SharePreviewModel(),
    this.status = const LinkedInStatusModel(),
    this.isLoading = false,
    this.isSharing = false,
    this.isConnecting = false,
    this.errorMessage,
    this.activePromoCode,
  });

  ReferralState copyWith({
    SharePreviewModel? sharePreview,
    LinkedInStatusModel? status,
    bool? isLoading,
    bool? isSharing,
    bool? isConnecting,
    String? errorMessage,
    String? activePromoCode,
    bool clearError = false,
  }) {
    return ReferralState(
      sharePreview: sharePreview ?? this.sharePreview,
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
      isSharing: isSharing ?? this.isSharing,
      isConnecting: isConnecting ?? this.isConnecting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      activePromoCode: activePromoCode ?? this.activePromoCode,
    );
  }
}

class ReferralNotifier extends Notifier<ReferralState> {
  late final ReferralRepository _repository;

  @override
  ReferralState build() {
    _repository = ref.watch(referralRepositoryProvider);
    Future.microtask(() => fetchData());
    return const ReferralState(isLoading: true);
  }

  Future<void> fetchData() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final preview = await _repository.getSharePreview();
      final status = await _repository.getLinkedInStatus();

      final effectiveConnected =
          status.connected || preview.linkedinConnected;
      final effectiveStatus = LinkedInStatusModel(
        connected: effectiveConnected,
        memberUrn: status.memberUrn,
        shareRewardClaimed:
            status.shareRewardClaimed || preview.shareRewardClaimed,
        promoCode: status.promoCode ?? preview.promoCode,
      );

      state = state.copyWith(
        sharePreview: preview,
        status: effectiveStatus,
        activePromoCode: effectiveStatus.promoCode,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<String?> getLinkedInConnectUrl() async {
    try {
      return await _repository.getLinkedInAuthorizationUrl();
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return null;
    }
  }

  Future<bool> launchLinkedInAuthorization() async {
    state = state.copyWith(isConnecting: true, clearError: true);
    try {
      final urlStr = await _repository.getLinkedInAuthorizationUrl();
      if (urlStr != null && urlStr.isNotEmpty) {
        final uri = Uri.parse(urlStr);
        final launched =
            await launchUrl(uri, mode: LaunchMode.externalApplication);
        state = state.copyWith(isConnecting: false);
        return launched;
      }
      state = state.copyWith(
        isConnecting: false,
        errorMessage: 'Unable to retrieve LinkedIn authorization link.',
      );
    } catch (e) {
      state = state.copyWith(
        isConnecting: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
    return false;
  }

  Future<LinkedInShareResult> shareOnLinkedIn({String? postMessage}) async {
    state = state.copyWith(isSharing: true, clearError: true);
    try {
      final result =
          await _repository.shareOnLinkedIn(postMessage: postMessage);

      if (result.success) {
        final promo = result.promoCode ?? state.activePromoCode;
        final updatedStatus = LinkedInStatusModel(
          connected: true,
          memberUrn: state.status.memberUrn,
          shareRewardClaimed: true,
          promoCode: promo,
        );

        state = state.copyWith(
          isSharing: false,
          status: updatedStatus,
          activePromoCode: promo,
        );
        return result;
      }

      state = state.copyWith(isSharing: false);
      return result;
    } catch (e) {
      final err = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(isSharing: false, errorMessage: err);
      return LinkedInShareResult(success: false, message: err);
    }
  }

  Future<void> refreshStatus() async {
    try {
      final updatedStatus = await _repository.getLinkedInStatus();
      state = state.copyWith(
        status: updatedStatus,
        activePromoCode: updatedStatus.promoCode ?? state.activePromoCode,
      );
    } catch (_) {}
  }

  Future<bool> validatePromoCode(String code) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final resp = await _repository.validatePromoCode(code);
      final isSuccess = resp['success'] == true;
      state = state.copyWith(
        isLoading: false,
        activePromoCode: isSuccess ? code : state.activePromoCode,
      );
      return isSuccess;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> redeemPromoCode({
    required String code,
    required String tier,
    required String billingPeriod,
    required double discountAmount,
    required String currency,
  }) async {
    try {
      final req = RedeemRequestModel(
        code: code,
        tier: tier,
        billingPeriod: billingPeriod,
        discountAmount: discountAmount,
        currency: currency,
      );
      final resp = await _repository.redeemPromoCode(req);
      return resp['success'] == true;
    } catch (_) {
      return false;
    }
  }
}

final referralProvider = NotifierProvider<ReferralNotifier, ReferralState>(ReferralNotifier.new);
