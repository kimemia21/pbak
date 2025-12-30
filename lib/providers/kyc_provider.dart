import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pbak/models/kyc_document_model.dart';
import 'package:pbak/services/kyc_service.dart';

// Service provider
final kycServiceProvider = Provider((ref) => KycService());

// KYC state notifier for managing document uploads
class KycNotifier extends StateNotifier<KycState> {
  final KycService _kycService;

  KycNotifier(this._kycService)
      : super(KycState(
          kycData: MemberKycData(),
          isUploading: false,
          uploadProgress: {},
          error: null,
        ));

  /// Upload passport photo after face verification
  Future<bool> uploadPassportPhoto({
    required String filePath,
    required bool livenessVerified,
  }) async {
    state = state.copyWith(isUploading: true, error: null);

    try {
      final document = await _kycService.uploadVerifiedPassportPhoto(
        filePath: filePath,
        livenessVerified: livenessVerified,
      );

      if (document != null) {
        state = state.copyWith(
          isUploading: false,
          kycData: state.kycData.copyWith(
            passportPhoto: document,
            isPassportPhotoVerified: livenessVerified,
          ),
        );
        return true;
      } else {
        state = state.copyWith(
          isUploading: false,
          error: 'Failed to upload passport photo',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Upload national ID
  Future<bool> uploadNationalId({
    required String filePath,
    String? idNumber,
  }) async {
    state = state.copyWith(isUploading: true, error: null);

    try {
      final document = await _kycService.uploadNationalId(
        filePath: filePath,
        idNumber: idNumber,
      );

      if (document != null) {
        state = state.copyWith(
          isUploading: false,
          kycData: state.kycData.copyWith(nationalId: document),
        );
        return true;
      } else {
        state = state.copyWith(
          isUploading: false,
          error: 'Failed to upload national ID',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Upload driving license
  Future<bool> uploadDrivingLicense({
    required String filePath,
    String? licenseNumber,
  }) async {
    state = state.copyWith(isUploading: true, error: null);

    try {
      final document = await _kycService.uploadDrivingLicense(
        filePath: filePath,
        licenseNumber: licenseNumber,
      );

      if (document != null) {
        state = state.copyWith(
          isUploading: false,
          kycData: state.kycData.copyWith(drivingLicense: document),
        );
        return true;
      } else {
        state = state.copyWith(
          isUploading: false,
          error: 'Failed to upload driving license',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Upload bike photos (all 3 at once)
  Future<bool> uploadBikePhotos({
    required String frontPhotoPath,
    required String sidePhotoPath,
    required String rearPhotoPath,
    String? plateNumber,
  }) async {
    state = state.copyWith(isUploading: true, error: null);

    try {
      final documents = await _kycService.uploadBikePhotos(
        frontPhotoPath: frontPhotoPath,
        sidePhotoPath: sidePhotoPath,
        rearPhotoPath: rearPhotoPath,
        plateNumber: plateNumber,
      );

      if (documents.length == 3) {
        final front = documents.firstWhere(
          (doc) => doc.type == KycDocumentType.bikePhotoFront,
        );
        final side = documents.firstWhere(
          (doc) => doc.type == KycDocumentType.bikePhotoSide,
        );
        final rear = documents.firstWhere(
          (doc) => doc.type == KycDocumentType.bikePhotoRear,
        );

        state = state.copyWith(
          isUploading: false,
          kycData: state.kycData.copyWith(
            bikePhotoFront: front,
            bikePhotoSide: side,
            bikePhotoRear: rear,
            areBikePhotosComplete: true,
          ),
        );
        return true;
      } else {
        state = state.copyWith(
          isUploading: false,
          error: 'Failed to upload all bike photos. Uploaded ${documents.length}/3',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Upload insurance card
  Future<bool> uploadInsuranceCard({
    required String filePath,
    String? policyNumber,
    String? insuranceCompany,
  }) async {
    state = state.copyWith(isUploading: true, error: null);

    try {
      final document = await _kycService.uploadInsuranceCard(
        filePath: filePath,
        policyNumber: policyNumber,
        insuranceCompany: insuranceCompany,
      );

      if (document != null) {
        state = state.copyWith(
          isUploading: false,
          kycData: state.kycData.copyWith(insuranceCard: document),
        );
        return true;
      } else {
        state = state.copyWith(
          isUploading: false,
          error: 'Failed to upload insurance card',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Upload logbook
  Future<bool> uploadLogbook({required String filePath}) async {
    state = state.copyWith(isUploading: true, error: null);

    try {
      final document = await _kycService.uploadLogbook(filePath: filePath);

      if (document != null) {
        state = state.copyWith(
          isUploading: false,
          kycData: state.kycData.copyWith(logbook: document),
        );
        return true;
      } else {
        state = state.copyWith(
          isUploading: false,
          error: 'Failed to upload logbook',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Upload medical insurance
  Future<bool> uploadMedicalInsurance({
    required String filePath,
    String? policyNumber,
    String? provider,
  }) async {
    state = state.copyWith(isUploading: true, error: null);

    try {
      final document = await _kycService.uploadMedicalInsurance(
        filePath: filePath,
        policyNumber: policyNumber,
        provider: provider,
      );

      if (document != null) {
        state = state.copyWith(
          isUploading: false,
          kycData: state.kycData.copyWith(medicalInsurance: document),
        );
        return true;
      } else {
        state = state.copyWith(
          isUploading: false,
          error: 'Failed to upload medical insurance',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Get all document IDs for registration
  Map<String, int?> getDocumentIds() {
    return state.kycData.documentIds;
  }

  /// Validate all required documents are uploaded
  bool validateDocuments() {
    return _kycService.validateKycDocuments(state.kycData);
  }

  /// Get document status
  Map<String, dynamic> getDocumentStatus() {
    return _kycService.getDocumentStatus(state.kycData);
  }

  /// Clear all documents
  void clearDocuments() {
    state = state.copyWith(
      kycData: MemberKycData(),
      uploadProgress: {},
      error: null,
    );
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Update document (used by enhanced upload screen)
  Future<void> updateDocument(KycDocument document) async {
    setDocument(document.type, document);
  }

  /// Remove document
  Future<void> removeDocument(KycDocumentType type) async {
    switch (type) {
      case KycDocumentType.passportPhoto:
        state = state.copyWith(
          kycData: state.kycData.copyWith(passportPhoto: null),
        );
        break;
      case KycDocumentType.nationalIdFront:
        state = state.copyWith(
          kycData: state.kycData.copyWith(nationalIdFront: null),
        );
        break;
      case KycDocumentType.nationalIdBack:
        state = state.copyWith(
          kycData: state.kycData.copyWith(nationalIdBack: null),
        );
        break;
      case KycDocumentType.nationalId:
        state = state.copyWith(
          kycData: state.kycData.copyWith(nationalId: null),
        );
        break;
      case KycDocumentType.drivingLicenseFront:
        state = state.copyWith(
          kycData: state.kycData.copyWith(drivingLicenseFront: null),
        );
        break;
      case KycDocumentType.drivingLicenseBack:
        state = state.copyWith(
          kycData: state.kycData.copyWith(drivingLicenseBack: null),
        );
        break;
      case KycDocumentType.drivingLicense:
        state = state.copyWith(
          kycData: state.kycData.copyWith(drivingLicense: null),
        );
        break;
      case KycDocumentType.bikePhotoFront:
        state = state.copyWith(
          kycData: state.kycData.copyWith(bikePhotoFront: null),
        );
        break;
      case KycDocumentType.bikePhotoSide:
        state = state.copyWith(
          kycData: state.kycData.copyWith(bikePhotoSide: null),
        );
        break;
      case KycDocumentType.bikePhotoRear:
        state = state.copyWith(
          kycData: state.kycData.copyWith(bikePhotoRear: null),
        );
        break;
      case KycDocumentType.insuranceCard:
        state = state.copyWith(
          kycData: state.kycData.copyWith(insuranceCard: null),
        );
        break;
      case KycDocumentType.logbook:
        state = state.copyWith(
          kycData: state.kycData.copyWith(logbook: null),
        );
        break;
      case KycDocumentType.medicalInsurance:
        state = state.copyWith(
          kycData: state.kycData.copyWith(medicalInsurance: null),
        );
        break;
    }
  }

  /// Set document directly (for testing or manual setting)
  void setDocument(KycDocumentType type, KycDocument document) {
    switch (type) {
      case KycDocumentType.passportPhoto:
        state = state.copyWith(
          kycData: state.kycData.copyWith(passportPhoto: document),
        );
        break;
      case KycDocumentType.nationalIdFront:
        state = state.copyWith(
          kycData: state.kycData.copyWith(nationalIdFront: document),
        );
        break;
      case KycDocumentType.nationalIdBack:
        state = state.copyWith(
          kycData: state.kycData.copyWith(nationalIdBack: document),
        );
        break;
      case KycDocumentType.nationalId:
        state = state.copyWith(
          kycData: state.kycData.copyWith(nationalId: document),
        );
        break;
      case KycDocumentType.drivingLicenseFront:
        state = state.copyWith(
          kycData: state.kycData.copyWith(drivingLicenseFront: document),
        );
        break;
      case KycDocumentType.drivingLicenseBack:
        state = state.copyWith(
          kycData: state.kycData.copyWith(drivingLicenseBack: document),
        );
        break;
      case KycDocumentType.drivingLicense:
        state = state.copyWith(
          kycData: state.kycData.copyWith(drivingLicense: document),
        );
        break;
      case KycDocumentType.bikePhotoFront:
        state = state.copyWith(
          kycData: state.kycData.copyWith(bikePhotoFront: document),
        );
        break;
      case KycDocumentType.bikePhotoSide:
        state = state.copyWith(
          kycData: state.kycData.copyWith(bikePhotoSide: document),
        );
        break;
      case KycDocumentType.bikePhotoRear:
        state = state.copyWith(
          kycData: state.kycData.copyWith(bikePhotoRear: document),
        );
        break;
      case KycDocumentType.insuranceCard:
        state = state.copyWith(
          kycData: state.kycData.copyWith(insuranceCard: document),
        );
        break;
      case KycDocumentType.logbook:
        state = state.copyWith(
          kycData: state.kycData.copyWith(logbook: document),
        );
        break;
      case KycDocumentType.medicalInsurance:
        state = state.copyWith(
          kycData: state.kycData.copyWith(medicalInsurance: document),
        );
        break;
    }
  }
}

// KYC state provider
final kycNotifierProvider = StateNotifierProvider<KycNotifier, KycState>((ref) {
  return KycNotifier(ref.read(kycServiceProvider));
});

// KYC state class
class KycState {
  final MemberKycData kycData;
  final bool isUploading;
  final Map<String, double> uploadProgress;
  final String? error;

  KycState({
    required this.kycData,
    required this.isUploading,
    required this.uploadProgress,
    this.error,
  });

  KycState copyWith({
    MemberKycData? kycData,
    bool? isUploading,
    Map<String, double>? uploadProgress,
    String? error,
  }) {
    return KycState(
      kycData: kycData ?? this.kycData,
      isUploading: isUploading ?? this.isUploading,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      error: error ?? this.error,
    );
  }
}
