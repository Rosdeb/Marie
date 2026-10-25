import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.name,
    super.firstName,
    super.lastName,
    required super.email,
    super.role,
    super.phoneNumber,
    super.profileUrl,
    super.profileType,
    super.profession,
    super.showFirstName = false,
    super.showProfession = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final visibility = json['profileVisibility'] is Map<String, dynamic>
        ? json['profileVisibility'] as Map<String, dynamic>
        : <String, dynamic>{};

    return UserModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      firstName: json['firstName']?.toString(),
      lastName: json['lastName']?.toString(),
      email: (json['email'] ?? '').toString(),
      role: json['role']?.toString(),
      phoneNumber: json['phoneNumber']?.toString(),
      profileUrl: json['profileUrl']?.toString(),
      profileType: json['profileType']?.toString() ?? 'Attorney',
      profession: json['profession']?.toString(),
      showFirstName: visibility['showFirstName'] == true,
      showProfession: visibility['showProfession'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'role': role,
      'phoneNumber': phoneNumber,
      'profileUrl': profileUrl,
      'profileType': profileType,
      'profession': profession,
      'profileVisibility': {
        'showFirstName': showFirstName,
        'showProfession': showProfession,
      },
    };
  }
}
