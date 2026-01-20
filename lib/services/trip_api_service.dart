import 'package:pbak/models/trip_model.dart';
import 'package:pbak/services/comms/comms_service.dart';
import 'package:pbak/services/comms/api_endpoints.dart';

/// Trip API Service
/// Handles all trip-related backend API calls
class TripApiService {
  static final TripApiService _instance = TripApiService._internal();
  factory TripApiService() => _instance;
  TripApiService._internal();

  final _comms = CommsService.instance;

  /// Get all trips for the current user
  Future<List<TripModel>> getAllTrips() async {
    try {
      final response = await _comms.get(ApiEndpoints.allTrips);

      if (response.success && response.data != null) {
        dynamic data = response.data;

        // Access nested data object if it exists
        if (data is Map && data['data'] != null) {
          data = data['data'];
        }

        // If data is a list, map it to TripModel
        if (data is List) {
          return data
              .map((json) => TripModel.fromJson(json as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load trips: $e');
    }
  }

  /// Start a new trip
  /// Returns the trip_id from the backend response
  Future<int?> startTrip({
    required int bikeId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _comms.post(
        ApiEndpoints.startTrip,
        data: {
          'bike_id': bikeId,
          'latitude': latitude,
          'longitude': longitude,
        },
      );

      if (response.success && response.data != null) {
        dynamic data = response.data;

        // Access nested data object if it exists
        if (data is Map && data['data'] != null) {
          data = data['data'];
        }

        // Extract trip_id from response
        if (data is Map) {
          return data['trip_id'] as int?;
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to start trip: $e');
    }
  }

  /// Push trip progress (GPS / Telemetry data)
  Future<bool> pushTripEvent({
    required int tripId,
    required double latitude,
    required double longitude,
    double? speedKmh,
    double? bearingDeg,
    double? inclinationDeg,
    double? altitudeM,
    DateTime? recordedAt,
  }) async {
    try {
      final data = <String, dynamic>{
        'trip_id': tripId,
        'latitude': latitude,
        'longitude': longitude,
      };

      // Add optional fields if provided
      if (speedKmh != null) data['speed_kmh'] = speedKmh;
      if (bearingDeg != null) data['bearing_deg'] = bearingDeg;
      if (inclinationDeg != null) data['inclination_deg'] = inclinationDeg;
      if (altitudeM != null) data['altitude_m'] = altitudeM;
      
      // Format recorded_at as "YYYY-MM-DD HH:mm:ss"
      final timestamp = recordedAt ?? DateTime.now();
      data['recorded_at'] = _formatDateTime(timestamp);

      final response = await _comms.post(
        ApiEndpoints.tripEvent,
        data: data,
      );

      return response.success;
    } catch (e) {
      // Don't throw - telemetry failures shouldn't crash the app
      print('Failed to push trip event: $e');
      return false;
    }
  }

  /// End a trip
  Future<Map<String, dynamic>?> endTrip({
    required int tripId,
    required double endLat,
    required double endLng,
  }) async {
    try {
      final response = await _comms.post(
        ApiEndpoints.endTrip,
        data: {
          'trip_id': tripId,
          'end_lat': endLat,
          'end_lng': endLng,
        },
      );

      if (response.success && response.data != null) {
        dynamic data = response.data;

        // Access nested data object if it exists
        if (data is Map && data['data'] != null) {
          data = data['data'];
        }

        if (data is Map<String, dynamic>) {
          return data;
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to end trip: $e');
    }
  }

  /// Get trip details by ID
  Future<TripModel?> getTripById(int tripId) async {
    try {
      final response = await _comms.get(ApiEndpoints.tripById(tripId));

      if (response.success && response.data != null) {
        dynamic data = response.data;

        // Access nested data object if it exists
        if (data is Map && data['data'] != null) {
          data = data['data'];
        }

        if (data is Map<String, dynamic>) {
          return TripModel.fromJson(data);
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to load trip details: $e');
    }
  }

  /// Format DateTime to "YYYY-MM-DD HH:mm:ss" format
  String _formatDateTime(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}:'
        '${dt.second.toString().padLeft(2, '0')}';
  }
}
