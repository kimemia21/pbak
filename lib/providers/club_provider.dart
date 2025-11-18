import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pbak/models/club_model.dart';
import 'package:pbak/services/club_service.dart';

// Service provider
final clubServiceProvider = Provider((ref) => ClubService());

// Clubs provider
final clubsProvider = FutureProvider<List<ClubModel>>((ref) async {
  final clubService = ref.read(clubServiceProvider);
  return await clubService.getAllClubs();
});

// Club detail provider
final clubDetailProvider = FutureProvider.family<ClubModel?, int>((ref, clubId) async {
  final clubService = ref.read(clubServiceProvider);
  return await clubService.getClubById(clubId);
});

// Club members provider
final clubMembersProvider = FutureProvider.family((ref, int clubId) async {
  final clubService = ref.read(clubServiceProvider);
  return await clubService.getClubMembers(clubId);
});

// Club notifier
final clubNotifierProvider = StateNotifierProvider<ClubNotifier, AsyncValue<List<ClubModel>>>((ref) {
  return ClubNotifier(ref.read(clubServiceProvider));
});

class ClubNotifier extends StateNotifier<AsyncValue<List<ClubModel>>> {
  final ClubService _clubService;

  ClubNotifier(this._clubService) : super(const AsyncValue.loading()) {
    loadClubs();
  }

  Future<void> loadClubs() async {
    state = const AsyncValue.loading();
    try {
      final clubs = await _clubService.getAllClubs();
      state = AsyncValue.data(clubs);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<bool> createClub(Map<String, dynamic> clubData) async {
    try {
      final newClub = await _clubService.createClub(clubData);
      
      if (newClub != null) {
        state.whenData((clubs) {
          state = AsyncValue.data([...clubs, newClub]);
        });
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateClub(int clubId, Map<String, dynamic> clubData) async {
    try {
      final updatedClub = await _clubService.updateClub(
        clubId: clubId,
        clubData: clubData,
      );
      
      if (updatedClub != null) {
        await loadClubs();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteClub(int clubId) async {
    try {
      final success = await _clubService.deleteClub(clubId);
      
      if (success) {
        await loadClubs();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> joinClub(int clubId) async {
    try {
      final success = await _clubService.joinClub(clubId);
      
      if (success) {
        await loadClubs();
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  Future<bool> leaveClub(int clubId) async {
    try {
      final success = await _clubService.leaveClub(clubId);
      
      if (success) {
        await loadClubs();
      }
      return success;
    } catch (e) {
      return false;
    }
  }
}
