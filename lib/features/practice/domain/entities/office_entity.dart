class OfficeDisciplineEntity {
  final String name;
  final int questions;

  const OfficeDisciplineEntity({
    required this.name,
    required this.questions,
  });
}

class OfficeEntity {
  final String code;
  final String name;
  final String territory;
  final String type; // 'international', 'regional', 'national'
  final List<OfficeDisciplineEntity> disciplines;
  final int sheets;
  final int questions;
  final List<String> levels;
  final bool hasAccess;
  final bool isAvailable;

  const OfficeEntity({
    required this.code,
    required this.name,
    required this.territory,
    required this.type,
    required this.disciplines,
    required this.sheets,
    required this.questions,
    required this.levels,
    required this.hasAccess,
    required this.isAvailable,
  });
}
