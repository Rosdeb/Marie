import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../subscription/domain/entities/entitlement_entity.dart';
import '../../../subscription/presentation/providers/entitlement_provider.dart';
import '../providers/auth_provider.dart';

class ConfirmSubscriptionScreen extends ConsumerStatefulWidget {
  const ConfirmSubscriptionScreen({super.key});

  @override
  ConsumerState<ConfirmSubscriptionScreen> createState() =>
      _ConfirmSubscriptionScreenState();
}

class _ConfirmSubscriptionScreenState
    extends ConsumerState<ConfirmSubscriptionScreen> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final selectedPlan = authState.selectedPlan;
    final selectedPaymentMethod = authState.selectedPaymentMethod;

    final isYearly = selectedPlan == 'yearly';
    final planTitle = isYearly ? 'Annual Premium' : 'Standard Monthly';
    final planPrice = isYearly ? '\$80.00' : '\$10.00';
    final planPeriod = isYearly ? '/ year' : '/ month';
    final originalPrice = isYearly ? '\$120.00' : '\$10.00';
    final discountAmount = isYearly ? '-\$40.00' : 'None';
    final billingIntervalDesc = isYearly ? 'Billed annually' : 'Billed monthly';
    final nextBillingDateStr = isYearly
        ? '1 year from today'
        : '1 month from today';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            size: 18,
            color: AppColors.textPrimary,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Confirm Subscription',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Heading
                    const Text(
                      'Review Your Order',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Please verify your selected plan and payment method before confirming.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Selected Plan Banner Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.06),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.workspace_premium_rounded,
                                      color: AppColors.primary,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        planTitle,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        billingIntervalDesc,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (isYearly)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.successLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'SAVE 33%',
                                    style: TextStyle(
                                      color: AppColors.success,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(height: 1, color: AppColors.border),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Price',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                              Row(
                                children: [
                                  if (isYearly) ...[
                                    Text(
                                      originalPrice,
                                      style: const TextStyle(
                                        decoration: TextDecoration.lineThrough,
                                        color: AppColors.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  Text(
                                    '$planPrice $planPeriod',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Payment Methods Section
                    const Text(
                      'Payment Method',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildPaymentOption(
                      id: 'apple_pay',
                      title: 'Apple Pay',
                      subtitle: 'Fast and secure 1-click checkout',
                      icon: Icons.apple,
                      isSelected: selectedPaymentMethod == 'apple_pay',
                      onTap: () => ref
                          .read(authProvider.notifier)
                          .selectPaymentMethod('apple_pay'),
                    ),
                    const SizedBox(height: 10),

                    _buildPaymentOption(
                      id: 'google_pay',
                      title: 'Google Pay',
                      subtitle: 'Pay directly with Google wallet',
                      icon: Icons.account_balance_wallet_outlined,
                      isSelected: selectedPaymentMethod == 'google_pay',
                      onTap: () => ref
                          .read(authProvider.notifier)
                          .selectPaymentMethod('google_pay'),
                    ),
                    const SizedBox(height: 10),

                    _buildPaymentOption(
                      id: 'credit_card',
                      title: 'Credit / Debit Card',
                      subtitle: 'Mastercard •••• 4242',
                      icon: Icons.credit_card_rounded,
                      isSelected: selectedPaymentMethod == 'credit_card',
                      onTap: () => ref
                          .read(authProvider.notifier)
                          .selectPaymentMethod('credit_card'),
                    ),
                    const SizedBox(height: 24),

                    // Order Summary Breakdown
                    const Text(
                      'Order Summary',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          _buildSummaryRow(
                            label: 'Subtotal',
                            value: originalPrice,
                          ),
                          const SizedBox(height: 10),
                          if (isYearly) ...[
                            _buildSummaryRow(
                              label: 'Annual Discount',
                              value: discountAmount,
                              valueColor: AppColors.success,
                            ),
                            const SizedBox(height: 10),
                          ],
                          _buildSummaryRow(
                            label: 'Estimated Taxes',
                            value: '\$0.00',
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(height: 1, color: AppColors.border),
                          ),
                          _buildSummaryRow(
                            label: 'Total Due Today',
                            value: planPrice,
                            isBold: true,
                            valueColor: AppColors.primary,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Next Billing Date',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                nextBillingDateStr,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // What's included checklist
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.badgeBg.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: AppColors.success,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Included in this plan:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Point 6.2, and Marie on 8 November 2026: "please
                          // remove them all; only true statements may remain."
                          //
                          // Four claims were replaced here:
                          //
                          //  - "all 500+ practice questions & mock exams".
                          //    "Mock exams" is the wording her Terms of Use
                          //    rule out, and the count was invented - what a
                          //    plan gives access to depends on which offices
                          //    it covers, so no single number is true of it.
                          //  - "Comprehensive legal rationales & reference
                          //    links". There are no links: Legal_Basis is a
                          //    citation, and "comprehensive" is a claim
                          //    nobody can stand behind.
                          //  - "Cancel anytime easily from account settings".
                          //    Plainly untrue. The subscription belongs to
                          //    the App Store or Google Play, not to the IPro
                          //    account, and it is cancelled there.
                          //  - the weakness analysis, which is real, but is
                          //    named for what the Progress page shows.
                          _buildIncludedItem(
                            'Exam-style questions in four levels for every office in the plan',
                          ),
                          _buildIncludedItem(
                            'An explanation and the legal basis for every answer',
                          ),
                          _buildIncludedItem(
                            'Progress by level and by theme, with your weakest themes named',
                          ),
                          _buildIncludedItem(
                            'Cancel at any time in your App Store or Google Play subscriptions',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Who takes the payment.
                    //
                    // This read "256-Bit SSL Encrypted & Secure Checkout",
                    // which is not IPro's to claim: there is no IPro
                    // checkout. The purchase is made by the App Store or
                    // Google Play, and the card never reaches our server.
                    // That is both true and more reassuring than a cipher
                    // length (point 6.2).
                    const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Payment is handled by the App Store or Google Play. '
                              'IPro never sees your card details.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Bottom Action Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomButton(
                    text: 'Confirm & Subscribe ($planPrice)',
                    isLoading: authState.isLoading,
                    onPressed: () async {
                      final success = await ref
                          .read(authProvider.notifier)
                          .confirmSubscription();
                      if (success && context.mounted) {
                        await ref
                            .read(entitlementProvider.notifier)
                            .syncFromRevenueCat();
                        if (!context.mounted) return;
                        final entitlement = ref.read(entitlementProvider);
                        if (entitlement.needsOfficeSelection &&
                            (entitlement.planId == PlanTier.focus ||
                                entitlement.planId == PlanTier.track)) {
                          context.go('/subscription/office-selection');
                        } else {
                          context.go('/subscription-success');
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Recurring billing. Cancel anytime before renewal date.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.8 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryLight : AppColors.badgeBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.primary : AppColors.border,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow({
    required String label,
    required String value,
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 15 : 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 17 : 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildIncludedItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check, size: 14, color: AppColors.success),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
