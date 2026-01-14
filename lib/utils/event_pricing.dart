import 'package:pbak/models/event_model.dart';
import 'package:pbak/models/event_product_model.dart';

class EventPricing {
  /// Calculates the price a user should pay for an event registration fee.
  ///
  /// If [isMember] and [event.memberFee] is provided, member fee is used.
  /// Otherwise [event.fee] is used.
  static double eventRegistrationFee(
    EventModel event, {
    required bool isMember,
  }) {
    final memberFee = event.memberFee;
    if (isMember && memberFee != null) return memberFee;
    return event.fee ?? 0;
  }

  /// Calculates the price to pay for an event product.
  ///
  /// Rules:
  /// - If [isMember] => use `member_price`.
  /// - Else (non-member) =>
  ///   - if event.joinedCount < product.basePriceFirst => use `base_price`
  ///   - else => use `later_price`
  static double productPrice(
    EventModel event,
    EventProductModel product, {
    required bool isMember,
  }) {
    if (isMember) return product.memberPrice;

    final threshold = product.basePriceFirst ?? 0;
    if (event.joinedCount < threshold) {
      return product.basePrice;
    }
    return product.laterPrice;
  }
}
