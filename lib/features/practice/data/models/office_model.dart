import '../../domain/entities/office_entity.dart';

class OfficeDisciplineModel extends OfficeDisciplineEntity {
  const OfficeDisciplineModel({
    required super.name,
    required super.questions,
  });

  factory OfficeDisciplineModel.fromJson(Map<String, dynamic> json) {
    return OfficeDisciplineModel(
      name: json['name'] as String? ?? '',
      questions: (json['questions'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'questions': questions,
    };
  }
}

class OfficeModel extends OfficeEntity {
  const OfficeModel({
    required super.code,
    required super.name,
    required super.territory,
    required super.type,
    required super.disciplines,
    required super.sheets,
    required super.questions,
    required super.levels,
    required super.hasAccess,
    required super.isAvailable,
  });

  factory OfficeModel.fromJson(Map<String, dynamic> json) {
    final disciplinesRaw = json['disciplines'] as List<dynamic>? ?? [];
    final disciplines = disciplinesRaw
        .map((d) => OfficeDisciplineModel.fromJson(d as Map<String, dynamic>))
        .toList();

    final levelsRaw = json['levels'] as List<dynamic>? ?? [];
    final levels = levelsRaw.map((l) => l.toString()).toList();

    return OfficeModel(
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      territory: json['territory'] as String? ?? '',
      type: json['type'] as String? ?? '',
      disciplines: disciplines,
      sheets: (json['sheets'] as num?)?.toInt() ?? 0,
      questions: (json['questions'] as num?)?.toInt() ?? 0,
      levels: levels,
      hasAccess: json['hasAccess'] as bool? ?? false,
      isAvailable: json['isAvailable'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'territory': territory,
      'type': type,
      'disciplines': disciplines
          .map((d) => (d as OfficeDisciplineModel).toJson())
          .toList(),
      'sheets': sheets,
      'questions': questions,
      'levels': levels,
      'hasAccess': hasAccess,
      'isAvailable': isAvailable,
    };
  }
}
