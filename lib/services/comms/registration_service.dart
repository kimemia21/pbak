import 'package:image_picker/image_picker.dart';
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
  ///
  /// If [lat]/[lon] are provided, the API will return clubs close to that
  /// coordinate within [distanceKm] kilometers.
  Future<List<Map<String, dynamic>>> fetchClubs({
    double? lat,
    double? lon,
    double? distanceKm,
  }) async {
    final queryParameters = <String, dynamic>{};
    if (lat != null) queryParameters['lat'] = lat;
    if (lon != null) queryParameters['lon'] = lon;
    if (distanceKm != null) queryParameters['distance'] = distanceKm;

    final response = await _comms.get<Map<String, dynamic>>(
      ApiEndpoints.allClubs,
      // queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );
    print('Fetch Clubs Response: ${response.rawData}');

    if (response.success && response.rawData != null) {
      final data = response.rawData!['data'];
      if (data is List) {
        return data
            .map((club) {
              return {
                'id': club['club_id'],
                'name': club['club_name'],
                'club_code': club['club_code'],
                'description': club['description'],
              };
            })
            .toList()
            .cast<Map<String, dynamic>>();
      }
    }
    return [];
  }

  /// Fetch all regions/counties
  Future<List<Map<String, dynamic>>> fetchRegions() async {
    final response = await _comms.get<Map<String, dynamic>>(
      ApiEndpoints.allRegions,
    );
    print('Fetch Regions Response: ${response.rawData}'); // Debug log

    if (response.success && response.rawData != null) {
      final data = response.rawData!['data'];
      if (data is List) {
        // Map the API response to match our expected format
        return data
            .map((county) {
              return {'id': county['county_id'], 'name': county['county_name']};
            })
            .toList()
            .cast<Map<String, dynamic>>();
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
        return data
            .map((town) {
              return {
                'id': town['town_id'],
                'name': town['town_name'],
                'county_id': town['county_id'],
              };
            })
            .toList()
            .cast<Map<String, dynamic>>();
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
        return data
            .map((estate) {
              return {
                'id': estate['estate_id'],
                'name': estate['estate_name'],
                'town_id': estate['town_id'],
              };
            })
            .toList()
            .cast<Map<String, dynamic>>();
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
  Future<int?> uploadImage(
    String filePath,
    String imageType, {
    String? notes,
  }) async {
    try {
      print('Uploading image: $filePath, type: $imageType');

      final response = await _comms.uploadFile(
        ApiEndpoints.uploadFile,
        filePath: filePath,
        fileField: 'file',
        data: {
          'doc_type': imageType,
          if (notes != null) 'notes': notes,
        },
      );
      print("Upload data: ${{'doc_type': imageType, if (notes != null) 'notes': notes}}");

      print('Upload response: ${response.rawData}');

      if (response.success && response.rawData != null) {
        final data = response.rawData!;

        // Try to extract ID from various possible locations in response
        int? id;

        // Check if id exists in data wrapper
        if (data['data'] != null) {
          final fileData = data['data'] as Map<String, dynamic>;
          id = fileData['doc_id'] ?? fileData['id'] ?? fileData['file_id'];
        }
        // Check if id exists at root level
        else if (data['doc_id'] != null || data['id'] != null) {
          id = data['doc_id'] ?? data['id'];
        }

        return id;
      }
      print('Upload failed: ${response.message}');
      return null;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  /// Web-safe upload using XFile bytes instead of file path.
  Future<int?> uploadImageXFile(
    XFile file,
    String imageType, {
    String? notes,
  }) async {
    try {
      final bytes = await file.readAsBytes();
      final filename = file.name.isNotEmpty
          ? file.name
          : (file.path.isNotEmpty ? file.path.split('/').last : 'upload.bin');

      print('Uploading image (web): $filename, type: $imageType');

      final response = await _comms.uploadFileBytes(
        ApiEndpoints.uploadFile,
        bytes: bytes,
        filename: filename,
        fileField: 'file',
        data: {
          'doc_type': imageType,
          if (notes != null) 'notes': notes,
        },
      );

      print('Upload response: ${response.rawData}');

      if (response.success && response.rawData != null) {
        final data = response.rawData!;

        int? id;

        if (data['data'] != null) {
          final fileData = data['data'] as Map<String, dynamic>;
          id = fileData['doc_id'] ?? fileData['id'] ?? fileData['file_id'];
        } else if (data['doc_id'] != null || data['id'] != null) {
          id = data['doc_id'] ?? data['id'];
        }
        // Extract ID from filename if id is null or empty
        // Response format: { filename: "1764924068428.jpg", newpath: "uploads/1764924068428.jpg", ... }
        else if (data['filename'] != null &&
            data['filename'].toString().isNotEmpty) {
          final filename = data['filename'].toString();
          // Extract number from filename (e.g., "1764924068428.jpg" -> "1764924068428")
          final filenameWithoutExt = filename.split('.').first;
          id = int.tryParse(filenameWithoutExt);
          print('Extracted ID from filename: $filename -> $id');
        }
        // Fallback: extract from newpath if filename not available
        else if (data['newpath'] != null &&
            data['newpath'].toString().isNotEmpty) {
          final newpath = data['newpath'].toString();
          // Extract from path like "uploads/1764924068428.jpg"
          final pathParts = newpath.split('/');
          if (pathParts.isNotEmpty) {
            final filename = pathParts.last;
            final filenameWithoutExt = filename.split('.').first;
            id = int.tryParse(filenameWithoutExt);
            print('Extracted ID from newpath: $newpath -> $id');
          }
        }

        if (id != null) {
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
    print("mems $userData");
    return await _comms.post<Map<String, dynamic>>(
      ApiEndpoints.register,
      data: userData,
    );
  }
}
