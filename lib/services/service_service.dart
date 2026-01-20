import 'package:pbak/models/service_model.dart';
import 'package:pbak/services/comms/api_endpoints.dart';
import 'package:pbak/services/comms/comms_service.dart';

/// Service directory API wrapper (real backend).
class ServiceService {
  static final ServiceService _instance = ServiceService._internal();
  factory ServiceService() => _instance;
  ServiceService._internal();

  final _comms = CommsService.instance;

  Future<List<ServiceModel>> getServices() async {
    final response = await _comms.get(ApiEndpoints.services);
    if (!response.success || response.data == null) return [];

    dynamic data = response.data;
    if (data is Map && data['data'] != null) data = data['data'];

    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => ServiceModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

  Future<ServiceModel?> getServiceById(String id) async {
    final response = await _comms.get(ApiEndpoints.serviceByIdV2(id));
    if (!response.success || response.data == null) return null;

    dynamic data = response.data;
    if (data is Map && data['data'] != null) data = data['data'];

    if (data is Map) {
      return ServiceModel.fromJson(Map<String, dynamic>.from(data));
    }
    return null;
  }

  Future<List<ServiceModel>> getNearbyServices({
    required double latitude,
    required double longitude,
  }) async {
    // Backend expects query params. Endpoint exists in ApiEndpoints.
    final response = await _comms.get(
      ApiEndpoints.nearbyServicesV2,
      queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
      },
    );

    if (!response.success || response.data == null) return [];

    dynamic data = response.data;
    if (data is Map && data['data'] != null) data = data['data'];

    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => ServiceModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }
}
