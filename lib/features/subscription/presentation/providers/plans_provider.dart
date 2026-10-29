import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../data/models/revenuecat_plan_models.dart';
import '../../data/models/subscription_models.dart';
import '../../data/repositories/subscription_repository_impl.dart';
import '../../data/services/revenuecat_purchase_service.dart';
import '../../domain/entities/entitlement_entity.dart';
import '../../domain/repositories/subscription_repository.dart';
import 'entitlement_provider.dart';
import '../../../referral/presentation/providers/referral_provider.dart';

class PlansState {
  final bool isLoading;
  final bool isPurchasing;
  final bool isRestoring;
  final String? errorMessage;
  final List<RevenueCatPlanGroup> planGroups;
  final Map<PlanTier, PlanBillingInterval> selectedIntervals;

  const PlansState({
    this.isLoading = false,
    this.isPurchasing = false,
    this.isRestoring = false,
    this.errorMessage,
    this.planGroups = const [],
    this.selectedIntervals = const {
      PlanTier.focus: PlanBillingInterval.annual,
      PlanTier.track: PlanBillingInterval.annual,
      PlanTier.majors: PlanBillingInterval.annual,
      PlanTier.global: PlanBillingInterval.annual,
    },
  });

  PlansState copyWith({
    bool? isLoading,
    bool? isPurchasing,
    bool? isRestoring,
    String? errorMessage,
    List<RevenueCatPlanGroup>? planGroups,
    Map<PlanTier, PlanBillingInterval>? selectedIntervals,
    bool clearError = false,
  }) {
    return PlansState(
      isLoading: isLoading ?? this.isLoading,
      isPurchasing: isPurchasing ?? this.isPurchasing,
      isRestoring: isRestoring ?? this.isRestoring,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      planGroups: planGroups ?? this.planGroups,
      selectedIntervals: selectedIntervals ?? this.selectedIntervals,
    );
  }
}

class PlansNotifier extends Notifier<PlansState> {
  late final RevenueCatPurchaseService _purchaseService;
  late final SubscriptionRepository _repository;

  @override
  PlansState build() {
    _purchaseService = ref.watch(revenueCatServiceProvider);
    _repository = ref.watch(subscriptionRepositoryProvider);
    Future.microtask(() => loadOfferings());
    return const PlansState(isLoading: true);
  }

  Future<void> loadOfferings() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // 1. Fetch Plan details from Backend API
      List<PlanModel>? apiPlans;
      try {
        apiPlans = await _repository.getPlans();
        debugPrint(
          '[Plans] API plans loaded: ${apiPlans.map((p) => '${p.name} (${p.currency} ${p.priceMonthly}/mo)').toList()}',
        );
      } catch (e) {
        debugPrint('[Plans] API getPlans failed (using defaults): $e');
      }

      // 2. Fetch Offerings & Packages from RevenueCat
      Offerings? offerings;
      try {
        offerings = await _purchaseService.getOfferings();
        debugPrint('[RevenueCat] Offerings received: ${offerings?.all.keys.toList()}');
      } catch (e) {
        debugPrint('[RevenueCat] getOfferings failed: $e');
      }

      // 3. Merge: API metadata (name, subtitle, fallback price) + RevenueCat store prices & packages
      //
      // A subscriber holding an unused promo code is shown the discounted
      // products. The discount cannot be applied at checkout - neither store
      // can take a percentage off a subscription - so it is a second set of
      // products at the lower price.
      final hasPromoCode =
          (ref.read(referralProvider).activePromoCode ?? '').isNotEmpty;

      final groups = RevenueCatPlanGroup.fromOfferings(
        offerings,
        apiPlans: apiPlans,
        useReferralOffering: hasPromoCode,
      );
      for (final g in groups) {
        debugPrint(
          '[Plans] Plan ${g.title}: Monthly=${g.monthlyPriceString} (pkg: ${g.monthlyPackage?.identifier}), Annual=${g.annualPriceString} (pkg: ${g.annualPackage?.identifier})',
        );
      }

