import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/entitlement_entity.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../../data/repositories/subscription_repository_impl.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../practice/presentation/providers/offices_provider.dart';

class EntitlementNotifier extends Notifier<EntitlementEntity> {
  late SubscriptionRepository _repository;

  @override
  EntitlementEntity build() {
    _repository = ref.watch(subscriptionRepositoryProvider);
    final isAuth = ref.watch(authProvider.select((s) => s.isAuthenticated));

    if (!isAuth) {
      return const EntitlementEntity(isLoading: false);
    }

    // Load cached entitlement immediately for offline-first readiness
    Future.microtask(() => _init());

    return const EntitlementEntity(isLoading: true);
  }

  Future<void> _init() async {
    final cached = await _repository.getCachedEntitlement();
    if (cached != null) {
      state = cached.copyWith(isLoading: true);
    }
    await refresh();
  }

  Future<void> refresh() async {
    final isAuth = ref.read(authProvider).isAuthenticated;
    if (!isAuth) {
      state = const EntitlementEntity(isLoading: false);
      return;
    }

    try {
      final entitlement = await _repository.getMyAccess();
      state = entitlement.copyWith(isLoading: false, clearError: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e
            .toString()
            .replaceFirst('ApiException: ', '')
            .replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<bool> syncFromRevenueCat() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final entitlement = await _repository.syncRevenueCat();
      state = entitlement.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('ApiException: ', ''),
      );
      return false;
    }
  }

  Future<bool> chooseOffices({
    String? single,
    String? national,
    String? regional,
  }) async {
    final isFocus = state.planId == PlanTier.focus;
    final isTrack = state.planId == PlanTier.track;
    final hasValidFocusChoice =
        isFocus &&
        single != null &&
        single.trim().isNotEmpty &&
        national == null &&
        regional == null;
    final hasValidTrackChoices =
        isTrack &&
        single == null &&
        national != null &&
        national.trim().isNotEmpty &&
        regional == null;

    if (!hasValidFocusChoice && !hasValidTrackChoices) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: isTrack
            ? 'Track requires one national office.'
            : 'Office selection is only available for Focus and Track plans.',
      );
      return false;
    }

    if (!state.needsOfficeSelection && !state.officeChangeAllowed) {
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            'Office changes are not available until the next billing period.',
      );
      return false;
    }

    String? subId = state.subscriptionId;

    // If subscriptionId is not yet available in current state, refresh from /subscription/my-access first
    if (subId == null || subId.isEmpty) {
      await refresh();
      subId = state.subscriptionId;
    }

    if (subId == null || subId.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            'Could not identify the subscription to update. Please refresh and try again.',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final ok = await _repository.chooseOffices(
        subscriptionId: subId,
        single: single,
        national: national,
        regional: regional,
      );

      // ALWAYS reload my-access API again to refresh subscription pages properly
      await refresh();
      ref.read(officesProvider.notifier).fetchOffices();

      return ok;
    } catch (e) {
      // Attempt refresh even on error to sync any partial backend updates
      await refresh();
      ref.read(officesProvider.notifier).fetchOffices();
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('ApiException: ', ''),
      );
      return false;
    }
  }

  void setMockPlanForTesting({
    required PlanTier tier,
    required SubscriptionStatus status,
    List<String> offices = const [],
    bool canChangeOffices = true,
  }) {
    List<String> resolved = List.from(offices);
    if (tier == PlanTier.global) {
      resolved = const [
        'WIPO',
        'EPO',
        'EUIPO',
        'UPC',
        'USPTO',
        'CNIPA',
        'UKIPO',
        'JPO',
        'KIPO',
        'INDIA',
        'INPI',
        'IPI',
        'DPMA',
        'IPAU',
        'CIPO',
      ];
    } else if (tier == PlanTier.majors && resolved.isEmpty) {
      resolved = const ['USPTO', 'EPO', 'JPO', 'CNIPA', 'KIPO', 'WIPO'];
    } else if (tier == PlanTier.track) {
      resolved = {...resolved, 'WIPO', 'EPO', 'EUIPO', 'UPC'}.toList();
    }

    state = EntitlementEntity(
      planId: tier,
      status: status,
      billingPeriod: 'monthly',
      includedOffices: resolved,
      selectedOffices: offices,
      activePlans: tier == PlanTier.none ? const [] : [tier],
      officeChangeAllowed: canChangeOffices,
      isLoading: false,
    );
  }

  void clear() {
    state = const EntitlementEntity(isLoading: false);
  }
}

final entitlementProvider =
    NotifierProvider<EntitlementNotifier, EntitlementEntity>(
      EntitlementNotifier.new,
    );
