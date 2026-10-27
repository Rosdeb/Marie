import 'package:flutter_test/flutter_test.dart';
import 'package:marie_nirva/features/subscription/domain/entities/entitlement_entity.dart';
import 'package:marie_nirva/features/subscription/data/models/subscription_models.dart';

void main() {
  group('Entitlement Entity Resolution Tests (Plan x Office Matrix)', () {
    test('Global plan unlocks all 15 IP offices without restriction', () {
      final entitlement = EntitlementEntity(
        planId: PlanTier.global,
        status: SubscriptionStatus.active,
        includedOffices: const [
          'WIPO', 'EPO', 'EUIPO', 'UPC', 'USPTO', 'CNIPA', 'UKIPO',
          'JPO', 'KIPO', 'INDIA', 'INPI', 'IPI', 'DPMA', 'IPAU', 'CIPO'
        ],
      );

      final all15Offices = [
        'WIPO', 'EPO', 'EUIPO', 'UPC', 'USPTO', 'CNIPA', 'UKIPO',
        'JPO', 'KIPO', 'INDIA', 'INPI', 'IPI', 'DPMA', 'IPAU', 'CIPO'
      ];

      for (final code in all15Offices) {
        expect(entitlement.canAccessOffice(code), isTrue,
            reason: 'Global plan should unlock $code');
        expect(entitlement.canAccessQuiz(code, 'Patents', 'Expert'), isTrue,
            reason: 'Global plan should unlock all levels/disciplines for $code');
        expect(entitlement.getLockReason(code), equals(LockReason.none));
      }
      expect(entitlement.getUpgradeOptions('EPO'), isEmpty);
    });

    test('Majors plan unlocks exactly the 6 fixed offices and locks the remaining 9', () {
      const majorsSet = {'USPTO', 'EPO', 'JPO', 'CNIPA', 'KIPO', 'WIPO'};
      const otherOffices = {'EUIPO', 'UPC', 'UKIPO', 'INDIA', 'INPI', 'IPI', 'DPMA', 'IPAU', 'CIPO'};

      final entitlement = EntitlementEntity(
        planId: PlanTier.majors,
        status: SubscriptionStatus.active,
        includedOffices: majorsSet.toList(),
      );

      for (final code in majorsSet) {
        expect(entitlement.canAccessOffice(code), isTrue,
            reason: 'Majors plan must unlock $code');
        expect(entitlement.getLockReason(code), equals(LockReason.none));
      }

      for (final code in otherOffices) {
        expect(entitlement.canAccessOffice(code), isFalse,
            reason: 'Majors plan must lock $code');
        expect(entitlement.getLockReason(code), equals(LockReason.notInPlan));
        // For Majors user, only Global should be suggested as an upgrade
        expect(entitlement.getUpgradeOptions(code), contains(PlanTier.global));
        expect(entitlement.getUpgradeOptions(code), isNot(contains(PlanTier.focus)));
      }
    });

    test('Track plan unlocks WIPO + selected national + selected regional', () {
      final entitlement = EntitlementEntity(
        planId: PlanTier.track,
        status: SubscriptionStatus.active,
        selectedOffices: const ['USPTO', 'EPO'],
        includedOffices: const ['WIPO', 'USPTO', 'EPO'],
      );

      expect(entitlement.canAccessOffice('WIPO'), isTrue);
      expect(entitlement.canAccessOffice('USPTO'), isTrue);
      expect(entitlement.canAccessOffice('EPO'), isTrue);

      // Other offices are locked
      expect(entitlement.canAccessOffice('JPO'), isFalse);
      expect(entitlement.canAccessOffice('EUIPO'), isFalse);
      expect(entitlement.canAccessOffice('IPI'), isFalse);

      expect(entitlement.getLockReason('JPO'), equals(LockReason.notInPlan));
    });

    test('Focus plan unlocks only the single chosen office', () {
      final entitlement = EntitlementEntity(
        planId: PlanTier.focus,
        status: SubscriptionStatus.active,
        selectedOffices: const ['IPI'],
        includedOffices: const ['IPI'],
      );

      expect(entitlement.canAccessOffice('IPI'), isTrue);
      expect(entitlement.canAccessOffice('WIPO'), isFalse);
      expect(entitlement.canAccessOffice('EPO'), isFalse);
      expect(entitlement.canAccessOffice('USPTO'), isFalse);

      // Verify all 4 difficulty levels are accessible for the chosen office
      for (final level in ['Beginner', 'Intermediate', 'Advanced', 'Expert']) {
        expect(entitlement.canAccessQuiz('IPI', 'Patents', level), isTrue);
      }
    });

    test('Free / Non-subscribed user has all offices locked', () {
      const entitlement = EntitlementEntity(
        planId: PlanTier.none,
        status: SubscriptionStatus.none,
      );

      expect(entitlement.canAccessOffice('IPI'), isFalse);
      expect(entitlement.canAccessOffice('EPO'), isFalse);
      expect(entitlement.canAccessOffice('WIPO'), isFalse);
      expect(entitlement.getLockReason('IPI'), equals(LockReason.noSubscription));
    });
  });

  group('Subscription Status & Expiry Handling Tests', () {
    test('Expired subscription blocks access and gives LockReason.expired', () {
      final entitlement = EntitlementEntity(
        planId: PlanTier.global,
        status: SubscriptionStatus.expired,
        includedOffices: const ['WIPO', 'EPO', 'USPTO'],
      );

      expect(entitlement.isActive, isFalse);
      expect(entitlement.canAccessOffice('EPO'), isFalse);
      expect(entitlement.getLockReason('EPO'), equals(LockReason.expired));
    });

    test('Cancelled-but-active-until-end retains full access', () {
      final futureDate = DateTime.now().add(const Duration(days: 15));
      final entitlement = EntitlementEntity(
        planId: PlanTier.track,
        status: SubscriptionStatus.cancelledActive,
        periodEnd: futureDate,
        includedOffices: const ['WIPO', 'EPO', 'USPTO'],
      );

      expect(entitlement.isActive, isTrue);
      expect(entitlement.canAccessOffice('EPO'), isTrue);
      expect(entitlement.getLockReason('EPO'), equals(LockReason.none));
    });
  });

  group('Office Change Limit Logic Tests', () {
    test('Respects officeChangeAllowed flag and nextOfficeChangeDate', () {
      final nextDate = DateTime.now().add(const Duration(days: 20));
      final entitlement = EntitlementEntity(
        planId: PlanTier.focus,
        status: SubscriptionStatus.active,
        officeChangeAllowed: false,
        nextOfficeChangeDate: nextDate,
        selectedOffices: const ['IPI'],
        includedOffices: const ['IPI'],
      );

      expect(entitlement.officeChangeAllowed, isFalse);
      expect(entitlement.nextOfficeChangeDate, equals(nextDate));
    });
  });

  group('UserAccessModel JSON Parsing Tests', () {
    test('Parses backend /subscription/my-access format correctly', () {
      final json = {
        "tier": "track",
        "status": "active",
        "billingPeriod": "yearly",
        "id": "sub_12345",
        "officeCodes": ["WIPO", "EPO", "USPTO"],
        "selectedOffices": ["USPTO", "EPO"],
        "canChangeOffices": true,
        "needsOfficeSelection": false
      };

      final model = UserAccessModel.fromJson(json);
      expect(model.tier, 'track');
      expect(model.status, 'active');
      expect(model.billingPeriod, 'yearly');
      expect(model.subscriptionId, 'sub_12345');
      expect(model.officeCodes, contains('EPO'));
      expect(model.canChangeOffices, isTrue);

      final entity = model.toEntity();
      expect(entity.planId, PlanTier.track);
      expect(entity.status, SubscriptionStatus.active);
      expect(entity.canAccessOffice('WIPO'), isTrue);
      expect(entity.canAccessOffice('EPO'), isTrue);
      expect(entity.canAccessOffice('USPTO'), isTrue);
      expect(entity.canAccessOffice('CNIPA'), isFalse);
    });

    test('Automatically expands Global plan to all 15 offices', () {
      final json = {
        "tier": "global",
        "status": "active",
        "billingPeriod": "monthly",
        "officeCodes": []
      };

      final model = UserAccessModel.fromJson(json);
      final entity = model.toEntity();
      expect(entity.includedOffices.length, 15);
      expect(entity.canAccessOffice('CIPO'), isTrue);
      expect(entity.canAccessOffice('IPAU'), isTrue);
      expect(entity.canAccessOffice('DPMA'), isTrue);
    });

    test('Parses root officeCodes combined with subscriptions array from my-access', () {
      final json = {
        "officeCodes": ["USPTO", "EPO", "WIPO"],
        "subscriptions": [
          {
            "id": "sub_focus_001",
            "tier": "track",
            "state": "active",
            "billingPeriod": "monthly",
            "officeSelection": {
              "national": "USPTO",
              "regional": "EPO"
            },
            "canChangeOffices": true,
            "needsOfficeSelection": false
          }
        ]
      };

      final model = UserAccessModel.fromJson(json);
      expect(model.subscriptionId, 'sub_focus_001');
      expect(model.tier, 'track');
      expect(model.officeCodes, containsAll(['USPTO', 'EPO', 'WIPO']));
      expect(model.selectedOffices, containsAll(['USPTO', 'EPO']));
      expect(model.canChangeOffices, isTrue);
      expect(model.needsOfficeSelection, isFalse);

      final entity = model.toEntity();
      expect(entity.canAccessOffice('USPTO'), isTrue);
      expect(entity.canAccessOffice('EPO'), isTrue);
      expect(entity.canAccessOffice('WIPO'), isTrue);
      expect(entity.canAccessOffice('CNIPA'), isFalse);
    });

    test('User with Majors and selected Focus preserves all office access and locks selection', () {
      final json = [
        {
          "id": "6ae0757b2dfedd3996220041",
          "tier": "majors",
          "planName": "Majors",
          "billingPeriod": "yearly",
          "state": "active",
          "store": "manual",
          "periodEnd": "2026-10-27T10:57:11.000Z",
          "willRenew": true,
          "officeCodes": [
            "WIPO",
            "EPO",
            "USPTO",
            "CNIPA",
            "JPO",
            "KIPO"
          ],
          "officeSelection": {
            "single": null,
            "national": null
          },
          "canChangeOffices": false,
          "pendingChoices": []
        },
        {
          "id": "6ae0716e2dfedd399622001f",
          "tier": "focus",
          "planName": "Focus",
          "billingPeriod": "yearly",
          "state": "active",
          "store": "manual",
          "periodEnd": "2026-10-27T10:39:56.670Z",
          "willRenew": true,
          "officeCodes": [
            "IPI"
          ],
          "officeSelection": {
            "single": "IPI",
            "national": null
          },
          "canChangeOffices": false,
          "pendingChoices": []
        },
        {
          "id": "6ae0716e2dfedd399622001e",
          "tier": "focus",
          "planName": "Focus",
          "billingPeriod": "yearly",
          "state": "active",
          "store": "manual",
          "periodEnd": "2026-10-27T10:39:56.000Z",
          "willRenew": true,
          "officeCodes": [],
          "officeSelection": {
            "single": null,
            "national": null
          },
          "canChangeOffices": true,
          "pendingChoices": [
            "single"
          ]
        }
      ];

      final model = UserAccessModel.fromJson(json);
      // Higher tier Majors wins as primary tier
      expect(model.tier, 'majors');
      expect(model.needsOfficeSelection, isFalse);
      expect(model.canChangeOffices, isFalse);
      // Union of all active offices: 6 from Majors + IPI from Focus
      expect(model.officeCodes, containsAll(['WIPO', 'EPO', 'USPTO', 'CNIPA', 'JPO', 'KIPO', 'IPI']));
      expect(model.selectedOffices, contains('IPI'));

      final entity = model.toEntity();
      expect(entity.canAccessOffice('IPI'), isTrue);
      expect(entity.canAccessOffice('USPTO'), isTrue);
      expect(entity.canAccessOffice('EPO'), isTrue);
      expect(entity.canAccessOffice('WIPO'), isTrue);
      expect(entity.canAccessOffice('CNIPA'), isTrue);
      expect(entity.canAccessOffice('JPO'), isTrue);
      expect(entity.canAccessOffice('KIPO'), isTrue);
      expect(entity.canAccessOffice('DPMA'), isFalse);
    });

    test('Focus user who already chose an office cannot re-select again', () {
      final json = [
        {
          "id": "6ae0716e2dfedd399622001f",
          "tier": "focus",
          "planName": "Focus",
          "billingPeriod": "yearly",
          "state": "active",
          "officeCodes": ["IPI"],
          "officeSelection": {
            "single": "IPI"
          },
          "canChangeOffices": false,
          "pendingChoices": []
        },
        {
          "id": "6ae0716e2dfedd399622001e",
          "tier": "focus",
          "planName": "Focus",
          "billingPeriod": "yearly",
          "state": "active",
          "officeCodes": [],
          "officeSelection": {
            "single": null
          },
          "canChangeOffices": true,
          "pendingChoices": ["single"]
        }
      ];

      final model = UserAccessModel.fromJson(json);
      expect(model.tier, 'focus');
      expect(model.selectedOffices, ['IPI']);
      expect(model.officeCodes, ['IPI']);
      expect(model.needsOfficeSelection, isFalse);
      expect(model.canChangeOffices, isFalse);

      final entity = model.toEntity();
      expect(entity.canAccessOffice('IPI'), isTrue);
      expect(entity.canAccessOffice('USPTO'), isFalse);
      expect(entity.officeChangeAllowed, isFalse);
      expect(entity.needsOfficeSelection, isFalse);
    });
  });
}
