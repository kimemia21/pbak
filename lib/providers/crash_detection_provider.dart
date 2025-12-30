import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pbak/services/crash_detection/crash_detector_service.dart';
import 'package:pbak/services/crash_detection/crash_alert_service.dart';
import 'package:pbak/providers/auth_provider.dart';

final crashDetectorProvider = StateNotifierProvider<CrashDetectorNotifier, CrashDetectionState>((ref) {
  return CrashDetectorNotifier(ref);
});

class CrashDetectorNotifier extends StateNotifier<CrashDetectionState> {
  final Ref _ref;
  final CrashDetectorService _detectorService = CrashDetectorService();
  final CrashAlertService _alertService = CrashAlertService();

  StreamSubscription? _crashSub;
  StreamSubscription? _alertSub;

  CrashDetectorNotifier(this._ref) : super(CrashDetectionState.initial()) {
    _initializeListeners();
  }

  void _initializeListeners() {
    // Listen to crash events
    _crashSub = _detectorService.crashStream.listen((crashEvent) {
      if (!mounted) return;
      _onCrashDetected(crashEvent);
    });

    // Listen to alert state
    _alertSub = _alertService.alertStateStream.listen((alertState) {
      if (!mounted) return;
      state = state.copyWith(
        alertActive: alertState.isActive,
        countdown: alertState.countdown,
        emergencyCalled: alertState.emergencyCalled,
      );
    });
  }

  Future<bool> startMonitoring() async {
    final success = await _detectorService.startMonitoring();
    if (success) {
      state = state.copyWith(isMonitoring: true);
    }
    return success;
  }

  void stopMonitoring() {
    _detectorService.stopMonitoring();
    state = state.copyWith(isMonitoring: false);
  }

  void _onCrashDetected(CrashEvent event) {
    state = state.copyWith(
      crashDetected: true,
      lastCrashEvent: event,
    );

    // Get emergency contacts from user profile
    final authState = _ref.read(authProvider);
    final emergencyContacts = authState.value != null && 
            authState.value!.emergencyContact != null &&
            authState.value!.emergencyContact!.isNotEmpty
        ? <String>[authState.value!.emergencyContact!]
        : <String>[];

    // Trigger alert with crash event data
    _alertService.triggerAlert(emergencyContacts, crashEvent: event);
  }

  void cancelAlert() {
    _alertService.cancelAlert();
    state = state.copyWith(alertActive: false);
  }

  void resetCrash() {
    _detectorService.resetCrashState();
    state = state.copyWith(
      crashDetected: false,
      lastCrashEvent: null,
      alertActive: false,
      countdown: 30,
      emergencyCalled: false,
    );
  }

  void simulateCrash() {
    _detectorService.simulateCrash();
  }

  @override
  void dispose() {
    _crashSub?.cancel();
    _alertSub?.cancel();
    _detectorService.dispose();
    _alertService.dispose();
    super.dispose();
  }
}

class CrashDetectionState {
  final bool isMonitoring;
  final bool crashDetected;
  final CrashEvent? lastCrashEvent;
  final bool alertActive;
  final int countdown;
  final bool emergencyCalled;

  CrashDetectionState({
    required this.isMonitoring,
    required this.crashDetected,
    this.lastCrashEvent,
    required this.alertActive,
    required this.countdown,
    required this.emergencyCalled,
  });

  factory CrashDetectionState.initial() {
    return CrashDetectionState(
      isMonitoring: false,
      crashDetected: false,
      lastCrashEvent: null,
      alertActive: false,
      countdown: 30,
      emergencyCalled: false,
    );
  }

  CrashDetectionState copyWith({
    bool? isMonitoring,
    bool? crashDetected,
    CrashEvent? lastCrashEvent,
    bool? alertActive,
    int? countdown,
    bool? emergencyCalled,
  }) {
    return CrashDetectionState(
      isMonitoring: isMonitoring ?? this.isMonitoring,
      crashDetected: crashDetected ?? this.crashDetected,
      lastCrashEvent: lastCrashEvent ?? this.lastCrashEvent,
      alertActive: alertActive ?? this.alertActive,
      countdown: countdown ?? this.countdown,
      emergencyCalled: emergencyCalled ?? this.emergencyCalled,
    );
  }
}
