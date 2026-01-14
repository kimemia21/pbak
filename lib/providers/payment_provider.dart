import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pbak/models/payment_model.dart';
import 'package:pbak/services/mock_api/mock_api_service.dart';
import 'package:pbak/services/mpesa_service.dart';
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

final paymentNotifierProvider =
    StateNotifierProvider<PaymentNotifier, AsyncValue<PaymentModel?>>((ref) {
      return PaymentNotifier(ref);
    });

/// M-Pesa Payment State
enum MpesaPaymentPhase {
  idle,
  initiating,
  waitingForUser, // User is entering PIN
  processing, // Payment is being processed
  completed,
  failed,
  timeout,
}

class MpesaPaymentState {
  final bool isLoading;
  final bool isPolling;
  final String? payId;
  final String? error;
  final MpesaStatusResponse? statusResponse;
  final MpesaInitiateResponse? initiateResponse;
  final MpesaPaymentPhase phase;
  final int pollAttempt;
  final int maxPollAttempts;
  final DateTime? initiatedAt;

  const MpesaPaymentState({
    this.isLoading = false,
    this.isPolling = false,
    this.payId,
    this.error,
    this.statusResponse,
    this.initiateResponse,
    this.phase = MpesaPaymentPhase.idle,
    this.pollAttempt = 0,
    this.maxPollAttempts = 10,
    this.initiatedAt,
  });

  MpesaPaymentState copyWith({
    bool? isLoading,
    bool? isPolling,
    String? payId,
    String? error,
    MpesaStatusResponse? statusResponse,
    MpesaInitiateResponse? initiateResponse,
    MpesaPaymentPhase? phase,
    int? pollAttempt,
    int? maxPollAttempts,
    DateTime? initiatedAt,
  }) {
    return MpesaPaymentState(
      isLoading: isLoading ?? this.isLoading,
      isPolling: isPolling ?? this.isPolling,
      payId: payId ?? this.payId,
      error: error,
      statusResponse: statusResponse ?? this.statusResponse,
      initiateResponse: initiateResponse ?? this.initiateResponse,
      phase: phase ?? this.phase,
      pollAttempt: pollAttempt ?? this.pollAttempt,
      maxPollAttempts: maxPollAttempts ?? this.maxPollAttempts,
      initiatedAt: initiatedAt ?? this.initiatedAt,
    );
  }

  bool get isInitiated => payId != null && initiateResponse?.success == true;
  bool get isCompleted =>
      phase == MpesaPaymentPhase.completed ||
      statusResponse?.isCompleted == true;
  bool get isFailed =>
      phase == MpesaPaymentPhase.failed ||
      (statusResponse?.isFailed == true &&
          phase != MpesaPaymentPhase.waitingForUser);
  bool get isPending =>
      phase == MpesaPaymentPhase.waitingForUser ||
      phase == MpesaPaymentPhase.processing ||
      statusResponse?.isPending == true;
  bool get isTimeout => phase == MpesaPaymentPhase.timeout;

  /// Progress percentage for UI (0.0 to 1.0)
  double get progress {
    if (maxPollAttempts == 0) return 0;
    return (pollAttempt / maxPollAttempts).clamp(0.0, 1.0);
  }

  /// Seconds elapsed since payment was initiated
  int get secondsElapsed {
    if (initiatedAt == null) return 0;
    return DateTime.now().difference(initiatedAt!).inSeconds;
  }
}

/// M-Pesa Payment Notifier
final mpesaPaymentProvider =
    StateNotifierProvider<MpesaPaymentNotifier, MpesaPaymentState>((ref) {
      return MpesaPaymentNotifier();
    });

class MpesaPaymentNotifier extends StateNotifier<MpesaPaymentState> {
  final MpesaService _mpesaService = MpesaService();
  bool _isCancelled = false;

  MpesaPaymentNotifier() : super(const MpesaPaymentState());

  /// Reset state for new payment
  void reset() {
    _isCancelled = false;
    state = const MpesaPaymentState();
  }

  /// Cancel ongoing polling
  void cancel() {
    _isCancelled = true;
  }

