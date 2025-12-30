import 'package:pbak/models/package_model.dart';
import 'package:pbak/services/comms/comms_service.dart';
import 'package:pbak/services/comms/api_endpoints.dart';

/// Package Service
/// Handles all package/subscription-related API calls
class PackageService {
  static final PackageService _instance = PackageService._internal();
  factory PackageService() => _instance;
  PackageService._internal();

  final _comms = CommsService.instance;

  /// Get all available packages
  Future<List<PackageModel>> getAllPackages() async {
    try {
      final response = await _comms.get(ApiEndpoints.allPackages);

      if (response.success && response.data != null) {
        dynamic data = response.data;

        // Access nested data object if it exists
        if (data is Map && data['data'] != null) {
          data = data['data'];
        }

        // If data is a list, map it to PackageModel
        if (data is List) {
          return data
              .map(
                (json) => PackageModel.fromJson(json as Map<String, dynamic>),
              )
              .toList();
        }
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load packages: $e');
    }
  }

  /// Get package by ID
  Future<PackageModel?> getPackageById(int packageId) async {
    try {
      final response = await _comms.get(ApiEndpoints.packageById(packageId));

      if (response.success && response.data != null) {
        dynamic data = response.data;

        // Access nested data object if it exists
        if (data is Map && data['data'] != null) {
          data = data['data'];
        }

        return PackageModel.fromJson(data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to load package: $e');
    }
  }

  /// Get member packages
  Future<List<PackageModel>> getMemberPackages(int memberId) async {
    try {
      final response = await _comms.get(ApiEndpoints.memberPackages(memberId));

      if (response.success && response.data != null) {
        dynamic data = response.data;

        // Access nested data array if it exists
        if (data is Map && data['data'] != null) {
          data = data['data'];
        }

        // If data is a list, map it to PackageModel
        if (data is List) {
          return data
              .map(
                (json) => PackageModel.fromJson(json as Map<String, dynamic>),
              )
              .toList();
        }
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load member packages: $e');
    }
  }

  /// Subscribe to a package
  Future<bool> subscribeToPackage({
    required int packageId,
    required int memberId,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final data = {
        'package_id': packageId,
        'member_id': memberId,
        ...?additionalData,
      };

      final response = await _comms.post(
        ApiEndpoints.subscribePackage,
        data: data,
      );
      return response.success;
    } catch (e) {
      return false;
    }
  }
}
