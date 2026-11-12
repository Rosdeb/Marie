import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../subscription/presentation/providers/entitlement_provider.dart';
import '../providers/offices_provider.dart';
import '../providers/practice_provider.dart';
import '../../../../../core/utils/office_label.dart';

/// "Theme across offices": pick two or more offices to compare the theme in.
///
/// Section 5: "the user chooses a theme, then two or more offices of their
/// plan; the quiz mixes the questions of that theme in those offices, across
/// the four levels."
///
/// WIPO and the UPC are not offered here. Their themes are their own, so
/// there is nothing to compare: "WIPO and the UPC have their own lists and
/// are excluded from this mode."
class ChooseCrossOfficesScreen extends ConsumerStatefulWidget {
  const ChooseCrossOfficesScreen({super.key});

  @override
  ConsumerState<ChooseCrossOfficesScreen> createState() =>
      _ChooseCrossOfficesScreenState();
}

class _ChooseCrossOfficesScreenState
    extends ConsumerState<ChooseCrossOfficesScreen> {
  static const _excluded = {'WIPO', 'UPC', 'JUB'};

  late Set<String> _picked;
  bool _seeded = false;

  @override
  Widget build(BuildContext context) {
    final selection = ref.watch(practiceProvider);
    final officesState = ref.watch(officesProvider);
    final entitlement = ref.watch(entitlementProvider);

    // The office the reader came in on is pre-ticked: they are already
    // practising it, and the mode needs at least one more beside it.
    if (!_seeded) {
      final current = selection.jurisdiction;
      _picked = {
        if (current != null && !_excluded.contains(current.toUpperCase()))
          current,
      };
      _seeded = true;
    }

    // Only offices that are in the plan and actually hold questions: a menu
    // entry with nothing behind it is not offered (section 4.2).
    final available = officesState.offices
        .where((o) => !_excluded.contains(o.code.toUpperCase()))
        .where((o) => o.questions > 0)
        .where((o) => entitlement.canAccessOffice(o.code))
        .toList();

    final enough = _picked.length >= 2;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: context.pop,
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
        ),
        title: const Text(
          'Which offices?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: officesState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selection.theme ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Choose two or more. WIPO and the UPC are not offered '
                        'here: their themes are their own, so there is nothing '
                        'to compare.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: available.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text(
                              'No other office in your plan has questions yet.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          itemCount: available.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final office = available[index];
                            final isPicked = _picked.contains(office.code);
                            return _OfficeTile(
                              code: office.code,
                              name: office.fullName.isNotEmpty
                                  ? office.fullName
                                  : office.name,
                              questions: office.questions,
                              selected: isPicked,
                              onTap: () => setState(() {
                                if (isPicked) {
                                  _picked.remove(office.code);
                                } else {
                                  _picked.add(office.code);
                                }
                              }),
                            );
                          },
                        ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Column(
                      children: [
                        if (!enough)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Text(
                              'Pick at least two offices to compare.',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        CustomButton(
                          text: 'Continue',
                          onPressed: enough
                              ? () {
                                  ref
                                      .read(practiceProvider.notifier)
                                      .setCrossOffices(_picked.toList());
                                  context.push('/practice/exam-ready');
                                }
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _OfficeTile extends StatelessWidget {
  const _OfficeTile({
    required this.code,
    required this.name,
    required this.questions,
    required this.selected,
    required this.onTap,
  });

  final String code;
  final String name;
  final int questions;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary.withValues(alpha: 0.07) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primary : const Color(0xFFE2E8F0),
              width: selected ? 1.2 : 0.8,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.check_box_rounded
                    : Icons.check_box_outline_blank_rounded,
                size: 20,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      officeLabel(code),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$questions',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
