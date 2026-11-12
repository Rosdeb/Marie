import '../../domain/entities/office_entity.dart';

class OfficeDisciplineModel extends OfficeDisciplineEntity {
  const OfficeDisciplineModel({
    required super.name,
    super.label,
    required super.questions,
    super.demoQuestions,
  });

  factory OfficeDisciplineModel.fromJson(Map<String, dynamic> json) {
    return OfficeDisciplineModel(
      name: json['name'] as String? ?? '',
      label: json['label'] as String? ?? '',
      questions: (json['questions'] as num?)?.toInt() ?? 0,
      // Absent on an older server, and zero is the honest answer then: a
      // screen that knows of no demo question announces none.
      demoQuestions: (json['demoQuestions'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'label': label,
      'questions': questions,
      'demoQuestions': demoQuestions,
    };
  }
}

class OfficeModel extends OfficeEntity {
  const OfficeModel({
    required super.code,
    required super.name,
    super.fullName,
    required super.territory,
    required super.type,
    required super.disciplines,
    required super.sheets,
    required super.questions,
    required super.levels,
    required super.hasAccess,
    required super.isAvailable,
    super.demoQuestions,
    super.hasDemo,
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
      fullName: json['fullName'] as String? ?? '',
      territory: json['territory'] as String? ?? '',
      type: json['type'] as String? ?? '',
      disciplines: disciplines,
      sheets: (json['sheets'] as num?)?.toInt() ?? 0,
      questions: (json['questions'] as num?)?.toInt() ?? 0,
      levels: levels,
      hasAccess: json['hasAccess'] as bool? ?? false,
      isAvailable: json['isAvailable'] as bool? ?? false,
      demoQuestions: (json['demoQuestions'] as num?)?.toInt() ?? 0,
      hasDemo: json['hasDemo'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'fullName': fullName,
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
