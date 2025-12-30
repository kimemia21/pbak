import 'dart:convert';

/// Package Model - represents both the package catalog and member packages
class PackageModel {
  // Member Package fields
  final int? memberPackageId;
  final int? memberId;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool? autoRenew;
  final String? status;
  final String? paymentStatus;
  final DateTime? cancellationDate;
  final String? cancellationReason;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? createdBy;
  final int? updatedBy;

  // Package Catalog fields
  final int? packageId;
  final String? packageName;
  final String? packageType;
  final String? description;
  final double? price;
  final String? currency;
  final int? durationDays;
  final bool? isRenewable;
  final bool? autoRenewDefault;
  final int? maxBikes;
  final int? maxMembers;
  final Map<String, dynamic>? features;
  final bool? isActive;

  PackageModel({
    this.memberPackageId,
    this.memberId,
    this.startDate,
    this.endDate,
    this.autoRenew,
    this.status,
    this.paymentStatus,
    this.cancellationDate,
    this.cancellationReason,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.packageId,
    this.packageName,
    this.packageType,
    this.description,
    this.price,
    this.currency,
    this.durationDays,
    this.isRenewable,
    this.autoRenewDefault,
    this.maxBikes,
    this.maxMembers,
    this.features,
    this.isActive,
  });

  factory PackageModel.fromJson(Map<String, dynamic> json) {
    // Parse features JSON if it's a string
    Map<String, dynamic>? features;
    if (json['features'] != null) {
      if (json['features'] is String) {
        try {
          features = jsonDecode(json['features']) as Map<String, dynamic>;
        } catch (e) {
          features = {};
        }
      } else if (json['features'] is Map) {
        features = json['features'] as Map<String, dynamic>;
      }
    }

    return PackageModel(
      memberPackageId: json['member_package_id'] as int?,
      memberId: json['member_id'] as int?,
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : null,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'])
          : null,
      autoRenew: json['auto_renew'] == 1 || json['auto_renew'] == true,
      status: json['status'] as String?,
      paymentStatus: json['payment_status'] as String?,
      cancellationDate: json['cancellation_date'] != null
          ? DateTime.parse(json['cancellation_date'])
          : null,
      cancellationReason: json['cancellation_reason'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      createdBy: json['created_by'] as int?,
      updatedBy: json['updated_by'] as int?,
      packageId: json['package_id'] as int?,
      packageName: json['package_name'] as String?,
      packageType: json['package_type'] as String?,
      description: json['description'] as String?,
      price: json['price'] != null
          ? double.tryParse(json['price'].toString())
          : null,
      currency: json['currency'] as String?,
      durationDays: json['duration_days'] as int?,
      isRenewable: json['is_renewable'] == 1 || json['is_renewable'] == true,
      autoRenewDefault:
          json['auto_renew_default'] == 1 || json['auto_renew_default'] == true,
      maxBikes: json['max_bikes'] as int?,
      maxMembers: json['max_members'] as int?,
      features: features,
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'member_package_id': memberPackageId,
      'member_id': memberId,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'auto_renew': autoRenew,
      'status': status,
      'payment_status': paymentStatus,
      'cancellation_date': cancellationDate?.toIso8601String(),
      'cancellation_reason': cancellationReason,
      'notes': notes,
      'package_id': packageId,
      'package_name': packageName,
      'package_type': packageType,
      'description': description,
      'price': price,
      'currency': currency,
      'duration_days': durationDays,
      'is_renewable': isRenewable,
      'auto_renew_default': autoRenewDefault,
      'max_bikes': maxBikes,
      'max_members': maxMembers,
      'features': features,
      'is_active': isActive,
    };
  }

  String get durationText {
    if (durationDays == null) return 'N/A';
    if (durationDays! < 30) {
      return '$durationDays days';
    } else if (durationDays! < 365) {
      final months = (durationDays! / 30).round();
      return '$months ${months == 1 ? 'month' : 'months'}';
    } else {
      final years = (durationDays! / 365).round();
      return '$years ${years == 1 ? 'year' : 'years'}';
    }
  }

  String get formattedPrice {
    if (price == null) return 'N/A';
    return '${currency ?? 'KES'} ${price!.toStringAsFixed(2)}';
  }

  List<String> get benefitsList {
    if (features == null || features!.isEmpty) {
      return ['Standard membership benefits'];
    }

    List<String> benefits = [];
    features!.forEach((key, value) {
      if (value != null && value != false) {
        String formattedKey = key.replaceAll('_', ' ').toUpperCase();
        benefits.add('$formattedKey: ${value.toString()}');
      }
    });

    return benefits.isEmpty ? ['Standard membership benefits'] : benefits;
  }

  bool get isExpired {
    if (endDate == null) return false;
    return DateTime.now().isAfter(endDate!);
  }

  bool get isExpiringSoon {
    if (endDate == null) return false;
    final daysUntilExpiry = endDate!.difference(DateTime.now()).inDays;
    return daysUntilExpiry > 0 && daysUntilExpiry <= 30;
  }

  int get daysRemaining {
    if (endDate == null) return 0;
    final days = endDate!.difference(DateTime.now()).inDays;
    return days > 0 ? days : 0;
  }
}

class AddOn {
  final String id;
  final String name;
  final double price;
  final String description;

  AddOn({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
  });

  factory AddOn.fromJson(Map<String, dynamic> json) {
    return AddOn(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'price': price, 'description': description};
  }
}
