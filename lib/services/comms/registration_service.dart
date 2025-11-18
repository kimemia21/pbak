import 'package:pbak/services/comms/comms.dart';

/// Service for handling registration-related API calls
class RegistrationService {
  final _comms = CommsService.instance;

  Future<void> initialize() async {
    // For testing purposes, set a static auth token
    _comms.setAuthToken(
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6MiwiaWF0IjoxNzYzNDUwNjk0LCJleHAiOjE3NjM1MzcwOTR9.eo0_oOfmRx0ZYk93pqy_SustQM9Rd9pm3vayL67_WJ0",
    );
  
  }

  /// Fetch all available clubs
  Future<List<Map<String, dynamic>>> fetchClubs() async {
    final response = await _comms.get<List>(ApiEndpoints.allClubs);
    print('Fetch Clubs Response: ${response.rawData}'); // Debug log

    if (response.success && response.data != null) {
      return response.data!.cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// Fetch all regions/counties
  Future<List<Map<String, dynamic>>> fetchRegions() async {
    final response = await _comms.get<List>(ApiEndpoints.regions);

    if (response.success && response.data != null) {
      return response.data!.cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// Fetch towns for a specific region
  Future<List<Map<String, dynamic>>> fetchTowns(String regionId) async {
    final response = await _comms.get<List>(ApiEndpoints.townsInRegion(int.parse(regionId)));

    if (response.success && response.data != null) {
      return response.data!.cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// Fetch estates for a specific region and town
  Future<List<Map<String, dynamic>>> fetchEstates(
    String regionId,
    String townId,
  ) async {
    final response = await _comms.get<List>(
      ApiEndpoints.estatesInTown(int.parse(regionId), int.parse(townId)),
    );

    if (response.success && response.data != null) {
      return response.data!.cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// Fetch occupations
  /// Since there's no API endpoint for occupations, return a static list
  Future<List<Map<String, dynamic>>> fetchOccupations() async {
    // Return static occupations list
    return [
      {'id': 1, 'name': 'Employed'},
      {'id': 2, 'name': 'Self-Employed'},
      {'id': 3, 'name': 'Student'},
      {'id': 4, 'name': 'Retired'},
      {'id': 5, 'name': 'Unemployed'},
      {'id': 6, 'name': 'Business Owner'},
      {'id': 7, 'name': 'Professional'},
      {'id': 8, 'name': 'Other'},
    ];
  }

  /// Upload image and get ID
  Future<int?> uploadImage(String filePath, String imageType) async {
    final response = await _comms.uploadFile<Map<String, dynamic>>(
      '/uploads/image',
      filePath: filePath,
      fileField: 'image',
      data: {'type': imageType},
    );

    if (response.success && response.rawData != null) {
      return response.rawData!['id'] as int?;
    }
    return null;
  }

  /// Register user
  Future<CommsResponse<Map<String, dynamic>>> registerUser(
    Map<String, dynamic> userData,
  ) async {
    return await _comms.post<Map<String, dynamic>>(
      ApiEndpoints.register,
      data: userData,
    );
  }
}
