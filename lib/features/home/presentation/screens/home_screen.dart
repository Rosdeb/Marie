import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/floating_success_bar.dart';
import '../../../../core/widgets/global_header.dart';
import '../../data/models/demo_model.dart';
import '../../../practice/presentation/providers/practice_provider.dart';
import '../providers/demo_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fixed Top App Bar Section
            const GlobalHeader(),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20.0, 4.0, 20.0, 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 2. LinkedIn Exclusive Referral Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: AppColors.primaryDeep, // Dark Navy Blue
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF1A3050,
                            ).withValues(alpha: 0.25),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Badge Tags
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0077B5),
                                  // LinkedIn Blue
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'LINKEDIN EXCLUSIVE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFCC00),
                                  // Gold/Yellow Accent
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  '10% OFF',
                                  style: TextStyle(
                                    color: Color(0xFF1E1E1E),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Banner Headline
                          const Text(
                            'Share IPro & Get 10% Off Your\nPlan',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Banner Description
                          const Text(
                            'Invite your LinkedIn network to level up their IP law practice and unlock exclusive savings on premium access.',
                            style: TextStyle(
                              color: Color(0xFFD0D7E1),
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Share Button
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.blue,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                context.push('/home/share-preview');
                              },
                              icon: const Icon(
                                Icons.share,
                                size: 16,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'Share on LinkedIn',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Subtitle Text
                    const Text(
                      'Learn IP law through focused practice and\nexam-style quizzes.',
                      style: TextStyle(
                        color: Color(0xFF6E6E6E),
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 3. Try Free Demo Cards (1 to 5)
                    ...List.generate(
                      5,
                      (index) => _buildDemoCard(
                        context,
                        ref,
                        DemoItem(
                          id: 'demo_${index + 1}',
                          title: 'Try Free Demo ${index + 1}',
                          questions: 20,
                          minutes: 25,
                          subdiscipline: 'IP Law Core Set ${index + 1}',
                          level: index == 0
                              ? 'Beginner'
                              : (index < 3 ? 'Intermediate' : 'Advanced'),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // 4. Topics Section Header
                    const Text(
                      'Topics',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF424242),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Topics Grid Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildTopicCard(
                            context,
                            ref,
                            'Patents',
                            'Practice patent law\nquestions',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTopicCard(
                            context,
                            ref,
                            'Trademarks',
                            'Test your trademark\nknowledge',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Full Width Topic Card
                    _buildTopicCard(
                      context,
                      ref,
                      'Designs',
                      'Practice design\nconcepts.',
                      isFullWidth: true,
                    ),

                    const SizedBox(height: 20),

                    // 5. Unlock Full Access Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Unlock Full Access',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Practice across more topics, jurisdictions, and\nlevels.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // View Plans Button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: () => context.push('/subscription'),
                              child: const Text(
                                'View Plans',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Restore Purchases Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Already purchased? ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  FloatingSuccessBar.show(
                                    context,
                                    message: 'Purchases restored successfully!',
                                  );
                                },
                                child: const Text(
                                  'Restore Purchases',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Demo Card Builder Helper
  Widget _buildDemoCard(BuildContext context, WidgetRef ref, DemoItem demo) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.primaryDeep,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A3050).withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            demo.title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '20 questions · No account required',
            style: TextStyle(fontSize: 12, color: Color(0xFFB0BEC5)),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                ref.read(selectedDemoProvider.notifier).selectDemo(demo);
                context.push('/home/demo-config');
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Start the demo',
                    style: TextStyle(
                      color: Color(0xFF1A3050),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: Color(0xFF1A3050),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Topic Card Builder Helper
  Widget _buildTopicCard(
    BuildContext context,
    WidgetRef ref,
    String title,
    String subtitle, {
    bool isFullWidth = false,
  }) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ref.read(practiceProvider.notifier).setTopic(title);
            context.push('/practice/choose-jurisdiction');
          },
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
