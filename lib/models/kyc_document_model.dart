/// KYC Document Models
/// Handles all document types required for member verification

enum KycDocumentType {
  passportPhoto('passport', 'Passport Photo'),
  nationalIdFront('national_id_front', 'National ID - Front'),
  nationalIdBack('national_id_back', 'National ID - Back'),
  nationalId('national_id', 'National ID'), // Legacy support
  drivingLicenseFront('dl_front', 'Driving License - Front'),
  drivingLicenseBack('dl_back', 'Driving License - Back'),
  drivingLicense('dl', 'Driving License'), // Legacy support
  bikePhotoFront('bike_front', 'Bike Photo - Front'),
  bikePhotoSide('bike_side', 'Bike Photo - Side'),
  bikePhotoRear('bike_rear', 'Bike Photo - Rear'),
  insuranceCard('insurance_card', 'Insurance Card'),
  logbook('logbook', 'Logbook'),
  medicalInsurance('medical_insurance', 'Medical Insurance Card');

  final String code;
  final String displayName;

  const KycDocumentType(this.code, this.displayName);

  static KycDocumentType fromCode(String code) {
    return KycDocumentType.values.firstWhere(
      (type) => type.code == code,
      orElse: () => KycDocumentType.nationalId,
    );
  }
}

/// Model for uploaded document
class KycDocument {
  final int? id;
  final KycDocumentType type;
  final String? filePath;
  final String? url;
  final String? filename;
  final DateTime? uploadedAt;
  final bool isVerified;
  final String? extractedData; // For OCR data like plate numbers

  KycDocument({
    this.id,
    required this.type,
    this.filePath,
    this.url,
    this.filename,
    this.uploadedAt,
    this.isVerified = false,
    this.extractedData,
  });

