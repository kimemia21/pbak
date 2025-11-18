import 'package:pbak/models/sos_model.dart';
import 'package:pbak/services/comms/comms_service.dart';
import 'package:pbak/services/comms/api_endpoints.dart';

/// SOS Service
/// Handles all emergency SOS-related API calls
class SOSService {
  static final SOSService _instance = SOSService._internal();
  factory SOSService() => _instance;
  SOSService._internal();

  final _comms = CommsService.instance;

  /// Send SOS alert
  Future<SOSModel?> sendSOS({
    required double latitude,
    required double longitude,
    required String type,
    String? description,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final data = {
        'latitude': latitude,
        'longitude': longitude,
        'type': type,
        'description': description,
        ...?additionalData,
      };

      final response = await _comms.post<Map<String, dynamic>>(
        ApiEndpoints.sendSOS,
        data: data,
      );
      
      if (response.success && response.data != null) {
        return SOSModel.fromJson(response.data!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to send SOS: $e');
    }
  }

  /// Get SOS by ID
  Future<SOSModel?> getSOSById(int sosId) async {
    try {
      final response = await _comms.get<Map<String, dynamic>>(
        ApiEndpoints.sosById(sosId),
      );
      
      if (response.success && response.data != null) {
        return SOSModel.fromJson(response.data!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to load SOS: $e');
    }
  }

  /// Get my SOS alerts
  Future<List<SOSModel>> getMySOS() async {
    try {
      final response = await _comms.get<List>(ApiEndpoints.mySOS);
      
      if (response.success && response.data != null) {
        return response.data!
            .map((json) => SOSModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load SOS alerts: $e');
    }
  }

  /// Cancel SOS alert
  Future<bool> cancelSOS(int sosId) async {
    try {
      final response = await _comms.post(ApiEndpoints.cancelSOS(sosId));
      return response.success;
    } catch (e) {
      return false;
    }
  }

  /// Get nearest service providers
  Future<List<ServiceProvider>> getNearestProviders({
    required double latitude,
    required double longitude,
    String? serviceType,
  }) async {
    try {
      final response = await _comms.get<List>(
        ApiEndpoints.nearestProviders,
        queryParameters: {
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
          if (serviceType != null) 'type': serviceType,
        },
      );
      
      if (response.success && response.data != null) {
        return response.data!
            .map((json) => ServiceProvider.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load service providers: $e');
    }
  }
}

/// Service Provider model
class ServiceProvider {
  final int id;
  final String name;
  final String type;
  final String phone;
  final double latitude;
  final double longitude;
  final double? distance;

  ServiceProvider({
    required this.id,
    required this.name,
    required this.type,
    required this.phone,
    required this.latitude,
    required this.longitude,
    this.distance,
  });

  factory ServiceProvider.fromJson(Map<String, dynamic> json) {
    return ServiceProvider(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      phone: json['phone'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      distance: json['distance']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'phone': phone,
        'latitude': latitude,
        'longitude': longitude,
        'distance': distance,
      };
}
