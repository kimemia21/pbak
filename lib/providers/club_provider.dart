import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pbak/models/club_model.dart';
import 'package:pbak/services/mock_api/mock_api_service.dart';

final clubsProvider = FutureProvider<List<ClubModel>>((ref) async {
  final apiService = MockApiService();
  return await apiService.getClubs();
});

final clubDetailProvider = FutureProvider.family<ClubModel, String>((ref, clubId) async {
  final apiService = MockApiService();
  return await apiService.getClubById(clubId);
});

final clubNotifierProvider = StateNotifierProvider<ClubNotifier, AsyncValue<List<ClubModel>>>((ref) {
  return ClubNotifier();
});

class ClubNotifier extends StateNotifier<AsyncValue<List<ClubModel>>> {
  final _apiService = MockApiService();

  ClubNotifier() : super(const AsyncValue.loading()) {
    loadClubs();
  }

  Future<void> loadClubs() async {
    state = const AsyncValue.loading();
    try {
      final clubs = await _apiService.getClubs();
      state = AsyncValue.data(clubs);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<bool> createClub(Map<String, dynamic> clubData) async {
    try {
      final newClub = await _apiService.createClub(clubData);
      state.whenData((clubs) {
        state = AsyncValue.data([...clubs, newClub]);
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}
