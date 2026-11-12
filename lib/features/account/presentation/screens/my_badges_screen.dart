import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../home/data/models/home_models.dart';

/// Account › My badges.
///
/// Marie's mock-up guide of 2 November, Badges: three colours per office and
/// discipline, "shown on the result screen and in Account › My badges".
///
/// The rules are printed at the bottom rather than left to be guessed. A badge
/// nobody can explain is not a reward, and the three are easy to confuse:
/// Bronze is one good quiz, Silver is a whole level, Gold is a whole
/// discipline.
final myBadgesProvider = FutureProvider<List<HomeBadge>>((ref) async {
  final response = await ref.read(apiClientProvider).get(ApiConstants.myBadges);
  final rows = response is Map<String, dynamic> ? response['data'] : null;
  if (rows is! List) return const [];
  return rows
      .whereType<Map<String, dynamic>>()
      .map(HomeBadge.fromJson)
      .toList();
});

class MyBadgesScreen extends ConsumerWidget {
  const MyBadgesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badges = ref.watch(myBadgesProvider);

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
        title: const Text(
          'My badges',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: badges.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) {
            debugPrint('[Badges] $e');
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Your badges could not be loaded. Please try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            );
          },
          data: (rows) => RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => ref.invalidate(myBadgesProvider),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                if (rows.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Text(
                      'No badge yet.\n\n'
                      'Your first one is Bronze: score at least 80% on a '
                      '20-question quiz in one level.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ...rows.map(
                  (b) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        _TierMedal(tier: b.tier),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                b.tier,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                b.title,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  height: 1.3,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              if (b.percentage > 0) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '${b.percentage}% correct',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.badgeBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How badges are earned',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Bronze — at least 80% on a 20-question quiz in one '
                        'level.\n'
                        'Silver — every question of a level answered, with at '
                        'least 80% correct.\n'
                        'Gold — Silver on all four levels of a discipline.\n\n'
                        'The free demo, "Retry the wrong ones" and "Review my '
                        'mistakes" do not count towards a badge, and each '
                        'badge is earned once.',
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.55,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
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

class _TierMedal extends StatelessWidget {
  const _TierMedal({required this.tier});

  final String tier;

  @override
  Widget build(BuildContext context) {
    final colour = switch (tier) {
      'Gold' => const Color(0xFFC9972B),
      'Silver' => const Color(0xFF9AA0AE),
      _ => const Color(0xFFB07B4F),
    };
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(color: colour, shape: BoxShape.circle),
      child: const Icon(
        Icons.workspace_premium_rounded,
        size: 24,
        color: Colors.white,
      ),
    );
  }
}
