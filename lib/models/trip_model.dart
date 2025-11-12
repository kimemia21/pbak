class TripModel {
  final String id;
  final String userId;
  final String bikeId;
  final String name;
  final String route;
  final double distance;
  final int durationMinutes;
  final double? averageSpeed;
  final double? maxSpeed;
  final DateTime startTime;
  final DateTime? endTime;
  final String status;
  final List<TripLocation> locations;

  TripModel({
    required this.id,
    required this.userId,
    required this.bikeId,
    required this.name,
    required this.route,
    required this.distance,
    required this.durationMinutes,
    this.averageSpeed,
    this.maxSpeed,
    required this.startTime,
    this.endTime,
    required this.status,
    required this.locations,
  });

  factory TripModel.fromJson(Map<String, dynamic> json) {
    return TripModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      bikeId: json['bikeId'] ?? '',
      name: json['name'] ?? '',
      route: json['route'] ?? '',
      distance: (json['distance'] ?? 0).toDouble(),
      durationMinutes: json['durationMinutes'] ?? 0,
      averageSpeed: json['averageSpeed']?.toDouble(),
      maxSpeed: json['maxSpeed']?.toDouble(),
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      status: json['status'] ?? '',
      locations: (json['locations'] as List<dynamic>?)
              ?.map((e) => TripLocation.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'bikeId': bikeId,
      'name': name,
      'route': route,
      'distance': distance,
      'durationMinutes': durationMinutes,
      'averageSpeed': averageSpeed,
      'maxSpeed': maxSpeed,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'status': status,
      'locations': locations.map((e) => e.toJson()).toList(),
    };
  }

  String get durationText {
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  bool get isActive => status.toLowerCase() == 'active';
}

class TripLocation {
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  TripLocation({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  factory TripLocation.fromJson(Map<String, dynamic> json) {
    return TripLocation(
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
