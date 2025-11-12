import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pbak/models/trip_model.dart';
import 'package:pbak/services/mock_api/mock_api_service.dart';
import 'package:pbak/providers/auth_provider.dart';

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
