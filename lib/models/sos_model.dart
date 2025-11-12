class SOSModel {
  final String id;
  final String userId;
  final String type;
  final double latitude;
  final double longitude;
  final String location;
  final String notes;
  final String status;
  final DateTime timestamp;
  final String? responderId;
  final String? responderName;
  final String? responderContact;
  final DateTime? responseTime;

  SOSModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.location,
    required this.notes,
    required this.status,
    required this.timestamp,
    this.responderId,
    this.responderName,
    this.responderContact,
    this.responseTime,
  });

  factory SOSModel.fromJson(Map<String, dynamic> json) {
    return SOSModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      type: json['type'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      location: json['location'] ?? '',
      notes: json['notes'] ?? '',
      status: json['status'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      responderId: json['responderId'],
      responderName: json['responderName'],
      responderContact: json['responderContact'],
      responseTime: json['responseTime'] != null
          ? DateTime.parse(json['responseTime'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'latitude': latitude,
      'longitude': longitude,
      'location': location,
      'notes': notes,
      'status': status,
      'timestamp': timestamp.toIso8601String(),
      'responderId': responderId,
      'responderName': responderName,
      'responderContact': responderContact,
      'responseTime': responseTime?.toIso8601String(),
    };
  }

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isResponded => status.toLowerCase() == 'responded';
  bool get isResolved => status.toLowerCase() == 'resolved';
}
