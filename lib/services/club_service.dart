import 'package:pbak/models/club_model.dart';
import 'package:pbak/models/user_model.dart';
import 'package:pbak/services/comms/comms_service.dart';
import 'package:pbak/services/comms/api_endpoints.dart';

/// Club Service
/// Handles all club-related API calls
class ClubService {
  static final ClubService _instance = ClubService._internal();
  factory ClubService() => _instance;
  ClubService._internal();

  final _comms = CommsService.instance;

  /// Get all clubs
  Future<List<ClubModel>> getAllClubs() async {
    try {
      final response = await _comms.get(ApiEndpoints.allClubs);
      
      if (response.success && response.data != null) {
        dynamic data = response.data;
        
        // Access nested data object if it exists
        if (data is Map && data['data'] != null) {
          data = data['data'];
        }
        
        // If data is a list, map it to ClubModel
        if (data is List) {
          return data
              .map((json) => ClubModel.fromJson(json as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load clubs: $e');
    }
  }

  /// Get club by ID
  Future<ClubModel?> getClubById(int clubId) async {
    try {
      final response = await _comms.get(
        ApiEndpoints.clubById(clubId),
      );
      
      if (response.success && response.data != null) {
        dynamic data = response.data;
        
        // Access nested data object if it exists
        if (data is Map && data['data'] != null) {
          data = data['data'];
        }
        
        return ClubModel.fromJson(data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to load club: $e');
    }
  }

  /// Create a new club
  Future<ClubModel?> createClub(Map<String, dynamic> clubData) async {
    try {
      final response = await _comms.post(
        ApiEndpoints.createClub,
        data: clubData,
      );
      
      if (response.success && response.data != null) {
        dynamic data = response.data;
        
        // Access nested data object if it exists
        if (data is Map && data['data'] != null) {
          data = data['data'];
        }
        
        return ClubModel.fromJson(data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to create club: $e');
    }
  }

  /// Update club
  Future<ClubModel?> updateClub({
    required int clubId,
    required Map<String, dynamic> clubData,
  }) async {
    try {
      final response = await _comms.put(
        ApiEndpoints.updateClub(clubId),
        data: clubData,
      );
      
      if (response.success && response.data != null) {
        dynamic data = response.data;
        
        // Access nested data object if it exists
        if (data is Map && data['data'] != null) {
          data = data['data'];
        }
        
        return ClubModel.fromJson(data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to update club: $e');
    }
  }

  /// Delete club
  Future<bool> deleteClub(int clubId) async {
    try {
      final response = await _comms.delete(ApiEndpoints.deleteClub(clubId));
      return response.success;
    } catch (e) {
      return false;
    }
  }

  /// Join a club
  Future<bool> joinClub(int clubId) async {
    try {
      final response = await _comms.post(ApiEndpoints.joinClub(clubId));
      return response.success;
    } catch (e) {
      return false;
    }
  }

  /// Leave a club
  Future<bool> leaveClub(int clubId) async {
    try {
      final response = await _comms.post(ApiEndpoints.leaveClub(clubId));
      return response.success;
    } catch (e) {
      return false;
    }
  }

  /// Get club members
  Future<List<UserModel>> getClubMembers(int clubId) async {
    try {
      final response = await _comms.get(
        ApiEndpoints.clubMembers(clubId),
      );
      
      if (response.success && response.data != null) {
        dynamic data = response.data;
        
        // Access nested data object if it exists
        if (data is Map && data['data'] != null) {
          data = data['data'];
        }
        
        // If data is a list, map it to UserModel
        if (data is List) {
          return data
              .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load club members: $e');
    }
  }
}