/// Model representing an insurance provider
class InsuranceProviderModel {
  final int providerId;
  final int providerTypeId;
  final String providerName;
  final String? contactPerson;
  final String? phone;
  final String? email;
  final String? address;
  final String? city;
  final String? stateProvince;
  final String? postalCode;
  final double? latitude;
  final double? longitude;
  final String? operatingHours;
  final int? serviceRadiusKm;
  final double? rating;
  final int? totalReviews;
  final bool isVerified;
  final DateTime? verificationDate;
  final String? website;
  final String? logoUrl;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  InsuranceProviderModel({
    required this.providerId,
    required this.providerTypeId,
    required this.providerName,
    this.contactPerson,
    this.phone,
    this.email,
    this.address,
    this.city,
    this.stateProvince,
    this.postalCode,
    this.latitude,
    this.longitude,
    this.operatingHours,
    this.serviceRadiusKm,
    this.rating,
    this.totalReviews,
    this.isVerified = false,
    this.verificationDate,
    this.website,
    this.logoUrl,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory InsuranceProviderModel.fromJson(Map<String, dynamic> json) {
    return InsuranceProviderModel(
      providerId: _parseInt(json['provider_id']) ?? 0,
      providerTypeId: _parseInt(json['provider_type_id']) ?? 0,
      providerName: (json['provider_name'] ?? '').toString(),
      contactPerson: json['contact_person']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      address: json['address']?.toString(),
      city: json['city']?.toString(),
      stateProvince: json['state_province']?.toString(),
      postalCode: json['postal_code']?.toString(),
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      operatingHours: json['operating_hours']?.toString(),
      serviceRadiusKm: _parseInt(json['service_radius_km']),
      rating: _parseDouble(json['rating']),
      totalReviews: _parseInt(json['total_reviews']),
      isVerified: json['is_verified'] == 1 || json['is_verified'] == true,
      verificationDate: _parseDateTime(json['verification_date']),
      website: json['website']?.toString(),
      logoUrl: json['logo_url']?.toString(),
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'provider_id': providerId,
      'provider_type_id': providerTypeId,
      'provider_name': providerName,
      'contact_person': contactPerson,
      'phone': phone,
      'email': email,
      'address': address,
      'city': city,
      'state_province': stateProvince,
      'postal_code': postalCode,
      'latitude': latitude,
      'longitude': longitude,
      'operating_hours': operatingHours,
      'service_radius_km': serviceRadiusKm,
      'rating': rating,
      'total_reviews': totalReviews,
      'is_verified': isVerified ? 1 : 0,
      'verification_date': verificationDate?.toIso8601String(),
      'website': website,
      'logo_url': logoUrl,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Get full address string
  String get fullAddress {
    final parts = [address, city, stateProvince, postalCode]
        .where((p) => p != null && p.isNotEmpty)
        .toList();
    return parts.join(', ');
  }

  /// Get rating as stars text
  String get ratingText {
    if (rating == null) return 'No rating';
    return '${rating!.toStringAsFixed(1)} ★';
  }

  /// Check if provider has contact info
  bool get hasContactInfo => phone != null || email != null;

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }
}
