import 'package:pbak/models/kyc_document_model.dart';
import 'package:pbak/services/comms/comms_service.dart';
import 'package:pbak/services/comms/api_endpoints.dart';

/// KYC Service
/// Handles document uploads and verification for Know Your Customer process
class KycService {
  static final KycService _instance = KycService._internal();
  factory KycService() => _instance;
  KycService._internal();

  final _comms = CommsService.instance;

  /// Upload a KYC document and return the document with ID
  Future<KycDocument?> uploadDocument({
    required String filePath,
    required KycDocumentType documentType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      print('🔼 Uploading ${documentType.displayName}: $filePath');

      final data = {
        'doc_type': documentType.code,
        ...?metadata,
      };

      final response = await _comms.uploadFile(
        ApiEndpoints.uploadFile,
        filePath: filePath,
        fileField: 'file',
        data: data,
      );

      print('📤 Upload response: ${response.rawData}');

      if (response.success && response.rawData != null) {
        final responseData = response.rawData!;

        // Handle different response formats
        int? documentId;
        String? url;

        if (responseData['data'] != null) {
          final fileData = responseData['data'] as Map<String, dynamic>;
          documentId = fileData['id'] ?? fileData['file_id'];
          url = fileData['url'] ?? fileData['newpath'] ?? fileData['file_url'];
        } else {
          documentId = responseData['id'] ?? responseData['file_id'];
          url = responseData['url'] ??
              responseData['newpath'] ??
              responseData['file_url'];
        }

        if (documentId != null) {
          print('✅ Upload successful! ID: $documentId');
          return KycDocument(
            id: documentId is int ? documentId : int.tryParse(documentId.toString()),
            type: documentType,
            filePath: filePath,
            url: url,
            filename: filePath.split('/').last,
            uploadedAt: DateTime.now(),
            isVerified: false,
          );
        }
      }

      print('❌ Upload failed: ${response.message}');
      return null;
    } catch (e) {
      print('❌ Error uploading document: $e');
      return null;
    }
  }

  /// Upload passport photo with liveness verification
  /// Should be called after face verification is complete
  Future<KycDocument?> uploadVerifiedPassportPhoto({
    required String filePath,
    required bool livenessVerified,
  }) async {
    return await uploadDocument(
      filePath: filePath,
      documentType: KycDocumentType.passportPhoto,
      metadata: {
        'liveness_verified': livenessVerified,
        'verification_timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Upload driving license
  Future<KycDocument?> uploadDrivingLicense({
    required String filePath,
    String? licenseNumber,
  }) async {
    return await uploadDocument(
      filePath: filePath,
      documentType: KycDocumentType.drivingLicense,
      metadata: licenseNumber != null ? {'license_number': licenseNumber} : null,
    );
  }

  /// Upload national ID
  Future<KycDocument?> uploadNationalId({
    required String filePath,
    String? idNumber,
  }) async {
    return await uploadDocument(
      filePath: filePath,
      documentType: KycDocumentType.nationalId,
      metadata: idNumber != null ? {'id_number': idNumber} : null,
    );
  }

  /// Upload bike photos (front, side, rear)
  Future<List<KycDocument>> uploadBikePhotos({
    required String frontPhotoPath,
    required String sidePhotoPath,
    required String rearPhotoPath,
    String? plateNumber,
  }) async {
    final results = <KycDocument>[];

    final metadata = plateNumber != null ? {'plate_number': plateNumber} : null;

    // Upload front
    final front = await uploadDocument(
      filePath: frontPhotoPath,
      documentType: KycDocumentType.bikePhotoFront,
      metadata: metadata,
    );
    if (front != null) results.add(front);

    // Upload side
    final side = await uploadDocument(
      filePath: sidePhotoPath,
      documentType: KycDocumentType.bikePhotoSide,
      metadata: metadata,
    );
    if (side != null) results.add(side);

    // Upload rear
    final rear = await uploadDocument(
      filePath: rearPhotoPath,
      documentType: KycDocumentType.bikePhotoRear,
      metadata: metadata,
    );
    if (rear != null) results.add(rear);

    return results;
  }

  /// Upload insurance document
  Future<KycDocument?> uploadInsuranceCard({
    required String filePath,
    String? policyNumber,
    String? insuranceCompany,
  }) async {
    return await uploadDocument(
      filePath: filePath,
      documentType: KycDocumentType.insuranceCard,
      metadata: {
        if (policyNumber != null) 'policy_number': policyNumber,
        if (insuranceCompany != null) 'insurance_company': insuranceCompany,
      },
    );
  }

  /// Upload logbook
  Future<KycDocument?> uploadLogbook({
    required String filePath,
  }) async {
    return await uploadDocument(
      filePath: filePath,
      documentType: KycDocumentType.logbook,
    );
  }

  /// Upload medical insurance card
  Future<KycDocument?> uploadMedicalInsurance({
    required String filePath,
    String? policyNumber,
    String? provider,
  }) async {
    return await uploadDocument(
      filePath: filePath,
      documentType: KycDocumentType.medicalInsurance,
      metadata: {
        if (policyNumber != null) 'policy_number': policyNumber,
        if (provider != null) 'provider': provider,
      },
    );
  }

  /// Batch upload multiple documents
  Future<List<KycDocument>> uploadMultipleDocuments(
    List<Map<String, dynamic>> documents,
  ) async {
    final results = <KycDocument>[];

    for (final doc in documents) {
      final filePath = doc['file_path'] as String?;
      final typeCode = doc['type'] as String?;

      if (filePath != null && typeCode != null) {
        final documentType = KycDocumentType.fromCode(typeCode);
        final result = await uploadDocument(
          filePath: filePath,
          documentType: documentType,
          metadata: doc['metadata'] as Map<String, dynamic>?,
        );

        if (result != null) {
          results.add(result);
        }
      }
    }

    return results;
  }

  /// Validate that all required KYC documents are present
  bool validateKycDocuments(MemberKycData kycData) {
    final requiredDocs = [
      kycData.passportPhoto,
      kycData.nationalId,
      kycData.drivingLicense,
      kycData.bikePhotoFront,
      kycData.bikePhotoSide,
      kycData.bikePhotoRear,
    ];

    return requiredDocs.every((doc) => doc != null && doc.id != null);
  }

  /// Get document status summary
  Map<String, dynamic> getDocumentStatus(MemberKycData kycData) {
    return {
      'has_passport_photo': kycData.passportPhoto != null,
      'has_national_id': kycData.nationalId != null,
      'has_driving_license': kycData.drivingLicense != null,
      'has_bike_photos': kycData.areBikePhotosComplete,
      'has_insurance': kycData.insuranceCard != null,
      'has_logbook': kycData.logbook != null,
      'has_medical_insurance': kycData.medicalInsurance != null,
      'is_verified': kycData.isPassportPhotoVerified,
      'is_complete': kycData.hasRequiredDocuments,
    };
  }
}
