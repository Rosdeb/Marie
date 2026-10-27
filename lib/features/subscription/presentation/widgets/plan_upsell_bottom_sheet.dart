import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/entitlement_entity.dart';
import '../providers/entitlement_provider.dart';

class PlanUpsellBottomSheet extends ConsumerWidget {
  final String officeCode;
  final String officeName;
  final String territory;

  const PlanUpsellBottomSheet({
    super.key,
    required this.officeCode,
    required this.officeName,
    required this.territory,
  });

  static Future<void> show(
    BuildContext context, {
    required String officeCode,
    required String officeName,
    required String territory,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PlanUpsellBottomSheet(
        officeCode: officeCode,
        officeName: officeName,
        territory: territory,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entitlement = ref.watch(entitlementProvider);
    final upgradeOptions = entitlement.getUpgradeOptions(officeCode);
    final isFocus = entitlement.planId == PlanTier.focus;
    final isTrack = entitlement.planId == PlanTier.track;
    final hasNoSub = entitlement.planId == PlanTier.none || !entitlement.isActive;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Office Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryDeep,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.lock_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$officeCode · $officeName',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            territory,
                            style: const TextStyle(
                              color: Color(0xFFB0BEC5),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Locked',
                        style: TextStyle(
                          color: Color(0xFFFCA5A5),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Context Description
              if (hasNoSub) ...[
                const Text(
                  'Subscription Required',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Access to official exam practice questions and comprehensive legal rationales requires an active subscription plan.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                CustomButton(
                  text: 'Explore Subscription Plans',
                  onPressed: () {
                    context.pop();
                    context.push('/subscription');
                  },
                ),
              ] else ...[
                Text(
                  '$officeCode is not in your ${entitlement.planId.displayName} plan',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your current plan unlocks ${entitlement.includedOffices.join(", ")}. Choose one of the options below to practice $officeCode.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),

                // Option 1: Switch Office (if on Focus or Track)
                if (isFocus || isTrack) ...[
                  _buildSwitchOfficeOption(context, ref, entitlement),
                  const SizedBox(height: 16),
                ],

                // Option 2: Upgrade Plans that include this office
                if (upgradeOptions.isNotEmpty) ...[
                  const Text(
                    'Upgrade Your Plan',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...upgradeOptions.map(
                    (tier) => _buildUpgradeCard(context, tier),
                  ),
                ],
              ],

              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => context.pop(),
                  child: const Text(
                    'Not now',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchOfficeOption(
    BuildContext context,
    WidgetRef ref,
    EntitlementEntity entitlement,
  ) {
    final canSwitch = entitlement.officeChangeAllowed;
    final changeDate = entitlement.nextOfficeChangeDate;
    final dateStr = changeDate != null
        ? '${changeDate.day}/${changeDate.month}/${changeDate.year}'
        : 'next billing period';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.swap_horiz_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Switch your plan office',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: canSwitch
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  canSwitch ? 'Available now' : 'Limit reached',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: canSwitch
                        ? const Color(0xFF059669)
                        : const Color(0xFFDC2626),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            canSwitch
                ? 'You may change your selected office once per billing period without paying anything extra.'
                : 'You have already changed your office for this billing period. Next change available on $dateStr.',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          if (canSwitch) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 38,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  context.pop();
                  final ok = await ref.read(entitlementProvider.notifier).chooseOffices(
                    single: officeCode,
                  );
                  if (context.mounted && ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Switched active office to $officeCode successfully!'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  }
                },
                child: Text(
                  'Switch active office to $officeCode',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUpgradeCard(BuildContext context, PlanTier tier) {
    String desc = '';
    String price = '';
    switch (tier) {
      case PlanTier.track:
        desc = 'Includes WIPO + 1 National + 1 Regional office';
        price = 'CHF 29.99/mo';
        break;
      case PlanTier.majors:
        desc = 'Fixed set: USPTO, EPO, JPO, CNIPA, KIPO, WIPO';
        price = 'CHF 54.99/mo';
        break;
      case PlanTier.global:
        desc = 'All 15 IP offices worldwide with full access';
        price = 'CHF 119.99/mo';
        break;
      default:
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      tier.displayName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      price,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              context.pop();
              context.push('/subscription');
            },
            child: const Text(
              'Upgrade',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
