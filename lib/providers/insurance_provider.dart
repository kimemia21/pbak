import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pbak/models/insurance_model.dart';
import 'package:pbak/models/insurance_provider_model.dart';
import 'package:pbak/services/insurance_service.dart';
import 'package:pbak/providers/auth_provider.dart';

// Insurance service provider
final insuranceServiceProvider = Provider((ref) => InsuranceService());

final myInsuranceProvider = FutureProvider<List<InsuranceModel>>((ref) async {
  final authState = ref.watch(authProvider);
  return authState.when(
    data: (user) async {
      if (user != null) {
        // TODO: hook to real backend once insurance endpoints are confirmed.
        // For go-live, do not use mock data.
        return [];
      }
      return [];
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

final availableInsuranceProvider = FutureProvider<List<InsuranceModel>>((ref) async {
  // TODO: hook to real backend once insurance endpoints are confirmed.
  // For go-live, do not use mock data.
  return [];
});

/// Provider for fetching insurance providers from the backend
final insuranceProvidersProvider = FutureProvider<List<InsuranceProviderModel>>((ref) async {
  try {
    final insuranceService = ref.read(insuranceServiceProvider);
    return await insuranceService.getInsuranceProviders();
  } catch (e) {
    print('Error loading insurance providers: $e');
    return [];
  }
});
