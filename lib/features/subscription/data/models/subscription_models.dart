import '../../domain/entities/entitlement_entity.dart';

class PlanChoicesModel {
  final bool anyOffice;
  final bool regionalAndNational;

  const PlanChoicesModel({
    required this.anyOffice,
    required this.regionalAndNational,
  });

  factory PlanChoicesModel.fromJson(Map<String, dynamic> json) {
    return PlanChoicesModel(
      anyOffice: json['anyOffice'] as bool? ?? false,
      regionalAndNational: json['regionalAndNational'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'anyOffice': anyOffice,
    'regionalAndNational': regionalAndNational,
  };
}

class PlanModel {
  final String tier;
  final String name;
  final String subtitle;
  final int officeCount;
  final String currency;
  final double priceMonthly;
  final double priceYearly;
  final List<String> fixedOffices;
  final PlanChoicesModel choices;

  const PlanModel({
    required this.tier,
    required this.name,
    required this.subtitle,
    required this.officeCount,
    required this.currency,
    required this.priceMonthly,
    required this.priceYearly,
    required this.fixedOffices,
    required this.choices,
  });

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    return PlanModel(
      tier: json['tier'] as String? ?? 'focus',
      name: json['name'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      officeCount: (json['officeCount'] as num?)?.toInt() ?? 1,
      currency: json['currency'] as String? ?? 'CHF',
      priceMonthly: (json['priceMonthly'] as num?)?.toDouble() ?? 0.0,
      priceYearly: (json['priceYearly'] as num?)?.toDouble() ?? 0.0,
      fixedOffices:
          (json['fixedOffices'] as List<dynamic>?)
              ?.map((e) => e.toString().toUpperCase())
              .toList() ??
          const [],
      choices: PlanChoicesModel.fromJson(
        json['choices'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  PlanTier get planTier => PlanTier.fromString(tier);
}

class UserAccessModel {
  final String? tier;
  final String? status;
  final String? billingPeriod;
  final String? subscriptionId;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final List<String> officeCodes;
  final List<String> selectedOffices;
  final bool canChangeOffices;
  final DateTime? nextChangeDate;
  final bool needsOfficeSelection;
  final List<String> pendingChoices;
  final List<String> activeTiers;

  const UserAccessModel({
    this.tier,
    this.status,
    this.billingPeriod,
    this.subscriptionId,
    this.periodStart,
    this.periodEnd,
    this.officeCodes = const [],
    this.selectedOffices = const [],
    this.canChangeOffices = false,
    this.nextChangeDate,
    this.needsOfficeSelection = false,
    this.pendingChoices = const [],
    this.activeTiers = const [],
  });

  static Map<String, dynamic> _parseSubscriptionItem(
    Map<String, dynamic> item,
  ) {
    final tier = item['tier']?.toString().toLowerCase();
    final status =
        item['state']?.toString().toLowerCase() ??
        item['status']?.toString().toLowerCase() ??
        'active';
    final billingPeriod = item['billingPeriod']?.toString() ?? 'monthly';
    final subscriptionId =
        item['id']?.toString() ??
        item['_id']?.toString() ??
        item['subscriptionId']?.toString();

    final periodStart = item['periodStart'] != null
        ? DateTime.tryParse(item['periodStart'].toString())
        : null;
    final periodEnd = item['periodEnd'] != null
        ? DateTime.tryParse(item['periodEnd'].toString())
        : null;

    final officeCodesList =
        (item['officeCodes'] as List<dynamic>?)
            ?.map((e) => e.toString().toUpperCase())
            .toList() ??
        <String>[];

    // Parse officeSelection: { "single": "USPTO", "national": null, "regional": null }
    final selectedList = <String>[];
    final selection = item['officeSelection'];
    if (selection is Map<String, dynamic>) {
      if (selection['single'] != null &&
          selection['single'].toString().isNotEmpty) {
        selectedList.add(selection['single'].toString().toUpperCase());
      }
      if (selection['national'] != null &&
          selection['national'].toString().isNotEmpty) {
        selectedList.add(selection['national'].toString().toUpperCase());
      }
      if (selection['regional'] != null &&
          selection['regional'].toString().isNotEmpty) {
        selectedList.add(selection['regional'].toString().toUpperCase());
      }
    }
    if (selectedList.isEmpty && item['selectedOffices'] is List) {
      selectedList.addAll(
        (item['selectedOffices'] as List<dynamic>).map(
          (e) => e.toString().toUpperCase(),
        ),
      );
    }

    final pendingChoices =
        (item['pendingChoices'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        <String>[];

    final needsOfficeSelection =
        pendingChoices.isNotEmpty ||
        item['needsOfficeSelection'] == true ||
        (selectedList.isEmpty && (tier == 'focus' || tier == 'track'));

    final canChangeOffices =
        item['canChangeOffices'] as bool? ??
        item['canChangeOffice'] as bool? ??
        false;

    final nextChangeDate = item['nextChangeDate'] != null
        ? DateTime.tryParse(item['nextChangeDate'].toString())
        : null;

    return {
      'tier': tier,
      'status': status,
      'billingPeriod': billingPeriod,
      'subscriptionId': subscriptionId,
      'periodStart': periodStart,
      'periodEnd': periodEnd,
      'officeCodes': officeCodesList,
      'selectedOffices': selectedList,
      'canChangeOffices': canChangeOffices,
      'nextChangeDate': nextChangeDate,
      'needsOfficeSelection': needsOfficeSelection,
      'pendingChoices': pendingChoices,
    };
  }

  static int _getTierRank(String? tier) {
    switch (tier?.toLowerCase().trim()) {
      case 'global':
        return 4;
      case 'majors':
        return 3;
      case 'track':
        return 2;
      case 'focus':
        return 1;
      default:
        return 0;
    }
  }

  factory UserAccessModel.fromJson(dynamic json) {
    if (json == null) return const UserAccessModel();

    if (json is List) {
      if (json.isEmpty) return const UserAccessModel();

      final allCodes = <String>{};
      final allSelectedOffices = <String>{};
      final activeTiers = <String>{};
      Map<String, dynamic>? chosenItem;

      for (final raw in json) {
        if (raw is Map<String, dynamic>) {
          final parsed = _parseSubscriptionItem(raw);
          final isActive = const {
            'active',
            'grace',
            'cancelled',
            'cancelledactive',
            'cancelled_active',
          }.contains(parsed['status']);

          if (isActive) {
            allCodes.addAll(parsed['officeCodes'] as List<String>);
            allSelectedOffices.addAll(parsed['selectedOffices'] as List<String>);
            final activeTier = parsed['tier'] as String?;
            if (activeTier != null) activeTiers.add(activeTier);
            if (activeTier == 'global') {
              allCodes.addAll(const [
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
              ]);
            } else if (activeTier == 'majors') {
              allCodes.addAll(const [
                'USPTO',
                'EPO',
                'JPO',
                'CNIPA',
                'KIPO',
                'WIPO',
              ]);
            } else if (activeTier == 'track') {
              // WIPO only: the national and the regional office are chosen
              // by the subscriber and come back in officeCodes.
              allCodes.add('WIPO');
            }

            if (chosenItem == null) {
              chosenItem = parsed;
            } else {
              final chosenRank = _getTierRank(chosenItem['tier'] as String?);
              final currentRank = _getTierRank(parsed['tier'] as String?);

              if (currentRank > chosenRank) {
                // Higher tier plan always takes precedence
                chosenItem = parsed;
              } else if (currentRank == chosenRank) {
                // If same tier, prefer the subscription where office is already chosen
                final chosenHasSelected =
                    (chosenItem['selectedOffices'] as List<String>).isNotEmpty;
                final currentHasSelected =
                    (parsed['selectedOffices'] as List<String>).isNotEmpty;

                if (!chosenHasSelected && currentHasSelected) {
                  chosenItem = parsed;
                } else if (chosenHasSelected == currentHasSelected) {
                  final chosenPending =
                      (chosenItem['pendingChoices'] as List<String>).isNotEmpty;
                  final currentPending =
                      (parsed['pendingChoices'] as List<String>).isNotEmpty;
                  if (chosenPending && !currentPending) {
                    chosenItem = parsed;
                  }
                }
              }
            }
          }
        }
      }

      final chosen =
          chosenItem ??
          _parseSubscriptionItem(json.first as Map<String, dynamic>);
      final chosenTier = (chosen['tier'] as String?)?.toLowerCase();

      // Does the user still need office selection?
      // 1. Majors and Global NEVER need office selection.
      // 2. Focus: If an office is already selected (e.g. single: "IPI"), no selection needed.
      // 3. Track: If offices are already selected, no selection needed.
      bool resolvedNeedsSelection = false;
      if (chosenTier == 'focus') {
        final hasSelected =
            (chosen['selectedOffices'] as List<String>).isNotEmpty ||
            allSelectedOffices.isNotEmpty;
        resolvedNeedsSelection = !hasSelected;
      } else if (chosenTier == 'track') {
        final hasSelected =
            (chosen['selectedOffices'] as List<String>).isNotEmpty ||
            allSelectedOffices.isNotEmpty;
        resolvedNeedsSelection = !hasSelected;
      } else {
        resolvedNeedsSelection = false;
      }

      final resolvedSelected =
          (chosen['selectedOffices'] as List<String>).isNotEmpty
              ? (chosen['selectedOffices'] as List<String>)
              : allSelectedOffices.toList();

      final canChange =
          resolvedNeedsSelection ||
          (chosen['canChangeOffices'] as bool? ?? false);

      return UserAccessModel(
        tier: chosen['tier'] as String?,
        status: chosen['status'] as String?,
        billingPeriod: chosen['billingPeriod'] as String?,
        subscriptionId: chosen['subscriptionId'] as String?,
        periodStart: chosen['periodStart'] as DateTime?,
        periodEnd: chosen['periodEnd'] as DateTime?,
        officeCodes: allCodes.isNotEmpty
            ? allCodes.toList()
            : (chosen['officeCodes'] as List<String>),
        selectedOffices: resolvedSelected,
        canChangeOffices: canChange,
        nextChangeDate: chosen['nextChangeDate'] as DateTime?,
        needsOfficeSelection: resolvedNeedsSelection,
        pendingChoices: resolvedNeedsSelection
            ? (chosen['pendingChoices'] as List<String>)
            : const [],
        activeTiers: activeTiers.toList(),
      );
    }

    if (json is Map<String, dynamic>) {
      if (json['data'] is List && (json['data'] as List).isNotEmpty) {
        return UserAccessModel.fromJson(json['data']);
      }
      if (json['data'] is Map<String, dynamic>) {
        return UserAccessModel.fromJson(json['data']);
      }

      final rootOfficeCodes =
          (json['officeCodes'] as List<dynamic>?)
              ?.map((e) => e.toString().toUpperCase())
              .toList() ??
          <String>[];

      if (json['subscriptions'] is List &&
          (json['subscriptions'] as List).isNotEmpty) {
        final subsModel = UserAccessModel.fromJson(json['subscriptions']);
        final combinedCodes = rootOfficeCodes.isNotEmpty
            ? rootOfficeCodes
            : subsModel.officeCodes;
        return UserAccessModel(
          tier: subsModel.tier,
          status: subsModel.status,
          billingPeriod: subsModel.billingPeriod,
          subscriptionId: subsModel.subscriptionId,
          periodStart: subsModel.periodStart,
          periodEnd: subsModel.periodEnd,
          officeCodes: combinedCodes,
          selectedOffices: subsModel.selectedOffices.isNotEmpty
              ? subsModel.selectedOffices
              : combinedCodes,
          canChangeOffices: subsModel.canChangeOffices,
          nextChangeDate: subsModel.nextChangeDate,
          needsOfficeSelection: subsModel.needsOfficeSelection,
          pendingChoices: subsModel.pendingChoices,
          activeTiers: subsModel.activeTiers,
        );
      }

      final parsed = _parseSubscriptionItem(json);
      final rootActiveTiers =
          (json['activeTiers'] as List<dynamic>?)
              ?.map((value) => value.toString().toLowerCase())
              .toList() ??
          <String>[];
      final finalOfficeCodes = rootOfficeCodes.isNotEmpty
          ? rootOfficeCodes
          : (parsed['officeCodes'] as List<String>);
      return UserAccessModel(
        tier: parsed['tier'] as String?,
        status: parsed['status'] as String?,
        billingPeriod: parsed['billingPeriod'] as String?,
        subscriptionId: parsed['subscriptionId'] as String?,
        periodStart: parsed['periodStart'] as DateTime?,
        periodEnd: parsed['periodEnd'] as DateTime?,
        officeCodes: finalOfficeCodes,
        selectedOffices: (parsed['selectedOffices'] as List<String>).isNotEmpty
            ? (parsed['selectedOffices'] as List<String>)
            : finalOfficeCodes,
        canChangeOffices: parsed['canChangeOffices'] as bool? ?? false,
        nextChangeDate: parsed['nextChangeDate'] as DateTime?,
        needsOfficeSelection: parsed['needsOfficeSelection'] as bool? ?? false,
        pendingChoices: parsed['pendingChoices'] as List<String>,
        activeTiers: rootActiveTiers.isNotEmpty
            ? rootActiveTiers
            : [if (parsed['tier'] case final String tier) tier],
      );
    }

    return const UserAccessModel();
  }

  EntitlementEntity toEntity() {
    final plan = PlanTier.fromString(tier);
    final subStatus = SubscriptionStatus.fromString(status);

    // If plan is global, resolve all 15 offices
    List<String> resolvedOffices = List.from(officeCodes);
    if (plan == PlanTier.global) {
      resolvedOffices = const [
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
    } else if (plan == PlanTier.majors && resolvedOffices.isEmpty) {
      resolvedOffices = const ['USPTO', 'EPO', 'JPO', 'CNIPA', 'KIPO', 'WIPO'];
    } else if (plan == PlanTier.track) {
      resolvedOffices = {
        ...resolvedOffices,
        'WIPO',
        'EPO',
        'EUIPO',
        'UPC',
      }.toList();
    }

    return EntitlementEntity(
      planId: plan,
      billingPeriod: billingPeriod ?? 'none',
      periodStart: periodStart,
      periodEnd: periodEnd,
      status: subStatus,
      subscriptionId: subscriptionId,
      selectedOffices: selectedOffices,
      includedOffices: resolvedOffices,
      officeChangeAllowed: canChangeOffices,
      nextOfficeChangeDate: nextChangeDate,
      needsOfficeSelection: needsOfficeSelection,
      activePlans: activeTiers
          .map(PlanTier.fromString)
          .where((tier) => tier != PlanTier.none)
          .toList(),
    );
  }
}
