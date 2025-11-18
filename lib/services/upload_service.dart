import 'package:pbak/services/comms/comms_service.dart';
import 'package:pbak/services/comms/api_endpoints.dart';

/// Upload Service
/// Handles all file upload-related API calls
class UploadService {
  static final UploadService _instance = UploadService._internal();
  factory UploadService() => _instance;
  UploadService._internal();

  final _comms = CommsService.instance;

  /// Upload a single file
  Future<UploadResult?> uploadFile({
    required String filePath,
    required String fileField,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final response = await _comms.uploadFile(
        ApiEndpoints.uploadFile,
        filePath: filePath,
        fileField: fileField,
        data: additionalData,
      );
      
      if (response.success && response.data != null) {
        return UploadResult.fromJson(response.data!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  /// Upload multiple files
  Future<List<UploadResult>> uploadMultipleFiles({
    required List<String> filePaths,
    required String fileField,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final results = <UploadResult>[];
      
      for (final filePath in filePaths) {
        final result = await uploadFile(
          filePath: filePath,
          fileField: fileField,
          additionalData: additionalData,
        );
        
        if (result != null) {
          results.add(result);
        }
      }
      
      return results;
    } catch (e) {
      throw Exception('Failed to upload files: $e');
    }
  }

  /// Upload profile photo
  Future<String?> uploadProfilePhoto({
    required String filePath,
    required int memberId,
  }) async {
    try {
      final result = await uploadFile(
        filePath: filePath,
        fileField: 'profile_photo',
        additionalData: {'member_id': memberId.toString()},
      );
      return result?.url;
    } catch (e) {
      return null;
    }
  }

  /// Upload bike photo
  Future<String?> uploadBikePhoto({
    required String filePath,
    required int bikeId,
  }) async {
    try {
      final result = await uploadFile(
        filePath: filePath,
        fileField: 'bike_photo',
        additionalData: {'bike_id': bikeId.toString()},
      );
      return result?.url;
    } catch (e) {
      return null;
    }
  }

  /// Upload document (ID, license, etc.)
  Future<String?> uploadDocument({
    required String filePath,
    required String documentType,
    required int memberId,
  }) async {
    try {
      final result = await uploadFile(
        filePath: filePath,
        fileField: documentType,
        additionalData: {
          'member_id': memberId.toString(),
          'document_type': documentType,
        },
      );
      return result?.url;
    } catch (e) {
      return null;
    }
  }
}

/// Upload Result model
class UploadResult {
  final String url;
  final String? filename;
  final int? size;
  final String? mimeType;

  UploadResult({
    required this.url,
    this.filename,
    this.size,
    this.mimeType,
  });

  factory UploadResult.fromJson(Map<String, dynamic> json) {
    return UploadResult(
      url: json['url'] ?? '',
      filename: json['filename'] ?? json['file_name'],
      size: json['size'],
      mimeType: json['mime_type'] ?? json['mimeType'],
    );
  }

  Map<String, dynamic> toJson() => {
        'url': url,
        'filename': filename,
        'size': size,
        'mime_type': mimeType,
      };
}
