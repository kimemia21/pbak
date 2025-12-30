import 'dart:convert';

import 'package:pbak/models/bike_model.dart';

class UserRole {
  final int roleId;
  final String roleName;
  final String? roleDescription;
  /// Backend sends this sometimes as a JSON string (e.g. "{\"view_events\":true}")
  final Map<String, dynamic>? permissions;
  final bool? isActive;

  UserRole({
    required this.roleId,
    required this.roleName,
    this.roleDescription,
    this.permissions,
    this.isActive,
  });

  factory UserRole.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? permissions;
    final raw = json['permissions'];
    if (raw is Map<String, dynamic>) {
      permissions = raw;
    } else if (raw is String) {
      // backend sometimes returns a quoted JSON string
      try {
        final cleaned = raw.startsWith('"') && raw.endsWith('"')
            ? raw.substring(1, raw.length - 1)
            : raw;
        // Unescape if needed
        final unescaped = cleaned.replaceAll('\\"', '"');
        permissions = unescaped.trim().isEmpty ? null : (jsonDecodeSafe(unescaped) as Map<String, dynamic>?);
      } catch (_) {
        permissions = null;
      }
    }

    return UserRole(
      roleId: (json['role_id'] as num?)?.toInt() ?? 0,
      roleName: (json['role_name'] ?? '').toString(),
      roleDescription: json['role_description']?.toString(),
      permissions: permissions,
      isActive: json['is_active'] == true || json['is_active'] == 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'role_id': roleId,
        'role_name': roleName,
        'role_description': roleDescription,
        'permissions': permissions,
        'is_active': isActive,
      };
}

class UserClub {
  final int clubId;
  final String clubName;
  final String? description;
  final bool? isActive;

  UserClub({
    required this.clubId,
    required this.clubName,
    this.description,
    this.isActive,
  });

  factory UserClub.fromJson(Map<String, dynamic> json) => UserClub(
        clubId: (json['club_id'] as num?)?.toInt() ?? 0,
        clubName: (json['club_name'] ?? '').toString(),
        description: json['description']?.toString(),
        isActive: json['is_active'] == true || json['is_active'] == 1,
      );

  Map<String, dynamic> toJson() => {
        'club_id': clubId,
        'club_name': clubName,
        'description': description,
        'is_active': isActive,
      };
}

class UserApprover {
  final int memberId;
  final String? firstName;
  final String? lastName;
  final String? fullName;

  UserApprover({
    required this.memberId,
    this.firstName,
    this.lastName,
    this.fullName,
  });

  factory UserApprover.fromJson(Map<String, dynamic> json) => UserApprover(
        memberId: (json['member_id'] as num?)?.toInt() ?? 0,
        firstName: json['first_name']?.toString(),
        lastName: json['last_name']?.toString(),
        fullName: json['full_name']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'member_id': memberId,
        'first_name': firstName,
        'last_name': lastName,
        'full_name': fullName,
      };
}

