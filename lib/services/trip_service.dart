import 'dart:async';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'location/location_service.dart';

/// Configuration for trip tracking thresholds
class TripConfig {
  final double minSpeedThreshold; // m/s - minimum speed to consider movement
  final double maxSpeedThreshold; // m/s - maximum realistic speed for filtering
  final int locationUpdateInterval; // milliseconds
  final double minDistanceFilter; // meters - minimum distance to record point

  const TripConfig({
    this.minSpeedThreshold = 0.5, // ~1.8 km/h
    this.maxSpeedThreshold = 55.56, // ~200 km/h
    this.locationUpdateInterval = 2000, // 2 seconds
    this.minDistanceFilter = 5.0, // 5 meters
  });
}

/// Real-time trip statistics
class TripStats {
  final double distance; // in kilometers
  final double currentSpeed; // in km/h
  final double averageSpeed; // in km/h
  final double maxSpeed; // in km/h
  final Duration duration;
  final List<LatLng> routePoints;

  TripStats({
    required this.distance,
    required this.currentSpeed,
    required this.averageSpeed,
    required this.maxSpeed,
    required this.duration,
    required this.routePoints,
  });

  TripStats copyWith({
    double? distance,
    double? currentSpeed,
    double? averageSpeed,
    double? maxSpeed,
    Duration? duration,
    List<LatLng>? routePoints,
  }) {
    return TripStats(
      distance: distance ?? this.distance,
      currentSpeed: currentSpeed ?? this.currentSpeed,
      averageSpeed: averageSpeed ?? this.averageSpeed,
      maxSpeed: maxSpeed ?? this.maxSpeed,
      duration: duration ?? this.duration,
      routePoints: routePoints ?? this.routePoints,
    );
  }

  static TripStats empty() {
    return TripStats(
      distance: 0,
      currentSpeed: 0,
      averageSpeed: 0,
      maxSpeed: 0,
      duration: Duration.zero,
      routePoints: [],
    );
  }
}

/// Service for managing trip tracking with location updates
class TripService {
  final TripConfig config;
  final LocationService _locationService = LocationService();
  StreamSubscription<Position>? _positionSubscription;
  final StreamController<TripStats> _statsController =
      StreamController<TripStats>.broadcast();

  Position? _lastPosition;
  DateTime? _tripStartTime;
  double _totalDistance = 0; // in meters
  double _maxSpeed = 0; // in km/h
  List<LatLng> _routePoints = [];
  List<double> _speeds = []; // For calculating average

  TripService({this.config = const TripConfig()});

  /// Stream of real-time trip statistics
  Stream<TripStats> get statsStream => _statsController.stream;

  /// Check and request location permissions
  Future<bool> checkPermissions() async {
    return await _locationService.ensurePermissions();
  }

  /// Get current location with high accuracy
  Future<Position?> getCurrentLocation() async {
    try {
      // Use high-accuracy location service
      return await _locationService.getCurrentPosition(
        forceAndroidLocationManager: true,
      );
    } catch (e) {
      return null;
    }
  }

  /// Start tracking the trip
  Future<bool> startTracking() async {
    try {
      final hasPermission = await checkPermissions();
      if (!hasPermission) return false;

      // Reset all tracking data
      _lastPosition = null;
      _tripStartTime = DateTime.now();
      _totalDistance = 0;
      _maxSpeed = 0;
      _routePoints = [];
      _speeds = [];

      // Get initial position
      final initialPosition = await getCurrentLocation();
      if (initialPosition != null) {
        _lastPosition = initialPosition;
        _routePoints.add(
          LatLng(initialPosition.latitude, initialPosition.longitude),
        );
      }

      // Start listening to position updates with high accuracy
      _positionSubscription = _locationService
          .getPositionStream(
            highAccuracy: true,
            forceAndroidLocationManager: true,
          )
          .listen(_onPositionUpdate);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Handle position updates
  void _onPositionUpdate(Position position) {
    // Filter out low-accuracy positions (accuracy > 50 meters)
    if (position.accuracy > 50.0) {
      return;
    }

    if (_lastPosition == null) {
      _lastPosition = position;
      _routePoints.add(LatLng(position.latitude, position.longitude));
      _emitStats(0);
      return;
    }

    // Calculate distance from last position
    final distance = Geolocator.distanceBetween(
      _lastPosition!.latitude,
      _lastPosition!.longitude,
      position.latitude,
      position.longitude,
    );

    // Calculate speed in km/h
    final speed = position.speed * 3.6; // Convert m/s to km/h

    // Filter out unrealistic speeds and stationary positions
    if (speed < config.minSpeedThreshold * 3.6 &&
        distance < config.minDistanceFilter) {
      _emitStats(0);
      return;
    }

    if (speed > config.maxSpeedThreshold * 3.6) {
      return; // Ignore unrealistic speed
    }

    // Update distance
    _totalDistance += distance;

    // Update max speed
    if (speed > _maxSpeed) {
      _maxSpeed = speed;
    }

    // Track speeds for average calculation
    if (speed > config.minSpeedThreshold * 3.6) {
      _speeds.add(speed);
    }

    // Add point to route
    _routePoints.add(LatLng(position.latitude, position.longitude));

    // Update last position
    _lastPosition = position;

    // Emit updated stats
    _emitStats(speed);
  }

  /// Emit current statistics
  void _emitStats(double currentSpeed) {
    if (_tripStartTime == null) return;

    final duration = DateTime.now().difference(_tripStartTime!);
    final distanceKm = _totalDistance / 1000;

    // Calculate average speed
    double avgSpeed = 0;
    if (_speeds.isNotEmpty) {
      avgSpeed = _speeds.reduce((a, b) => a + b) / _speeds.length;
    }

    final stats = TripStats(
      distance: distanceKm,
      currentSpeed: currentSpeed,
      averageSpeed: avgSpeed,
      maxSpeed: _maxSpeed,
      duration: duration,
      routePoints: List.from(_routePoints),
    );

    _statsController.add(stats);
  }

  /// Stop tracking and return final stats
  TripStats stopTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;

    final duration = _tripStartTime != null
        ? DateTime.now().difference(_tripStartTime!)
        : Duration.zero;

    final distanceKm = _totalDistance / 1000;

    double avgSpeed = 0;
    if (_speeds.isNotEmpty) {
      avgSpeed = _speeds.reduce((a, b) => a + b) / _speeds.length;
    }

    return TripStats(
      distance: distanceKm,
      currentSpeed: 0,
      averageSpeed: avgSpeed,
      maxSpeed: _maxSpeed,
      duration: duration,
      routePoints: List.from(_routePoints),
    );
  }

  /// Calculate distance between two points using Haversine formula
  static double calculateDistance(LatLng point1, LatLng point2) {
    const earthRadius = 6371000.0; // meters

    final lat1 = point1.latitude * math.pi / 180;
    final lat2 = point2.latitude * math.pi / 180;
    final deltaLat = (point2.latitude - point1.latitude) * math.pi / 180;
    final deltaLng = (point2.longitude - point1.longitude) * math.pi / 180;

    final a =
        math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(deltaLng / 2) *
            math.sin(deltaLng / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  /// Dispose resources
  void dispose() {
    _positionSubscription?.cancel();
    _statsController.close();
  }
}
