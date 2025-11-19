class EventModel {
  final String id;
  final String title;
  final String description;
  final DateTime dateTime;
  final String location;
  final String? locationLatLng;
  final String hostClubId;
  final String hostClubName;
  final double? fee;
  final int? maxAttendees;
  final int currentAttendees;
  final String type;
  final String? imageUrl;
  final List<String> attendeeIds;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.dateTime,
    required this.location,
    this.locationLatLng,
    required this.hostClubId,
    required this.hostClubName,
    this.fee,
    this.maxAttendees,
    required this.currentAttendees,
    required this.type,
    this.imageUrl,
    required this.attendeeIds,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    // Parse date and time
    DateTime eventDateTime;
    try {
      if (json['event_date'] != null) {
        eventDateTime = DateTime.parse(json['event_date']);
      } else if (json['dateTime'] != null) {
        eventDateTime = DateTime.parse(json['dateTime']);
      } else {
        eventDateTime = DateTime.now();
      }
    } catch (e) {
      eventDateTime = DateTime.now();
    }
    
    // Construct location lat/lng if available
    String? latLng;
    if (json['latitude'] != null && json['longitude'] != null) {
      latLng = '${json['latitude']},${json['longitude']}';
    }
    
    return EventModel(
      id: (json['event_id'] ?? json['id'] ?? '').toString(),
      title: json['event_name'] ?? json['title'] ?? '',
      description: json['description'] ?? '',
      dateTime: eventDateTime,
      location: json['location'] ?? '',
      locationLatLng: latLng ?? json['locationLatLng'],
      hostClubId: (json['club_id'] ?? json['hostClubId'] ?? '').toString(),
      hostClubName: json['club_name'] ?? json['hostClubName'] ?? '',
      fee: json['registration_fee'] != null 
          ? double.tryParse(json['registration_fee'].toString()) 
          : (json['fee']?.toDouble()),
      maxAttendees: json['max_participants'] ?? json['maxAttendees'],
      currentAttendees: json['current_participants'] ?? json['currentAttendees'] ?? 0,
      type: json['event_type'] ?? json['type'] ?? '',
      imageUrl: json['event_banner_url'] ?? json['imageUrl'],
      attendeeIds: List<String>.from(json['attendeeIds'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dateTime': dateTime.toIso8601String(),
      'location': location,
      'locationLatLng': locationLatLng,
      'hostClubId': hostClubId,
      'hostClubName': hostClubName,
      'fee': fee,
      'maxAttendees': maxAttendees,
      'currentAttendees': currentAttendees,
      'type': type,
      'imageUrl': imageUrl,
      'attendeeIds': attendeeIds,
    };
  }

  bool get isFull => maxAttendees != null && currentAttendees >= maxAttendees!;
  bool get isPast => dateTime.isBefore(DateTime.now());
  bool get isUpcoming => dateTime.isAfter(DateTime.now());
}
