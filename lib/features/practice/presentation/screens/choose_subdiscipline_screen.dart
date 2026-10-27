import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/offices_provider.dart';
import '../providers/practice_provider.dart';
import '../providers/quiz_provider.dart';

class ChooseSubdisciplineScreen extends ConsumerWidget {
  const ChooseSubdisciplineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(practiceProvider);
    final selectedSubdiscipline = ref.watch(quizProvider).selectedSubdiscipline;
    final offices = ref.watch(officesProvider).offices;

    final jurisdiction = selection.jurisdiction ?? 'IPI';
    final disciplines = _resolveDisciplinesForOffice(jurisdiction, offices);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text(
          '$jurisdiction Disciplines',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select a discipline within $jurisdiction',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'All disciplines and legal variants are included in your subscription.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: disciplines.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = disciplines[index];
                  final isSelected = item == selectedSubdiscipline;

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.transparent,
                        width: isSelected ? 1.5 : 0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          ref.read(quizProvider.notifier).setSubdiscipline(item);
                          ref.read(practiceProvider.notifier).setTopic(item);
                          context.push('/practice/choose-level');
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Full syllabus & official questions',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 14,
                                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _resolveDisciplinesForOffice(
    String code,
    List<dynamic> remoteOffices,
  ) {
    final upper = code.toUpperCase().trim();
    if (upper == 'WIPO') {
      return const ['Patents (PCT)', 'Trademarks (Madrid)', 'Designs (Hague)'];
    }
    if (upper == 'EPO') {
      return const ['Patents'];
    }
    if (upper == 'EUIPO') {
      return const ['Trademarks', 'Designs'];
    }
    if (upper == 'UPC') {
      return const ['Unitary Patent', 'Procedure', 'Decisions'];
    }

    // Check remote office disciplines if available
    for (final off in remoteOffices) {
      if (off.code.toString().toUpperCase() == upper && off.disciplines.isNotEmpty) {
        return off.disciplines.map<String>((d) => d.name.toString()).toList();
      }
    }

    // Standard national IP branches
    return const ['Patents', 'Trademarks', 'Designs'];
  }
}
