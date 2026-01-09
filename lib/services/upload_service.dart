import 'package:pbak/services/comms/comms_service.dart';
import 'package:pbak/services/comms/api_endpoints.dart';

/// Upload Service
/// Handles all file upload-related API calls
import 'package:image_picker/image_picker.dart';

class UploadService {
  static final UploadService _instance = UploadService._internal();
  factory UploadService() => _instance;
  UploadService._internal();

  final _comms = CommsService.instance;

  /// Upload a single file (mobile/desktop)
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

  /// Upload a single file from an [XFile] (web-safe)
  Future<UploadResult?> uploadXFile({
    required XFile file,
    required String fileField,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final bytes = await file.readAsBytes();
      final safeName = (file.name.isNotEmpty)
          ? file.name
          : (file.path.isNotEmpty ? file.path.split('/').last : 'upload.bin');

      final response = await _comms.uploadFileBytes(
        ApiEndpoints.uploadFile,
        bytes: bytes,
        filename: safeName,
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
  ///
  /// Backend (multer) typically expects the binary to be under a fixed field
  /// name (commonly `file`). The type of document is communicated via metadata.
  Future<String?> uploadDocument({
    required String filePath,
    required String documentType,
    required int memberId,
  }) async {
    final result = await uploadFile(
      filePath: filePath,
      // IMPORTANT: Keep multipart file field name stable for backend.
      fileField: 'file',
      additionalData: {
        'member_id': memberId.toString(),
        // Backend commonly expects `doc_type` (see RegistrationService/KycService).
        'doc_type': documentType,
      },
    );
    return result?.url;
  }

  /// Upload document from an [XFile] (web-safe)
  Future<String?> uploadDocumentXFile({
    required XFile file,
    required String documentType,
    required int memberId,
  }) async {
    final result = await uploadXFile(
      file: file,
      // IMPORTANT: Keep multipart file field name stable for backend.
      fileField: 'file',
      additionalData: {
        'member_id': memberId.toString(),
        'doc_type': documentType,
      },
    );
    return result?.url;
  }
}

/// Upload Result model
class UploadResult {
  final String url;
  final String? filename;
  final int? size;
  final String? mimeType;
  final int? id;

  UploadResult({
    required this.url,
    this.filename,
    this.size,
    this.mimeType,
    this.id,
  });

  factory UploadResult.fromJson(Map<String, dynamic> json) {
    // Extract ID from various possible locations
    int? extractedId;
    
    // Try to get ID directly from response
    if (json['doc_id'] != null) {
      extractedId = json['doc_id'] is int
          ? json['doc_id']
          : int.tryParse(json['doc_id'].toString());
    } else if (json['id'] != null) {
      extractedId =
          json['id'] is int ? json['id'] : int.tryParse(json['id'].toString());
    } else if (json['file_id'] != null) {
      extractedId = json['file_id'] is int
          ? json['file_id']
          : int.tryParse(json['file_id'].toString());
    }
    // Extract ID from filename if not present
    // Response format: { filename: "1764924068428.jpg", newpath: "uploads/1764924068428.jpg", ... }
    else if (json['filename'] != null && json['filename'].toString().isNotEmpty) {
      final filename = json['filename'].toString();
      final filenameWithoutExt = filename.split('.').first;
      extractedId = int.tryParse(filenameWithoutExt);
    }
    // Fallback: extract from newpath
    else if (json['newpath'] != null && json['newpath'].toString().isNotEmpty) {
      final newpath = json['newpath'].toString();
      final pathParts = newpath.split('/');
      if (pathParts.isNotEmpty) {
        final filename = pathParts.last;
        final filenameWithoutExt = filename.split('.').first;
        extractedId = int.tryParse(filenameWithoutExt);
      }
    }
    // Also try path field as fallback
    else if (json['path'] != null && json['path'].toString().isNotEmpty) {
      final path = json['path'].toString();
      final pathParts = path.split('/');
      if (pathParts.isNotEmpty) {
        final filename = pathParts.last;
        final filenameWithoutExt = filename.split('.').first;
        extractedId = int.tryParse(filenameWithoutExt);
      }
    }
    
    // Construct URL from newpath or path if url not present
    String url = json['url'] ?? json['newpath'] ?? json['path'] ?? '';
    
    return UploadResult(
      url: url,
      filename: json['filename'] ?? json['file_name'] ?? json['originalname'],
      size: json['size'],
      mimeType: json['mime_type'] ?? json['mimeType'] ?? json['mimetype'],
      id: extractedId,
    );
  }

  Map<String, dynamic> toJson() => {
        'url': url,
        'filename': filename,
        'size': size,
        'mime_type': mimeType,
        'id': id,
      };
}