      state = state.copyWith(
        isLoading: false,
        planGroups: groups,
      );
    } catch (e) {
      debugPrint('[RevenueCat] loadOfferings error: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to load subscription offerings. Please check your connection.',
      );
    }
  }

  void selectInterval(PlanTier tier, PlanBillingInterval interval) {
    final updated = Map<PlanTier, PlanBillingInterval>.from(state.selectedIntervals);
    updated[tier] = interval;
    state = state.copyWith(selectedIntervals: updated);
  }

  /// Tells the server that a promo code was spent on this purchase.
  ///
  /// The discount itself is applied inside the App Store or Google Play, and
  /// neither of them tells our server anything about it. Without this call a
  /// code stays "unlocked" for ever and the dashboard never shows a single
  /// redemption, so it runs after every successful purchase where the
  /// subscriber was holding a code.
  ///
  /// It is deliberately quiet: the purchase has already gone through, and a
  /// failure to record it must not look to the subscriber like a failed
  /// payment. The endpoint is idempotent, so a retry costs nothing.
  Future<void> _reportRedemption(PlanTier tier, PlanBillingInterval interval) async {
    try {
      final code = ref.read(referralProvider).activePromoCode;
      if (code == null || code.isEmpty) return;

      await ref.read(referralProvider.notifier).redeemPromoCode(
            code: code,
            tier: tier.name,
            billingPeriod: interval == PlanBillingInterval.annual
                ? 'yearly'
                : 'monthly',
            discountAmount: 0,
            currency: '',
          );
    } catch (_) {
      // Never surfaced: see above.
    }
  }

  Future<bool> purchasePlan(PlanTier tier) async {
    final plan = state.planGroups.firstWhere((p) => p.tier == tier);
    final interval = state.selectedIntervals[tier] ?? PlanBillingInterval.annual;
    final package = plan.getPackage(interval);

    // In RC test mode (with Web Test Store key) or if package is null:
    // Native mobile StoreKit / Google Play sheets cannot open with a test_ key.
    // Simulate successful purchase with a realistic delay and unlock mock entitlement.
    if (package == null || RevenueCatPurchaseService.isRcTest) {
      state = state.copyWith(isPurchasing: true);
      await Future.delayed(const Duration(milliseconds: 1000));
      try {
        await ref.read(entitlementProvider.notifier).syncFromRevenueCat();
      } catch (_) {}

      final currentEntitlement = ref.read(entitlementProvider);
      if (!currentEntitlement.isActive || currentEntitlement.planId != tier) {
        ref.read(entitlementProvider.notifier).setMockPlanForTesting(
          tier: tier,
          status: SubscriptionStatus.active,
        );
      }
      state = state.copyWith(isPurchasing: false);
      return true;
    }

    state = state.copyWith(isPurchasing: true, clearError: true);
    try {
      final result = await _purchaseService.purchasePackage(package);
      state = state.copyWith(isPurchasing: false);

      if (result != null) {
        // Sync with backend to refresh access
        await ref.read(entitlementProvider.notifier).syncFromRevenueCat();
        await _reportRedemption(tier, interval);
        return true;
      }
      return false; // User cancelled
    } catch (e) {
      // In test mode fallback if native store rejects test key
      if (RevenueCatPurchaseService.isRcTest) {
        ref.read(entitlementProvider.notifier).setMockPlanForTesting(
          tier: tier,
          status: SubscriptionStatus.active,
        );
        state = state.copyWith(isPurchasing: false);
        return true;
      }

      state = state.copyWith(
        isPurchasing: false,
        errorMessage: 'Purchase could not be completed. Please try again.',
      );
      return false;
    }
  }

  Future<bool> restorePurchases() async {
    state = state.copyWith(isRestoring: true, clearError: true);
    try {
      if (RevenueCatPurchaseService.isRcTest) {
        await Future.delayed(const Duration(milliseconds: 800));
        ref.read(entitlementProvider.notifier).setMockPlanForTesting(
          tier: PlanTier.global,
          status: SubscriptionStatus.active,
        );
        state = state.copyWith(isRestoring: false);
        return true;
      }

      final customerInfo = await _purchaseService.restorePurchases();
      state = state.copyWith(isRestoring: false);

      if (customerInfo != null && customerInfo.entitlements.active.isNotEmpty) {
        await ref.read(entitlementProvider.notifier).syncFromRevenueCat();
        return true;
      }
      return false;
    } catch (e) {
      if (RevenueCatPurchaseService.isRcTest) {
        ref.read(entitlementProvider.notifier).setMockPlanForTesting(
          tier: PlanTier.global,
          status: SubscriptionStatus.active,
        );
        state = state.copyWith(isRestoring: false);
        return true;
      }

      state = state.copyWith(
        isRestoring: false,
        errorMessage: 'Unable to restore purchases at this time.',
      );
      return false;
    }
  }
}

final plansProvider = NotifierProvider<PlansNotifier, PlansState>(PlansNotifier.new);
