import 'package:pbak/models/insurance_provider_model.dart';
import 'package:pbak/services/comms/comms_service.dart';
import 'package:pbak/services/comms/api_endpoints.dart';

/// Insurance Service
/// Handles all insurance-related API calls
class InsuranceService {
  static final InsuranceService _instance = InsuranceService._internal();
  factory InsuranceService() => _instance;
  InsuranceService._internal();

  final _comms = CommsService.instance;

  /// Get all insurance providers
  /// GET /providers/7 (type 7 = insurance)
  Future<List<InsuranceProviderModel>> getInsuranceProviders() async {
    try {
      final response = await _comms.get(ApiEndpoints.insuranceProviders);

      if (response.success && response.data != null) {
        dynamic data = response.data;

        // Access nested data object if it exists
        if (data is Map && data['data'] != null) {
          data = data['data'];
        }

        // If data is a list, map it to InsuranceProviderModel
        if (data is List) {
          return data
              .map((json) => InsuranceProviderModel.fromJson(json as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load insurance providers: $e');
    }
  }

  /// Get providers by type ID
  /// GET /providers/{type_id}
  Future<List<InsuranceProviderModel>> getProvidersByType(int typeId) async {
    try {
      final response = await _comms.get(ApiEndpoints.providersByType(typeId));

      if (response.success && response.data != null) {
        dynamic data = response.data;

        // Access nested data object if it exists
        if (data is Map && data['data'] != null) {
          data = data['data'];
        }

        // If data is a list, map it to InsuranceProviderModel
        if (data is List) {
          return data
              .map((json) => InsuranceProviderModel.fromJson(json as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load providers: $e');
    }
  }
}
