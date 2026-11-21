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
///
/// Marie's point 15 gives the acronym for each office beside its dashboard
/// code, and three of them differ: JUB reads UPC, KIPO reads MOIP, and INDIA
/// reads IPO. The codes themselves never move - they are what the workbooks,
/// the DEMO sheets and the store entitlements are keyed on. JUB is not here
/// because the questions are already stored under UPC; it is only Marie's
/// file names that say JUB.
const Map<String, String> _renamed = {
  'KIPO': 'MOIP',
  'INDIA': 'IPO',
};

String _normalizeOfficeKey(String? code) {
  final key = (code ?? '').trim().toUpperCase();
  // UKIPO before KIPO: "UKIPO" contains "KIPO", and checking KIPO first read
  // the United Kingdom's office as Korea's and printed it MOIP.
  if (key.contains('UKIPO')) return 'UKIPO';
  if (key.contains('KIPO') || key.contains('MOIP')) return 'KIPO';
  if (key.contains('USPTO')) return 'USPTO';
  if (key.contains('EUIPO')) return 'EUIPO';
  if (key.contains('CNIPA')) return 'CNIPA';
  if (key.contains('DPMA')) return 'DPMA';
  if (key.contains('INPI')) return 'INPI';
  if (key.contains('IPAU')) return 'IPAU';
  if (key.contains('CIPO')) return 'CIPO';
  if (key.contains('WIPO')) return 'WIPO';
  if (key.contains('UPC')) return 'UPC';
  if (key.contains('EPO')) return 'EPO';
  if (key.contains('JPO')) return 'JPO';
  if (key.contains('IPI')) return 'IPI';
  if (key.contains('INDIA') || key == 'IPO') return 'INDIA';
  return key;
}

/// Line 2 of the card: the name of the office.
///
/// Written out in full, exactly as Marie's point 15 writes it. Several of
/// these used to be shortened to fit - "European Union IP Office", "China
/// National IP Administration", "Swiss Federal Institute of IP" - and an
/// abbreviation is not the office's name. The card wraps.
const Map<String, String> _officeFullNames = {
  'WIPO': 'World Intellectual Property Organization',
  'EPO': 'European Patent Office',
  'EUIPO': 'European Union Intellectual Property Office',
  'UPC': 'Unified Patent Court',
  'USPTO': 'United States Patent and Trademark Office',
  // The office calls itself the Intellectual Property Office; "United
  // Kingdom" is line 1, where the country goes.
  'UKIPO': 'Intellectual Property Office',
  'JPO': 'Japan Patent Office',
  'CNIPA': 'China National Intellectual Property Administration',
  'KIPO': 'Ministry of Intellectual Property',
  'INDIA': 'Office of the Controller General of Patents, Designs and Trade Marks',
  'INPI': 'National Institute of Industrial Property',
  'IPI': 'Swiss Federal Institute of Intellectual Property',
  'DPMA': 'German Patent and Trade Mark Office',
  'IPAU': 'IP Australia',
  'CIPO': 'Canadian Intellectual Property Office',
};

const Map<String, String> _officeTerritories = {
  'WIPO': 'International',
  'EPO': 'Europe',
  'EUIPO': 'European Union',
  // The Unitary Patent is what tells this court from the EPO, which is also
  // "Europe".
  'UPC': 'Europe – Unitary Patent',
  'USPTO': 'United States',
  'UKIPO': 'United Kingdom',
  'JPO': 'Japan',
  'CNIPA': 'China',
  'KIPO': 'South Korea',
  'INDIA': 'India',
  'INPI': 'France',
  'IPI': 'Switzerland',
  'DPMA': 'Germany',
  'IPAU': 'Australia',
  'CIPO': 'Canada',
};

/// The short name to print where a code would otherwise be shown.
String officeLabel(String? code) {
  final norm = _normalizeOfficeKey(code);
  if (norm.isEmpty) return '';
  return _renamed[norm] ?? norm;
}

/// The country or region of the office (e.g. Europe, South Korea, United States).
String officeTerritory(String? code, {String? territory}) {
  final given = (territory ?? '').trim();
  if (given.isNotEmpty) return given;
  final norm = _normalizeOfficeKey(code);
  return _officeTerritories[norm] ?? '';
}

/// The long form, for the line under the short name.
///
/// `name` and `fullName` come from the server, which already applies the
/// rename; this only steps in when a screen has no server data to hand.
String officeFullName(String? code, {String? fullName}) {
  final given = (fullName ?? '').trim();
  if (given.isNotEmpty) return given;
  final norm = _normalizeOfficeKey(code);
  return _officeFullNames[norm] ?? '';
}