  factory KycDocument.fromJson(Map<String, dynamic> json) {
    return KycDocument(
      id: json['id'] ?? json['file_id'],
      type: KycDocumentType.fromCode(json['doc_type'] ?? json['type'] ?? ''),
      filePath: json['file_path'],
      url: json['url'] ?? json['file_url'],
      filename: json['filename'] ?? json['originalname'],
      uploadedAt: json['uploaded_at'] != null
          ? DateTime.tryParse(json['uploaded_at'])
          : null,
      isVerified: json['is_verified'] ?? false,
      extractedData: json['extracted_data'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'doc_type': type.code,
        'file_path': filePath,
        'url': url,
        'filename': filename,
        'uploaded_at': uploadedAt?.toIso8601String(),
        'is_verified': isVerified,
        'extracted_data': extractedData,
      };

  KycDocument copyWith({
    int? id,
    KycDocumentType? type,
    String? filePath,
    String? url,
    String? filename,
    DateTime? uploadedAt,
    bool? isVerified,
    String? extractedData,
  }) {
    return KycDocument(
      id: id ?? this.id,
      type: type ?? this.type,
      filePath: filePath ?? this.filePath,
      url: url ?? this.url,
      filename: filename ?? this.filename,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      isVerified: isVerified ?? this.isVerified,
      extractedData: extractedData ?? this.extractedData,
    );
  }
}

/// Complete KYC data for a member
class MemberKycData {
  // Personal Documents
  final KycDocument? passportPhoto;
  final KycDocument? nationalIdFront;
  final KycDocument? nationalIdBack;
  final KycDocument? nationalId; // Legacy support
  final KycDocument? drivingLicenseFront;
  final KycDocument? drivingLicenseBack;
  final KycDocument? drivingLicense; // Legacy support

  // Bike Documents
  final KycDocument? bikePhotoFront;
  final KycDocument? bikePhotoSide;
  final KycDocument? bikePhotoRear;
  final KycDocument? insuranceCard;
  final KycDocument? logbook;

  // Medical Documents
  final KycDocument? medicalInsurance;

  // Verification Status
  final bool isPassportPhotoVerified;
  final bool areBikePhotosComplete;
  final bool isFullyVerified;

  MemberKycData({
    this.passportPhoto,
    this.nationalIdFront,
    this.nationalIdBack,
    this.nationalId, // Legacy support
    this.drivingLicenseFront,
    this.drivingLicenseBack,
    this.drivingLicense, // Legacy support
    this.bikePhotoFront,
    this.bikePhotoSide,
    this.bikePhotoRear,
    this.insuranceCard,
    this.logbook,
    this.medicalInsurance,
    this.isPassportPhotoVerified = false,
    this.areBikePhotosComplete = false,
    this.isFullyVerified = false,
  });

  /// Check if all required documents are uploaded
  bool get hasRequiredDocuments {
    final hasNationalId = (nationalIdFront != null && nationalIdBack != null) || nationalId != null;
    final hasDrivingLicense = (drivingLicenseFront != null && drivingLicenseBack != null) || drivingLicense != null;
    
    return passportPhoto != null &&
        hasNationalId &&
        hasDrivingLicense &&
        bikePhotoFront != null &&
        bikePhotoSide != null &&
        bikePhotoRear != null;
  }

  /// Get all document IDs for registration payload
  Map<String, int?> get documentIds {
    return {
      'passport_photo_id': passportPhoto?.id,
      'national_id_front_id': nationalIdFront?.id,
      'national_id_back_id': nationalIdBack?.id,
      'national_id_id': nationalId?.id, // Legacy support
      'driving_license_front_id': drivingLicenseFront?.id,
      'driving_license_back_id': drivingLicenseBack?.id,
      'driving_license_id': drivingLicense?.id, // Legacy support
      'bike_photo_front_id': bikePhotoFront?.id,
      'bike_photo_side_id': bikePhotoSide?.id,
      'bike_photo_rear_id': bikePhotoRear?.id,
      'insurance_card_id': insuranceCard?.id,
      'logbook_id': logbook?.id,
      'medical_insurance_id': medicalInsurance?.id,
    };
  }

  MemberKycData copyWith({
    KycDocument? passportPhoto,
    KycDocument? nationalIdFront,
    KycDocument? nationalIdBack,
    KycDocument? nationalId,
    KycDocument? drivingLicenseFront,
    KycDocument? drivingLicenseBack,
    KycDocument? drivingLicense,
    KycDocument? bikePhotoFront,
    KycDocument? bikePhotoSide,
    KycDocument? bikePhotoRear,
    KycDocument? insuranceCard,
    KycDocument? logbook,
    KycDocument? medicalInsurance,
    bool? isPassportPhotoVerified,
    bool? areBikePhotosComplete,
    bool? isFullyVerified,
  }) {
    return MemberKycData(
      passportPhoto: passportPhoto ?? this.passportPhoto,
      nationalIdFront: nationalIdFront ?? this.nationalIdFront,
      nationalIdBack: nationalIdBack ?? this.nationalIdBack,
      nationalId: nationalId ?? this.nationalId,
      drivingLicenseFront: drivingLicenseFront ?? this.drivingLicenseFront,
      drivingLicenseBack: drivingLicenseBack ?? this.drivingLicenseBack,
      drivingLicense: drivingLicense ?? this.drivingLicense,
      bikePhotoFront: bikePhotoFront ?? this.bikePhotoFront,
      bikePhotoSide: bikePhotoSide ?? this.bikePhotoSide,
      bikePhotoRear: bikePhotoRear ?? this.bikePhotoRear,
      insuranceCard: insuranceCard ?? this.insuranceCard,
      logbook: logbook ?? this.logbook,
      medicalInsurance: medicalInsurance ?? this.medicalInsurance,
      isPassportPhotoVerified:
          isPassportPhotoVerified ?? this.isPassportPhotoVerified,
      areBikePhotosComplete:
          areBikePhotosComplete ?? this.areBikePhotosComplete,
      isFullyVerified: isFullyVerified ?? this.isFullyVerified,
    );
  }
}
