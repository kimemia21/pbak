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
    // Parse founded date
    DateTime founded;
    try {
      if (json['founded_date'] != null) {
        founded = DateTime.parse(json['founded_date']);
      } else if (json['foundedDate'] != null) {
        founded = DateTime.parse(json['foundedDate']);
      } else {
        founded = DateTime.now();
      }
    } catch (e) {
      founded = DateTime.now();
    }
    
    return ClubModel(
      id: (json['club_id'] ?? json['id'] ?? '').toString(),
      name: json['club_name'] ?? json['name'] ?? '',
      region: json['region_name'] ?? json['region'] ?? '',
      description: json['description'] ?? '',
      logoUrl: json['club_logo_url'] ?? json['logoUrl'],
      officials: (json['officials'] as List<dynamic>?)
              ?.map((e) => ClubOfficial.fromJson(e))
              .toList() ??
          [],
      memberCount: json['member_count'] ?? json['memberCount'] ?? 0,
      foundedDate: founded,
      meetingLocation: json['meeting_location'] ?? json['meetingLocation'],
      contactEmail: json['contact_email'] ?? json['contactEmail'],
      contactPhone: json['contact_phone'] ?? json['contactPhone'],
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
