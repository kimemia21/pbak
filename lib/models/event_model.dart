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
    return EventModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      dateTime: DateTime.parse(json['dateTime']),
      location: json['location'] ?? '',
      locationLatLng: json['locationLatLng'],
      hostClubId: json['hostClubId'] ?? '',
      hostClubName: json['hostClubName'] ?? '',
      fee: json['fee']?.toDouble(),
      maxAttendees: json['maxAttendees'],
      currentAttendees: json['currentAttendees'] ?? 0,
      type: json['type'] ?? '',
      imageUrl: json['imageUrl'],
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
