import 'package:pbak/models/bike_model.dart';
import 'package:pbak/services/comms/comms_service.dart';
import 'package:pbak/services/comms/api_endpoints.dart';

/// Bike Service
/// Handles all bike-related API calls
class BikeService {
  static final BikeService _instance = BikeService._internal();
  factory BikeService() => _instance;
  BikeService._internal();

  final _comms = CommsService.instance;

  /// Get all bikes for current user
  Future<List<BikeModel>> getMyBikes() async {
    try {
      final response = await _comms.get(ApiEndpoints.allBikes);
      
      if (response.success && response.data != null) {
        dynamic data = response.data;
        print('mesh ${data}');
        
        // Access the nested data object first
        if (data is Map && data['data'] != null) {
          data = data['data'];
        }
        
        // Then access the items array
        if (data is Map && data['items'] != null && data['items'] is List) {
          final items = data['items'] as List;
          return items
              .map((json) => BikeModel.fromJson(json as Map<String, dynamic>))
              .toList();
        }
        
        // Fallback: if data is directly a list
        if (data is List) {
          return data
              .map((json) => BikeModel.fromJson(json as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error loading bikes: $e');
      throw Exception('Failed to load bikes: $e');
    }
  }

  /// Get bike by ID
  Future<BikeModel?> getBikeById(int bikeId) async {
    try {
      final response = await _comms.get<Map<String, dynamic>>(
        ApiEndpoints.bikeById(bikeId),
      );
      
      if (response.success && response.data != null) {
        return BikeModel.fromJson(response.data!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to load bike: $e');
    }
  }

  /// Get all bike makes
  Future<List<BikeMake>> getBikeMakes() async {
    try {
      final response = await _comms.get(ApiEndpoints.bikeMakes);
      
      if (response.success && response.data != null) {
        dynamic data = response.data;
        
        // Access the nested data object first
        if (data is Map && data['data'] != null) {
          data = data['data'];
        }
        
        // Then access the makes array
        if (data is Map && data['makes'] != null && data['makes'] is List) {
          final makes = data['makes'] as List;
          return makes
              .map((json) => BikeMake.fromJson(json as Map<String, dynamic>))
              .toList();
        }
        
        // Fallback: if data is directly a list
        if (data is List) {
          return data
              .map((json) => BikeMake.fromJson(json as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load bike makes: $e');
    }
  }

  /// Get bike models for a specific make
  Future<List<BikeModel>> getBikeModels(int makeId) async {
    try {
      final response = await _comms.get(
        ApiEndpoints.bikeModels(makeId),
      );
      
      if (response.success && response.data != null) {
        dynamic data = response.data;
        
        // Access the nested data object first
        if (data is Map && data['data'] != null) {
          data = data['data'];
        }
        
        // Then access the models array
        if (data is Map && data['models'] != null && data['models'] is List) {
          final models = data['models'] as List;
          return models
              .map((json) => BikeModel.fromJson(json as Map<String, dynamic>))
              .toList();
        }
        
        // Fallback: if data is directly a list
        if (data is List) {
          return data
              .map((json) => BikeModel.fromJson(json as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load bike models: $e');
    }
  }

  /// Add a new bike
  Future<BikeModel?> addBike(Map<String, dynamic> bikeData) async {
    try {
      final response = await _comms.post<Map<String, dynamic>>(
        ApiEndpoints.addBike,
        data: bikeData,
      );
      
      if (response.success && response.data != null) {
        return BikeModel.fromJson(response.data!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to add bike: $e');
    }
  }

  /// Update bike
  Future<BikeModel?> updateBike({
    required int bikeId,
    required Map<String, dynamic> bikeData,
  }) async {
    try {
      final response = await _comms.put<Map<String, dynamic>>(
        ApiEndpoints.updateBike(bikeId),
        data: bikeData,
      );
      
      if (response.success && response.data != null) {
        return BikeModel.fromJson(response.data!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to update bike: $e');
    }
  }

  /// Delete bike
  Future<bool> deleteBike(int bikeId) async {
    try {
      final response = await _comms.delete(ApiEndpoints.deleteBike(bikeId));
      return response.success;
    } catch (e) {
      return false;
    }
  }

  /// Upload bike image
  Future<String?> uploadBikeImage({
    required int bikeId,
    required String imagePath,
  }) async {
    try {
      final response = await _comms.uploadFile(
        ApiEndpoints.uploadFile,
        filePath: imagePath,
        fileField: 'bike_photo',
        data: {'bike_id': bikeId.toString()},
      );
      
      if (response.success && response.data != null) {
        return response.data!['url'] as String?;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to upload bike image: $e');
    }
  }
}

/// Bike Make model
class BikeMake {
  final int id;
  final String name;

  BikeMake({required this.id, required this.name});

  factory BikeMake.fromJson(Map<String, dynamic> json) {
    return BikeMake(
      id: json['id'] ?? json['make_id'] ?? 0,
      name: json['name'] ?? json['make_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}
