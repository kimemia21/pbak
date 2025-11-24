import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class CrashDetectorService {
  static final CrashDetectorService _instance = CrashDetectorService._internal();
  factory CrashDetectorService() => _instance;
  CrashDetectorService._internal();

  // Crash detection thresholds
  static const double crashThreshold = 2.5; // G-force threshold (m/s²)
  static const double suddenStopThreshold = 2.0; // Sudden deceleration
  static const int checkIntervalMs = 100; // Check every 100ms
  
  // State management
  bool _isMonitoring = false;
  bool _crashDetected = false;
  DateTime? _crashTime;
  
  // Sensor data
  double _previousAcceleration = 0.0;
  List<double> _accelerationHistory = [];
  List<AccelerometerEvent> _rawAccelerometerHistory = [];
  static const int historySize = 10;
  static const int rawHistorySize = 20; // Store more raw data for crash analysis
  
  // Streams
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  
  // Controllers
  final _crashController = StreamController<CrashEvent>.broadcast();
  Stream<CrashEvent> get crashStream => _crashController.stream;
  
  // Getters
  bool get isMonitoring => _isMonitoring;
  bool get crashDetected => _crashDetected;
  DateTime? get crashTime => _crashTime;

  /// Initialize and start crash detection
  Future<bool> startMonitoring() async {
    if (_isMonitoring) {
      debugPrint('Crash detector already running');
      return true;
    }

    // Request permissions
    final sensorsPermission = await _requestPermissions();
    if (!sensorsPermission) {
      debugPrint('Sensor permissions not granted');
      return false;
    }

    try {
      // Start accelerometer monitoring
      _accelerometerSubscription = accelerometerEventStream(
        samplingPeriod: Duration(milliseconds: checkIntervalMs),
      ).listen(_onAccelerometerData);

      // Start gyroscope monitoring (for rotation detection)
      _gyroscopeSubscription = gyroscopeEventStream(
        samplingPeriod: Duration(milliseconds: checkIntervalMs),
      ).listen(_onGyroscopeData);

      _isMonitoring = true;
      _crashDetected = false;
      debugPrint('Crash detector started successfully');
      return true;
    } catch (e) {
      debugPrint('Error starting crash detector: $e');
      return false;
    }
  }

  /// Stop crash detection
  void stopMonitoring() {
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _accelerometerSubscription = null;
    _gyroscopeSubscription = null;
    _isMonitoring = false;
    debugPrint('Crash detector stopped');
  }

  /// Reset crash detection state
  void resetCrashState() {
    _crashDetected = false;
    _crashTime = null;
    _accelerationHistory.clear();
    debugPrint('Crash state reset');
  }

  /// Process accelerometer data
  void _onAccelerometerData(AccelerometerEvent event) {
    // Calculate total acceleration magnitude (G-force)
    final acceleration = sqrt(
      pow(event.x, 2) + pow(event.y, 2) + pow(event.z, 2)
    );

    // Store raw accelerometer data for crash analysis
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
    _checkCrashConditions(acceleration);

    _previousAcceleration = acceleration;
  }

  /// Process gyroscope data
  void _onGyroscopeData(GyroscopeEvent event) {
    // Calculate rotation magnitude
    final rotation = sqrt(
      pow(event.x, 2) + pow(event.y, 2) + pow(event.z, 2)
    );

    // High rotation + high acceleration = potential crash
    if (rotation > 5.0 && _previousAcceleration > crashThreshold * 0.7) {
      debugPrint('High rotation detected with acceleration: $rotation rad/s');
    }
  }

  /// Check if crash conditions are met
  void _checkCrashConditions(double acceleration) {
    // Condition 1: Extreme acceleration (impact)
    if (acceleration > crashThreshold) {
      _triggerCrash(
        CrashType.impact,
        'High-velocity Impact: Severe collision detected with peak force ${acceleration.toStringAsFixed(1)}m/s² exceeding safety threshold',
        acceleration,
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
          CrashType.suddenStop,
          'Sudden Deceleration: Rapid velocity change of ${(_previousAcceleration - recentAvg).toStringAsFixed(1)}m/s² indicates emergency braking or frontal collision',
          recentAvg,
        );
        return;
      }
    }

    // Condition 3: Sustained high acceleration
    if (_accelerationHistory.length >= historySize) {
      final avg = _accelerationHistory.reduce((a, b) => a + b) / historySize;
      if (avg > crashThreshold * 0.8) {
        _triggerCrash(
          CrashType.sustained,
          'Sustained High-G Force: Prolonged acceleration of ${avg.toStringAsFixed(1)}m/s² detected over ${historySize * checkIntervalMs}ms period suggesting rollover or tumbling motion',
          avg,
        );
      }
    }
  }

  /// Trigger crash event
  void _triggerCrash(CrashType type, String description, double magnitude) {
    if (_crashDetected) return; // Already in crash state

    _crashDetected = true;
    _crashTime = DateTime.now();

    // Get accelerometer values before and after crash
    final accValBefore = _getAccelerometerValuesBeforeCrash();
    final accValAfter = _getAccelerometerValuesAfterCrash();
    final accChange = (magnitude - _previousAcceleration).toStringAsFixed(2);

    final crashEvent = CrashEvent(
      type: type,
      timestamp: _crashTime!,
      description: description,
      magnitude: magnitude,
      location: null, // Will be populated by location service
      accValBefore: accValBefore,
      accValAfter: accValAfter,
      accChange: accChange,
    );

    debugPrint('🚨 CRASH DETECTED: $description');
    _crashController.add(crashEvent);
  }

  /// Get accelerometer values before crash (last 4 readings)
  String _getAccelerometerValuesBeforeCrash() {
    if (_rawAccelerometerHistory.length < 8) {
      return '';
    }
    
    // Get the 4 readings before the crash point (middle of history)
    final midPoint = _rawAccelerometerHistory.length ~/ 2;
    final beforeReadings = _rawAccelerometerHistory
        .sublist(max(0, midPoint - 4), midPoint)
        .map((e) => '${e.x.toStringAsFixed(2)},${e.y.toStringAsFixed(2)},${e.z.toStringAsFixed(2)}')
        .join(';');
    
    return beforeReadings;
  }

  /// Get accelerometer values after crash (last 4 readings)
  String _getAccelerometerValuesAfterCrash() {
    if (_rawAccelerometerHistory.length < 4) {
      return '';
    }
    
    // Get the last 4 readings (after crash)
    final afterReadings = _rawAccelerometerHistory
        .sublist(_rawAccelerometerHistory.length - 4)
        .map((e) => '${e.x.toStringAsFixed(2)},${e.y.toStringAsFixed(2)},${e.z.toStringAsFixed(2)}')
        .join(';');
    
    return afterReadings;
  }

  /// Request necessary permissions
  Future<bool> _requestPermissions() async {
    // Sensors don't need runtime permissions on most devices
    // But we'll check phone permission for calling
    final phoneStatus = await Permission.phone.request();
    return phoneStatus.isGranted || phoneStatus.isLimited;
  }

  /// Simulate crash for testing
  void simulateCrash({CrashType type = CrashType.impact}) {
    _triggerCrash(
      type,
      'SIMULATED CRASH - Testing crash detection',
      crashThreshold + 5.0,
    );
  }

  /// Dispose resources
  void dispose() {
    stopMonitoring();
    _crashController.close();
  }
}

/// Crash event data
class CrashEvent {
  final CrashType type;
  final DateTime timestamp;
  final String description;
  final double magnitude;
  final String? location;
  final String accValBefore;
  final String accValAfter;
  final String accChange;
  final String? bearing;

  CrashEvent({
    required this.type,
    required this.timestamp,
    required this.description,
    required this.magnitude,
    this.location,
    this.accValBefore = '',
    this.accValAfter = '',
    this.accChange = '',
    this.bearing,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString(),
      'timestamp': timestamp.toIso8601String(),
      'description': description,
      'magnitude': magnitude,
      'location': location,
      'accValBefore': accValBefore,
      'accValAfter': accValAfter,
      'accChange': accChange,
      'bearing': bearing,
    };
  }
}

/// Types of crashes
enum CrashType {
  impact,       // Sudden high impact
  suddenStop,   // Rapid deceleration
  sustained,    // Sustained high acceleration
  rollover,     // Vehicle rollover
}
