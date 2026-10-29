import 'package:purchases_flutter/purchases_flutter.dart';
import '../../domain/entities/entitlement_entity.dart';
import 'subscription_models.dart';

enum PlanBillingInterval { monthly, annual }

class RevenueCatPlanGroup {
  final PlanTier tier;
  final String title;
  final String? badge;
  final String description;
  final List<String> features;
  final Package? monthlyPackage;
  final Package? annualPackage;
  final String? fallbackMonthlyPrice;
  final String? fallbackAnnualPrice;

  const RevenueCatPlanGroup({
    required this.tier,
    required this.title,
    this.badge,
    required this.description,
    required this.features,
    this.monthlyPackage,
    this.annualPackage,
    this.fallbackMonthlyPrice,
    this.fallbackAnnualPrice,
  });

  String get monthlyPriceString =>
      monthlyPackage?.storeProduct.priceString ?? fallbackMonthlyPrice ?? '—';
  String get annualPriceString =>
      annualPackage?.storeProduct.priceString ?? fallbackAnnualPrice ?? '—';

  Package? getPackage(PlanBillingInterval interval) {
    return interval == PlanBillingInterval.annual ? annualPackage : monthlyPackage;
  }

  static List<RevenueCatPlanGroup> fromOffering(
    Offering? offering, {
    List<PlanModel>? apiPlans,
    bool useReferralOffering = false,
  }) {
    return fromOfferings(
      offering != null
          ? Offerings({offering.identifier: offering}, current: offering)
          : null,
      apiPlans: apiPlans,
      useReferralOffering: useReferralOffering,
    );
  }

  /// Suffix of the RevenueCat offering that holds the reduced-price products.
  ///
  /// Neither store can take a percentage off a subscription, so the 10%
  /// referral discount is a second set of products at the lower price, in an
  /// offering of its own: `focus` and `focus_ref10`, and so on.
  static const String referralOfferingSuffix = '_ref10';

