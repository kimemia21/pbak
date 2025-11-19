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
    final response = await _comms.get<Map<String, dynamic>>(ApiEndpoints.allClubs);
    print('Fetch Clubs Response: ${response.rawData}'); // Debug log

    if (response.success && response.rawData != null) {
      final data = response.rawData!['data'];
      if (data is List) {
        // Map the API response to match our expected format
        return data.map((club) {
          return {
            'id': club['club_id'],
            'name': club['club_name'],
            'club_code': club['club_code'],
            'description': club['description'],
          };
        }).toList().cast<Map<String, dynamic>>();
      }
    }
    return [];
  }

  /// Fetch all regions/counties
  Future<List<Map<String, dynamic>>> fetchRegions() async {
    final response = await _comms.get<Map<String, dynamic>>(ApiEndpoints.allRegions);
    print('Fetch Regions Response: ${response.rawData}'); // Debug log

    if (response.success && response.rawData != null) {
      final data = response.rawData!['data'];
      if (data is List) {
        // Map the API response to match our expected format
        return data.map((county) {
          return {
            'id': county['county_id'],
            'name': county['county_name'],
          };
        }).toList().cast<Map<String, dynamic>>();
      }
    }
    return [];
  }

  /// Fetch towns for a specific region
  Future<List<Map<String, dynamic>>> fetchTowns(String regionId) async {
    final response = await _comms.get<Map<String, dynamic>>(
      ApiEndpoints.townsInRegion(int.parse(regionId)),
    );
    print('Fetch Towns Response: ${response.rawData}'); // Debug log

    if (response.success && response.rawData != null) {
      final data = response.rawData!['data'];
      if (data is List) {
        return data.map((town) {
          return {
            'id': town['town_id'],
            'name': town['town_name'],
            'county_id': town['county_id'],
          };
        }).toList().cast<Map<String, dynamic>>();
      }
    }
    return [];
  }

  /// Fetch estates for a specific region and town
  Future<List<Map<String, dynamic>>> fetchEstates(
    String regionId,
    String townId,
  ) async {
    final response = await _comms.get<Map<String, dynamic>>(
      ApiEndpoints.estatesInTown(int.parse(regionId), int.parse(townId)),
    );
    print('Fetch Estates Response: ${response.rawData}'); // Debug log

    if (response.success && response.rawData != null) {
      final data = response.rawData!['data'];
      if (data is List) {
        return data.map((estate) {
          return {
            'id': estate['estate_id'],
            'name': estate['estate_name'],
            'town_id': estate['town_id'],
          };
        }).toList().cast<Map<String, dynamic>>();
      }
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
  /// imageType: 'dl' for driving license, 'passport' for passport photo
  Future<int?> uploadImage(String filePath, String imageType) async {
    try {
      print('Uploading image: $filePath, type: $imageType');
      
      final response = await _comms.uploadFile(
        ApiEndpoints.uploadFile,
        filePath: filePath,
        fileField: 'file',
        data: {'doc_type': imageType},
      );

      print('Upload response: ${response.rawData}');

      if (response.success && response.rawData != null) {
        // API might return { status: "success", data: { id: 123, url: "..." } }
        // or { id: 123, url: "..." }
        final data = response.rawData!;
        
        if (data['data'] != null) {
          final fileData = data['data'] as Map<String, dynamic>;
          final id = fileData['id'] ?? fileData['file_id'];
          print('Uploaded successfully, ID: $id');
          return id is int ? id : int.tryParse(id.toString());
        } else if (data['id'] != null) {
          final id = data['id'];
          print('Uploaded successfully, ID: $id');
          return id is int ? id : int.tryParse(id.toString());
        }
      }
      
      print('Upload failed: ${response.message}');
      return null;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
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
