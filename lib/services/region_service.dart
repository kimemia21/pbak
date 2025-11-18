import 'package:pbak/services/comms/comms_service.dart';
import 'package:pbak/services/comms/api_endpoints.dart';

/// Region Service
/// Handles all region/location-related API calls (Counties, Towns, Estates)
class RegionService {
  static final RegionService _instance = RegionService._internal();
  factory RegionService() => _instance;
  RegionService._internal();

  final _comms = CommsService.instance;

  /// Get all counties (regions)
  Future<List<County>> getAllCounties() async {
    try {
      final response = await _comms.get<List>(ApiEndpoints.allRegions);
      
      if (response.success && response.data != null) {
        return response.data!
            .map((json) => County.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load counties: $e');
    }
  }

  /// Get towns in a county
  Future<List<Town>> getTownsInCounty(int countyId) async {
    try {
      final response = await _comms.get<List>(
        ApiEndpoints.townsInRegion(countyId),
      );
      
      if (response.success && response.data != null) {
        return response.data!
            .map((json) => Town.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load towns: $e');
    }
  }

  /// Get estates in a town
  Future<List<Estate>> getEstatesInTown({
    required int countyId,
    required int townId,
  }) async {
    try {
      final response = await _comms.get<List>(
        ApiEndpoints.estatesInTown(countyId, townId),
      );
      
      if (response.success && response.data != null) {
        return response.data!
            .map((json) => Estate.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load estates: $e');
    }
  }
}

/// County model
class County {
  final int id;
  final String name;

  County({required this.id, required this.name});

  factory County.fromJson(Map<String, dynamic> json) {
    return County(
      id: json['id'] ?? json['county_id'] ?? 0,
      name: json['name'] ?? json['county_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

/// Town model
class Town {
  final int id;
  final String name;
  final int countyId;

  Town({
    required this.id,
    required this.name,
    required this.countyId,
  });

  factory Town.fromJson(Map<String, dynamic> json) {
    return Town(
      id: json['id'] ?? json['town_id'] ?? 0,
      name: json['name'] ?? json['town_name'] ?? '',
      countyId: json['county_id'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'county_id': countyId,
      };
}

/// Estate model
class Estate {
  final int id;
  final String name;
  final int townId;

  Estate({
    required this.id,
    required this.name,
    required this.townId,
  });

  factory Estate.fromJson(Map<String, dynamic> json) {
    return Estate(
      id: json['id'] ?? json['estate_id'] ?? 0,
      name: json['name'] ?? json['estate_name'] ?? '',
      townId: json['town_id'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'town_id': townId,
      };
}