/// Small safe JSON decode helper to avoid importing dart:convert everywhere.
dynamic jsonDecodeSafe(String value) {
  try {
    return jsonDecode(value);
  } catch (_) {
    return null;
  }
}

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

  // Address
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? stateProvince;
  final String? postalCode;
  final String? country;

  // Work
  final String? employer;
  final String? industry;
  final String? workLatLong;
  final String? workPlaceId;

  // Membership + approvals
  final String membershipNumber;
  final String role;
  final int? roleId;
  final int? clubId;
  final String? clubName;
  final int? estateId;
  final String? roadName;
  final int? occupation;
  final String approvalStatus;
  final DateTime? approvalDate;
  final int? approvedBy;
  final int? dlPic;
  final int? passportPhoto;
  final String? rejectionReason;

  // Interests
  final bool? interestSafetyTraining;
  final bool? interestAssociation;
  final bool? interestBikerAdvocacy;
  final bool? interestCertTrain;
  final bool? interestSafetyWorkshops;
  final bool? interestMemberWelfare;
  final bool? interestLegalSupport;
  final bool? interestMedical;

  // Nested objects
  final UserRole? roleDetails;
  final UserClub? club;
  final UserApprover? approver;
  final List<BikeModel> bikes;

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

    // Address
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.stateProvince,
    this.postalCode,
    this.country,

    // Work
    this.employer,
    this.industry,
    this.workLatLong,
    this.workPlaceId,

    // Membership + approvals
    required this.membershipNumber,
    required this.role,
    this.roleId,
    this.clubId,
    this.clubName,
    this.estateId,
    this.roadName,
    this.occupation,
    this.approvalStatus = 'pending',
    this.approvalDate,
    this.approvedBy,
    this.dlPic,
    this.passportPhoto,
    this.rejectionReason,

    // Interests
    this.interestSafetyTraining,
    this.interestAssociation,
    this.interestBikerAdvocacy,
    this.interestCertTrain,
    this.interestSafetyWorkshops,
    this.interestMemberWelfare,
    this.interestLegalSupport,
    this.interestMedical,

    // Nested
    this.roleDetails,
    this.club,
    this.approver,
    this.bikes = const [],

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
    // The backend sometimes wraps responses as:
    // { "status": "success", "data": { "member": {...} } }
    final unwrapped = (json['data'] is Map<String, dynamic> &&
            (json['data'] as Map<String, dynamic>)['member'] is Map<String, dynamic>)
        ? ((json['data'] as Map<String, dynamic>)['member'] as Map<String, dynamic>)
        : json;

    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    String? parseString(dynamic value) {
      if (value == null) return null;
      return value.toString();
    }

    bool? parseBool(dynamic value) {
      if (value == null) return null;
      if (value is bool) return value;
      if (value is num) return value == 1;
      final v = value.toString().toLowerCase();
      if (v == 'true' || v == '1') return true;
      if (v == 'false' || v == '0') return false;
      return null;
    }

    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return null;
      }
    }

    final roleMap = unwrapped['role'] is Map<String, dynamic>
        ? (unwrapped['role'] as Map<String, dynamic>)
        : null;
    final clubMap = unwrapped['club'] is Map<String, dynamic>
        ? (unwrapped['club'] as Map<String, dynamic>)
        : null;
    final approverMap = unwrapped['approver'] is Map<String, dynamic>
        ? (unwrapped['approver'] as Map<String, dynamic>)
        : null;

    final bikesList = unwrapped['bikes'] is List ? (unwrapped['bikes'] as List) : const [];

    return UserModel(
      memberId: parseInt(unwrapped['member_id'] ?? unwrapped['id']) ?? 0,
      email: parseString(unwrapped['email']) ?? '',
      firstName: parseString(unwrapped['first_name'] ?? unwrapped['firstName']) ?? '',
      lastName: parseString(unwrapped['last_name'] ?? unwrapped['lastName']) ?? '',
      phone: parseString(unwrapped['phone']),
      alternativePhone: parseString(unwrapped['alternative_phone']),
      nationalId: parseString(unwrapped['national_id']),
      drivingLicenseNumber: parseString(unwrapped['driving_license_number']),
      dateOfBirth: parseDateTime(unwrapped['date_of_birth']),
      gender: parseString(unwrapped['gender']),
      emergencyContact: parseString(unwrapped['emergency_contact']),
      bloodGroup: parseString(unwrapped['blood_group']),
      allergies: parseString(unwrapped['allergies']),
      medicalPolicyNo: parseString(unwrapped['medical_policy_no']),
      profilePhotoUrl: parseString(unwrapped['profile_photo_url']),

      // Address
      addressLine1: parseString(unwrapped['address_line1']),
      addressLine2: parseString(unwrapped['address_line2']),
      city: parseString(unwrapped['city']),
      stateProvince: parseString(unwrapped['state_province']),
      postalCode: parseString(unwrapped['postal_code']),
      country: parseString(unwrapped['country']),

      // Work
      employer: parseString(unwrapped['employer']),
      industry: parseString(unwrapped['industry']),
      workLatLong: parseString(unwrapped['work_lat_long']),
      workPlaceId: parseString(unwrapped['work_place_id']),

      membershipNumber: parseString(unwrapped['membership_number']) ?? '',
      role: unwrapped['role'] is String
          ? parseString(unwrapped['role']) ?? 'member'
          : (roleMap != null ? (parseString(roleMap['role_name']) ?? 'member') : 'member'),
      roleId: parseInt(unwrapped['role_id']) ?? (roleMap != null ? parseInt(roleMap['role_id']) : null),
      clubId: parseInt(unwrapped['club_id']) ?? (clubMap != null ? parseInt(clubMap['club_id']) : null),
      clubName: clubMap != null ? parseString(clubMap['club_name']) : parseString(unwrapped['club_name']),
      estateId: parseInt(unwrapped['estate_id']),
      roadName: parseString(unwrapped['road_name']),
      occupation: parseInt(unwrapped['occupation']),

      approvalStatus: parseString(unwrapped['approval_status']) ?? 'pending',
      approvalDate: parseDateTime(unwrapped['approval_date']),
      approvedBy: parseInt(unwrapped['approved_by']),
      dlPic: parseInt(unwrapped['dl_pic']),
      passportPhoto: parseInt(unwrapped['passport_photo']),
      rejectionReason: parseString(unwrapped['rejection_reason']),

      interestSafetyTraining: parseBool(unwrapped['interest_safety_training']),
      interestAssociation: parseBool(unwrapped['interest_association']),
      interestBikerAdvocacy: parseBool(unwrapped['interest_biker_advocacy']),
      interestCertTrain: parseBool(unwrapped['interest_cert_train']),
      interestSafetyWorkshops: parseBool(unwrapped['interest_safety_workshops']),
      interestMemberWelfare: parseBool(unwrapped['interest_member_welfare']),
      interestLegalSupport: parseBool(unwrapped['interest_legal_support']),
      interestMedical: parseBool(unwrapped['interest_medical']),

      roleDetails: roleMap != null ? UserRole.fromJson(roleMap) : null,
      club: clubMap != null ? UserClub.fromJson(clubMap) : null,
      approver: approverMap != null ? UserApprover.fromJson(approverMap) : null,
      bikes: bikesList
          .whereType<Map>()
          .map((e) => BikeModel.fromJson(e.cast<String, dynamic>()))
          .toList(),

      joinedDate: parseDateTime(unwrapped['joined_date']),
      lastLogin: parseDateTime(unwrapped['last_login']),
      isActive: parseBool(unwrapped['is_active']) ?? true,
      createdAt: parseDateTime(unwrapped['created_at']) ?? DateTime.now(),
      updatedAt: parseDateTime(unwrapped['updated_at']) ?? DateTime.now(),
    );
  } catch (e, stackTrace) {
    // keep existing log style
    // ignore: avoid_print
    print('❌ Error parsing UserModel from JSON:');
    // ignore: avoid_print
    print('Error: $e');
    // ignore: avoid_print
    print('StackTrace: $stackTrace');
    // ignore: avoid_print
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

      // Address
      'address_line1': addressLine1,
      'address_line2': addressLine2,
      'city': city,
      'state_province': stateProvince,
      'postal_code': postalCode,
      'country': country,

      // Work
      'employer': employer,
      'industry': industry,
      'work_lat_long': workLatLong,
      'work_place_id': workPlaceId,

      'membership_number': membershipNumber,
      'role': role,
      'role_id': roleId,
      'club_id': clubId,
      'club': club?.toJson(),
      'estate_id': estateId,
      'road_name': roadName,
      'occupation': occupation,
      'approval_status': approvalStatus,
      'approval_date': approvalDate?.toIso8601String(),
      'approved_by': approvedBy,
      'dl_pic': dlPic,
      'passport_photo': passportPhoto,
      'rejection_reason': rejectionReason,

      // Interests
      'interest_safety_training': interestSafetyTraining,
      'interest_association': interestAssociation,
      'interest_biker_advocacy': interestBikerAdvocacy,
      'interest_cert_train': interestCertTrain,
      'interest_safety_workshops': interestSafetyWorkshops,
      'interest_member_welfare': interestMemberWelfare,
      'interest_legal_support': interestLegalSupport,
      'interest_medical': interestMedical,

      'role_details': roleDetails?.toJson(),
      'approver': approver?.toJson(),
      'bikes': bikes.map((e) => e.toJson()).toList(),
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

    // Address
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? stateProvince,
    String? postalCode,
    String? country,

    // Work
    String? employer,
    String? industry,
    String? workLatLong,
    String? workPlaceId,

    // Membership
    String? membershipNumber,
    String? role,
    int? roleId,
    int? clubId,
    String? clubName,
    int? estateId,
    String? roadName,
    int? occupation,

    // Approval
    String? approvalStatus,
    DateTime? approvalDate,
    int? approvedBy,
    int? dlPic,
    int? passportPhoto,
    String? rejectionReason,

    // Interests
    bool? interestSafetyTraining,
    bool? interestAssociation,
    bool? interestBikerAdvocacy,
    bool? interestCertTrain,
    bool? interestSafetyWorkshops,
    bool? interestMemberWelfare,
    bool? interestLegalSupport,
    bool? interestMedical,

    // Nested
    UserRole? roleDetails,
    UserClub? club,
    UserApprover? approver,
    List<BikeModel>? bikes,

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

      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      stateProvince: stateProvince ?? this.stateProvince,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,

      employer: employer ?? this.employer,
      industry: industry ?? this.industry,
      workLatLong: workLatLong ?? this.workLatLong,
      workPlaceId: workPlaceId ?? this.workPlaceId,

      membershipNumber: membershipNumber ?? this.membershipNumber,
      role: role ?? this.role,
      roleId: roleId ?? this.roleId,
      clubId: clubId ?? this.clubId,
      clubName: clubName ?? this.clubName,
      estateId: estateId ?? this.estateId,
      roadName: roadName ?? this.roadName,
      occupation: occupation ?? this.occupation,

      approvalStatus: approvalStatus ?? this.approvalStatus,
      approvalDate: approvalDate ?? this.approvalDate,
      approvedBy: approvedBy ?? this.approvedBy,
      dlPic: dlPic ?? this.dlPic,
      passportPhoto: passportPhoto ?? this.passportPhoto,
      rejectionReason: rejectionReason ?? this.rejectionReason,

      interestSafetyTraining: interestSafetyTraining ?? this.interestSafetyTraining,
      interestAssociation: interestAssociation ?? this.interestAssociation,
      interestBikerAdvocacy: interestBikerAdvocacy ?? this.interestBikerAdvocacy,
      interestCertTrain: interestCertTrain ?? this.interestCertTrain,
      interestSafetyWorkshops: interestSafetyWorkshops ?? this.interestSafetyWorkshops,
      interestMemberWelfare: interestMemberWelfare ?? this.interestMemberWelfare,
      interestLegalSupport: interestLegalSupport ?? this.interestLegalSupport,
      interestMedical: interestMedical ?? this.interestMedical,

      roleDetails: roleDetails ?? this.roleDetails,
      club: club ?? this.club,
      approver: approver ?? this.approver,
      bikes: bikes ?? this.bikes,

      joinedDate: joinedDate ?? this.joinedDate,
      lastLogin: lastLogin ?? this.lastLogin,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
