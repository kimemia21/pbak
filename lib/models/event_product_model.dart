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

  /// Whether this product is only available to members.
  /// Maps to `prod_members_only` from API (0 = false, 1 = true).
  /// Stored as nullable to handle legacy cached data, use getter for safe access.
  final bool? _isMembersOnly;

  /// Safe getter for isMembersOnly that handles null from legacy cached data.
  bool get isMembersOnly => _isMembersOnly ?? false;

  /// Maximum count available for purchase (from `maxcnt` in API).
  /// This represents the maximum number of slots/items available.
  final int? maxCount;

  /// Number of slots/items already taken (from `taken` in API).
  /// Used to determine availability. Stored as nullable for legacy data safety.
  final int? _taken;

  /// Safe getter for taken that handles null from legacy cached data.
  int get taken => _taken ?? 0;

  /// Maximum quantity per member (from `max_per_member` in API).
  final int? maxPerMember;

  /// Joined count for this product (from `joined_count` or `product_joined_count` in API).
  final int? joinedCount;

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
    bool? isMembersOnly,
    this.maxCount,
    int? taken,
    this.maxPerMember,
    this.joinedCount,
    this.description,
    this.location,
    this.disclaimer,
    this.registrationDeadline,
    this.paymentRef,
    this.paymentMethod,
    this.paymentDate,
  }) : _isMembersOnly = isMembersOnly,
       _taken = taken;

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

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    final s = value.toString().trim().toLowerCase();
    return s == '1' || s == 'true' || s == 'yes';
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
      // Members-only flag
      isMembersOnly: _parseBool(json['prod_members_only']),
      // Availability fields
      maxCount: _parseInt(json['maxcnt']),
      taken: _parseInt(json['taken']) ?? 0,
      maxPerMember: _parseInt(json['max_per_member']),
      joinedCount: _parseInt(
        json['joined_count'] ?? json['product_joined_count'],
      ),
      description: json['description']?.toString(),
      location: json['product_location']?.toString(),
      disclaimer: json['disclaimer']?.toString(),
      registrationDeadline: _parseDate(json['registration_deadline']),
      paymentRef: json['payment_ref']?.toString(),
      paymentMethod: json['payment_method']?.toString(),
      paymentDate: _parseDate(json['payment_date']),
    );
  }

  /// Check if this product is available for the user to purchase.
  /// Takes into account members-only restriction and availability.
  bool isAvailableForUser({required bool isMember}) {
    // Use null-safe access for isMembersOnly in case of legacy cached data
    final bool membersOnly = (isMembersOnly as bool?) ?? false;
    // If product is members-only and user is not a member, not available
    if (membersOnly && !isMember) {
      return false;
    }
    return true;
  }

  /// Check if product has available slots (not sold out).
  bool get hasAvailableSlots {
    if (maxCount == null) return true; // No limit set
    final int takenValue = (taken as int?) ?? 0;
    return takenValue < maxCount!;
  }

  /// Get remaining slots available.
  int? get remainingSlots {
    if (maxCount == null) return null;
    final int takenValue = (taken as int?) ?? 0;
    final remaining = maxCount! - takenValue;
    print('Remaining slots. ${name} : $remaining');
    return remaining > 0 ? remaining : 0;
  }

  Map<String, dynamic> toJson() {
    // Use null-safe access for isMembersOnly in case of legacy cached data
    final bool membersOnly = (isMembersOnly as bool?) ?? false;
    final int takenValue = (taken as int?) ?? 0;

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
      'prod_members_only': membersOnly ? 1 : 0,
      'maxcnt': maxCount,
      'taken': takenValue,
      'max_per_member': maxPerMember,
      'joined_count': joinedCount,
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
