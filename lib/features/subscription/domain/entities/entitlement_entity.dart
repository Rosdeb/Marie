enum PlanTier {
  none,
  focus,
  track,
  majors,
  global;

  String get displayName {
    switch (this) {
      case PlanTier.focus:
        return 'Focus';
      case PlanTier.track:
        return 'Track';
      case PlanTier.majors:
        return 'Majors';
      case PlanTier.global:
        return 'Global';
      case PlanTier.none:
        return 'Free';
    }
  }

  static PlanTier fromString(String? value) {
    if (value == null) return PlanTier.none;
    switch (value.toLowerCase().trim()) {
      case 'focus':
        return PlanTier.focus;
      case 'track':
        return PlanTier.track;
      case 'majors':
        return PlanTier.majors;
      case 'global':
        return PlanTier.global;
      default:
        return PlanTier.none;
    }
  }
}

enum SubscriptionStatus {
  none,
  active,
  grace,
  expired,
  cancelledActive;

  static SubscriptionStatus fromString(String? value) {
    if (value == null) return SubscriptionStatus.none;
    switch (value.toLowerCase().trim()) {
      case 'active':
        return SubscriptionStatus.active;
      case 'grace':
        return SubscriptionStatus.grace;
      case 'expired':
        return SubscriptionStatus.expired;
      case 'cancelled':
      case 'cancelledactive':
      case 'cancelled_active':
        return SubscriptionStatus.cancelledActive;
      default:
        return SubscriptionStatus.none;
    }
  }
}

enum LockReason {
  none,
  notInPlan,
  expired,
  noSubscription;

  String get displayMessage {
    switch (this) {
      case LockReason.notInPlan:
        return 'Not in your plan';
      case LockReason.expired:
        return 'Subscription expired';
      case LockReason.noSubscription:
        return 'Subscription required';
      case LockReason.none:
        return '';
    }
  }
}

class EntitlementEntity {
  final PlanTier planId;
  final String billingPeriod; // 'monthly' | 'yearly' | 'none'
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final SubscriptionStatus status;
  final String? subscriptionId;
  // Focus: 1 office; Track: 1 chosen national office.
  final List<String> selectedOffices;
  final List<String> includedOffices; // resolved office codes in uppercase
  final bool officeChangeAllowed;
  final DateTime? nextOfficeChangeDate;
  final bool needsOfficeSelection;
  final List<PlanTier> activePlans;
  final bool isLoading;
  final String? errorMessage;

  const EntitlementEntity({
    this.planId = PlanTier.none,
    this.billingPeriod = 'none',
    this.periodStart,
    this.periodEnd,
    this.status = SubscriptionStatus.none,
    this.subscriptionId,
    this.selectedOffices = const [],
    this.includedOffices = const [],
    this.officeChangeAllowed = false,
    this.nextOfficeChangeDate,
    this.needsOfficeSelection = false,
    this.activePlans = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  EntitlementEntity copyWith({
    PlanTier? planId,
    String? billingPeriod,
    DateTime? periodStart,
    DateTime? periodEnd,
    SubscriptionStatus? status,
    String? subscriptionId,
    List<String>? selectedOffices,
    List<String>? includedOffices,
    bool? officeChangeAllowed,
    DateTime? nextOfficeChangeDate,
    bool? needsOfficeSelection,
    List<PlanTier>? activePlans,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return EntitlementEntity(
      planId: planId ?? this.planId,
      billingPeriod: billingPeriod ?? this.billingPeriod,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      status: status ?? this.status,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      selectedOffices: selectedOffices ?? this.selectedOffices,
      includedOffices: includedOffices ?? this.includedOffices,
      officeChangeAllowed: officeChangeAllowed ?? this.officeChangeAllowed,
      nextOfficeChangeDate: nextOfficeChangeDate ?? this.nextOfficeChangeDate,
      needsOfficeSelection: needsOfficeSelection ?? this.needsOfficeSelection,
      activePlans: activePlans ?? this.activePlans,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  // --- Entitlement Helpers ---

  bool get isActive =>
      status == SubscriptionStatus.active ||
      status == SubscriptionStatus.cancelledActive ||
      status == SubscriptionStatus.grace;

  bool canAccessOffice(String officeId) {
    if (!isActive) return false;
    if (planId == PlanTier.global) return true;
    return includedOffices.contains(officeId.toUpperCase().trim());
  }

  bool canAccessQuiz(String officeId, String discipline, String difficulty) {
    // "All four levels and all disciplines are included in every plan. Everything inside an included office comes with it."
    return canAccessOffice(officeId);
  }

  LockReason getLockReason(String officeId) {
    if (!isActive) {
      if (status == SubscriptionStatus.expired) return LockReason.expired;
      return LockReason.noSubscription;
    }
    if (!canAccessOffice(officeId)) {
      return LockReason.notInPlan;
    }
    return LockReason.none;
  }

  /// Returns which plans would unlock this office for the user.
  List<PlanTier> getUpgradeOptions(String officeId) {
    final code = officeId.toUpperCase().trim();
    final options = <PlanTier>[];

    // Global unlocks all 15 offices
    if (planId != PlanTier.global) {
      options.add(PlanTier.global);
    }

    // Majors fixed set: USPTO, EPO, JPO, CNIPA, KIPO, WIPO
    const majorsOffices = {'USPTO', 'EPO', 'JPO', 'CNIPA', 'KIPO', 'WIPO'};
    if (majorsOffices.contains(code) &&
        planId != PlanTier.majors &&
        planId != PlanTier.global) {
      options.insert(0, PlanTier.majors);
    }

    // Track includes WIPO + all regional offices + 1 chosen national office.
    const regionalOffices = {'EPO', 'EUIPO', 'UPC'};
    const internationalOffices = {'WIPO'};
    final isTrackCandidate =
        internationalOffices.contains(code) ||
        regionalOffices.contains(code) ||
        !regionalOffices.contains(code); // Any national office can be selected

    if (isTrackCandidate &&
        planId != PlanTier.track &&
        planId != PlanTier.majors &&
        planId != PlanTier.global) {
      if (!options.contains(PlanTier.track)) {
        options.insert(0, PlanTier.track);
      }
    }

    // Focus allows choosing any 1 office
    if (planId == PlanTier.none) {
      if (!options.contains(PlanTier.focus)) {
        options.insert(0, PlanTier.focus);
      }
    }

    return options;
  }
}
