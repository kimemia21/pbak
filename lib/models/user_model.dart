class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String idNumber;
  final DateTime dateOfBirth;
  final String emergencyContact;
  final String licenseNumber;
  final String? profileImage;
  final String? licenseImage;
  final String? idImage;
  final String role;
  final String region;
  final bool isVerified;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.idNumber,
    required this.dateOfBirth,
    required this.emergencyContact,
    required this.licenseNumber,
    this.profileImage,
    this.licenseImage,
    this.idImage,
    required this.role,
    required this.region,
    this.isVerified = false,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      idNumber: json['idNumber'] ?? '',
      dateOfBirth: DateTime.parse(json['dateOfBirth']),
      emergencyContact: json['emergencyContact'] ?? '',
      licenseNumber: json['licenseNumber'] ?? '',
      profileImage: json['profileImage'],
      licenseImage: json['licenseImage'],
      idImage: json['idImage'],
      role: json['role'] ?? 'Member',
      region: json['region'] ?? '',
      isVerified: json['isVerified'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'idNumber': idNumber,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'emergencyContact': emergencyContact,
      'licenseNumber': licenseNumber,
      'profileImage': profileImage,
      'licenseImage': licenseImage,
      'idImage': idImage,
      'role': role,
      'region': region,
      'isVerified': isVerified,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? idNumber,
    DateTime? dateOfBirth,
    String? emergencyContact,
    String? licenseNumber,
    String? profileImage,
    String? licenseImage,
    String? idImage,
    String? role,
    String? region,
    bool? isVerified,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      idNumber: idNumber ?? this.idNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      profileImage: profileImage ?? this.profileImage,
      licenseImage: licenseImage ?? this.licenseImage,
      idImage: idImage ?? this.idImage,
      role: role ?? this.role,
      region: region ?? this.region,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
