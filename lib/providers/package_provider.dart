import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pbak/models/package_model.dart';
import 'package:pbak/services/mock_api/mock_api_service.dart';

final packagesProvider = FutureProvider<List<PackageModel>>((ref) async {
  final apiService = MockApiService();
  return await apiService.getPackages();
});

final packageDetailProvider = FutureProvider.family<PackageModel, String>((ref, packageId) async {
  final apiService = MockApiService();
  return await apiService.getPackageById(packageId);
});
