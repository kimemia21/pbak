import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pbak/models/payment_model.dart';
import 'package:pbak/services/mock_api/mock_api_service.dart';
import 'package:pbak/providers/auth_provider.dart';

final myPaymentsProvider = FutureProvider<List<PaymentModel>>((ref) async {
  final authState = ref.watch(authProvider);
  return authState.when(
    data: (user) async {
      if (user != null) {
        final apiService = MockApiService();
        return await apiService.getMyPayments(user.id);
      }
      return [];
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

final paymentNotifierProvider = StateNotifierProvider<PaymentNotifier, AsyncValue<PaymentModel?>>((ref) {
  return PaymentNotifier(ref);
});

class PaymentNotifier extends StateNotifier<AsyncValue<PaymentModel?>> {
  final Ref _ref;
  final _apiService = MockApiService();

  PaymentNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<bool> initiatePayment(Map<String, dynamic> paymentData) async {
    state = const AsyncValue.loading();
    try {
      final authState = _ref.read(authProvider);
      final user = authState.value;
      if (user != null) {
        paymentData['userId'] = user.id;
        final payment = await _apiService.initiatePayment(paymentData);
        state = AsyncValue.data(payment);
        return true;
      }
      return false;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }
}
