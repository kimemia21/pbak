import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pbak/models/trip_model.dart';
import 'package:pbak/providers/auth_provider.dart';
import 'package:pbak/services/trip_service.dart';
import 'package:pbak/services/trip_api_service.dart';
import 'package:pbak/services/local_storage/local_storage_service.dart';
import 'package:uuid/uuid.dart';

// Trip API service provider
final tripApiServiceProvider = Provider((ref) => TripApiService());

final myTripsProvider = FutureProvider<List<TripModel>>((ref) async {
  final authState = ref.watch(authProvider);
  final user = authState.valueOrNull;
  
  if (user != null) {
    try {
      final tripApiService = ref.read(tripApiServiceProvider);
      return await tripApiService.getAllTrips();
    } catch (e) {
      print('Error loading trips: $e');
      return [];
    }
  }
  return [];
});

final tripNotifierProvider = StateNotifierProvider<TripNotifier, AsyncValue<TripModel?>>((ref) {
  return TripNotifier(ref);
});

// Active trip tracking provider
final activeTripProvider = StateNotifierProvider<ActiveTripNotifier, ActiveTripState>((ref) {
  return ActiveTripNotifier();
});

// Trip service provider
final tripServiceProvider = Provider<TripService>((ref) {
  return TripService();
});

/// State for active trip tracking
class ActiveTripState {
  final bool isTracking;
  final String? tripId; // Local UUID for tracking
  final int? backendTripId; // Backend trip ID from API
  final String? startLocation;
  final String? endLocation;
  final LatLng? startLatLng;
  final LatLng? endLatLng;
  final String? selectedBikeId;
  final int? selectedBikeIdInt; // Bike ID as int for API
  final TripStats stats;
  final DateTime? startTime;
  
  ActiveTripState({
    this.isTracking = false,
    this.tripId,
    this.backendTripId,
    this.startLocation,
    this.endLocation,
    this.startLatLng,
    this.endLatLng,
    this.selectedBikeId,
    this.selectedBikeIdInt,
    TripStats? stats,
    this.startTime,
  }) : stats = stats ?? TripStats.empty();
  
  ActiveTripState copyWith({
    bool? isTracking,
    String? tripId,
    int? backendTripId,
    String? startLocation,
    String? endLocation,
    LatLng? startLatLng,
    LatLng? endLatLng,
    String? selectedBikeId,
    int? selectedBikeIdInt,
    TripStats? stats,
    DateTime? startTime,
  }) {
    return ActiveTripState(
      isTracking: isTracking ?? this.isTracking,
      tripId: tripId ?? this.tripId,
      backendTripId: backendTripId ?? this.backendTripId,
      startLocation: startLocation ?? this.startLocation,
      endLocation: endLocation ?? this.endLocation,
      startLatLng: startLatLng ?? this.startLatLng,
      endLatLng: endLatLng ?? this.endLatLng,
      selectedBikeId: selectedBikeId ?? this.selectedBikeId,
      selectedBikeIdInt: selectedBikeIdInt ?? this.selectedBikeIdInt,
      stats: stats ?? this.stats,
      startTime: startTime ?? this.startTime,
    );
  }
}

/// Notifier for active trip tracking
class ActiveTripNotifier extends StateNotifier<ActiveTripState> {
  TripService? _tripService;
  TripApiService? _tripApiService;
  LocalStorageService? _localStorage;
  StreamSubscription? _statsSubscription;
  Timer? _telemetryTimer;
  
  // Telemetry push interval (every 5 seconds)
  static const Duration _telemetryInterval = Duration(seconds: 5);
  
  ActiveTripNotifier() : super(ActiveTripState()) {
    _initializeStorage();
    _tripApiService = TripApiService();
  }
  
  Future<void> _initializeStorage() async {
    _localStorage = await LocalStorageService.getInstance();
    _loadSavedTrip();
  }
  
