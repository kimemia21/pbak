import 'package:pbak/models/payment_model.dart';
import 'package:pbak/services/comms/comms_service.dart';
import 'package:pbak/services/comms/api_endpoints.dart';

/// Payment Service
/// Handles all payment history related API calls
class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  final _comms = CommsService.instance;

  /// Get all payments for the current user
  /// GET /payments
  Future<List<PaymentModel>> getAllPayments() async {
    try {
      final response = await _comms.get(ApiEndpoints.allPayments);

      if (response.success && response.data != null) {
        dynamic data = response.data;

        // Access nested data object if it exists
        if (data is Map && data['data'] != null) {
          data = data['data'];
        }

        // If data is a list, map it to PaymentModel
        if (data is List) {
          return data
              .map((json) => PaymentModel.fromJson(json as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load payments: $e');
    }
  }

  /// Get a specific payment by order ID
  /// GET /payments/{order_id}
  Future<PaymentModel?> getPaymentByOrderId(int orderId) async {
    try {
      final response = await _comms.get(ApiEndpoints.paymentByOrderId(orderId));

      if (response.success && response.data != null) {
        dynamic data = response.data;

        // Access nested data object if it exists
        if (data is Map && data['data'] != null) {
          data = data['data'];
        }

        if (data is Map<String, dynamic>) {
          return PaymentModel.fromJson(data);
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to load payment details: $e');
    }
  }
}
