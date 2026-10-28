import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../referral/data/models/referral_models.dart';
import '../../../referral/presentation/providers/referral_provider.dart';
import '../../../referral/presentation/widgets/referral_video_player.dart';

class HowItWorksScreen extends ConsumerWidget {
  const HowItWorksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final refState = ref.watch(referralProvider);
    final howItWorks = refState.sharePreview.howItWorks;
    final video = refState.sharePreview.video;

    final steps = howItWorks.steps.isNotEmpty
        ? howItWorks.steps
        : const [
            HowItWorksStep(
              step: 1,
              title: 'Review your post',
              body: 'Check the message and your personal referral link.',
            ),
            HowItWorksStep(
              step: 2,
              title: 'Share on LinkedIn',
              body: 'Connect your account and post directly to your network.',
            ),
            HowItWorksStep(
              step: 3,
              title: 'Get 10% off in the app',
              body: 'Unlock your exclusive promo code immediately for checkout.',
            ),
          ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            size: 18,
            color: AppColors.textPrimary,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          howItWorks.screenTitle.isNotEmpty
              ? howItWorks.screenTitle
              : 'How it works',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Video Guide Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title ?? 'How It Works — Video Guide',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ReferralVideoPlayer(
                      videoUrl: video.videoUrl,
                      thumbnailUrl: video.thumbnailUrl,
                      title: video.title ?? 'How It Works Video Guide',
                      comingSoon: video.comingSoon,
                      height: 180,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 2. Grey Availability Card (if provided by backend)
              if (howItWorks.availabilityTitle != null &&
                  howItWorks.availabilityTitle!.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9), // Grey availability card
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 18,
                            color: Color(0xFF475569),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              howItWorks.availabilityTitle!,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (howItWorks.availabilityNote != null &&
                          howItWorks.availabilityNote!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          howItWorks.availabilityNote!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 3. Steps Guide Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      howItWorks.title.isNotEmpty
                          ? howItWorks.title
                          : 'Share on LinkedIn. Get 10% off.',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Dynamic Steps
                    ...steps.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final step = entry.value;
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: idx < steps.length - 1 ? 20.0 : 0.0,
                        ),
                        child: _buildStepRow(
                          stepNumber: '${step.step}',
                          title: step.title,
                          description: step.body,
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Step Row Helper
  Widget _buildStepRow({
    required String stepNumber,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              stepNumber,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
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
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
