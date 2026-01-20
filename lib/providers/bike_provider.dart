import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pbak/models/bike_model.dart';
import 'package:pbak/services/bike_service.dart';
import 'package:pbak/providers/auth_provider.dart';

// Service provider
final bikeServiceProvider = Provider((ref) => BikeService());

// Bikes provider - fetches bikes from member profile endpoint
final myBikesProvider = FutureProvider<List<BikeModel>>((ref) async {
  final authState = ref.watch(authProvider);
  final user = authState.valueOrNull;
  
  if (user != null) {
    final bikeService = ref.read(bikeServiceProvider);
    return await bikeService.getMyBikes(memberId: user.memberId);
  }
  return [];
});

// Bike makes provider
final bikeMakesProvider = FutureProvider((ref) async {
  final bikeService = ref.read(bikeServiceProvider);
  return await bikeService.getBikeMakes();
});

// Bike models provider (family for make ID)
final bikeModelsProvider = FutureProvider.family<List<BikeModelCatalog>, int>((ref, makeId) async {
  final bikeService = ref.read(bikeServiceProvider);
  return await bikeService.getBikeModels(makeId);
});

// Bike by ID provider
final bikeByIdProvider = FutureProvider.family<BikeModel?, int>((ref, bikeId) async {
  final bikeService = ref.read(bikeServiceProvider);
  return await bikeService.getBikeById(bikeId);
});

// Bike notifier
final bikeNotifierProvider = StateNotifierProvider<BikeNotifier, AsyncValue<List<BikeModel>>>((ref) {
  return BikeNotifier(
    ref.read(bikeServiceProvider),
    ref,
  );
});

class BikeNotifier extends StateNotifier<AsyncValue<List<BikeModel>>> {
  final BikeService _bikeService;
  final Ref _ref;

  BikeNotifier(this._bikeService, this._ref) : super(const AsyncValue.loading()) {
    loadBikes();
  }

  Future<void> loadBikes() async {
    state = const AsyncValue.loading();
    try {
      final authState = _ref.read(authProvider);
      final user = authState.value;
      
      if (user != null) {
        final bikes = await _bikeService.getMyBikes(memberId: user.memberId);
        state = AsyncValue.data(bikes);
      } else {
        state = const AsyncValue.data([]);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<bool> addBike(Map<String, dynamic> bikeData) async {
    try {
      final authState = _ref.read(authProvider);
      final user = authState.value;
      
      if (user != null) {
        final newBike = await _bikeService.addBike(bikeData);
        
        if (newBike != null) {
          state.whenData((bikes) {
            state = AsyncValue.data([...bikes, newBike]);
          });
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateBike(int bikeId, Map<String, dynamic> bikeData) async {
    try {
      final updatedBike = await _bikeService.updateBike(
        bikeId: bikeId,
        bikeData: bikeData,
      );
      
      if (updatedBike != null) {
        await loadBikes();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteBike(int bikeId) async {
    try {
      final success = await _bikeService.deleteBike(bikeId);
      
      if (success) {
        await loadBikes();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<String?> uploadBikeImage(int bikeId, String imagePath) async {
    try {
      return await _bikeService.uploadBikeImage(
        bikeId: bikeId,
        imagePath: imagePath,
      );
    } catch (e) {
      return null;
    }
  }
}
