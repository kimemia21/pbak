import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pbak/models/service_model.dart';
import 'package:pbak/services/mock_api/mock_api_service.dart';

final servicesProvider = FutureProvider<List<ServiceModel>>((ref) async {
  final apiService = MockApiService();
  return await apiService.getServices();
});

final nearbyServicesProvider = FutureProvider.family<List<ServiceModel>, Map<String, double>>((ref, location) async {
  final apiService = MockApiService();
  return await apiService.getNearbyServices(location['latitude']!, location['longitude']!);
});

final serviceDetailProvider = FutureProvider.family<ServiceModel, String>((ref, serviceId) async {
  final apiService = MockApiService();
  return await apiService.getServiceById(serviceId);
});