  void _loadSavedTrip() {
    final savedTrip = _localStorage?.getCurrentTrip();
    if (savedTrip != null) {
      state = ActiveTripState(
        isTracking: false,
        tripId: savedTrip['id'],
        backendTripId: savedTrip['backendTripId'],
        startLocation: savedTrip['startLocation'],
        endLocation: savedTrip['endLocation'],
        startLatLng: savedTrip['startLatLng'] != null 
            ? LatLng(savedTrip['startLatLng']['lat'], savedTrip['startLatLng']['lng'])
            : null,
        endLatLng: savedTrip['endLatLng'] != null
            ? LatLng(savedTrip['endLatLng']['lat'], savedTrip['endLatLng']['lng'])
            : null,
        selectedBikeId: savedTrip['bikeId'],
        selectedBikeIdInt: savedTrip['bikeIdInt'],
        startTime: savedTrip['startTime'] != null 
            ? DateTime.parse(savedTrip['startTime'])
            : null,
      );
    }
  }
  
  void setStartLocation(String address, double lat, double lng) {
    state = state.copyWith(
      startLocation: address,
      startLatLng: LatLng(lat, lng),
    );
  }
  
  void setEndLocation(String address, double lat, double lng) {
    state = state.copyWith(
      endLocation: address,
      endLatLng: LatLng(lat, lng),
    );
  }
  
  void setSelectedBike(String bikeId, {int? bikeIdInt}) {
    state = state.copyWith(
      selectedBikeId: bikeId,
      selectedBikeIdInt: bikeIdInt ?? int.tryParse(bikeId),
    );
  }
  
  Future<bool> startTrip() async {
    if (_tripService == null) {
      _tripService = TripService();
    }
    
    final hasPermission = await _tripService!.checkPermissions();
    if (!hasPermission) return false;
    
    // Get current location for backend
    final currentPosition = await _tripService!.getCurrentLocation();
    if (currentPosition == null) return false;
    
    final startLat = state.startLatLng?.latitude ?? currentPosition.latitude;
    final startLng = state.startLatLng?.longitude ?? currentPosition.longitude;
    
    // Validate bike selection
    final bikeId = state.selectedBikeIdInt;
    if (bikeId == null) {
      print('No bike selected for trip');
      return false;
    }
    
    // Start trip on backend
    int? backendTripId;
    try {
      backendTripId = await _tripApiService?.startTrip(
        bikeId: bikeId,
        latitude: startLat,
        longitude: startLng,
      );
      
      if (backendTripId == null) {
        print('Failed to start trip on backend');
        // Continue anyway for offline support
      } else {
        print('Trip started on backend with ID: $backendTripId');
      }
    } catch (e) {
      print('Error starting trip on backend: $e');
      // Continue anyway for offline support
    }
    
    // Start local tracking
    final success = await _tripService!.startTracking();
    if (!success) return false;
    
    final tripId = const Uuid().v4();
    final startTime = DateTime.now();
    
    state = state.copyWith(
      isTracking: true,
      tripId: tripId,
      backendTripId: backendTripId,
      startTime: startTime,
      startLatLng: LatLng(startLat, startLng),
    );
    
    // Save to local storage
    await _saveTripToLocal();
    
    // Listen to stats updates
    _statsSubscription = _tripService!.statsStream.listen((stats) {
      state = state.copyWith(stats: stats);
      _saveTripToLocal();
    });
    
    // Start telemetry push timer if we have a backend trip ID
    if (backendTripId != null) {
      _startTelemetryPush();
    }
    
    return true;
  }
  
  /// Start periodic telemetry push to backend
  void _startTelemetryPush() {
    _telemetryTimer?.cancel();
    _telemetryTimer = Timer.periodic(_telemetryInterval, (_) {
      _pushTelemetry();
    });
  }
  
  /// Push current telemetry data to backend
  Future<void> _pushTelemetry() async {
    if (!state.isTracking || state.backendTripId == null) return;
    
    final stats = state.stats;
    if (stats.routePoints.isEmpty) return;
    
    final lastPoint = stats.routePoints.last;
    
    try {
      await _tripApiService?.pushTripEvent(
        tripId: state.backendTripId!,
        latitude: lastPoint.latitude,
        longitude: lastPoint.longitude,
        speedKmh: stats.currentSpeed,
        recordedAt: DateTime.now(),
      );
    } catch (e) {
      print('Failed to push telemetry: $e');
    }
  }
  
