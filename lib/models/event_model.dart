class EventModel {
  final int? regionId;
  final int? townId;

  /// Local id used by app routing (stringified event_id).
  final String id;

  /// API identifiers
  final int? eventId;
  final int? clubId;

  final String title;
  final String description;

  /// Event date (from event_date)
  final DateTime dateTime;

  /// Optional times (HH:mm:ss)
  final String? startTime;
  final String? endTime;

  final String location;
  final double? latitude;
  final double? longitude;

  final String hostClubId;
  final String hostClubName;

  final int? maxAttendees;
  final int currentAttendees;

  final double? fee;
  final DateTime? registrationDeadline;

  final String type;
  final String? imageUrl;
  final String? routeMapUrl;
  final String? routeDetails;
  final String? status;
  final bool isMembersOnly;
  final String? whatsappLink;

  // Region meta
  final String? regionName;
  final String? regionCode;
  final String? country;
  final String? stateProvince;
  final bool? isActive;

  final List<String> attendeeIds;

  EventModel({
    this.regionId,
    this.townId,
    required this.id,
    this.eventId,
    this.clubId,
    required this.title,
    required this.description,
    required this.dateTime,
    this.startTime,
    this.endTime,
    required this.location,
    this.latitude,
    this.longitude,
    required this.hostClubId,
    required this.hostClubName,
    this.maxAttendees,
    required this.currentAttendees,
    this.fee,
    this.registrationDeadline,
    required this.type,
    this.imageUrl,
    this.routeMapUrl,
    this.routeDetails,
    this.status,
    this.isMembersOnly = false,
    this.whatsappLink,
    this.regionName,
    this.regionCode,
    this.country,
    this.stateProvince,
    this.isActive,
    this.attendeeIds = const [],
  });

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return DateTime.now();
    }
  }

  static DateTime? _parseNullableDate(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  static double? _parseNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static int? _parseNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    final s = value.toString().trim().toLowerCase();
    return s == '1' || s == 'true' || s == 'yes';
  }

  factory EventModel.fromJson(Map<String, dynamic> json) {
    final eventDate = json['event_date'] ?? json['dateTime'];

    return EventModel(
      regionId: _parseNullableInt(json['region_id']),
      townId: _parseNullableInt(json['town_id']),
      id: (json['event_id'] ?? json['id'] ?? '').toString(),
      eventId: _parseNullableInt(json['event_id'] ?? json['id']),
      clubId: _parseNullableInt(json['club_id']),
      title: (json['event_name'] ?? json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      dateTime: _parseDate(eventDate),
      startTime: json['start_time']?.toString(),
      endTime: json['end_time']?.toString(),
      location: (json['location'] ?? '').toString(),
      latitude: _parseNullableDouble(json['latitude']),
      longitude: _parseNullableDouble(json['longitude']),
      hostClubId: (json['club_id'] ?? json['hostClubId'] ?? '').toString(),
      hostClubName: (json['club_name'] ?? json['hostClubName'] ?? '').toString(),
      maxAttendees: _parseNullableInt(json['max_participants'] ?? json['maxAttendees']),
      currentAttendees: _parseNullableInt(json['current_participants'] ?? json['currentAttendees']) ?? 0,
      fee: _parseNullableDouble(json['registration_fee'] ?? json['fee']),
      registrationDeadline: _parseNullableDate(json['registration_deadline']),
      type: (json['event_type'] ?? json['type'] ?? '').toString(),
      imageUrl: json['event_banner_url']?.toString() ?? json['imageUrl']?.toString(),
      routeMapUrl: json['route_map_url']?.toString(),
      routeDetails: json['route_details']?.toString(),
      status: json['status']?.toString(),
      isMembersOnly: _parseBool(json['is_members_only']),
      whatsappLink: json['whatsapp_link']?.toString(),
      regionName: json['region_name']?.toString(),
      regionCode: json['region_code']?.toString(),
      country: json['country']?.toString(),
      stateProvince: json['state_province']?.toString(),
      isActive: json['is_active'] == null ? null : _parseBool(json['is_active']),
      attendeeIds: List<String>.from(json['attendeeIds'] ?? const []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'region_id': regionId,
      'town_id': townId,
      'event_id': eventId,
      'club_id': clubId,
      'event_name': title,
      'description': description,
      'event_date': dateTime.toIso8601String(),
      'start_time': startTime,
      'end_time': endTime,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'max_participants': maxAttendees,
      'registration_deadline': registrationDeadline?.toIso8601String(),
      'registration_fee': fee,
      'event_banner_url': imageUrl,
      'route_map_url': routeMapUrl,
      'route_details': routeDetails,
      'status': status,
      'is_members_only': isMembersOnly ? 1 : 0,
      'whatsapp_link': whatsappLink,
      'region_name': regionName,
      'region_code': regionCode,
      'country': country,
      'state_province': stateProvince,
      'is_active': isActive,
      'attendeeIds': attendeeIds,
    };
  }

  bool get isFull => maxAttendees != null && currentAttendees >= maxAttendees!;
  bool get isPast => dateTime.isBefore(DateTime.now());
  bool get isUpcoming => dateTime.isAfter(DateTime.now());

  String? get latLngLabel {
    if (latitude == null || longitude == null) return null;
    return '$latitude,$longitude';
  }
}
