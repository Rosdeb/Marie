import '../data/models/discipline_theme_models.dart';

/// Helper to sort themes in canonical order according to Appendix B:
/// "Display the themes in this order:
/// Patents: Foundations & institutions · Patentability · Filing & formalities ·
/// Priority · Search, publication & examination · Grant, term & maintenance ·
/// Time limits & remedies · Opposition, invalidity & appeal · Transfers & licences ·
/// International routes (PCT, EP) · Infringement & remedies.
/// The same rule applies to Trade marks, Designs, WIPO and the UPC (Appendix B)."
class ThemeOrderHelper {
  static const List<String> patentsThemes = [
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
  ];

  static const List<String> tradeMarksThemes = [
    'Foundations & institutions',
    'Signs & grounds for refusal',
    'Filing, examination & registration',
    'Priority & seniority',
    'Opposition & observations',
    'Surrender, revocation & invalidity',
    'Transfers, licences & rights in rem',
    'International registration (Madrid)',
    'Infringement & remedies',
  ];

  static const List<String> designsThemes = [
    'Foundations & institutions',
    'Requirements for protection',
    'Filing, examination & registration',
    'Priority',
    'Invalidity & appeals',
    'Transfers, licences & rights in rem',
    'International registration (Hague)',
    'Infringement & remedies',
  ];

  static const List<String> upcThemes = [
    'Foundations & institutions',
    'Jurisdiction & competence',
    'Procedures before the Court of First Instance',
    'Appeals before the Court of Appeal',
    'Summary proceedings & provisional measures',
    'Evidence & language of proceedings',
    'Remedies & enforcement',
    'Opt-out & transitional regime',
  ];

  static const List<String> wipoThemes = [
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
    'International registration (Madrid)',
    'International registration (Hague)',
    'Infringement & remedies',
  ];

  static List<String> getCanonicalListForDiscipline(String? discipline) {
    final d = (discipline ?? '').trim().toLowerCase();
    if (d.contains('patent')) return patentsThemes;
    if (d.contains('trade') || d.contains('mark')) return tradeMarksThemes;
    if (d.contains('design')) return designsThemes;
    if (d.contains('upc')) return upcThemes;
    if (d.contains('wipo')) return wipoThemes;
    return patentsThemes;
  }

  static String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll('&', 'and')
        .replaceAll('licence', 'license')
        .replaceAll('licences', 'licenses')
        .replaceAll(RegExp(r'[^a-z0-9]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Calculates a sort index for a given theme title within a discipline.
  static int getThemeSortIndex(String? discipline, String themeTitle) {
    final normTitle = _normalize(themeTitle);
    if (normTitle.isEmpty) return 9999;

    final primaryList = getCanonicalListForDiscipline(discipline);

    // 1. Direct exact or substring match in primary discipline list
    for (int i = 0; i < primaryList.length; i++) {
      final normCanonical = _normalize(primaryList[i]);
      if (normTitle == normCanonical ||
          normTitle.contains(normCanonical) ||
          normCanonical.contains(normTitle)) {
        return i;
      }
    }

    // 2. Keyword/token match in primary discipline list
    final titleWords = normTitle.split(' ').where((w) => w.length > 3).toSet();
    if (titleWords.isNotEmpty) {
      for (int i = 0; i < primaryList.length; i++) {
        final canonicalWords = _normalize(primaryList[i])
            .split(' ')
            .where((w) => w.length > 3)
            .toSet();
        if (titleWords.intersection(canonicalWords).isNotEmpty) {
          return i;
        }
      }
    }

    // 3. Fallback: check other canonical lists
    final allLists = [
      patentsThemes,
      tradeMarksThemes,
      designsThemes,
      upcThemes,
      wipoThemes,
    ];

    for (final list in allLists) {
      if (identical(list, primaryList)) continue;
      for (int i = 0; i < list.length; i++) {
        final normCanonical = _normalize(list[i]);
        if (normTitle == normCanonical ||
            normTitle.contains(normCanonical) ||
            normCanonical.contains(normTitle)) {
          return 500 + i;
        }
      }
    }

    return 1000;
  }

  /// Sorts a list of [ThemeDetailModel] according to the canonical order of [discipline].
  static List<ThemeDetailModel> sortThemes(
    List<ThemeDetailModel> themes,
    String? discipline,
  ) {
    final listWithOriginalIndex = themes.asMap().entries.toList();

    listWithOriginalIndex.sort((a, b) {
      final indexA = getThemeSortIndex(discipline, a.value.theme);
      final indexB = getThemeSortIndex(discipline, b.value.theme);

      if (indexA != indexB) {
        return indexA.compareTo(indexB);
      }
      return a.key.compareTo(b.key);
    });

    return listWithOriginalIndex.map((e) => e.value).toList();
  }
}