  Future<Map<String, dynamic>> stopTrip() async {
    if (_tripService == null) return {};
    
    // Stop telemetry timer
    _telemetryTimer?.cancel();
    _telemetryTimer = null;
    
    // Cancel stats subscription
    _statsSubscription?.cancel();
    _statsSubscription = null;
    
    final finalStats = _tripService!.stopTracking();
    
    // Get end location
    final endLat = finalStats.routePoints.isNotEmpty 
        ? finalStats.routePoints.last.latitude 
        : state.startLatLng?.latitude ?? 0;
    final endLng = finalStats.routePoints.isNotEmpty 
        ? finalStats.routePoints.last.longitude 
        : state.startLatLng?.longitude ?? 0;
    
    // End trip on backend
    if (state.backendTripId != null) {
      try {
        final backendResponse = await _tripApiService?.endTrip(
          tripId: state.backendTripId!,
          endLat: endLat,
          endLng: endLng,
        );
        print('Trip ended on backend: $backendResponse');
      } catch (e) {
        print('Error ending trip on backend: $e');
      }
    }
    
    state = state.copyWith(
      isTracking: false,
      stats: finalStats,
      endLatLng: LatLng(endLat, endLng),
    );
    
    // Prepare trip data for local storage
    final tripData = _prepareTripData(finalStats);
    
    // Save to history
    await _localStorage?.saveTripToHistory(tripData);
    await _localStorage?.clearCurrentTrip();
    
    return tripData;
  }
  
  Map<String, dynamic> _prepareTripData(TripStats stats) {
    return {
      'id': state.tripId,
      'backendTripId': state.backendTripId,
      'startLocation': state.startLocation,
      'endLocation': state.endLocation,
      'startLatLng': state.startLatLng != null
          ? {
              'lat': state.startLatLng!.latitude,
              'lng': state.startLatLng!.longitude,
            }
          : null,
      'endLatLng': state.endLatLng != null
          ? {
              'lat': state.endLatLng!.latitude,
              'lng': state.endLatLng!.longitude,
            }
          : null,
      'bikeId': state.selectedBikeId,
      'bikeIdInt': state.selectedBikeIdInt,
      'startTime': state.startTime?.toIso8601String(),
      'endTime': DateTime.now().toIso8601String(),
      'distance': stats.distance,
      'duration': stats.duration.inMinutes,
      'averageSpeed': stats.averageSpeed,
      'maxSpeed': stats.maxSpeed,
      'currentSpeed': stats.currentSpeed,
      'routePoints': stats.routePoints.map((point) => {
        'lat': point.latitude,
        'lng': point.longitude,
      }).toList(),
      'status': 'completed',
    };
  }
  
  Future<void> _saveTripToLocal() async {
    final tripData = _prepareTripData(state.stats);
    await _localStorage?.saveCurrentTrip(tripData);
  }
  
  void reset() {
    _telemetryTimer?.cancel();
    _telemetryTimer = null;
    _statsSubscription?.cancel();
    _statsSubscription = null;
    _tripService?.dispose();
    _tripService = null;
    _localStorage?.clearCurrentTrip();
    state = ActiveTripState();
  }
  
  @override
  void dispose() {
    _telemetryTimer?.cancel();
    _statsSubscription?.cancel();
    _tripService?.dispose();
    super.dispose();
  }
}

class TripNotifier extends StateNotifier<AsyncValue<TripModel?>> {
  final Ref _ref;
  final TripApiService _apiService = TripApiService();

  TripNotifier(this._ref) : super(const AsyncValue.data(null));

  /// Load a specific trip by ID
  Future<void> loadTrip(int tripId) async {
    state = const AsyncValue.loading();
    try {
      final trip = await _apiService.getTripById(tripId);
      state = AsyncValue.data(trip);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Start a new trip (used for manual trip creation if needed)
  Future<int?> startTrip({
    required int bikeId,
    required double latitude,
    required double longitude,
  }) async {
    state = const AsyncValue.loading();
    try {
      final tripId = await _apiService.startTrip(
        bikeId: bikeId,
        latitude: latitude,
        longitude: longitude,
      );
      
      if (tripId != null) {
        // Optionally load the trip details
        await loadTrip(tripId);
      }
      
      return tripId;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  /// End a trip
  Future<bool> endTrip({
    required int tripId,
    required double endLat,
    required double endLng,
  }) async {
    try {
      final result = await _apiService.endTrip(
        tripId: tripId,
        endLat: endLat,
        endLng: endLng,
      );
      
      if (result != null) {
        state = const AsyncValue.data(null);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Clear current trip state
  void clearTrip() {
    state = const AsyncValue.data(null);
  }
}