  /// Initiate M-Pesa STK push payment
  Future<bool> initiatePayment({
    required String mpesaNo,
    required String reference,
    required double amount,
    required String description,
    int? eventId,
    int? packageId,
    String? memberId,
    List<int>? eventProductIds,
  }) async {
    _isCancelled = false;
    state = state.copyWith(
      isLoading: true,
      error: null,
      phase: MpesaPaymentPhase.initiating,
    );

    print(
      "Initiating payment to M-Pesa No: $mpesaNo, Reference: $reference, Amount: $amount",
    );

    try {
      final response = await _mpesaService.initiatePayment(
        mpesaNo: mpesaNo,
        reference: reference,
        amount: amount,
        description: description,
        eventId: eventId,
        packageId: packageId,
        memberId: memberId,
        eventProductIds: eventProductIds,
      );

      if (response.success && response.payId != null) {
        state = state.copyWith(
          isLoading: false,
          payId: response.payId,
          initiateResponse: response,
          phase: MpesaPaymentPhase.waitingForUser,
          initiatedAt: DateTime.now(),
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.errorMessage ?? 'Failed to initiate payment',
          phase: MpesaPaymentPhase.failed,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error: $e',
        phase: MpesaPaymentPhase.failed,
      );
      return false;
    }
  }

  /// Check payment status once
  Future<MpesaStatusResponse?> checkStatus() async {
    if (state.payId == null) return null;

    try {
      final response = await _mpesaService.checkPaymentStatus(state.payId!);

      MpesaPaymentPhase newPhase = state.phase;
      if (response.isCompleted) {
        newPhase = MpesaPaymentPhase.completed;
      } else if (response.isFailed) {
        newPhase = MpesaPaymentPhase.failed;
      }

      state = state.copyWith(statusResponse: response, phase: newPhase);
      return response;
    } catch (e) {
      // Don't immediately fail on network errors during polling
      return null;
    }
  }

  /// Smart polling with user-friendly timing
  /// - Initial delay: 5 seconds (give user time to see STK push)
  /// - First 15 seconds: Poll every 3 seconds (user entering PIN)
  /// - Next 30 seconds: Poll every 5 seconds (processing)
  /// - After 45 seconds: Consider timeout but allow manual check
  Future<MpesaStatusResponse?> pollStatus({
    int initialDelaySeconds = 5,
    int totalTimeoutSeconds = 60,
    void Function(int secondsRemaining)? onTick,
  }) async {
    if (state.payId == null) return null;

    _isCancelled = false;

    state = state.copyWith(
      isPolling: true,
      phase: MpesaPaymentPhase.waitingForUser,
      pollAttempt: 0,
      maxPollAttempts: (totalTimeoutSeconds / 3).ceil(),
    );

    // Initial delay - let user see the STK push on their phone
    await Future.delayed(Duration(seconds: initialDelaySeconds));

    if (_isCancelled || !mounted) return null;

    int elapsed = initialDelaySeconds;
    int attempt = 0;

    while (elapsed < totalTimeoutSeconds && !_isCancelled && mounted) {
      attempt++;

      if (elapsed < 15) {
        state = state.copyWith(
          phase: MpesaPaymentPhase.waitingForUser,
          pollAttempt: attempt,
        );
      } else {
        state = state.copyWith(
          phase: MpesaPaymentPhase.processing,
          pollAttempt: attempt,
        );
      }

      // Notify UI of remaining time
      onTick?.call(totalTimeoutSeconds - elapsed);

      try {
        print('Polling attempt $attempt at ${elapsed}s');
        print("Checking payment status for PayID: ${state.payId}");
        final response = await _mpesaService.checkPaymentStatus(state.payId!);
        print(
          'Received status: rsp=${response.rsp}, wait=${response.wait}, success=${response.success}',
        );

        // If wait=false and success=true, payment completed
        if (response.isCompleted) {
          state = state.copyWith(
            isPolling: false,
            statusResponse: response,
            phase: MpesaPaymentPhase.completed,
          );
          return response;
        }

        // If wait=false and success=false, payment failed
        // But only mark as failed after 30 seconds to give user enough time
        if (response.isFailed) {
          state = state.copyWith(
            isPolling: false,
            statusResponse: response,
            phase: MpesaPaymentPhase.failed,
          );
          return response;
        }

        state = state.copyWith(statusResponse: response);
      } catch (e) {
        // Network error - continue polling, don't fail immediately
      }

      // Adaptive polling interval
      int interval;
      if (elapsed < 15) {
        interval = 3; // Quick checks while user enters PIN
      } else if (elapsed < 30) {
        interval = 4; // Medium interval during processing
      } else {
        interval = 5; // Slower checks near timeout
      }

      await Future.delayed(Duration(seconds: interval));
      elapsed += interval;
    }

    if (_isCancelled) {
      return state.statusResponse;
    }

    // Timeout reached - but don't mark as failed, let user retry
    state = state.copyWith(isPolling: false, phase: MpesaPaymentPhase.timeout);

    return state.statusResponse;
  }

  /// Mark payment as completed (for manual confirmation)
  void markCompleted() {
    state = state.copyWith(phase: MpesaPaymentPhase.completed);
  }

  /// Mark payment as failed
  void markFailed(String? errorMessage) {
    state = state.copyWith(
      phase: MpesaPaymentPhase.failed,
      error: errorMessage,
    );
  }
}

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
