import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// High-accuracy location service for precise GPS tracking
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  StreamSubscription<Position>? _positionStreamSubscription;
  Position? _lastKnownPosition;
  

  /// Get the last known position
  Position? get lastKnownPosition => _lastKnownPosition;

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check location permission status
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permission
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Ensure location permissions are granted
  Future<bool> ensurePermissions() async {
    // Check if location services are enabled
    bool serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    // Check permissions
    LocationPermission permission = await checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Get current position with high accuracy
  Future<Position?> getCurrentPosition({
    bool forceAndroidLocationManager = true,
  }) async {
    try {
      final hasPermission = await ensurePermissions();
      if (!hasPermission) return null;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
        timeLimit: const Duration(seconds: 10),
      );

      _lastKnownPosition = position;
      return position;
    } catch (e) {
      print('Error getting current position: $e');
      return null;
    }
  }

  /// Start listening to position updates with high accuracy
  Stream<Position> getPositionStream({
    bool highAccuracy = true,
    bool forceAndroidLocationManager = true,
  }) {
    final settings = AndroidSettings(
      accuracy: highAccuracy 
          ? LocationAccuracy.bestForNavigation 
          : LocationAccuracy.high,
      distanceFilter: highAccuracy ? 5 : 10,
      forceLocationManager: forceAndroidLocationManager,
      intervalDuration: const Duration(seconds: 5),
      foregroundNotificationConfig: const ForegroundNotificationConfig(
        notificationText: "PBAK is tracking your location for trip safety",
        notificationTitle: "Trip Tracking Active",
        enableWakeLock: true,
      ),
    );

    return Geolocator.getPositionStream(
      locationSettings: settings,
    );
  }

  /// Start tracking location with callback
  Future<void> startTracking({
    required Function(Position) onLocationUpdate,
    bool highAccuracy = true,
    bool forceAndroidLocationManager = true,
  }) async {
    final hasPermission = await ensurePermissions();
    if (!hasPermission) {
      throw Exception('Location permissions not granted');
    }

    // Cancel any existing subscription
    await stopTracking();

    // Start new subscription
    _positionStreamSubscription = getPositionStream(
      highAccuracy: highAccuracy,
      forceAndroidLocationManager: forceAndroidLocationManager,
    ).listen(
      (Position position) {
        _lastKnownPosition = position;
        onLocationUpdate(position);
      },
      onError: (error) {
        print('Location tracking error: $error');
      },
    );
  }

  /// Stop tracking location
  Future<void> stopTracking() async {
    await _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  /// Convert Position to LatLng
  LatLng positionToLatLng(Position position) {
    return LatLng(position.latitude, position.longitude);
  }

  /// Calculate distance between two positions in meters
  double calculateDistance(Position start, Position end) {
    return Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
  }

  /// Calculate bearing between two positions
  double calculateBearing(Position start, Position end) {
    return Geolocator.bearingBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
  }

  /// Get position accuracy in meters
  double? getAccuracy(Position? position) {
    return position?.accuracy;
  }

  /// Check if position has acceptable accuracy (less than 20 meters)
  bool hasAcceptableAccuracy(Position? position) {
    if (position == null) return false;
    return (position.accuracy) <= 20.0;
  }

  /// Wait for accurate position (retry until accuracy is acceptable)
  Future<Position?> waitForAccuratePosition({
    int maxRetries = 5,
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    for (int i = 0; i < maxRetries; i++) {
      final position = await getCurrentPosition();
      if (position != null && hasAcceptableAccuracy(position)) {
        return position;
      }
      if (i < maxRetries - 1) {
        await Future.delayed(retryDelay);
      }
    }
    return _lastKnownPosition; // Return last known if can't get accurate
  }

  /// Dispose resources
  void dispose() {
    stopTracking();
  }
}
