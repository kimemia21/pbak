class PaymentModel {
  final int orderId;
  final String paymentRef;
  final String trxId;
  final String ref;
  final String paymentStatus;
  final double paymentTotal;
  final String paymentMethod;
  final String? paymentStatusDesc;
  
  // Package info (if payment was for a package)
  final int? packageId;
  final String? packageName;
  final String? packageDesc;
  final double? packagePrice;
  final int? durationDays;
  final bool? isRenewable;
  
  // Event info (if payment was for an event)
  final String? eventName;
  final String? eventType;
  final String? eventDescription;
  final DateTime? eventDate;
  final int? joinedCount;
  final String? eventBannerUrl;
  final double? registrationFee;
  final DateTime? registrationDeadline;
  final String? whatsappLink;

  PaymentModel({
    required this.orderId,
    required this.paymentRef,
    required this.trxId,
    required this.ref,
    required this.paymentStatus,
    required this.paymentTotal,
    required this.paymentMethod,
    this.paymentStatusDesc,
    this.packageId,
    this.packageName,
    this.packageDesc,
    this.packagePrice,
    this.durationDays,
    this.isRenewable,
    this.eventName,
    this.eventType,
    this.eventDescription,
    this.eventDate,
    this.joinedCount,
    this.eventBannerUrl,
    this.registrationFee,
    this.registrationDeadline,
    this.whatsappLink,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      orderId: _parseInt(json['order_id']) ?? 0,
      paymentRef: (json['payment_ref'] ?? '').toString(),
      trxId: (json['trx_id'] ?? '').toString(),
      ref: (json['ref'] ?? '').toString(),
      paymentStatus: (json['payment_status'] ?? '').toString(),
      paymentTotal: _parseDouble(json['payment_total']) ?? 0.0,
      paymentMethod: (json['payment_method'] ?? '').toString(),
      paymentStatusDesc: json['payment_status_desc']?.toString(),
      packageId: _parseInt(json['package_id']),
      packageName: json['package_name']?.toString(),
      packageDesc: json['package_desc']?.toString(),
      packagePrice: _parseDouble(json['package_price']),
      durationDays: _parseInt(json['duration_days']),
      isRenewable: json['is_renewable'] == 1 || json['is_renewable'] == true,
      eventName: json['event_name']?.toString(),
      eventType: json['event_type']?.toString(),
      eventDescription: json['event_description']?.toString(),
      eventDate: _parseDateTime(json['event_date']),
      joinedCount: _parseInt(json['joined_count']),
      eventBannerUrl: json['event_banner_url']?.toString(),
      registrationFee: _parseDouble(json['registration_fee']),
      registrationDeadline: _parseDateTime(json['registration_deadline']),
      whatsappLink: json['whatsapp_link']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'payment_ref': paymentRef,
      'trx_id': trxId,
      'ref': ref,
      'payment_status': paymentStatus,
      'payment_total': paymentTotal,
      'payment_method': paymentMethod,
      'payment_status_desc': paymentStatusDesc,
      'package_id': packageId,
      'package_name': packageName,
      'package_desc': packageDesc,
      'package_price': packagePrice,
      'duration_days': durationDays,
      'is_renewable': isRenewable,
      'event_name': eventName,
      'event_type': eventType,
      'event_description': eventDescription,
      'event_date': eventDate?.toIso8601String(),
      'joined_count': joinedCount,
      'event_banner_url': eventBannerUrl,
      'registration_fee': registrationFee,
      'registration_deadline': registrationDeadline?.toIso8601String(),
      'whatsapp_link': whatsappLink,
    };
  }

  // Helper getters
  bool get isSuccessful => paymentStatus.toUpperCase() == 'SUCCESS';
  bool get isPending => paymentStatus.toUpperCase() == 'PENDING';
  bool get isFailed => paymentStatus.toUpperCase() == 'FAILED';
  
  /// Check if this payment is for a package
  bool get isPackagePayment => packageId != null && packageId! > 0 && packageName != null && packageName!.isNotEmpty;
  
  /// Check if this payment is for an event
  bool get isEventPayment => eventName != null && eventName!.isNotEmpty;
  
  /// Get a display-friendly purpose string
  String get purpose {
    if (isPackagePayment) {
      return packageName ?? 'Package Payment';
    } else if (isEventPayment) {
      return eventName ?? 'Event Registration';
    }
    return 'PBAK Payment';
  }
  
  /// Get a short description
  String get description {
    if (isPackagePayment && packageDesc != null && packageDesc!.isNotEmpty) {
      return packageDesc!;
    } else if (isEventPayment && eventDescription != null && eventDescription!.isNotEmpty) {
      return eventDescription!;
    }
    return paymentMethod.isNotEmpty ? 'Payment via $paymentMethod' : 'PBAK Payment';
  }
  
  /// Safe getter for payment reference (never null)
  String get safePaymentRef => paymentRef.isNotEmpty ? paymentRef : 'N/A';
  
  /// Safe getter for transaction ID (never null)
  String get safeTrxId => trxId.isNotEmpty ? trxId : 'N/A';
  
  /// Safe getter for reference (never null)
  String get safeRef => ref.isNotEmpty ? ref : 'N/A';
  
  /// Safe getter for payment method (never null)
  String get safePaymentMethod => paymentMethod.isNotEmpty ? paymentMethod : 'Unknown';
  
  /// Safe getter for payment status (never null)
  String get safePaymentStatus => paymentStatus.isNotEmpty ? paymentStatus : 'Unknown';

  // Parse helpers
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
