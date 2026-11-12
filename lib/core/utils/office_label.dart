/// How an IP office is written for a reader.
///
/// The office *code* is a key: the workbook is `South_Korea_KIPO_ALL`, the DEMO
/// sheet is named `KIPO`, the questions are stored with office `KIPO`, and the
/// store entitlement is keyed on it. None of that may change, or imports and
/// purchases break.
///
/// The *label* is a different matter, and for one office the two differ: KIPO
/// became the Ministry of Intellectual Property on 1 October 2025. Marie asked
/// for it three times - point 6.3 of 3 November, again on 8 November, and again
/// on 11 November (point 10, with screenshots):
///
///   "The Korean office is still shown as KIPO or KIPO - MOIP. Expected:
///    MOIP - Ministry of Intellectual Property (South Korea) everywhere the
///    user sees it; only the file name and the DEMO sheet code stay KIPO for
///    the import."
///
/// It kept coming back because every screen printed `office.code` itself. This
/// file is the one place that decides, so a screen added later cannot
/// reintroduce the old name by accident.
library;

/// Codes whose reader-facing short name is not the code itself.
const Map<String, String> _renamed = {
  'KIPO': 'MOIP',
};

/// The short name to print where a code would otherwise be shown.
String officeLabel(String? code) {
  final key = (code ?? '').trim().toUpperCase();
  if (key.isEmpty) return '';
  return _renamed[key] ?? code!.trim();
}

/// The long form, for the line under the short name.
///
/// `name` and `fullName` come from the server, which already applies the
/// rename; this only steps in when a screen has no server data to hand.
String officeFullName(String? code, {String? fullName}) {
  final given = (fullName ?? '').trim();
  if (given.isNotEmpty) return given;
  final key = (code ?? '').trim().toUpperCase();
  if (key == 'KIPO') return 'Ministry of Intellectual Property';
  return '';
}
