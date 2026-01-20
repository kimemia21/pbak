class EventProductModel {
  final int? productId;
  final int? eventId;
  final String name;

  final String? description;
  final String? location;
  final String? disclaimer;
  final DateTime? registrationDeadline;

  /// Pricing fields come as strings from API.
  final double basePrice;
  final int? basePriceFirst;
  final double laterPrice;
  final double memberPrice;

  /// Dynamic amount from API (member-specific pricing based on ID number).
  /// This is the actual price the user should pay, returned by the API.
  final double? amount;

  /// Maximum quantity a user can purchase for this product.
  /// Defaults to 1 if not provided by the API.
  final int purchaseCount;

  /// Payment info (may be null)
  final String? paymentRef;
  final String? paymentMethod;
  final DateTime? paymentDate;

  const EventProductModel({
    this.productId,
    this.eventId,
    required this.name,
    required this.basePrice,
    this.basePriceFirst,
    required this.laterPrice,
    required this.memberPrice,
    this.amount,
    this.purchaseCount = 1,
    this.description,
    this.location,
    this.disclaimer,
    this.registrationDeadline,
    this.paymentRef,
    this.paymentMethod,
    this.paymentDate,
  });

  static double _parseDouble(dynamic v, {double fallback = 0}) {
    if (v == null) return fallback;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? fallback;
  }

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  factory EventProductModel.fromJson(Map<String, dynamic> json) {
    return EventProductModel(
      productId: _parseInt(json['product_id']),
      eventId: _parseInt(json['event_id']),
      name: (json['product_name'] ?? '').toString(),
      basePrice: _parseDouble(json['base_price']),
      basePriceFirst: _parseInt(json['base_price_first']),
      laterPrice: _parseDouble(json['later_price']),
      memberPrice: _parseDouble(json['member_price']),
      // Parse dynamic amount from API (member-specific pricing)
      amount: json['amount'] != null ? _parseDouble(json['amount']) : null,
      // Maximum quantity user can purchase (defaults to 1)
      purchaseCount: _parseInt(json['purchase_count']) ?? 1,
      description: json['description']?.toString(),
      location: json['product_location']?.toString(),
      disclaimer: json['disclaimer']?.toString(),
      registrationDeadline: _parseDate(json['registration_deadline']),
      paymentRef: json['payment_ref']?.toString(),
      paymentMethod: json['payment_method']?.toString(),
      paymentDate: _parseDate(json['payment_date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'event_id': eventId,
      'product_name': name,
      'base_price': basePrice,
      'base_price_first': basePriceFirst,
      'later_price': laterPrice,
      'member_price': memberPrice,
      'amount': amount,
      'purchase_count': purchaseCount,
      'description': description,
      'product_location': location,
      'disclaimer': disclaimer,
      'registration_deadline': registrationDeadline?.toIso8601String(),
      'payment_ref': paymentRef,
      'payment_method': paymentMethod,
      'payment_date': paymentDate?.toIso8601String(),
    };
  }
}
