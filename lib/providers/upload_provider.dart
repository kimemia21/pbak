import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pbak/services/upload_service.dart';

// Service provider
final uploadServiceProvider = Provider((ref) => UploadService());

// Upload state notifier for managing upload operations
class UploadNotifier extends StateNotifier<UploadState> {
  final UploadService _uploadService;

  UploadNotifier(this._uploadService)
      : super(UploadState(
          isUploading: false,
          uploadProgress: 0.0,
          uploadedFiles: [],
          error: null,
        ));

  Future<UploadResult?> uploadFile({
    required String filePath,
    required String fileField,
    Map<String, dynamic>? additionalData,
  }) async {
    state = state.copyWith(isUploading: true, error: null);

    try {
      final result = await _uploadService.uploadFile(
        filePath: filePath,
        fileField: fileField,
        additionalData: additionalData,
      );

      if (result != null) {
        final updatedFiles = [...state.uploadedFiles, result];
        state = state.copyWith(
          isUploading: false,
          uploadedFiles: updatedFiles,
        );
        return result;
      } else {
        state = state.copyWith(
          isUploading: false,
          error: 'Upload failed',
        );
        return null;
      }
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  Future<List<UploadResult>> uploadMultipleFiles({
    required List<String> filePaths,
    required String fileField,
    Map<String, dynamic>? additionalData,
  }) async {
    state = state.copyWith(isUploading: true, error: null);

    try {
      final results = await _uploadService.uploadMultipleFiles(
        filePaths: filePaths,
        fileField: fileField,
        additionalData: additionalData,
      );

      final updatedFiles = [...state.uploadedFiles, ...results];
      state = state.copyWith(
        isUploading: false,
        uploadedFiles: updatedFiles,
      );

      return results;
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        error: e.toString(),
      );
      return [];
    }
  }

  Future<String?> uploadProfilePhoto({
    required String filePath,
    required int memberId,
  }) async {
    state = state.copyWith(isUploading: true, error: null);

    try {
      final url = await _uploadService.uploadProfilePhoto(
        filePath: filePath,
        memberId: memberId,
      );

      state = state.copyWith(isUploading: false);
      return url;
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  Future<String?> uploadBikePhoto({
    required String filePath,
    required int bikeId,
  }) async {
    state = state.copyWith(isUploading: true, error: null);

    try {
      final url = await _uploadService.uploadBikePhoto(
        filePath: filePath,
        bikeId: bikeId,
      );

      state = state.copyWith(isUploading: false);
      return url;
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  Future<String?> uploadDocument({
    required String filePath,
    required String documentType,
    required int memberId,
  }) async {
    state = state.copyWith(isUploading: true, error: null);

    try {
      final url = await _uploadService.uploadDocument(
        filePath: filePath,
        documentType: documentType,
        memberId: memberId,
      );

      state = state.copyWith(isUploading: false);
      return url;
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  Future<String?> uploadDocumentXFile({
    required XFile file,
    required String documentType,
    required int memberId,
  }) async {
    state = state.copyWith(isUploading: true, error: null);

    try {
      final url = await _uploadService.uploadDocumentXFile(
        file: file,
        documentType: documentType,
        memberId: memberId,
      );

      state = state.copyWith(isUploading: false);
      return url;
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  void clearUploads() {
    state = state.copyWith(uploadedFiles: []);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Upload state provider
final uploadNotifierProvider = StateNotifierProvider<UploadNotifier, UploadState>((ref) {
  return UploadNotifier(ref.read(uploadServiceProvider));
});

// Upload state class
class UploadState {
  final bool isUploading;
  final double uploadProgress;
  final List<UploadResult> uploadedFiles;
  final String? error;

  UploadState({
    required this.isUploading,
    required this.uploadProgress,
    required this.uploadedFiles,
    this.error,
  });

  UploadState copyWith({
    bool? isUploading,
    double? uploadProgress,
    List<UploadResult>? uploadedFiles,
    String? error,
  }) {
    return UploadState(
      isUploading: isUploading ?? this.isUploading,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      uploadedFiles: uploadedFiles ?? this.uploadedFiles,
      error: error ?? this.error,
    );
  }
}
