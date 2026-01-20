import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pbak/models/service_model.dart';
import 'package:pbak/services/service_service.dart';

final serviceServiceProvider = Provider((ref) => ServiceService());

final servicesProvider = FutureProvider<List<ServiceModel>>((ref) async {
  final api = ref.read(serviceServiceProvider);
  return api.getServices();
});

final nearbyServicesProvider = FutureProvider.family<List<ServiceModel>, Map<String, double>>((ref, location) async {
  final api = ref.read(serviceServiceProvider);
  return api.getNearbyServices(
    latitude: location['latitude']!,
    longitude: location['longitude']!,
  );
});

final serviceDetailProvider = FutureProvider.family<ServiceModel?, String>((ref, serviceId) async {
  final api = ref.read(serviceServiceProvider);
  return api.getServiceById(serviceId);
});
