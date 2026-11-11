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

  /// The RevenueCat offering this plan was read from - `focus`, `focus_ref10` -
  /// or the id that was looked for and not found.
  ///
  /// Carried so that a plan which cannot be shown can say *which* offering is
  /// missing. "Plans unavailable" on its own is not a diagnosis.
  final String offeringId;

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
    this.offeringId = '',
  });

  /// Whether anything in this plan can be bought.
  ///
  /// False means RevenueCat returned no package for it - a missing offering, a
  /// product still in *Missing Metadata*, or a store agreement that is not yet
  /// active. The paywall must say so rather than offer a button that cannot
  /// work.
  bool get isAvailable => monthlyPackage != null || annualPackage != null;

  /// The price the store itself quotes, in the buyer's own currency.
  ///
  /// Falls back to the price Marie entered on the dashboard, and then to a
  /// dash. It never falls back to a figure written into the app: the store is
  /// the only place that knows what this person will actually be charged, and
  /// a stale number beside a purchase button is both wrong and a reason for
  /// Apple to reject the build.
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

    /// Which offering id each plan was resolved from, for the unavailable state.
    final resolvedIds = <PlanTier, String>{};

    Offering? getOfferingForTier(PlanTier tier) {
      final name = tier.name.toLowerCase();

      if (offerings == null) {
        resolvedIds[tier] = name;
        return null;
      }

      // A redeemed referral asks for the discounted basket first and falls
      // back to the list price if it is not set up. That fallback is required,
      // not defensive: a buyer paying full price is a worse outcome than the
      // discount, and a far better one than an empty paywall.
      if (useReferralOffering) {
        final discountedId = '$name$referralOfferingSuffix';
        final discounted = offeringNamed(discountedId);
        if (discounted != null) {
          resolvedIds[tier] = discountedId;
          return discounted;
        }
      }

      resolvedIds[tier] = name;
      // Deliberately no `?? offerings.current`. There are eight equal
      // offerings - one per plan, at each of the two prices - so none of them
      // is a default, and asking for "current" would hand back some arbitrary
      // plan's products and sell the buyer the wrong thing. Missing is missing.
      return offeringNamed(name);
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
            // "unlimited questions" is a count nobody can stand behind and
            // "mock exams" is ruled out by her Terms of Use - point 9.
            : 'Practice one office of your choice, with every discipline and all four levels.',
        features: const [
          'Choose any 1 office (e.g. USPTO, EPO, IPI)',
          'Change office once per billing period',
          'All 4 difficulty levels included',
          'Full legal rationales & explanations',
        ],
        offeringId: resolvedIds[PlanTier.focus] ?? 'focus',
        monthlyPackage: resolvePackage(focusOffering, PlanBillingInterval.monthly),
        annualPackage: resolvePackage(focusOffering, PlanBillingInterval.annual),
        fallbackMonthlyPrice: focusApi != null
            ? '${focusApi.currency} ${focusApi.priceMonthly.toStringAsFixed(2)}/mo'
            : null,
        fallbackAnnualPrice: focusApi != null
            ? '${focusApi.currency} ${focusApi.priceYearly.toStringAsFixed(0)}/yr'
            : null,
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
        offeringId: resolvedIds[PlanTier.track] ?? 'track',
        monthlyPackage: resolvePackage(trackOffering, PlanBillingInterval.monthly),
        annualPackage: resolvePackage(trackOffering, PlanBillingInterval.annual),
        fallbackMonthlyPrice: trackApi != null
            ? '${trackApi.currency} ${trackApi.priceMonthly.toStringAsFixed(2)}/mo'
            : null,
        fallbackAnnualPrice: trackApi != null
            ? '${trackApi.currency} ${trackApi.priceYearly.toStringAsFixed(0)}/yr'
            : null,
      ),
      RevenueCatPlanGroup(
        tier: PlanTier.majors,
        title: majorsApi?.name.isNotEmpty == true ? majorsApi!.name : 'Majors',
        badge: 'TOP VALUE',
        description: majorsApi?.subtitle.isNotEmpty == true
            ? majorsApi!.subtitle
            : '6 major global IP offices for international practitioners.',
        features: const [
          // Marie, 3 November 2026, point 6.2: "No question count and only
          // features that exist." The invented "Over 15,000" is gone, and
          // "official exam questions" with it - her Terms of Use state that no
          // official exam question is reproduced.
          //
          // Point 6.3: KIPO became the Ministry of Intellectual Property on
          // 1 October 2025. The office code stays KIPO in the data and in the
          // workbook file names; only what the reader sees changes.
          'USPTO, EPO, JPO, CNIPA, MOIP & WIPO',
          'Exam-style questions in four levels',
          'Study across every office in the plan',
          'Explanation and legal basis for every answer',
        ],
        offeringId: resolvedIds[PlanTier.majors] ?? 'majors',
        monthlyPackage: resolvePackage(majorsOffering, PlanBillingInterval.monthly),
        annualPackage: resolvePackage(majorsOffering, PlanBillingInterval.annual),
        fallbackMonthlyPrice: majorsApi != null
            ? '${majorsApi.currency} ${majorsApi.priceMonthly.toStringAsFixed(2)}/mo'
            : null,
        fallbackAnnualPrice: majorsApi != null
            ? '${majorsApi.currency} ${majorsApi.priceYearly.toStringAsFixed(0)}/yr'
            : null,
      ),
      RevenueCatPlanGroup(
        tier: PlanTier.global,
        title: globalApi?.name.isNotEmpty == true ? globalApi!.name : 'Global',
        badge: 'COMPLETE',
        description: globalApi?.subtitle.isNotEmpty == true
            ? globalApi!.subtitle
            : 'Complete access to all 15 international, regional and national offices.',
        features: const [
          // "Priority updates for new legislation" was never offered (6.2).
          'All 15 IP offices worldwide',
          'No office selection needed — everything unlocked',
          'Exam-style questions in four levels',
          'Explanation and legal basis for every answer',
        ],
        offeringId: resolvedIds[PlanTier.global] ?? 'global',
        monthlyPackage: resolvePackage(globalOffering, PlanBillingInterval.monthly),
        annualPackage: resolvePackage(globalOffering, PlanBillingInterval.annual),
        fallbackMonthlyPrice: globalApi != null
            ? '${globalApi.currency} ${globalApi.priceMonthly.toStringAsFixed(2)}/mo'
            : null,
        fallbackAnnualPrice: globalApi != null
            ? '${globalApi.currency} ${globalApi.priceYearly.toStringAsFixed(0)}/yr'
            // No figure here on purpose. A yearly price used to be written
            // into this file, and it was wrong twice - once at 959 and once
            // after Marie changed the plan table. The store knows the price
            // and the dashboard knows her intent; the app should know neither.
            : null,
      ),
    ];
  }

}
