import 'package:pbak/services/comms/api_endpoints.dart';
import 'package:pbak/services/comms/comms_service.dart';

/// M-Pesa Payment Response Models
class MpesaInitiateResponse {
  final bool success;
  final String? payId;
  final String message;
  final String? errorMessage;

  MpesaInitiateResponse({
    required this.success,
    this.payId,
    required this.message,
    this.errorMessage,
  });

  factory MpesaInitiateResponse.fromJson(Map<String, dynamic> json) {
    final rsp = json['rsp'] as bool? ?? false;
    return MpesaInitiateResponse(
      success: rsp,
      payId: json['payId'] as String?,
      message: json['message'] as String? ?? '',
      errorMessage: rsp
          ? null
          : (json['message'] as String? ?? 'Payment initiation failed'),
    );
  }

  factory MpesaInitiateResponse.error(String message) {
    return MpesaInitiateResponse(
      success: false,
      message: message,
      errorMessage: message,
    );
  }
}

class MpesaStatusResponse {
  final bool rsp;
  final bool wait;
  final bool success;
  final String transCode;
  final String status; // e.g., 'pending', 'completed', 'failed'
  final String message;
  final Map<String, dynamic>? data;

  MpesaStatusResponse({
    required this.rsp,
    required this.wait,
    required this.success,
    this.transCode = '',
    required this.status,
    required this.message,
    this.data,
  });

  factory MpesaStatusResponse.fromJson(Map<String, dynamic> json) {
    print(json);

    final rsp = json['rsp'] as bool? ?? false;
    final wait = json['wait'] as bool? ?? true;
    final success = json['success'] as bool? ?? false;
    final transCode = json['trans_code'] as String? ?? '';

    // Determine status based on wait and success flags
    String status;
    if (wait) {
      // Still waiting for user to complete payment
      status = 'pending';
    } else {
      // Wait is false - we have a definitive result
      status = success ? 'completed' : 'failed';
    }

    return MpesaStatusResponse(
      rsp: rsp,
      wait: wait,
      success: success,
      transCode: transCode,
      status: status.toLowerCase(),
      message: json['message'] as String? ?? '',
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  factory MpesaStatusResponse.error(String message) {
    return MpesaStatusResponse(
      rsp: false,
      wait: false,
      success: false,
      status: 'error',
      message: message,
    );
  }

  /// Payment is completed when wait=false and success=true
  bool get isCompleted => rsp && !wait && success;

  /// Payment is pending when wait=true (still waiting for user action)
  bool get isPending => wait;

  /// Payment failed when wait=false and success=false
  bool get isFailed => !rsp || wait == false;
}

/// M-Pesa Payment Service
/// Handles M-Pesa STK push payments
class MpesaService {
  final CommsService _comms = CommsService.instance;

  /// Initiate an M-Pesa STK push payment
  ///
  /// [mpesaNo] - The M-Pesa phone number (format: 254XXXXXXXXX)
  /// [reference] - Reference ID (typically user's ID number)
  /// [amount] - Amount to pay
  /// [description] - Payment description
  Future<MpesaInitiateResponse> initiatePayment({
    required String mpesaNo,
    required String reference,
    required double amount,
    required String description,
    int? eventId,
    int? packageId,
    String? memberId,
    List<int>? eventProductIds,
    /// New products array with quantity and rate: [{product_id, quantity, rate}, ...]
    List<Map<String, dynamic>>? products,
    bool? isVegetarian,
    String? specialFoodRequirements,
    String? email,
    /// Discounted registration: 1 if user clicked 50% off button, 0 otherwise
    int? discounted,
  }) async {
    try {
      final data = <String, dynamic>{
        'mpesaNo': mpesaNo,
        'reference': reference,
        'amount': amount,
        'description': description,
      };

      if (eventId != null) data['event_id'] = eventId;
      if (packageId != null) data['package_id'] = packageId ?? 0;
      if (memberId != null && memberId.trim().isNotEmpty) {
        data['member_id'] = memberId.trim();
      }
      if (eventProductIds != null && eventProductIds.isNotEmpty) {
        data['event_product_ids'] = eventProductIds.join(',');
      }
      // New products array with quantity and rate
      if (products != null && products.isNotEmpty) {
        data['products'] = products;
      }
      // Food preferences for event registration
      if (isVegetarian != null) {
        data['is_vegetarian'] = isVegetarian;
      }
      if (specialFoodRequirements != null && specialFoodRequirements.trim().isNotEmpty) {
        data['special_food_requirements'] = specialFoodRequirements.trim();
      }
      // Email for event payments
      if (email != null && email.trim().isNotEmpty) {
        data['email'] = email.trim();
      }
      // Discounted registration flag (1 = 50% off, 0 = normal)
      if (discounted != null) {
        data['discounted'] = discounted;
      }

print('meshyy: $data');
      final response = await _comms.post(
        ApiEndpoints.initiateMpesaPayment,
        data: data,
      );

      if (response.success && response.rawData != null) {
        return MpesaInitiateResponse.fromJson(response.rawData!);
      } else {
        return MpesaInitiateResponse.error(
          response.message ?? 'Failed to initiate payment',
        );
      }
    } catch (e) {
      return MpesaInitiateResponse.error('Error: $e');
    }
  }

  /// Check the status of an M-Pesa payment
  ///
  /// [payId] - The payment ID returned from initiatePayment
  Future<MpesaStatusResponse> checkPaymentStatus(String payId) async {
    try {
      final response = await _comms.post(
        ApiEndpoints.mpesaPaymentStatus(payId),
      );

      if (response.success && response.rawData != null) {
        return MpesaStatusResponse.fromJson(response.rawData!);
      } else {
        return MpesaStatusResponse.error(
          response.message ?? 'Failed to check payment status',
        );
      }
    } catch (e) {
      return MpesaStatusResponse.error('Error: $e');
    }
  }

  /// Poll payment status until completed, failed, or timeout
  ///
  /// [payId] - The payment ID to check
  /// [onStatusUpdate] - Callback for status updates
  /// [maxAttempts] - Maximum polling attempts (default: 30)
  /// [intervalSeconds] - Seconds between polls (default: 3)
  Future<MpesaStatusResponse> pollPaymentStatus({
    required String payId,
    void Function(MpesaStatusResponse)? onStatusUpdate,
    int maxAttempts = 30,
    int intervalSeconds = 3,
  }) async {
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      final status = await checkPaymentStatus(payId);

      onStatusUpdate?.call(status);

      if (status.isCompleted || status.isFailed) {
        return status;
      }

      // Wait before next poll
      await Future.delayed(Duration(seconds: intervalSeconds));
    }

    // Timeout - return last known status as pending
    return MpesaStatusResponse(
      rsp: false,
      wait: false,
      success: false,
      status: 'timeout',
      message:
          'Payment verification timed out. Please check your M-Pesa messages.',
    );
  }
}
