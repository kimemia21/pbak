import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pbak/services/region_service.dart';

// Service provider
final regionServiceProvider = Provider((ref) => RegionService());

// All counties provider
final countiesProvider = FutureProvider<List<County>>((ref) async {
  final service = ref.read(regionServiceProvider);
  return await service.getAllCounties();
});

// Towns in county provider
final townsProvider = FutureProvider.family<List<Town>, int>((ref, countyId) async {
  final service = ref.read(regionServiceProvider);
  return await service.getTownsInCounty(countyId);
});

// Estates in town provider
final estatesProvider = FutureProvider.family<List<Estate>, EstateParams>((ref, params) async {
  final service = ref.read(regionServiceProvider);
  return await service.getEstatesInTown(
    countyId: params.countyId,
    townId: params.townId,
  );
});

// Region state notifier for managing region operations
class RegionNotifier extends StateNotifier<RegionState> {
  final RegionService _regionService;

  RegionNotifier(this._regionService)
      : super(RegionState(
          counties: const AsyncValue.loading(),
          selectedCountyId: null,
          towns: const AsyncValue.data([]),
          selectedTownId: null,
          estates: const AsyncValue.data([]),
        )) {
    loadCounties();
  }

  Future<void> loadCounties() async {
    state = state.copyWith(counties: const AsyncValue.loading());
    try {
      final counties = await _regionService.getAllCounties();
      state = state.copyWith(counties: AsyncValue.data(counties));
    } catch (e, stack) {
      state = state.copyWith(counties: AsyncValue.error(e, stack));
    }
  }

  Future<void> selectCounty(int countyId) async {
    state = state.copyWith(
      selectedCountyId: countyId,
      towns: const AsyncValue.loading(),
      selectedTownId: null,
      estates: const AsyncValue.data([]),
    );

    try {
      final towns = await _regionService.getTownsInCounty(countyId);
      state = state.copyWith(towns: AsyncValue.data(towns));
    } catch (e, stack) {
      state = state.copyWith(towns: AsyncValue.error(e, stack));
    }
  }

  Future<void> selectTown(int townId) async {
    if (state.selectedCountyId == null) return;

    state = state.copyWith(
      selectedTownId: townId,
      estates: const AsyncValue.loading(),
    );

    try {
      final estates = await _regionService.getEstatesInTown(
        countyId: state.selectedCountyId!,
        townId: townId,
      );
      state = state.copyWith(estates: AsyncValue.data(estates));
    } catch (e, stack) {
      state = state.copyWith(estates: AsyncValue.error(e, stack));
    }
  }

  void reset() {
    state = RegionState(
      counties: state.counties,
      selectedCountyId: null,
      towns: const AsyncValue.data([]),
      selectedTownId: null,
      estates: const AsyncValue.data([]),
    );
  }
}

// Region state provider
final regionNotifierProvider = StateNotifierProvider<RegionNotifier, RegionState>((ref) {
  return RegionNotifier(ref.read(regionServiceProvider));
});

// Region state class
class RegionState {
  final AsyncValue<List<County>> counties;
  final int? selectedCountyId;
  final AsyncValue<List<Town>> towns;
  final int? selectedTownId;
  final AsyncValue<List<Estate>> estates;

  RegionState({
    required this.counties,
    required this.selectedCountyId,
    required this.towns,
    required this.selectedTownId,
    required this.estates,
  });

  RegionState copyWith({
    AsyncValue<List<County>>? counties,
    int? selectedCountyId,
    AsyncValue<List<Town>>? towns,
    int? selectedTownId,
    AsyncValue<List<Estate>>? estates,
  }) {
    return RegionState(
      counties: counties ?? this.counties,
      selectedCountyId: selectedCountyId ?? this.selectedCountyId,
      towns: towns ?? this.towns,
      selectedTownId: selectedTownId ?? this.selectedTownId,
      estates: estates ?? this.estates,
    );
  }
}

// Estate params for provider
class EstateParams {
  final int countyId;
  final int townId;

  EstateParams({
    required this.countyId,
    required this.townId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EstateParams &&
          runtimeType == other.runtimeType &&
          countyId == other.countyId &&
          townId == other.townId;

  @override
  int get hashCode => countyId.hashCode ^ townId.hashCode;
}
