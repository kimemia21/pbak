import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pbak/models/trip_model.dart';
import 'package:pbak/services/mock_api/mock_api_service.dart';
import 'package:pbak/providers/auth_provider.dart';
import 'package:pbak/services/trip_service.dart';
import 'package:pbak/services/local_storage/local_storage_service.dart';
import 'package:uuid/uuid.dart';

final myTripsProvider = FutureProvider<List<TripModel>>((ref) async {
  final authState = ref.watch(authProvider);
  return authState.when(
    data: (user) async {
      if (user != null) {
        final apiService = MockApiService();
        return await apiService.getMyTrips(user.id);
      }
      return [];
    },
    loading: () => [],
    error: (_, __) => [],
  );
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
  final String? tripId;
  final String? startLocation;
  final String? endLocation;
  final LatLng? startLatLng;
  final LatLng? endLatLng;
  final String? selectedBikeId;
  final TripStats stats;
  final DateTime? startTime;
  
  ActiveTripState({
    this.isTracking = false,
    this.tripId,
    this.startLocation,
    this.endLocation,
    this.startLatLng,
    this.endLatLng,
    this.selectedBikeId,
    TripStats? stats,
    this.startTime,
  }) : stats = stats ?? TripStats.empty();
  
  ActiveTripState copyWith({
    bool? isTracking,
    String? tripId,
    String? startLocation,
    String? endLocation,
    LatLng? startLatLng,
    LatLng? endLatLng,
    String? selectedBikeId,
    TripStats? stats,
    DateTime? startTime,
  }) {
    return ActiveTripState(
      isTracking: isTracking ?? this.isTracking,
      tripId: tripId ?? this.tripId,
      startLocation: startLocation ?? this.startLocation,
      endLocation: endLocation ?? this.endLocation,
      startLatLng: startLatLng ?? this.startLatLng,
      endLatLng: endLatLng ?? this.endLatLng,
      selectedBikeId: selectedBikeId ?? this.selectedBikeId,
      stats: stats ?? this.stats,
      startTime: startTime ?? this.startTime,
    );
  }
}

/// Notifier for active trip tracking
class ActiveTripNotifier extends StateNotifier<ActiveTripState> {
  TripService? _tripService;
  LocalStorageService? _localStorage;
  
  ActiveTripNotifier() : super(ActiveTripState()) {
    _initializeStorage();
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
        startLocation: savedTrip['startLocation'],
        endLocation: savedTrip['endLocation'],
        startLatLng: savedTrip['startLatLng'] != null 
            ? LatLng(savedTrip['startLatLng']['lat'], savedTrip['startLatLng']['lng'])
            : null,
        endLatLng: savedTrip['endLatLng'] != null
            ? LatLng(savedTrip['endLatLng']['lat'], savedTrip['endLatLng']['lng'])
            : null,
        selectedBikeId: savedTrip['bikeId'],
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
  
  void setSelectedBike(String bikeId) {
    state = state.copyWith(selectedBikeId: bikeId);
  }
  
  Future<bool> startTrip() async {
    if (_tripService == null) {
      _tripService = TripService();
    }
    
    final hasPermission = await _tripService!.checkPermissions();
    if (!hasPermission) return false;
    
    final success = await _tripService!.startTracking();
    if (!success) return false;
    
    final tripId = const Uuid().v4();
    final startTime = DateTime.now();
    
    state = state.copyWith(
      isTracking: true,
      tripId: tripId,
      startTime: startTime,
    );
    
    // Save to local storage
    await _saveTripToLocal();
    
    // Listen to stats updates
    _tripService!.statsStream.listen((stats) {
      state = state.copyWith(stats: stats);
      _saveTripToLocal();
    });
    
    return true;
  }
  
  Future<Map<String, dynamic>> stopTrip() async {
    if (_tripService == null) return {};
    
    final finalStats = _tripService!.stopTracking();
    
    state = state.copyWith(
      isTracking: false,
      stats: finalStats,
    );
    
    // Prepare trip data for API
    final tripData = _prepareTripData(finalStats);
    
    // Save to history
    await _localStorage?.saveTripToHistory(tripData);
    await _localStorage?.clearCurrentTrip();
    
    return tripData;
  }
  
  Map<String, dynamic> _prepareTripData(TripStats stats) {
    return {
      'id': state.tripId,
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
    _tripService?.dispose();
    _tripService = null;
    _localStorage?.clearCurrentTrip();
    state = ActiveTripState();
  }
  
  @override
  void dispose() {
    _tripService?.dispose();
    super.dispose();
  }
}

class TripNotifier extends StateNotifier<AsyncValue<TripModel?>> {
  final Ref _ref;
  final _apiService = MockApiService();

  TripNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<bool> startTrip(Map<String, dynamic> tripData) async {
    state = const AsyncValue.loading();
    try {
      final authState = _ref.read(authProvider);
      final user = authState.value;
      if (user != null) {
        tripData['userId'] = user.id;
        final trip = await _apiService.startTrip(tripData);
        state = AsyncValue.data(trip);
        return true;
      }
      return false;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<bool> endTrip(Map<String, dynamic> tripData) async {
    try {
      final currentTrip = state.value;
      if (currentTrip != null) {
        await _apiService.endTrip(currentTrip.id, tripData);
        state = const AsyncValue.data(null);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
