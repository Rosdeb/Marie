import 'package:flutter_test/flutter_test.dart';
import 'package:marie_nirva/features/practice/data/models/discipline_theme_models.dart';
import 'package:marie_nirva/features/practice/utils/theme_order_helper.dart';

void main() {
  group('ThemeOrderHelper Tests', () {
    test('sorts Patents themes in Appendix B canonical order', () {
      final input = [
        const ThemeDetailModel(theme: 'Search, publication & examination'),
        const ThemeDetailModel(theme: 'Filing & formalities'),
        const ThemeDetailModel(theme: 'Foundations & institutions'),
        const ThemeDetailModel(theme: 'Priority'),
        const ThemeDetailModel(theme: 'Patentability'),
        const ThemeDetailModel(theme: 'Infringement & remedies'),
        const ThemeDetailModel(theme: 'Opposition, invalidity & appeal'),
        const ThemeDetailModel(theme: 'Grant, term & maintenance'),
        const ThemeDetailModel(theme: 'Time limits & remedies'),
        const ThemeDetailModel(theme: 'Transfers & licences'),
        const ThemeDetailModel(theme: 'International routes (PCT, EP)'),
      ];

      final sorted = ThemeOrderHelper.sortThemes(input, 'Patents');
      final names = sorted.map((t) => t.theme).toList();

      expect(names, [
        'Foundations & institutions',
        'Patentability',
        'Filing & formalities',
        'Priority',
        'Search, publication & examination',
        'Grant, term & maintenance',
        'Time limits & remedies',
        'Opposition, invalidity & appeal',
        'Transfers & licences',
        'International routes (PCT, EP)',
        'Infringement & remedies',
      ]);
    });

    test('handles variations such as "and" vs "&" and spelling differences', () {
      final input = [
        const ThemeDetailModel(theme: 'Transfers & licenses'),
        const ThemeDetailModel(theme: 'Foundations and institutions'),
      ];

      final sorted = ThemeOrderHelper.sortThemes(input, 'Patents');
      expect(sorted.first.theme, 'Foundations and institutions');
      expect(sorted.last.theme, 'Transfers & licenses');
    });

    test('sorts Trade marks themes correctly', () {
      final input = [
        const ThemeDetailModel(theme: 'Opposition & observations'),
        const ThemeDetailModel(theme: 'Foundations & institutions'),
        const ThemeDetailModel(theme: 'Signs & grounds for refusal'),
      ];

      final sorted = ThemeOrderHelper.sortThemes(input, 'Trade marks');
      expect(sorted.map((t) => t.theme).toList(), [
        'Foundations & institutions',
        'Signs & grounds for refusal',
        'Opposition & observations',
      ]);
    });
  });
}
