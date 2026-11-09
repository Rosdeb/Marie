import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/custom_shimmer.dart';
import '../../data/models/revenuecat_plan_models.dart';
import '../../domain/entities/entitlement_entity.dart';
import '../providers/entitlement_provider.dart';
import '../providers/plans_provider.dart';

class PlansScreen extends ConsumerStatefulWidget {
  const PlansScreen({super.key});

  @override
  ConsumerState<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends ConsumerState<PlansScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(entitlementProvider.notifier).refresh();
      ref.read(plansProvider.notifier).loadOfferings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final plansState = ref.watch(plansProvider);
    final entitlement = ref.watch(entitlementProvider);
    final plansNotifier = ref.read(plansProvider.notifier);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.close_rounded,
                color: AppColors.textPrimary,
              ),
              onPressed: () => context.pop(),
            ),
            actions: [
              TextButton(
                onPressed: plansState.isRestoring
                    ? null
                    : () async {
                        final ok = await plansNotifier.restorePurchases();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ok
                                    ? 'Purchases restored successfully!'
                                    : 'No active purchases to restore.',
                              ),
                              backgroundColor: ok
                                  ? AppColors.primary
                                  : Colors.black87,
                            ),
                          );
                        }
                      },
                child: plansState.isRestoring
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Restore',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            child: plansState.isLoading
                ? _buildLoadingSkeleton()
                : plansState.errorMessage != null &&
                      plansState.planGroups.isEmpty
                ? _buildErrorView(
                    context,
                    plansNotifier,
                    plansState.errorMessage!,
                  )
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Active Subscription Section
                        if (entitlement.isActive) ...[
                          _buildMySubscriptionCard(context, ref, entitlement),
                          const SizedBox(height: 16),
                          const Text(
                            'Available Plans',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Add a plan at any time. Your access is every office of every plan you hold.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ] else ...[
                          const Text(
                            'Choose your office access',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'One subscription, full access to your selected offices. All difficulty levels and disciplines are included.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Plan Cards
                        ...plansState.planGroups.map(
                          (plan) => _buildPlanCard(
                            context: context,
                            ref: ref,
                            plan: plan,
                            currentTier: entitlement.planId,
                            activePlans: entitlement.activePlans,
                            isSubscribed: entitlement.isActive,
                            selectedInterval:
                                plansState.selectedIntervals[plan.tier] ??
                                PlanBillingInterval.annual,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Footer Strip
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Hold as many plans as you like. A new plan is added to the ones you already have, never in place of them.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Legal links & How it works
                        Center(
                          child: Column(
                            children: [
                              TextButton(
                                onPressed: () =>
                                    context.push('/subscription/how-it-works'),
                                child: const Text(
                                  'How subscriptions work',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  TextButton(
                                    onPressed: () => context.push('/terms'),
                                    child: const Text(
                                      'Terms of Service',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  const Text(
                                    '•',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        context.push('/privacy-policy'),
                                    child: const Text(
                                      'Privacy Policy',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
          ),
        ),

        // Purchasing overlay blocking interaction
        if (plansState.isPurchasing)
          Container(
            color: Colors.black.withValues(alpha: 0.45),
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text(
                    'Processing purchase...',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPlanCard({
    required BuildContext context,
    required WidgetRef ref,
    required RevenueCatPlanGroup plan,
    required PlanTier currentTier,
    required List<PlanTier> activePlans,
    required bool isSubscribed,
    required PlanBillingInterval selectedInterval,
  }) {
    final isCurrent =
        isSubscribed &&
        (activePlans.isNotEmpty
            ? activePlans.contains(plan.tier)
            : currentTier == plan.tier);
    // There is no upgrade and no downgrade.
    //
    // Marie, point 6.1: "A user can hold several plans; access is the union
    // of their offices. Buttons 'Subscribe to ...'; nothing is downgraded or
    // replaced." Ranking the plans by tier and calling the move up an
    // upgrade and the move down a downgrade described the opposite of what
    // the product does - a second plan is added to the first.
    final ctaText = isCurrent ? 'Current Plan' : 'Subscribe to ${plan.title}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCurrent
              ? AppColors.primary
              : (plan.badge != null
                    ? AppColors.primary.withValues(alpha: 0.3)
                    : const Color(0xFFE2E8F0)),
          width: isCurrent ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isCurrent
                ? AppColors.primary.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Title + Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  plan.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (isCurrent)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'CURRENT PLAN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  )
                else if (plan.badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF10B981),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      plan.badge!,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF059669),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              plan.description,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),

            // Feature Checklist
            ...plan.features.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 15,
                      color: Color(0xFF10B981),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        f,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textPrimary,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Monthly vs Annual Price Selector Boxes
            Row(
              children: [
                Expanded(
                  child: _buildPriceBox(
                    label: 'Monthly',
                    price: plan.monthlyPriceString,
                    subtitle: 'Billed monthly',
                    isSelected: selectedInterval == PlanBillingInterval.monthly,
                    onTap: () {
                      ref
                          .read(plansProvider.notifier)
                          .selectInterval(
                            plan.tier,
                            PlanBillingInterval.monthly,
                          );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildPriceBox(
                    label: 'Annual',
                    price: plan.annualPriceString,
                    subtitle: 'Save up to 20%',
                    isBestValue: true,
                    isSelected: selectedInterval == PlanBillingInterval.annual,
                    onTap: () {
                      ref
                          .read(plansProvider.notifier)
                          .selectInterval(
                            plan.tier,
                            PlanBillingInterval.annual,
                          );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // CTA Button
            CustomButton(
              text: ctaText,
              onPressed: isCurrent
                  ? null
                  : () async {
                      /*
                       * A second plan is explained before it is bought.
                       *
                       * Marie, 8 November 2026, agreeing to one App Store
                       * subscription group per plan:
                       *   "However, users must understand what this means.
                       *    Before they buy a second plan, and in Help &
                       *    Support, the app must explain clearly that each
                       *    plan is a separate subscription on the iPhone and
                       *    must be cancelled separately."
                       *
                       * Separate groups are what let a subscriber hold Focus
                       * and Majors at once - two subscriptions in one group
                       * can never both be active on Apple, so a single group
                       * would make the second purchase replace the first,
                       * which is precisely what point 6.1 forbids. The cost
                       * of the arrangement is that the store shows two
                       * subscriptions and asks for two cancellations, and a
                       * subscriber should learn that here rather than when
                       * they come to cancel.
                       *
                       * Only shown when a plan is already held: on a first
                       * purchase there is nothing separate to explain, and a
                       * sheet about cancelling two subscriptions would be
                       * noise in front of the one that matters.
                       */
                      if (activePlans.isNotEmpty) {
                        final held = activePlans
                            .map((t) => t.displayName)
                            .join(', ');
                        final goAhead = await _confirmAdditionalPlan(
                          context,
                          adding: plan.title,
                          held: held,
                          totalAfter: activePlans.length + 1,
                        );
                        if (goAhead != true) return;
                      }

                      final success = await ref
                          .read(plansProvider.notifier)
                          .purchasePlan(plan.tier);
                      if (success && context.mounted) {
                        // Refresh entitlement to fetch latest /subscription/my-access state
                        await ref.read(entitlementProvider.notifier).refresh();

                        final refreshed = ref.read(entitlementProvider);
                        if (refreshed.needsOfficeSelection &&
                            (refreshed.planId == PlanTier.focus ||
                                refreshed.planId == PlanTier.track) &&
                            context.mounted) {
                          context.push('/subscription/office-selection');
                        }

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Subscribed to ${plan.title}!'),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        }
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }

  /// What holding more than one plan means, shown before the purchase.
  ///
  /// Returns true only if the subscriber chooses to continue. The wording
  /// names the plans they already hold and how many subscriptions they will
  /// end up with, because "each plan is separate" stays abstract until it is
  /// "you will have two subscriptions".
  ///
  /// It says "App Store or Google Play" rather than naming one. Google does
  /// allow several products at once without the group arrangement, but the
  /// subscription still lives in Play and is still cancelled there, so the
  /// sentence is true on both platforms and needs no second version.
  Future<bool?> _confirmAdditionalPlan(
    BuildContext context, {
    required String adding,
    required String held,
    required int totalAfter,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: 20 + MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.layers_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Adding $adding to your access',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'You already have $held. $adding is added to it - nothing '
                  'is replaced, and your access becomes every office of both.',
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.badgeBg.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Because plans add up, each one is a separate '
                        'subscription:',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '-  You will be billed for $totalAfter subscriptions, '
                        'each on its own renewal date.',
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.45,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '-  They appear as $totalAfter separate subscriptions '
                        'in your App Store or Google Play settings, and each '
                        'must be cancelled separately.',
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.45,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '-  Cancelling one leaves the other running, and you '
                        'keep the offices it covers.',
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.45,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(sheetContext).pop(false),
                        child: const Text(
                          'Not now',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CustomButton(
                        text: 'Continue',
                        onPressed: () => Navigator.of(sheetContext).pop(true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMySubscriptionCard(
    BuildContext context,
    WidgetRef ref,
    EntitlementEntity entitlement,
  ) {
    final isFocus = entitlement.planId == PlanTier.focus;
    final isTrack = entitlement.planId == PlanTier.track;
    final isFixedOfficePlan =
        entitlement.planId == PlanTier.majors ||
        entitlement.planId == PlanTier.global;
    final needsSelection =
        entitlement.needsOfficeSelection || entitlement.selectedOffices.isEmpty;

    String officesDescription;
    if (isFocus) {
      if (!needsSelection && entitlement.selectedOffices.isNotEmpty) {
        officesDescription =
            'Selected Office: ${entitlement.selectedOffices.first}';
      } else {
        officesDescription =
            'Office not selected yet. Choose 1 office to start practicing.';
      }
    } else if (isTrack) {
      if (!needsSelection && entitlement.selectedOffices.isNotEmpty) {
        // All three, in the order they are granted, rather than one of them
        // plus a claim about the rest.
        officesDescription =
            'Your offices: ${entitlement.selectedOffices.join(', ')}';
      } else {
        officesDescription =
            'Choose 1 national office and 1 regional office. WIPO is included: three offices in all.';
      }
    } else if (entitlement.planId == PlanTier.majors) {
      // MOIP, not KIPO. The office was renamed the Ministry of Intellectual
      // Property on 1 October 2025 (point 6.3), and Marie asked on 8 November
      // 2026 for MOIP "everywhere the user reads it". The code stays KIPO in
      // the data and in the store entitlement; only this sentence changes.
      officesDescription =
          'Fixed access to all 6 major offices: USPTO, EPO, JPO, CNIPA, MOIP & WIPO.';
    } else {
      officesDescription =
          // Not all fifteen are patent offices: the EUIPO registers trade
          // marks and designs, and the UPC is a court (point 6.1).
          'Full access to all 15 IP offices.';
    }

    final renewalDate = entitlement.periodEnd != null
        ? 'Renews ${_formatDate(entitlement.periodEnd)}'
        : (entitlement.billingPeriod != 'none'
              ? '${entitlement.billingPeriod[0].toUpperCase()}${entitlement.billingPeriod.substring(1)} billing'
              : 'Active subscription');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.workspace_premium_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'MY SUBSCRIPTION',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF10B981),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'ACTIVE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF059669),
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${entitlement.planId.displayName} Plan',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      renewalDate,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  officesDescription,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: needsSelection && (isFocus || isTrack)
                        ? const Color(0xFFD97706)
                        : AppColors.textSecondary,
                    fontWeight: needsSelection && (isFocus || isTrack)
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),

                // Office badges if selected
                if (entitlement.selectedOffices.isNotEmpty &&
                    !isFixedOfficePlan) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (isTrack)
                        _buildOfficeChip('WIPO (Fixed)', isFixed: true),
                      ...entitlement.selectedOffices.map(
                        (code) => _buildOfficeChip(code),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),

                // Action button
                if (isFocus || isTrack)
                  CustomButton(
                    text: needsSelection
                        ? 'Choose Your Office'
                        : (entitlement.officeChangeAllowed
                            ? 'Change Office Access'
                            : 'Start Practicing'),
                    icon: Icon(
                      needsSelection || entitlement.officeChangeAllowed
                          ? Icons.tune_rounded
                          : Icons.arrow_forward_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      if (needsSelection || entitlement.officeChangeAllowed) {
                        context.push('/subscription/office-selection');
                      } else {
                        context.push('/practice');
                      }
                    },
                  )
                else
                  CustomButton(
                    text: 'Start Practicing',
                    icon: const Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      context.push('/practice');
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfficeChip(String label, {bool isFixed = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isFixed ? const Color(0xFFF1F5F9) : AppColors.primaryLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isFixed
              ? const Color(0xFFCBD5E1)
              : AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isFixed ? AppColors.textSecondary : AppColors.primary,
        ),
      ),
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  Widget _buildPriceBox({
    required String label,
    required String price,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    bool isBestValue = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
            width: isSelected ? 1.6 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
                ),
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  size: 16,
                  color: isSelected ? AppColors.primary : Colors.grey.shade400,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              price,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: isBestValue
                    ? const Color(0xFF059669)
                    : AppColors.textSecondary,
                fontWeight: isBestValue ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          CustomShimmer(
            child: Container(
              width: double.infinity,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 12),
          CustomShimmer(
            child: Container(
              width: double.infinity,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 24),
          CustomShimmer(
            child: Container(
              width: double.infinity,
              height: 220,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          CustomShimmer(
            child: Container(
              width: double.infinity,
              height: 220,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(
    BuildContext context,
    PlansNotifier notifier,
    String message,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'Unable to load subscription plans',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: notifier.loadOfferings,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
