/// User's Bike Model - represents bikes owned by users
class BikeModel {
  final int? bikeId;
  final int? memberId;
  final int? modelId;
  final String? registrationNumber;
  final String? chassisNumber;
  final String? engineNumber;
  final String? color;
  final DateTime? purchaseDate;
  final DateTime? registrationDate;
  final DateTime? registrationExpiry;
  final String? bikePhotoUrl;
  final String? odometerReading;
  final DateTime? insuranceExpiry;
  final bool? isPrimary;
  final DateTime? yom;
  final int? photoFrontId;
  final int? photoSideId;
  final int? photoRearId;
  final int? insuranceLogbookId;
  final bool? hasInsurance;
  final int? experienceYears;
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Nested objects from API
  final BikeModelCatalog? bikeModel;
  final BikeMember? member;

  BikeModel({
    this.bikeId,
    this.memberId,
    this.modelId,
    this.registrationNumber,
    this.chassisNumber,
    this.engineNumber,
    this.color,
    this.purchaseDate,
    this.registrationDate,
    this.registrationExpiry,
    this.bikePhotoUrl,
    this.odometerReading,
    this.insuranceExpiry,
    this.isPrimary,
    this.yom,
    this.photoFrontId,
    this.photoSideId,
    this.photoRearId,
    this.insuranceLogbookId,
    this.hasInsurance,
    this.experienceYears,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.bikeModel,
    this.member,
  });

