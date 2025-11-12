import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pbak/models/bike_model.dart';
import 'package:pbak/services/mock_api/mock_api_service.dart';
import 'package:pbak/providers/auth_provider.dart';

final myBikesProvider = FutureProvider<List<BikeModel>>((ref) async {
  final authState = ref.watch(authProvider);
  return authState.when(
    data: (user) async {
      if (user != null) {
        final apiService = MockApiService();
        return await apiService.getMyBikes(user.id);
      }
      return [];
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

final bikeNotifierProvider = StateNotifierProvider<BikeNotifier, AsyncValue<List<BikeModel>>>((ref) {
  return BikeNotifier(ref);
});

class BikeNotifier extends StateNotifier<AsyncValue<List<BikeModel>>> {
  final Ref _ref;
  final _apiService = MockApiService();

  BikeNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadBikes();
  }

  Future<void> loadBikes() async {
    state = const AsyncValue.loading();
    try {
      final authState = _ref.read(authProvider);
      authState.when(
        data: (user) async {
          if (user != null) {
            final bikes = await _apiService.getMyBikes(user.id);
            state = AsyncValue.data(bikes);
          } else {
            state = const AsyncValue.data([]);
          }
        },
        loading: () => state = const AsyncValue.loading(),
        error: (e, stack) => state = AsyncValue.error(e, stack),
      );
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<bool> addBike(Map<String, dynamic> bikeData) async {
    try {
      final authState = _ref.read(authProvider);
      final user = authState.value;
      if (user != null) {
        bikeData['userId'] = user.id;
        final newBike = await _apiService.addBike(bikeData);
        state.whenData((bikes) {
          state = AsyncValue.data([...bikes, newBike]);
        });
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
