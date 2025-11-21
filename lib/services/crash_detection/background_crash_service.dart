import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

/// Background Crash Detection Service
/// This service runs independently of the app and monitors for crashes 24/7
class BackgroundCrashService {
  static const String _keyEnabled = 'crash_detection_enabled';
  static const String _keyEmergencyContact = 'emergency_contact';
  
  /// Initialize the background service
  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    // Configure notification channel for Android
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'pbak_crash_detection',
        initialNotificationTitle: 'PBAK Crash Detection',
        initialNotificationContent: 'Monitoring for crashes...',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
    
    await service.startService();
  }

  /// Check if service is enabled
  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyEnabled) ?? true; // Default ON for safety
  }

  /// Enable crash detection
  static Future<void> enable(String emergencyContact) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, true);
    await prefs.setString(_keyEmergencyContact, emergencyContact);
    
    final service = FlutterBackgroundService();
    if (!await service.isRunning()) {
      await service.startService();
    }
    service.invoke('start_monitoring');
  }

  /// Disable crash detection
  static Future<void> disable() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, false);
    
    final service = FlutterBackgroundService();
    service.invoke('stop_monitoring');
  }

  /// Background service entry point
  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    service.on('start_monitoring').listen((event) async {
      await _startCrashMonitoring(service);
    });

    service.on('stop_monitoring').listen((event) {
      _stopCrashMonitoring();
    });

    // Auto-start monitoring
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_keyEnabled) ?? true;
    
    if (enabled) {
      await _startCrashMonitoring(service);
    }
  }

  /// iOS background handler
  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  // Crash detection state
  static StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  static StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  static List<double> _accelerationHistory = [];
  static List<AccelerometerEvent> _rawAccelerometerHistory = [];
  static double _previousAcceleration = 0.0;
  static const double crashThreshold = 30.0;
  static const double suddenStopThreshold = 25.0;
  static const int historySize = 10;
  static const int rawHistorySize = 20;

  /// Start crash monitoring
  static Future<void> _startCrashMonitoring(ServiceInstance service) async {
    debugPrint('🚀 Background crash monitoring started');

    // Update notification
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: '🛡️ PBAK Crash Detection Active',
        content: 'Monitoring your ride - Stay safe!',
      );
    }

    // Start sensor monitoring
    _accelerometerSubscription = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 100),
    ).listen((event) {
      _onAccelerometerData(event, service);
    });

    _gyroscopeSubscription = gyroscopeEventStream(
      samplingPeriod: const Duration(milliseconds: 100),
    ).listen((event) {
      // Process gyroscope data
    });
  }

  /// Stop crash monitoring
  static void _stopCrashMonitoring() {
    debugPrint('🛑 Background crash monitoring stopped');
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _accelerationHistory.clear();
  }

  /// Process accelerometer data
  static void _onAccelerometerData(
    AccelerometerEvent event,
    ServiceInstance service,
  ) {
    // Calculate total acceleration magnitude
    final acceleration = sqrt(
      pow(event.x, 2) + pow(event.y, 2) + pow(event.z, 2),
    );

    // Store raw accelerometer data
    _rawAccelerometerHistory.add(event);
    if (_rawAccelerometerHistory.length > rawHistorySize) {
      _rawAccelerometerHistory.removeAt(0);
    }

    // Add to history
    _accelerationHistory.add(acceleration);
    if (_accelerationHistory.length > historySize) {
      _accelerationHistory.removeAt(0);
    }

    // Check for crash conditions
    _checkCrashConditions(acceleration, service);

    _previousAcceleration = acceleration;
  }

  /// Check if crash conditions are met
  static void _checkCrashConditions(
    double acceleration,
    ServiceInstance service,
  ) {
    // Condition 1: Extreme acceleration (impact)
    if (acceleration > crashThreshold) {
      _triggerCrash(
        'High-velocity Impact: Severe collision detected with peak force ${acceleration.toStringAsFixed(1)}m/s² exceeding safety threshold',
        acceleration,
        service,
      );
      return;
    }

    // Condition 2: Sudden deceleration
    if (_accelerationHistory.length >= 3) {
      final recentAvg = _accelerationHistory
          .sublist(_accelerationHistory.length - 3)
          .reduce((a, b) => a + b) / 3;

      if (_previousAcceleration - recentAvg > suddenStopThreshold) {
        _triggerCrash(
          'Sudden Deceleration: Rapid velocity change of ${(_previousAcceleration - recentAvg).toStringAsFixed(1)}m/s² indicates emergency braking or frontal collision',
          recentAvg,
          service,
        );
        return;
      }
    }

    // Condition 3: Sustained high acceleration
    if (_accelerationHistory.length >= historySize) {
      final avg = _accelerationHistory.reduce((a, b) => a + b) / historySize;
      if (avg > crashThreshold * 0.8) {
        _triggerCrash(
          'Sustained High-G Force: Prolonged acceleration of ${avg.toStringAsFixed(1)}m/s² detected over ${historySize * 100}ms period suggesting rollover or tumbling motion',
          avg,
          service,
        );
      }
    }
  }

  /// Trigger crash alert
  static void _triggerCrash(
    String description,
    double magnitude,
    ServiceInstance service,
  ) async {
    debugPrint('🚨 CRASH DETECTED IN BACKGROUND: $description');

    // Update notification to alert
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: '🚨 CRASH DETECTED!',
        content: 'Emergency alert activated - $description',
      );
    }

    // Get accelerometer values before and after crash
    final accValBefore = _getAccelerometerValuesBeforeCrash();
    final accValAfter = _getAccelerometerValuesAfterCrash();
    final accChange = magnitude.toStringAsFixed(2);

    // Send SOS to backend immediately
    await _sendSOSToBackend(description, accValBefore, accValAfter, accChange);

    // Start vibration
    await _startVibration();

    // Wait 30 seconds for user cancellation
    await Future.delayed(const Duration(seconds: 30));

    // If not cancelled, call emergency contact
    await _callEmergencyContact();
  }

  /// Get accelerometer values before crash
  static String _getAccelerometerValuesBeforeCrash() {
    if (_rawAccelerometerHistory.length < 8) {
      return '';
    }
    
    final midPoint = _rawAccelerometerHistory.length ~/ 2;
    final beforeReadings = _rawAccelerometerHistory
        .sublist(max(0, midPoint - 4), midPoint)
        .map((e) => '${e.x.toStringAsFixed(2)},${e.y.toStringAsFixed(2)},${e.z.toStringAsFixed(2)}')
        .join(';');
    
    return beforeReadings;
  }

  /// Get accelerometer values after crash
  static String _getAccelerometerValuesAfterCrash() {
    if (_rawAccelerometerHistory.length < 4) {
      return '';
    }
    
    final afterReadings = _rawAccelerometerHistory
        .sublist(_rawAccelerometerHistory.length - 4)
        .map((e) => '${e.x.toStringAsFixed(2)},${e.y.toStringAsFixed(2)},${e.z.toStringAsFixed(2)}')
        .join(';');
    
    return afterReadings;
  }

  /// Send SOS to backend
  static Future<void> _sendSOSToBackend(
    String description,
    String accValBefore,
    String accValAfter,
    String accChange,
  ) async {
    try {
      // Note: In background service, we need to use platform channels or http directly
      // For now, we'll log the data that would be sent
      debugPrint('📡 Would send SOS to backend:');
      debugPrint('  Description: $description');
      debugPrint('  Acc Before: $accValBefore');
      debugPrint('  Acc After: $accValAfter');
      debugPrint('  Acc Change: $accChange');
      
      // TODO: Implement direct HTTP call to SOS endpoint in background
      // Cannot use CommsService in background isolate
    } catch (e) {
      debugPrint('❌ Failed to send SOS: $e');
    }
  }

  /// Start vibration pattern
  static Future<void> _startVibration() async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        // Emergency vibration pattern
        final pattern = [0, 200, 100, 500, 100, 200, 100, 500];
        
        // Vibrate repeatedly
        for (int i = 0; i < 15; i++) {
          await Vibration.vibrate(pattern: pattern);
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    } catch (e) {
      debugPrint('Error vibrating: $e');
    }
  }

  /// Call emergency contact
  static Future<void> _callEmergencyContact() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final emergencyContact = prefs.getString(_keyEmergencyContact);

      if (emergencyContact != null && emergencyContact.isNotEmpty) {
        final cleanNumber = emergencyContact.replaceAll(RegExp(r'[^\d+]'), '');
        debugPrint('📞 Calling emergency contact: $cleanNumber');
        await FlutterPhoneDirectCaller.callNumber(cleanNumber);
      } else {
        debugPrint('⚠️ No emergency contact configured');
      }
    } catch (e) {
      debugPrint('Error calling emergency: $e');
    }
  }
}