  factory BikeModel.fromJson(Map<String, dynamic> json) {
    return BikeModel(
      bikeId: json['bike_id'] as int?,
      memberId: json['member_id'] as int?,
      modelId: json['model_id'] as int?,
      registrationNumber: json['registration_number'] as String?,
      chassisNumber: json['chassis_number'] as String?,
      engineNumber: json['engine_number'] as String?,
      color: json['color'] as String?,
      purchaseDate: json['purchase_date'] != null
          ? DateTime.parse(json['purchase_date'])
          : null,
      registrationDate: json['registration_date'] != null
          ? DateTime.parse(json['registration_date'])
          : null,
      registrationExpiry: json['registration_expiry'] != null
          ? DateTime.parse(json['registration_expiry'])
          : null,
      bikePhotoUrl: json['bike_photo_url'] as String?,
      odometerReading: json['odometer_reading']?.toString(),
      insuranceExpiry: json['insurance_expiry'] != null
          ? DateTime.parse(json['insurance_expiry'])
          : null,
      isPrimary: json['is_primary'] == 1 || json['is_primary'] == true,
      yom: json['yom'] != null && json['yom'] != 'null'
          ? DateTime.parse(json['yom'])
          : null,
      photoFrontId: json['photo_front_id'] as int?,
      photoSideId: json['photo_side_id'] as int?,
      photoRearId: json['photo_rear_id'] as int?,
      insuranceLogbookId: json['insurance_logbook_id'] as int?,
      hasInsurance: json['has_insurance'] == 1 || json['has_insurance'] == true,
      experienceYears: json['experience_years'] as int?,
      status: json['status'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      bikeModel: json['model'] != null
          ? BikeModelCatalog.fromJson(json['model'] as Map<String, dynamic>)
          : null,
      member: json['member'] != null
          ? BikeMember.fromJson(json['member'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bike_id': bikeId,
      'member_id': memberId,
      'model_id': modelId,
      'registration_number': registrationNumber,
      'chassis_number': chassisNumber,
      'engine_number': engineNumber,
      'color': color,
      'purchase_date': purchaseDate?.toIso8601String(),
      'registration_date': registrationDate?.toIso8601String(),
      'registration_expiry': registrationExpiry?.toIso8601String(),
      'bike_photo_url': bikePhotoUrl,
      'odometer_reading': odometerReading,
      'insurance_expiry': insuranceExpiry?.toIso8601String(),
      'is_primary': isPrimary,
      'yom': yom?.toIso8601String(),
      'photo_front_id': photoFrontId,
      'photo_side_id': photoSideId,
      'photo_rear_id': photoRearId,
      'insurance_logbook_id': insuranceLogbookId,
      'has_insurance': hasInsurance,
      'experience_years': experienceYears,
      'status': status,
    };
  }

  // Helper getters for convenience
  String get displayName => bikeModel?.displayName ?? 'Bike';
  String get makeName => bikeModel?.makeName ?? 'Unknown';
  String get modelName => bikeModel?.modelName ?? 'Unknown';
}

/// Bike Model Catalog - represents available bike models in the system
class BikeModelCatalog {
  final int? modelId;
  final int? makeId;
  final int? typeId;
  final String? modelName;
  final int? modelYear;
  final String? engineCapacity;
  final String? category;
  final String? fuelType;
  final String? imageUrl;
  final bool? isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Nested objects
  final BikeMakeCatalog? make;
  final BikeTypeCatalog? type;

  BikeModelCatalog({
    this.modelId,
    this.makeId,
    this.typeId,
    this.modelName,
    this.modelYear,
    this.engineCapacity,
    this.category,
    this.fuelType,
    this.imageUrl,
    this.isActive,
    this.createdAt,
    this.updatedAt,
    this.make,
    this.type,
  });

  factory BikeModelCatalog.fromJson(Map<String, dynamic> json) {
    return BikeModelCatalog(
      modelId: json['model_id'] as int?,
      makeId: json['make_id'] as int?,
      typeId: json['type_id'] as int?,
      modelName: json['model_name'] as String?,
      modelYear: json['model_year'] as int?,
      engineCapacity: json['engine_capacity'] as String?,
      category: json['category'] as String?,
      fuelType: json['fuel_type'] as String?,
      imageUrl: json['image_url'] as String?,
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      make: json['make'] != null
          ? BikeMakeCatalog.fromJson(json['make'] as Map<String, dynamic>)
          : null,
      type: json['type'] != null
          ? BikeTypeCatalog.fromJson(json['type'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'model_id': modelId,
      'make_id': makeId,
      'type_id': typeId,
      'model_name': modelName,
      'model_year': modelYear,
      'engine_capacity': engineCapacity,
      'category': category,
      'fuel_type': fuelType,
      'image_url': imageUrl,
      'is_active': isActive,
    };
  }

  String get displayName => '$makeName $modelName ${engineCapacity ?? ''}';
  String get makeName => make?.makeName ?? 'Unknown';
}

/// Bike Make Catalog
class BikeMakeCatalog {
  final int? makeId;
  final String? makeName;
  final String? countryOfOrigin;
  final String? logoUrl;
  final String? website;
  final bool? isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BikeMakeCatalog({
    this.makeId,
    this.makeName,
    this.countryOfOrigin,
    this.logoUrl,
    this.website,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory BikeMakeCatalog.fromJson(Map<String, dynamic> json) {
    return BikeMakeCatalog(
      makeId: json['make_id'] as int?,
      makeName: json['make_name'] as String?,
      countryOfOrigin: json['country_of_origin'] as String?,
      logoUrl: json['logo_url'] as String?,
      website: json['website'] as String?,
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'make_id': makeId,
      'make_name': makeName,
      'country_of_origin': countryOfOrigin,
      'logo_url': logoUrl,
      'website': website,
      'is_active': isActive,
    };
  }
}

/// Bike Type Catalog
class BikeTypeCatalog {
  final int? typeId;
  final String? typeName;
  final String? description;
  final bool? isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BikeTypeCatalog({
    this.typeId,
    this.typeName,
    this.description,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory BikeTypeCatalog.fromJson(Map<String, dynamic> json) {
    return BikeTypeCatalog(
      typeId: json['type_id'] as int?,
      typeName: json['type_name'] as String?,
      description: json['description'] as String?,
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type_id': typeId,
      'type_name': typeName,
      'description': description,
      'is_active': isActive,
    };
  }
}

/// Bike Member - represents the owner of a bike
class BikeMember {
  final int? memberId;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;

  BikeMember({
    this.memberId,
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
  });

  factory BikeMember.fromJson(Map<String, dynamic> json) {
    return BikeMember(
      memberId: json['member_id'] as int?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'member_id': memberId,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
    };
  }

  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();
}
