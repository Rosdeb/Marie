import '../../domain/entities/profile_entity.dart';

class ProfileModel extends ProfileEntity {
  const ProfileModel({
    super.id,
    super.name,
    super.firstName,
    super.lastName,
    super.email,
    super.phone,
    super.bio,
    super.avatarUrl,
    super.profileType,
    super.profession,
    super.showFirstName,
    super.showProfession,
    super.notificationsEnabled,
    super.referralCode,
    super.totalReferrals,
    super.referralEarnings,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> target = json;
    if (json['data'] is Map<String, dynamic>) {
      final data = json['data'] as Map<String, dynamic>;
      if (data['results'] is Map<String, dynamic>) {
        target = data['results'] as Map<String, dynamic>;
      } else {
        target = data;
      }
    } else if (json['results'] is Map<String, dynamic>) {
      target = json['results'] as Map<String, dynamic>;
    }

    final visibility = target['profileVisibility'] is Map<String, dynamic>
        ? target['profileVisibility'] as Map<String, dynamic>
        : <String, dynamic>{};

    return ProfileModel(
      id: (target['_id'] ?? target['id'] ?? '').toString(),
      name: (target['name'] ?? '').toString(),
      firstName: (target['firstName'] ?? '').toString(),
      lastName: (target['lastName'] ?? '').toString(),
      email: (target['email'] ?? '').toString(),
      phone: (target['phoneNumber'] ?? target['phone'] ?? '').toString(),
      bio: (target['bio'] ?? '').toString(),
      avatarUrl: (target['profileUrl'] ?? target['avatarUrl'] ?? '').toString(),
      profileType: (target['profileType'] ?? 'Attorney').toString(),
      profession: (target['profession'] ?? '').toString(),
      showFirstName: visibility['showFirstName'] == true,
      showProfession: visibility['showProfession'] == true,
      notificationsEnabled: target['notificationsEnabled'] != false,
      referralCode: (target['referralCode'] ?? '').toString(),
      totalReferrals: target['totalReferrals'] is int ? target['totalReferrals'] as int : 0,
      referralEarnings: target['referralEarnings'] is num ? (target['referralEarnings'] as num).toDouble() : 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phone,
      'bio': bio,
      'profileUrl': avatarUrl,
      'profileType': profileType,
      'profession': profession,
      'profileVisibility': {
        'showFirstName': showFirstName,
        'showProfession': showProfession,
      },
    };
  }
}
