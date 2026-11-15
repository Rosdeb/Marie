import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/office_entity.dart';
import '../providers/offices_provider.dart';
import '../providers/practice_provider.dart';
import '../providers/quiz_provider.dart';

/// The choices made so far, as chips that can be changed where they stand.
///
/// Marie, 11 November 2026, point 11 of her test of build 9:
///
///   "Each time I want another office or another discipline, I have to go back
///    through several screens. This is exactly what I wanted to avoid... on the
///    next screens the office and the discipline stay visible at the top and
///    can be changed in place, without going back."
///
/// So this is one widget used on every screen after the office is chosen -
/// How do you want to practise?, Choose a level, Choose a theme, Ready? -
/// rather than a header copied into each of them. A chip opens a sheet, the
/// choice is made, and the screen stays where it is.
///
/// The office list is the plan's offices that actually have questions in the
/// discipline; the discipline list is the office's own disciplines, counted
/// from the imported workbooks. Nothing is offered that cannot be practised.
class PracticeChips extends ConsumerWidget {
  const PracticeChips({super.key, this.showMode = false});

  /// Whether the mode is shown as a third chip. False before a mode is chosen.
  final bool showMode;

  static const Map<String, String> _modeLabels = {
    'by_level': 'By level',
    'by_theme': 'By theme',
    'random': 'Random mix',
    'theme_across_offices': 'Theme across offices',
    'review_mistakes': 'Review my mistakes',
    'learning_path': 'Learning path',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(practiceProvider);

    final office = selection.jurisdiction ?? '';
    final discipline = selection.topic ?? '';

    // The discipline is written as the server writes it for a reader, so
    // WIPO's Patents sheet reads "PCT" here as it does everywhere else.
    final disciplineLabel =
        selection.disciplines
            .where((d) => d.name == discipline)
            .map((d) => d.displayName)
            .firstOrNull ??
        discipline;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Wrap(
        spacing: 7,
        runSpacing: 7,
        children: [
          if (office.isNotEmpty)
            _Chip(
              text: _officeLabelOf(ref, office),
              onTap: () => _pickOffice(context, ref),
            ),
          if (disciplineLabel.isNotEmpty)
            _Chip(
              text: disciplineLabel,
              onTap: () => _pickDiscipline(context, ref),
            ),
          if (showMode && (selection.mode).isNotEmpty)
            _Chip(
              text: _modeLabels[selection.mode] ?? selection.mode,
              onTap: () => _pickMode(context, ref),
            ),
        ],
      ),
    );
  }

  String _officeLabelOf(WidgetRef ref, String code) {
    final match = ref
        .watch(officesProvider)
        .offices
        .where((o) => o.code == code)
        .firstOrNull;
    return (match?.name.isNotEmpty ?? false) ? match!.name : code;
  }

  // ------------------------------------------------------------ the pickers

  Future<void> _pickOffice(BuildContext context, WidgetRef ref) async {
    var offices = ref.read(officesProvider).offices;
    if (offices.isEmpty) {
      await ref.read(officesProvider.notifier).fetchOffices();
      if (!context.mounted) return;
      offices = ref.read(officesProvider).offices;
    }

    final picked = await _showPicker<OfficeEntity>(
      context,
      title: 'Office',
      items: offices,
      isCurrent: (o) => o.code == ref.read(practiceProvider).jurisdiction,
      label: (o) => o.name.isNotEmpty ? o.name : o.code,
      detail: (o) {
        if (o.disciplines.isNotEmpty) {
          return o.disciplines.map((d) => d.displayName).join(' · ');
        }
        if (o.fullName.isNotEmpty) {
          return o.fullName;
        }
        return o.territory;
      },
      empty: 'No offices available.',
    );

    if (picked == null) return;
    ref.read(practiceProvider.notifier).setJurisdiction(picked.code);
    ref.read(quizProvider.notifier).setOffice(picked.code);
  }

  Future<void> _pickDiscipline(BuildContext context, WidgetRef ref) async {
    final disciplines = ref.read(practiceProvider).disciplines;

    final picked = await _showPicker(
      context,
      title: 'Discipline',
      items: disciplines,
      isCurrent: (d) => d.name == ref.read(practiceProvider).topic,
      label: (d) => d.displayName,
      detail: (d) => '${d.questions} questions',
      empty: 'This office has no imported questions yet.',
    );

    if (picked == null) return;
    ref.read(practiceProvider.notifier).setTopic(picked.name);
    ref.read(quizProvider.notifier).setSubdiscipline(picked.name);
  }

  Future<void> _pickMode(BuildContext context, WidgetRef ref) async {
    final office = ref.read(practiceProvider).jurisdiction ?? '';

    final entries = _modeLabels.entries
        .where(
          (e) =>
              e.key != 'theme_across_offices' ||
              !(office == 'WIPO' || office == 'UPC'),
        )
        .toList();

    final picked = await _showPicker(
      context,
      title: 'How to practise',
      items: entries,
      isCurrent: (e) => e.key == ref.read(practiceProvider).mode,
      label: (e) => e.value,
      detail: (e) => '',
      empty: '',
    );

    if (picked == null) return;
    ref.read(practiceProvider.notifier).setMode(picked.key);
  }

  /// One sheet for all three, so the three chips behave identically.
  Future<T?> _showPicker<T>(
    BuildContext context, {
    required String title,
    required List<T> items,
    required bool Function(T) isCurrent,
    required String Function(T) label,
    required String Function(T) detail,
    required String empty,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(sheetContext).size.height * 0.75,
        ),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 22),
                child: Text(
                  empty,
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    color: AppColors.textSecondary,
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final item = items[i];
                    final current = isCurrent(item);
                    final note = detail(item);
                    return Material(
                      color: current ? AppColors.primaryLight : Colors.white,
                      borderRadius: BorderRadius.circular(13),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(13),
                        onTap: () => Navigator.of(sheetContext).pop(item),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 13,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      label(item),
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: current
                                            ? FontWeight.w700
                                            : FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    if (note.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        note,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          height: 1.3,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (current)
                                const Icon(
                                  Icons.check_rounded,
                                  size: 19,
                                  color: AppColors.primary,
                                ),
                            ],
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
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.primary, width: 1.3),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 17,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