  static List<RevenueCatPlanGroup> fromOfferings(
    Offerings? offerings, {
    List<PlanModel>? apiPlans,
    /// True when the subscriber holds a valid promo code, in which case the
    /// discounted offering is shown. Falls back to the standard one when the
    /// discounted offering has not been set up yet, so a missing offering
    /// means full price rather than no price at all.
    bool useReferralOffering = false,
  }) {
    PlanModel? getApiPlan(PlanTier tier) {
      if (apiPlans == null || apiPlans.isEmpty) return null;
      try {
        return apiPlans.firstWhere((p) => p.planTier == tier);
      } catch (_) {
        return null;
      }
    }

    Offering? offeringNamed(String name) {
      if (offerings == null) return null;
      for (final entry in offerings.all.entries) {
        if (entry.key.toLowerCase() == name) return entry.value;
      }
      return null;
    }

    Offering? getOfferingForTier(PlanTier tier) {
      if (offerings == null) return null;
      final name = tier.name.toLowerCase();

      if (useReferralOffering) {
        final discounted = offeringNamed('$name$referralOfferingSuffix');
        if (discounted != null) return discounted;
      }

      return offeringNamed(name) ?? offerings.current;
    }

    Package? resolvePackage(Offering? offering, PlanBillingInterval interval) {
      if (offering == null) return null;

      final packages = offering.availablePackages;
      if (packages.isEmpty) return null;

      if (interval == PlanBillingInterval.annual) {
        if (offering.annual != null) return offering.annual;
        try {
          return packages.firstWhere(
            (p) =>
                p.packageType == PackageType.annual ||
                p.identifier.toLowerCase().contains('annual') ||
                p.identifier.toLowerCase().contains('year'),
          );
        } catch (_) {
          return null;
        }
      } else {
        if (offering.monthly != null) return offering.monthly;
        try {
          return packages.firstWhere(
            (p) =>
                p.packageType == PackageType.monthly ||
                p.identifier.toLowerCase().contains('monthly') ||
                p.identifier.toLowerCase().contains('month'),
          );
        } catch (_) {
          return null;
        }
      }
    }

    final focusApi = getApiPlan(PlanTier.focus);
    final trackApi = getApiPlan(PlanTier.track);
    final majorsApi = getApiPlan(PlanTier.majors);
    final globalApi = getApiPlan(PlanTier.global);

    final focusOffering = getOfferingForTier(PlanTier.focus);
    final trackOffering = getOfferingForTier(PlanTier.track);
    final majorsOffering = getOfferingForTier(PlanTier.majors);
    final globalOffering = getOfferingForTier(PlanTier.global);

    return [
      RevenueCatPlanGroup(
        tier: PlanTier.focus,
        title: focusApi?.name.isNotEmpty == true ? focusApi!.name : 'Focus',
        description: focusApi?.subtitle.isNotEmpty == true
            ? focusApi!.subtitle
            : 'Practice 1 office of your choice with unlimited questions and mock exams.',
        features: const [
          'Choose any 1 office (e.g. USPTO, EPO, IPI)',
          'Change office once per billing period',
          'All 4 difficulty levels included',
          'Full legal rationales & explanations',
        ],
        monthlyPackage: resolvePackage(focusOffering, PlanBillingInterval.monthly),
        annualPackage: resolvePackage(focusOffering, PlanBillingInterval.annual),
        fallbackMonthlyPrice: focusApi != null
            ? '${focusApi.currency} ${focusApi.priceMonthly.toStringAsFixed(2)}/mo'
            : 'CHF 19.99/mo',
        fallbackAnnualPrice: focusApi != null
            ? '${focusApi.currency} ${focusApi.priceYearly.toStringAsFixed(0)}/yr'
            : 'CHF 199/yr',
      ),
      RevenueCatPlanGroup(
        tier: PlanTier.track,
        title: trackApi?.name.isNotEmpty == true ? trackApi!.name : 'Track',
        badge: 'POPULAR',
        description: trackApi?.subtitle.isNotEmpty == true
            ? trackApi!.subtitle
            : 'One national office, one regional office and WIPO.',
        // Track is three offices: WIPO, plus two the subscriber picks.
        features: const [
          'Includes WIPO (PCT, Madrid, Hague)',
          'Choose 1 regional office (EPO, EUIPO or UPC)',
          'Choose 1 national office',
          'All 4 levels included',
        ],
        monthlyPackage: resolvePackage(trackOffering, PlanBillingInterval.monthly),
        annualPackage: resolvePackage(trackOffering, PlanBillingInterval.annual),
        fallbackMonthlyPrice: trackApi != null
            ? '${trackApi.currency} ${trackApi.priceMonthly.toStringAsFixed(2)}/mo'
            : 'CHF 39.99/mo',
        fallbackAnnualPrice: trackApi != null
            ? '${trackApi.currency} ${trackApi.priceYearly.toStringAsFixed(0)}/yr'
            : 'CHF 399/yr',
      ),
      RevenueCatPlanGroup(
        tier: PlanTier.majors,
        title: majorsApi?.name.isNotEmpty == true ? majorsApi!.name : 'Majors',
        badge: 'TOP VALUE',
        description: majorsApi?.subtitle.isNotEmpty == true
            ? majorsApi!.subtitle
            : '6 major global IP offices for international practitioners.',
        features: const [
          'USPTO, EPO, JPO, CNIPA, KIPO & WIPO',
          'Over 15,000 official exam questions',
          'Study across every office in the plan',
          'All difficulty levels included',
        ],
        monthlyPackage: resolvePackage(majorsOffering, PlanBillingInterval.monthly),
        annualPackage: resolvePackage(majorsOffering, PlanBillingInterval.annual),
        fallbackMonthlyPrice: majorsApi != null
            ? '${majorsApi.currency} ${majorsApi.priceMonthly.toStringAsFixed(2)}/mo'
            : 'CHF 59.99/mo',
        fallbackAnnualPrice: majorsApi != null
            ? '${majorsApi.currency} ${majorsApi.priceYearly.toStringAsFixed(0)}/yr'
            : 'CHF 599/yr',
      ),
      RevenueCatPlanGroup(
        tier: PlanTier.global,
        title: globalApi?.name.isNotEmpty == true ? globalApi!.name : 'Global',
        badge: 'COMPLETE',
        description: globalApi?.subtitle.isNotEmpty == true
            ? globalApi!.subtitle
            : 'Complete access to all 15 international, regional and national offices.',
        features: const [
          'All 15 IP offices worldwide',
          'No office selection needed — everything unlocked',
          'Priority updates for new legislation',
          'All 4 difficulty levels included',
        ],
        monthlyPackage: resolvePackage(globalOffering, PlanBillingInterval.monthly),
        annualPackage: resolvePackage(globalOffering, PlanBillingInterval.annual),
        fallbackMonthlyPrice: globalApi != null
            ? '${globalApi.currency} ${globalApi.priceMonthly.toStringAsFixed(2)}/mo'
            : 'CHF 139.99/mo',
        fallbackAnnualPrice: globalApi != null
            ? '${globalApi.currency} ${globalApi.priceYearly.toStringAsFixed(0)}/yr'
            : 'CHF 959.00/yr',
      ),
    ];
  }

}
