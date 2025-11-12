import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pbak/models/insurance_model.dart';
import 'package:pbak/services/mock_api/mock_api_service.dart';
import 'package:pbak/providers/auth_provider.dart';

final myInsuranceProvider = FutureProvider<List<InsuranceModel>>((ref) async {
  final authState = ref.watch(authProvider);
  return authState.when(
    data: (user) async {
      if (user != null) {
        final apiService = MockApiService();
        return await apiService.getMyInsurance(user.id);
      }
      return [];
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

final availableInsuranceProvider = FutureProvider<List<InsuranceModel>>((ref) async {
  final apiService = MockApiService();
  return await apiService.getAvailableInsurance();
});
