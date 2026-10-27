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
  final String? errorMessage;
  final String? activePromoCode;

  const ReferralState({
    this.sharePreview = const SharePreviewModel(),
    this.status = const LinkedInStatusModel(),
    this.isLoading = false,
    this.isSharing = false,
    this.errorMessage,
    this.activePromoCode,
  });

  ReferralState copyWith({
    SharePreviewModel? sharePreview,
    LinkedInStatusModel? status,
    bool? isLoading,
    bool? isSharing,
    String? errorMessage,
    String? activePromoCode,
    bool clearError = false,
  }) {
    return ReferralState(
      sharePreview: sharePreview ?? this.sharePreview,
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
      isSharing: isSharing ?? this.isSharing,
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

      state = state.copyWith(
        sharePreview: preview,
        status: status,
        activePromoCode: status.promoCode,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<bool> launchLinkedInAuthorization() async {
    try {
      final urlStr = await _repository.getLinkedInAuthorizationUrl();
      if (urlStr != null && urlStr.isNotEmpty) {
        final uri = Uri.parse(urlStr);
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
    return false;
  }

  Future<LinkedInShareResult> shareOnLinkedIn({String? message}) async {
    state = state.copyWith(isSharing: true, clearError: true);
    try {
      final result = await _repository.shareOnLinkedIn(message: message);

      if (result.success) {
        // Automatically claim discount if not yet claimed
        try {
          final claimResp = await _repository.claimDiscount();
          final promo = claimResp['data']?['promoCode']?.toString();
          if (promo != null && promo.isNotEmpty) {
            state = state.copyWith(activePromoCode: promo);
          }
        } catch (_) {}

        final updatedStatus = await _repository.getLinkedInStatus();
        state = state.copyWith(
          isSharing: false,
          status: updatedStatus,
          activePromoCode: updatedStatus.promoCode ?? state.activePromoCode,
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

  Future<String?> claimDiscount() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final claimResp = await _repository.claimDiscount();
      final promo = claimResp['data']?['promoCode']?.toString();
      final updatedStatus = await _repository.getLinkedInStatus();

      state = state.copyWith(
        isLoading: false,
        status: updatedStatus,
        activePromoCode: promo ?? updatedStatus.promoCode,
      );
      return promo;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return null;
    }
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
}

final referralProvider =
    NotifierProvider<ReferralNotifier, ReferralState>(ReferralNotifier.new);
