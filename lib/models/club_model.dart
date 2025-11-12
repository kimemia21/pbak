class ClubModel {
  final String id;
  final String name;
  final String region;
  final String description;
  final String? logoUrl;
  final List<ClubOfficial> officials;
  final int memberCount;
  final DateTime foundedDate;
  final String? meetingLocation;
  final String? contactEmail;
  final String? contactPhone;

  ClubModel({
    required this.id,
    required this.name,
    required this.region,
    required this.description,
    this.logoUrl,
    required this.officials,
    required this.memberCount,
    required this.foundedDate,
    this.meetingLocation,
    this.contactEmail,
    this.contactPhone,
  });

  factory ClubModel.fromJson(Map<String, dynamic> json) {
    return ClubModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      region: json['region'] ?? '',
      description: json['description'] ?? '',
      logoUrl: json['logoUrl'],
      officials: (json['officials'] as List<dynamic>?)
              ?.map((e) => ClubOfficial.fromJson(e))
              .toList() ??
          [],
      memberCount: json['memberCount'] ?? 0,
      foundedDate: DateTime.parse(json['foundedDate']),
      meetingLocation: json['meetingLocation'],
      contactEmail: json['contactEmail'],
      contactPhone: json['contactPhone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'region': region,
      'description': description,
      'logoUrl': logoUrl,
      'officials': officials.map((e) => e.toJson()).toList(),
      'memberCount': memberCount,
      'foundedDate': foundedDate.toIso8601String(),
      'meetingLocation': meetingLocation,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
    };
  }
}

class ClubOfficial {
  final String userId;
  final String name;
  final String position;
  final String? photoUrl;

  ClubOfficial({
    required this.userId,
    required this.name,
    required this.position,
    this.photoUrl,
  });

  factory ClubOfficial.fromJson(Map<String, dynamic> json) {
    return ClubOfficial(
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      position: json['position'] ?? '',
      photoUrl: json['photoUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'position': position,
      'photoUrl': photoUrl,
    };
  }
}
