class UserModel {
  final int memberId;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? alternativePhone;
  final String? nationalId;
  final String? drivingLicenseNumber;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? emergencyContact;
  final String? bloodGroup;
  final String? allergies;
  final String? medicalPolicyNo;
  final String? profilePhotoUrl;
  final String membershipNumber;
  final String role;
  final int? roleId;
  final int? clubId;
  final String? clubName;
  final int? estateId;
  final String? roadName;
  final int? occupation;
  final String approvalStatus;
  final DateTime? joinedDate;
  final DateTime? lastLogin;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.memberId,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.alternativePhone,
    this.nationalId,
    this.drivingLicenseNumber,
    this.dateOfBirth,
    this.gender,
    this.emergencyContact,
    this.bloodGroup,
    this.allergies,
    this.medicalPolicyNo,
    this.profilePhotoUrl,
    required this.membershipNumber,
    required this.role,
    this.roleId,
    this.clubId,
    this.clubName,
    this.estateId,
    this.roadName,
    this.occupation,
    this.approvalStatus = 'pending',
    this.joinedDate,
    this.lastLogin,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullName => '$firstName $lastName';

  // For backward compatibility with old code
  String get id => memberId.toString();
  String get name => fullName;
  String get idNumber => nationalId ?? '';
  String get licenseNumber => drivingLicenseNumber ?? '';
  String? get profileImage => profilePhotoUrl;
  String get region => clubName ?? '';
  bool get isVerified => approvalStatus == 'approved';
factory UserModel.fromJson(Map<String, dynamic> json) {
  try {
    // Helper function to safely parse int values
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    // Helper function to safely parse string values
    String? parseString(dynamic value) {
      if (value == null) return null;
      return value.toString();
    }

    // Helper function to safely parse DateTime
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      try {
        return DateTime.parse(value.toString());
      } catch (e) {
        print('⚠️ Failed to parse DateTime: $value');
        return null;
      }
    }

    // Handle both login response (minimal data) and full member data
    return UserModel(
      memberId: parseInt(json['member_id'] ?? json['id']) ?? 0,
      email: parseString(json['email']) ?? '',
      firstName: parseString(json['first_name'] ?? json['firstName']) ?? '',
      lastName: parseString(json['last_name'] ?? json['lastName']) ?? '',
      phone: parseString(json['phone']),
      alternativePhone: parseString(json['alternative_phone']),
      nationalId: parseString(json['national_id']),
      drivingLicenseNumber: parseString(json['driving_license_number']),
      dateOfBirth: parseDateTime(json['date_of_birth']),
      gender: parseString(json['gender']),
      emergencyContact: parseString(json['emergency_contact']),
      bloodGroup: parseString(json['blood_group']),
      allergies: parseString(json['allergies']),
      medicalPolicyNo: parseString(json['medical_policy_no']),
      profilePhotoUrl: parseString(json['profile_photo_url']),
      membershipNumber: parseString(json['membership_number']) ?? '',
      role: json['role'] is String 
          ? json['role'] 
          : (json['role'] is Map ? parseString(json['role']['role_name']) ?? 'member' : 'member'),
      roleId: parseInt(json['role_id']) ?? (json['role'] is Map ? parseInt(json['role']['role_id']) : null),
      clubId: parseInt(json['club_id']) ?? (json['club'] is Map ? parseInt(json['club']['club_id']) : null),
      clubName: json['club'] is Map ? parseString(json['club']['club_name']) : null,
      estateId: parseInt(json['estate_id']),
      roadName: parseString(json['road_name']),
      occupation: parseInt(json['occupation']),
      approvalStatus: parseString(json['approval_status']) ?? 'pending',
      joinedDate: parseDateTime(json['joined_date']),
      lastLogin: parseDateTime(json['last_login']),
      isActive: json['is_active'] == true || 
                json['is_active']?.toString().toLowerCase() == 'true' || 
                json['is_active'] == null,
      createdAt: parseDateTime(json['created_at']) ?? DateTime.now(),
      updatedAt: parseDateTime(json['updated_at']) ?? DateTime.now(),
    );
  } catch (e, stackTrace) {
    print('❌ Error parsing UserModel from JSON:');
    print('Error: $e');
    print('StackTrace: $stackTrace');
    print('JSON data: $json');
    rethrow;
  }
}
  Map<String, dynamic> toJson() {
    return {
      'member_id': memberId,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'alternative_phone': alternativePhone,
      'national_id': nationalId,
      'driving_license_number': drivingLicenseNumber,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'emergency_contact': emergencyContact,
      'blood_group': bloodGroup,
      'allergies': allergies,
      'medical_policy_no': medicalPolicyNo,
      'profile_photo_url': profilePhotoUrl,
      'membership_number': membershipNumber,
      'role': role,
      'role_id': roleId,
      'club_id': clubId,
      'estate_id': estateId,
      'road_name': roadName,
      'occupation': occupation,
      'approval_status': approvalStatus,
      'joined_date': joinedDate?.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    int? memberId,
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
    String? alternativePhone,
    String? nationalId,
    String? drivingLicenseNumber,
    DateTime? dateOfBirth,
    String? gender,
    String? emergencyContact,
    String? bloodGroup,
    String? allergies,
    String? medicalPolicyNo,
    String? profilePhotoUrl,
    String? membershipNumber,
    String? role,
    int? roleId,
    int? clubId,
    String? clubName,
    int? estateId,
    String? roadName,
    int? occupation,
    String? approvalStatus,
    DateTime? joinedDate,
    DateTime? lastLogin,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      memberId: memberId ?? this.memberId,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      alternativePhone: alternativePhone ?? this.alternativePhone,
      nationalId: nationalId ?? this.nationalId,
      drivingLicenseNumber: drivingLicenseNumber ?? this.drivingLicenseNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      allergies: allergies ?? this.allergies,
      medicalPolicyNo: medicalPolicyNo ?? this.medicalPolicyNo,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      membershipNumber: membershipNumber ?? this.membershipNumber,
      role: role ?? this.role,
      roleId: roleId ?? this.roleId,
      clubId: clubId ?? this.clubId,
      clubName: clubName ?? this.clubName,
      estateId: estateId ?? this.estateId,
      roadName: roadName ?? this.roadName,
      occupation: occupation ?? this.occupation,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      joinedDate: joinedDate ?? this.joinedDate,
      lastLogin: lastLogin ?? this.lastLogin,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
