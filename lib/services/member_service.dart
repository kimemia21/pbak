import 'package:pbak/models/user_model.dart';
import 'package:pbak/models/package_model.dart';
import 'package:pbak/services/comms/comms_service.dart';
import 'package:pbak/services/comms/api_endpoints.dart';

/// Member Service
/// Handles all member-related API calls
class MemberService {
  static final MemberService _instance = MemberService._internal();
  factory MemberService() => _instance;
  MemberService._internal();

  final _comms = CommsService.instance;

  /// Get all members
  Future<List<UserModel>> getAllMembers() async {
    try {
      final response = await _comms.get<List>(ApiEndpoints.allMembers);
      
      if (response.success && response.data != null) {
        return response.data!
            .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load members: $e');
    }
  }

  /// Get member by ID
  Future<UserModel?> getMemberById(int memberId) async {
    try {
      final response = await _comms.get<Map<String, dynamic>>(
        ApiEndpoints.memberById(memberId),
      );
      
      if (response.success && response.data != null) {
        return UserModel.fromJson(response.data!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to load member: $e');
    }
  }

  /// Get member statistics
  Future<Map<String, dynamic>> getMemberStats() async {
    try {
      final response = await _comms.get<Map<String, dynamic>>(
        ApiEndpoints.memberStats,
      );
      
      if (response.success && response.data != null) {
        return response.data!;
      }
      return {};
    } catch (e) {
      throw Exception('Failed to load member stats: $e');
    }
  }

  /// Update member parameters
  Future<bool> updateMemberParams({
    required int memberId,
    required Map<String, dynamic> params,
  }) async {
    try {
      final response = await _comms.put(
        ApiEndpoints.updateMemberParams(memberId),
        data: params,
      );
      return response.success;
    } catch (e) {
      return false;
    }
  }

  /// Check member by ID number and return raw payload.
  ///
  /// Endpoint: GET /searchmember?id_number={idNumber}
  ///
  /// Expected response structure:
  /// {
  ///   "status": "success",
  ///   "rsp": true,
  ///   "data": { "linked": 0|1, ... }
  /// }
  Future<Map<String, dynamic>?> searchMemberByIdNumber(
    int idNumber, {
    String? email,
  }) async {
    try {
      final response = await _comms.get<Map<String, dynamic>>(
        ApiEndpoints.searchMember,
        queryParameters: {
          'id_number': idNumber,
          if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
        },
      );

      if (response.success && response.data != null) {
        // Some APIs wrap the payload under `data`.
        final data = response.data!;
        if (data['data'] is Map<String, dynamic>) {
          return data['data'] as Map<String, dynamic>;
        }
        return data;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to search member: $e');
    }
  }

  /// Check whether a member (by ID number) has an active linked package.
  /// linked == 1 => has active subscription
  /// linked == 0 => no active subscription
  Future<bool> hasActivePackageByIdNumber(
    int idNumber, {
    String? email,
  }) async {
    final data = await searchMemberByIdNumber(idNumber, email: email);
    final linked = data?['linked'];
    if (linked is int) return linked == 1;
    if (linked is bool) return linked;
    if (linked is String) return linked == '1' || linked.toLowerCase() == 'true';
    return false;
  }

  /// Get member's packages
  Future<List<PackageModel>> getMemberPackages(int memberId) async {
    try {
      final response = await _comms.get<List>(
        ApiEndpoints.memberPackages(memberId),
      );
      
      if (response.success && response.data != null) {
        return response.data!
            .map((json) => PackageModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load member packages: $e');
    }
  }

  /// Update member profile
  Future<UserModel?> updateProfile({
    required int memberId,
    required Map<String, dynamic> profileData,
  }) async {
    try {
      final response = await _comms.put<Map<String, dynamic>>(
        ApiEndpoints.memberById(memberId),
        data: profileData,
      );
      
      if (response.success && response.data != null) {
        return UserModel.fromJson(response.data!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  /// Upload profile image
  Future<String?> uploadProfileImage({
    required int memberId,
    required String imagePath,
  }) async {
    try {
      final response = await _comms.uploadFile(
        ApiEndpoints.uploadFile,
        filePath: imagePath,
        fileField: 'profile_photo',
        data: {'member_id': memberId.toString()},
      );
      
      if (response.success && response.data != null) {
        return response.data!['url'] as String?;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to upload profile image: $e');
    }
  }
}
