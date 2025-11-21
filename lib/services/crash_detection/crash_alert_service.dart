import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:pbak/services/sos_service.dart';
import 'package:pbak/services/location/location_service.dart';
import 'package:pbak/services/crash_detection/crash_detector_service.dart';

class CrashAlertService {
  static final CrashAlertService _instance = CrashAlertService._internal();
  factory CrashAlertService() => _instance;
  CrashAlertService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  final SOSService _sosService = SOSService();
  final LocationService _locationService = LocationService();
  Timer? _countdownTimer;
  int _countdown = 30; // 30 seconds to cancel
  bool _alertActive = false;
  bool _emergencyCalled = false;
  CrashEvent? _currentCrashEvent;

  // Alert state stream
  final _alertStateController = StreamController<AlertState>.broadcast();
  Stream<AlertState> get alertStateStream => _alertStateController.stream;

  bool get isAlertActive => _alertActive;
  int get countdown => _countdown;
  bool get emergencyCalled => _emergencyCalled;

  /// Trigger crash alert sequence
  Future<void> triggerAlert(List<String> emergencyContacts, {CrashEvent? crashEvent}) async {
    if (_alertActive) return;

    _alertActive = true;
    _emergencyCalled = false;
    _countdown = 30;
    _currentCrashEvent = crashEvent;

    debugPrint('🚨 Crash alert triggered! Starting countdown...');
    
    // Start countdown
    _startCountdown(emergencyContacts);
    
    // Play alert sound
    await _playAlertSound();
    
    // Vibrate device
    await _startVibration();
    
    // Emit initial state
    _emitState();
  }

  /// Start countdown timer
  void _startCountdown(List<String> emergencyContacts) {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _countdown--;
      _emitState();

      debugPrint('Alert countdown: $_countdown seconds');

      if (_countdown <= 0) {
        timer.cancel();
        _callEmergencyContacts(emergencyContacts);
      }
    });
  }

  /// Cancel alert before emergency call
  void cancelAlert() {
    if (!_alertActive) return;

    debugPrint('Alert cancelled by user');
    _stopAlert();
  }

  /// Stop alert
  void _stopAlert() {
    _countdownTimer?.cancel();
    _audioPlayer.stop();
    Vibration.cancel();
    _alertActive = false;
    _emitState();
  }

  /// Play alert sound
  Future<void> _playAlertSound() async {
    try {
      // In production, use a custom alert sound asset
      // For now, using a system sound
      await _audioPlayer.setVolume(1.0);
      // Repeat alert sound
      Timer.periodic(const Duration(seconds: 2), (timer) async {
        if (!_alertActive) {
          timer.cancel();
          return;
        }
        // Play sound (would need actual audio file in assets)
        debugPrint('🔊 Playing alert sound');
      });
    } catch (e) {
      debugPrint('Error playing alert sound: $e');
    }
  }

  /// Start vibration pattern
  Future<void> _startVibration() async {
    try {
      // Check if device has vibrator
      final hasVibrator = await Vibration.hasVibrator();
      
      if (hasVibrator == true) {
        debugPrint('📳 Starting vibration pattern for alert');
        
        // Create a strong vibration pattern for emergency alert
        // Pattern: short-long-short-long (SOS-like)
        // Pattern format: [wait, vibrate, wait, vibrate, ...] in milliseconds
        final pattern = [
          0,    // Start immediately
          200,  // Short vibration (200ms)
          100,  // Pause (100ms)
          500,  // Long vibration (500ms)
          100,  // Pause (100ms)
          200,  // Short vibration (200ms)
          100,  // Pause (100ms)
          500,  // Long vibration (500ms)
        ];
        
        // Repeat vibration pattern while alert is active
        Timer.periodic(const Duration(seconds: 2), (timer) async {
          if (!_alertActive) {
            timer.cancel();
            await Vibration.cancel();
            return;
          }
          
          // Vibrate with pattern
          await Vibration.vibrate(pattern: pattern);
        });
      } else {
        debugPrint('Device does not support vibration');
      }
    } catch (e) {
      debugPrint('Error vibrating: $e');
    }
  }

  /// Call emergency contacts
  Future<void> _callEmergencyContacts(List<String> contacts) async {
    if (contacts.isEmpty) {
      debugPrint('No emergency contacts configured');
      _stopAlert();
      return;
    }

    debugPrint('📞 Calling emergency contacts...');
    _emergencyCalled = true;
    _emitState();

    // Send SOS to backend first
    await _sendSOSToBackend();

    // Call the first emergency contact
    final primaryContact = contacts.first;
    await _makePhoneCall(primaryContact);

    // Stop alert after initiating call
    _stopAlert();
  }

  /// Send SOS data to backend
  Future<void> _sendSOSToBackend() async {
    try {
      // Get current location
      final position = await _locationService.getCurrentPosition();
      
      if (position == null) {
        debugPrint('⚠️ Could not get location for SOS');
        return;
      }

      // Calculate bearing if we have previous position
      String? bearing;
      if (_locationService.lastKnownPosition != null) {
        final bearingValue = _locationService.calculateBearing(
          _locationService.lastKnownPosition!,
          position,
        );
        bearing = bearingValue.toStringAsFixed(2);
      }

      // Prepare crash data
      final description = _currentCrashEvent?.description ?? 
          'Automatic Crash Detection: High-impact collision detected requiring immediate assistance';
      final accValBefore = _currentCrashEvent?.accValBefore ?? '';
      final accValAfter = _currentCrashEvent?.accValAfter ?? '';
      final accChange = _currentCrashEvent?.accChange ?? '';

      debugPrint('📡 Sending SOS to backend...');
      
      // Send SOS to backend
      await _sosService.sendCrashSOS(
        latitude: position.latitude,
        longitude: position.longitude,
        description: description,
        accValBefore: accValBefore,
        accValAfter: accValAfter,
        accChange: accChange,
        bearing: bearing,
      );

      debugPrint('✅ SOS sent successfully to backend');
    } catch (e) {
      debugPrint('❌ Failed to send SOS to backend: $e');
    }
  }

  /// Make phone call
  Future<void> _makePhoneCall(String phoneNumber) async {
    try {
      // Remove any non-numeric characters
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      debugPrint('Calling emergency contact: $cleanNumber');
      
      await FlutterPhoneDirectCaller.callNumber(cleanNumber);
    } catch (e) {
      debugPrint('Error making phone call: $e');
    }
  }

  /// Send SMS to emergency contacts (would need additional package)
  Future<void> sendEmergencySMS(List<String> contacts, String message) async {
    // This would require additional package like flutter_sms
    debugPrint('Would send SMS to ${contacts.length} contacts: $message');
  }

  /// Emit current state
  void _emitState() {
    _alertStateController.add(AlertState(
      isActive: _alertActive,
      countdown: _countdown,
      emergencyCalled: _emergencyCalled,
    ));
  }

  /// Dispose resources
  void dispose() {
    _stopAlert();
    _audioPlayer.dispose();
    _alertStateController.close();
  }
}

/// Alert state
class AlertState {
  final bool isActive;
  final int countdown;
  final bool emergencyCalled;

  AlertState({
    required this.isActive,
    required this.countdown,
    required this.emergencyCalled,
  });
}
