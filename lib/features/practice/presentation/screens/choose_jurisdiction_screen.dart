import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/practice_provider.dart';

class ChooseJurisdictionScreen extends ConsumerWidget {
  const ChooseJurisdictionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(practiceProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Choose Jurisdiction',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                children: [
                  Text(
                    'Topic: ${selection.topic ?? "Patents"}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Select a jurisdiction to test specific legal frameworks.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 1. International Systems
                  _buildSectionHeader('International Systems'),
                  const SizedBox(height: 10),
                  _buildJurisdictionCard(
                    context: context,
                    ref: ref,
                    code: 'PCT',
                    name: 'Patent Cooperation Treaty',
                    category: 'WIPO International System',
                    isSelected: selection.jurisdiction == 'PCT',
                  ),
                  const SizedBox(height: 10),
                  _buildJurisdictionCard(
                    context: context,
                    ref: ref,
                    code: 'Madrid System',
                    name: 'International Trademark System',
                    category: 'WIPO International System',
                    isSelected: selection.jurisdiction == 'Madrid System',
                  ),
                  const SizedBox(height: 10),
                  _buildJurisdictionCard(
                    context: context,
                    ref: ref,
                    code: 'Hague System',
                    name: 'International Design System',
                    category: 'WIPO International System',
                    isSelected: selection.jurisdiction == 'Hague System',
                  ),
                  const SizedBox(height: 24),

                  // 2. Regional
                  _buildSectionHeader('Regional'),
                  const SizedBox(height: 10),
                  _buildJurisdictionCard(
                    context: context,
                    ref: ref,
                    code: 'EPO',
                    name: 'European Patent Office',
                    category: 'European Regional System',
                    isSelected: selection.jurisdiction == 'EPO',
                  ),
                  const SizedBox(height: 10),
                  _buildJurisdictionCard(
                    context: context,
                    ref: ref,
                    code: 'EUIPO',
                    name: 'European Union Intellectual Property Office',
                    category: 'EU Regional System',
                    isSelected: selection.jurisdiction == 'EUIPO',
                  ),
                  const SizedBox(height: 24),

                  // 3. National
                  _buildSectionHeader('National'),
                  const SizedBox(height: 10),
                  _buildJurisdictionCard(
                    context: context,
                    ref: ref,
                    code: 'USPTO',
                    name: 'United States Patent & Trademark Office',
                    category: 'United States',
                    isSelected: selection.jurisdiction == 'USPTO',
                  ),
                  const SizedBox(height: 10),
                  _buildJurisdictionCard(
                    context: context,
                    ref: ref,
                    code: 'CNIPA',
                    name: 'China National IP Administration',
                    category: 'China',
                    isSelected: selection.jurisdiction == 'CNIPA',
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CustomButton(
                    text: 'Continue',
                    onPressed: selection.jurisdiction != null
                        ? () => context.push('/practice/choose-level')
                        : null,
                  ),

                  const SizedBox(height: 16,),

                ],
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildJurisdictionCard({
    required BuildContext context,
    required WidgetRef ref,
    required String code,
    required String name,
    required String category,
    required bool isSelected,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppColors.primary : Colors.transparent,
          width: 1.5,
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
            ref.read(practiceProvider.notifier).setJurisdiction(code);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [

                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        code,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: isSelected ? AppColors.primary : AppColors.border,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
