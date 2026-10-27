import 'package:flutter_test/flutter_test.dart';
import 'package:marie_nirva/features/subscription/data/models/revenuecat_plan_models.dart';
import 'package:marie_nirva/features/subscription/data/models/subscription_models.dart';
import 'package:marie_nirva/features/subscription/domain/entities/entitlement_entity.dart';

void main() {
  group('RevenueCat Plan Models & Offering Parser Tests', () {
    test('fromOffering with null falls back to the 4 standard plan tiers', () {
      final groups = RevenueCatPlanGroup.fromOffering(null);

      expect(groups.length, 4);
      expect(groups[0].tier, PlanTier.focus);
      expect(groups[0].title, 'Focus');
      expect(groups[1].tier, PlanTier.track);
      expect(groups[1].title, 'Track');
      expect(groups[2].tier, PlanTier.majors);
      expect(groups[2].title, 'Majors');
      expect(groups[3].tier, PlanTier.global);
      expect(groups[3].title, 'Global');

      // Prices default to fallback pricing when no StoreProduct is attached
      expect(groups[0].monthlyPriceString, 'CHF 14.99/mo');
      expect(groups[0].annualPriceString, 'CHF 119.00/yr');
    });

    test('Each plan has complete feature list and difficulty inclusion', () {
      final groups = RevenueCatPlanGroup.fromOffering(null);

      for (final plan in groups) {
        expect(plan.features, isNotEmpty);
        expect(
          plan.features.any((f) => f.contains('difficulty levels included')),
          isTrue,
          reason: '${plan.title} must state all difficulty levels are included',
        );
      }
    });

    test('Plan tiers have correct upgrade/downgrade order', () {
      expect(PlanTier.focus.index < PlanTier.track.index, isTrue);
      expect(PlanTier.track.index < PlanTier.majors.index, isTrue);
      expect(PlanTier.majors.index < PlanTier.global.index, isTrue);
    });
  });

  group('Entitlement & Office Selection Logic Tests', () {
    test('Track plan locks regional and international offices as included', () {
      const entitlement = EntitlementEntity(
        planId: PlanTier.track,
        status: SubscriptionStatus.active,
        selectedOffices: ['USPTO'],
        includedOffices: ['WIPO', 'EPO', 'EUIPO', 'UPC', 'USPTO'],
      );

      // Track automatically includes WIPO and regional offices
      expect(entitlement.canAccessOffice('WIPO'), isTrue);
      expect(entitlement.canAccessOffice('EPO'), isTrue);
      expect(entitlement.canAccessOffice('EUIPO'), isTrue);
      expect(entitlement.canAccessOffice('UPC'), isTrue);
      expect(entitlement.canAccessOffice('USPTO'), isTrue);

      // Other national offices are locked
      expect(entitlement.canAccessOffice('JPO'), isFalse);
      expect(entitlement.canAccessOffice('CNIPA'), isFalse);
      expect(entitlement.canAccessOffice('IPI'), isFalse);
    });

    test('Focus plan allows user to pick any 1 of 15 offices', () {
      const entitlement = EntitlementEntity(
        planId: PlanTier.focus,
        status: SubscriptionStatus.active,
        selectedOffices: ['CNIPA'],
        includedOffices: ['CNIPA'],
        officeChangeAllowed: true,
      );

      expect(entitlement.canAccessOffice('CNIPA'), isTrue);
      expect(entitlement.canAccessOffice('USPTO'), isFalse);
      expect(entitlement.officeChangeAllowed, isTrue);
    });

    test('Office change limit is strictly enforced when flag is false', () {
      final nextChange = DateTime(2026, 11, 15);
      final entitlement = EntitlementEntity(
        planId: PlanTier.focus,
        status: SubscriptionStatus.active,
        selectedOffices: ['IPI'],
        includedOffices: ['IPI'],
        officeChangeAllowed: false,
        nextOfficeChangeDate: nextChange,
      );

      expect(entitlement.officeChangeAllowed, isFalse);
      expect(entitlement.nextOfficeChangeDate, equals(nextChange));
    });

    test(
      'UserAccessModel parses backend my-access array and preserves choices',
      () {
        final backendJson = {
          "success": true,
          "statusCode": 200,
          "message": "Access retrieved successfully",
          "data": [
            {
              "id": "6adf36542dfedd399621ded0",
              "tier": "focus",
              "planName": "Focus",
              "billingPeriod": "monthly",
              "state": "active",
              "periodEnd": "2026-10-26T11:20:30.612Z",
              "willRenew": true,
              "officeCodes": ["USPTO"],
              "officeSelection": {
                "single": "USPTO",
                "national": null,
                "regional": null,
              },
              "canChangeOffices": false,
              "pendingChoices": [],
            },
          ],
        };

        final access = UserAccessModel.fromJson(backendJson);
        final entitlement = access.toEntity();

        expect(entitlement.isActive, isTrue);
        expect(entitlement.planId, PlanTier.focus);
        expect(entitlement.selectedOffices, contains('USPTO'));
        expect(entitlement.needsOfficeSelection, isFalse);
        expect(entitlement.subscriptionId, '6adf36542dfedd399621ded0');
      },
    );

    test(
      'UserAccessModel detects pendingChoices for newly purchased Track/Focus',
      () {
        final backendJson = {
          "data": [
            {
              "id": "6adf35f82dfedd399621decd",
              "tier": "track",
              "planName": "Track",
              "billingPeriod": "monthly",
              "state": "active",
              "periodEnd": "2026-10-26T11:18:59.640Z",
              "willRenew": true,
              "officeCodes": ["WIPO"],
              "officeSelection": {
                "single": null,
                "national": null,
                "regional": null,
              },
              "canChangeOffices": true,
              "pendingChoices": ["national", "regional"],
            },
          ],
        };

        final access = UserAccessModel.fromJson(backendJson);
        final entitlement = access.toEntity();

        expect(entitlement.isActive, isTrue);
        expect(entitlement.planId, PlanTier.track);
        expect(entitlement.needsOfficeSelection, isTrue);
        expect(entitlement.officeChangeAllowed, isTrue);
        expect(
          entitlement.includedOffices,
          containsAll(['WIPO', 'EPO', 'EUIPO', 'UPC']),
        );
      },
    );

    test(
      'multiple subscriptions preserve aggregate access and prioritize highest tier',
      () {
        final access = UserAccessModel.fromJson({
          'data': [
            {
              'id': 'majors_1',
              'tier': 'majors',
              'state': 'active',
              'officeCodes': ['WIPO', 'EPO', 'USPTO', 'CNIPA', 'JPO', 'KIPO'],
              'officeSelection': {'single': null, 'national': null},
              'canChangeOffices': false,
              'pendingChoices': <String>[],
            },
            {
              'id': 'focus_selected',
              'tier': 'focus',
              'state': 'active',
              'officeCodes': ['IPI'],
              'officeSelection': {'single': 'IPI', 'national': null},
              'canChangeOffices': false,
              'pendingChoices': <String>[],
            },
            {
              'id': 'focus_pending',
              'tier': 'focus',
              'state': 'active',
              'officeCodes': <String>[],
              'officeSelection': {'single': null, 'national': null},
              'canChangeOffices': true,
              'pendingChoices': ['single'],
            },
          ],
        });

        final entitlement = access.toEntity();
        expect(entitlement.subscriptionId, 'majors_1');
        expect(entitlement.planId, PlanTier.majors);
        expect(entitlement.needsOfficeSelection, isFalse);
        expect(
          entitlement.includedOffices,
          containsAll(['WIPO', 'USPTO', 'IPI']),
        );
        expect(
          entitlement.activePlans,
          containsAll([PlanTier.majors, PlanTier.focus]),
        );
      },
    );
  });
}
