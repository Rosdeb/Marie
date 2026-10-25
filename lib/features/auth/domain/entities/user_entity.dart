class UserEntity {
  final String id;
  final String name;
  final String? firstName;
  final String? lastName;
  final String email;
  final String? role;
  final String? phoneNumber;
  final String? profileUrl;
  final String? profileType; // 'Attorney' | 'Paralegal'
  final String? profession;
  final bool showFirstName;
  final bool showProfession;

  const UserEntity({
    required this.id,
    required this.name,
    this.firstName,
    this.lastName,
    required this.email,
    this.role,
    this.phoneNumber,
    this.profileUrl,
    this.profileType,
    this.profession,
    this.showFirstName = false,
    this.showProfession = false,
  });
}
