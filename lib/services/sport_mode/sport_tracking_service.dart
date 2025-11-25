import 'dart:async';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';

class SportTrackingService {
  // Lean angle tracking
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  
  // GPS tracking
  StreamSubscription<Position>? _positionSubscription;
  Position? _lastPosition;
  double _totalDistance = 0.0;
  
  // Stats
  double _currentSpeed = 0.0;
  double _maxSpeed = 0.0;
  double _averageSpeed = 0.0;
  double _altitude = 0.0;
  double _leanAngle = 0.0;
  double _acceleration = 0.0;
  
  // Speed tracking for average
  List<double> _speedReadings = [];
  
  // AUTO-CALIBRATION: Store multiple upright samples
  List<_Vector3> _uprightSamples = [];
  static const int MAX_UPRIGHT_SAMPLES = 50; // Keep last 50 upright positions
  static const int MIN_SAMPLES_FOR_CALIBRATION = 10; // Need at least 10 to calibrate
  
  // Reference calibration vectors
  double _calibrationRefX = 0.0;
  double _calibrationRefY = 0.0;
  double _calibrationRefZ = 9.81;
  
  double _calibrationForwardX = 0.0;
  double _calibrationForwardY = 1.0;
  double _calibrationForwardZ = 0.0;
  
  bool _isCalibrated = false;
  AutoCalibrationStatus _calibrationStatus = AutoCalibrationStatus.notStarted;
  
  // Raw sensor data
  double _rawAccelX = 0.0;
  double _rawAccelY = 0.0;
  double _rawAccelZ = 9.81;
  double _rawGyroX = 0.0;
  double _rawGyroY = 0.0;
  double _rawGyroZ = 0.0;
  
  // Filtering
  static const double SPEED_THRESHOLD = 1.5;
  static const double ACCEL_NOISE_THRESHOLD = 0.5;
  static const double MIN_DISTANCE_THRESHOLD = 10.0;
  static const double GPS_ACCURACY_THRESHOLD = 20.0;
  
  // Low-pass filter
  double _filteredAccelX = 0.0;
  double _filteredAccelY = 0.0;
  double _filteredAccelZ = 9.81;
  static const double ALPHA = 0.8;
  
  // AUTO-CALIBRATION THRESHOLDS
// AUTO-CALIBRATION THRESHOLDS (New Constant)
static const double UPRIGHT_SPEED_MIN = 0.5; // Moving slowly (km/h)
static const double UPRIGHT_SPEED_MAX = 3.0; // Not moving fast
static const double STABILITY_THRESHOLD = 0.15; // Low gyro activity
static const double MIN_UPRIGHT_TIME = 2.0; // Must be stable for 2 seconds

int _stableFrameCount = 0;
static const int STABLE_FRAMES_REQUIRED = 120; // ~2 seconds at 60Hz

// NEW: Angle threshold for detecting a change in orientation
static const double POSITION_CHANGE_ANGLE_THRESHOLD = 15.0; // Degrees
/// Helper function to calculate the forward reference vector
_Vector3 _calculateForwardVector(_Vector3 gravityVec) {
  _Vector3 forward = _Vector3(0, 1, 0); // Default guess

  // If the gravity vector is already mostly pointing along the (0, 1, 0) axis,
  // use the (1, 0, 0) axis as the initial guess to ensure a good cross product.
  if (gravityVec.dot(forward).abs() > 0.9 * gravityVec.magnitude()) {
    forward = _Vector3(1, 0, 0);
  }

  // Calculate the forward vector that is perpendicular to the gravity vector
  // but closest to the device's assumed forward (Y or X axis).
  final cross1 = gravityVec.cross(forward);
  final cross2 = cross1.cross(gravityVec);
  
  return cross2.normalized();
}
  

  
  // Callbacks
  Function(double)? onLeanAngleChanged;
  Function(double)? onSpeedChanged;
  Function(double)? onDistanceChanged;
  Function(double)? onAltitudeChanged;
  Function(double)? onAccelerationChanged;
  Function(double)? onAverageSpeedChanged;
  Function(SensorData)? onRawSensorData;
  Function(AutoCalibrationStatus)? onCalibrationStatusChanged;
  Function(String)? onCalibrationMessage;
  
  // Getters
  double get leanAngle => _leanAngle;
  double get currentSpeed => _currentSpeed;
  double get maxSpeed => _maxSpeed;
  double get averageSpeed => _averageSpeed;
  double get totalDistance => _totalDistance;
  double get altitude => _altitude;
  double get acceleration => _acceleration;
  double get rawAccelX => _rawAccelX;
  double get rawAccelY => _rawAccelY;
  double get rawAccelZ => _rawAccelZ;
  double get rawGyroX => _rawGyroX;
  double get rawGyroY => _rawGyroY;
  double get rawGyroZ => _rawGyroZ;
  bool get isCalibrated => _isCalibrated;
  AutoCalibrationStatus get calibrationStatus => _calibrationStatus;
  int get calibrationProgress => (_uprightSamples.length * 100 / MIN_SAMPLES_FOR_CALIBRATION).clamp(0, 100).toInt();
  
  // Calibration vector getters (for saving/loading)
  double get calibrationRefX => _calibrationRefX;
  double get calibrationRefY => _calibrationRefY;
  double get calibrationRefZ => _calibrationRefZ;
  double get calibrationForwardX => _calibrationForwardX;
  double get calibrationForwardY => _calibrationForwardY;
  double get calibrationForwardZ => _calibrationForwardZ;
  
  Future<void> startTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    _startGPSTracking();
    _startSensorTracking();
    
    // Start auto-calibration
    _updateCalibrationStatus(AutoCalibrationStatus.waitingForStability);
    onCalibrationMessage?.call('Detecting riding position...');
  }
  
  void _startGPSTracking() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );
    
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      if (position.accuracy > GPS_ACCURACY_THRESHOLD) {
        return;
      }
      
      _altitude = position.altitude;
      onAltitudeChanged?.call(_altitude);
      
      double rawSpeed = position.speed * 3.6;
      
      if (rawSpeed < SPEED_THRESHOLD) {
        _currentSpeed = 0.0;
      } else {
        _currentSpeed = rawSpeed;
        
        if (_currentSpeed > _maxSpeed) {
          _maxSpeed = _currentSpeed;
        }
        
        _speedReadings.add(_currentSpeed);
        if (_speedReadings.length > 100) {
          _speedReadings.removeAt(0);
        }
      }
      
      onSpeedChanged?.call(_currentSpeed);
      
      if (_speedReadings.isNotEmpty) {
        _averageSpeed = _speedReadings.reduce((a, b) => a + b) / _speedReadings.length;
        onAverageSpeedChanged?.call(_averageSpeed);
      }
      
      if (_lastPosition != null) {
        double distance = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );
        
        if (distance >= MIN_DISTANCE_THRESHOLD && _currentSpeed > 0) {
          _totalDistance += distance / 1000;
          onDistanceChanged?.call(_totalDistance);
        }
      }
      
      _lastPosition = position;
    });
  }
  
  void _startSensorTracking() {
    _accelerometerSubscription = accelerometerEventStream().listen(
      (AccelerometerEvent event) {
        _rawAccelX = event.x;
        _rawAccelY = event.y;
        _rawAccelZ = event.z;
        
        // Apply low-pass filter
        _filteredAccelX = ALPHA * _filteredAccelX + (1 - ALPHA) * event.x;
        _filteredAccelY = ALPHA * _filteredAccelY + (1 - ALPHA) * event.y;
        _filteredAccelZ = ALPHA * _filteredAccelZ + (1 - ALPHA) * event.z;
        
        // AUTO-CALIBRATION: Check if conditions are right
        _checkAndUpdateAutoCalibration();
        
        // Calculate lean angle
        _leanAngle = _calculateLeanAngleWithCalibration(
          _filteredAccelX, 
          _filteredAccelY, 
          _filteredAccelZ
        );
        
        _leanAngle = _leanAngle.clamp(-65.0, 65.0);
        
        onLeanAngleChanged?.call(_leanAngle);
        
        onRawSensorData?.call(SensorData(
          accelX: _rawAccelX,
          accelY: _rawAccelY,
          accelZ: _rawAccelZ,
          gyroX: _rawGyroX,
          gyroY: _rawGyroY,
          gyroZ: _rawGyroZ,
          filteredAccelX: _filteredAccelX,
          filteredAccelY: _filteredAccelY,
          filteredAccelZ: _filteredAccelZ,
          isLandscape: false,
        ));
        
        double totalAcceleration = sqrt(
          _filteredAccelX * _filteredAccelX + 
          _filteredAccelY * _filteredAccelY + 
          _filteredAccelZ * _filteredAccelZ
        );
        
        double rawAcceleration = (totalAcceleration - 9.81).abs();
        
        if (rawAcceleration < ACCEL_NOISE_THRESHOLD) {
          _acceleration = 0.0;
        } else {
          _acceleration = rawAcceleration;
        }
        
        onAccelerationChanged?.call(_acceleration);
      },
    );
    
    _gyroscopeSubscription = gyroscopeEventStream().listen(
      (GyroscopeEvent event) {
        _rawGyroX = event.x;
        _rawGyroY = event.y;
        _rawGyroZ = event.z;
      },
    );
  }
  
  /// AUTO-CALIBRATION: Check if rider is upright and stable
  void _checkAndUpdateAutoCalibration() {


    // ALWAYS monitor for position changes and recalibrate when needed
    
    // Check if conditions are right for upright detection:
    // 1. Moving slowly (or stationary)
    // 2. Device is stable (low rotation)
    // 3. Not accelerating hard
    
    bool isMovingSlowly = _currentSpeed >= UPRIGHT_SPEED_MIN && 
                          _currentSpeed <= UPRIGHT_SPEED_MAX;
    
    bool isStable = _rawGyroX.abs() < STABILITY_THRESHOLD &&
                    _rawGyroY.abs() < STABILITY_THRESHOLD &&
                    _rawGyroZ.abs() < STABILITY_THRESHOLD;
    
    bool lowAcceleration = _acceleration < ACCEL_NOISE_THRESHOLD * 2;
    
    // Conditions met for upright position
    if ((isMovingSlowly || _currentSpeed == 0) && isStable && lowAcceleration) {
      _stableFrameCount++;
      
      // Update status
      if (_calibrationStatus == AutoCalibrationStatus.waitingForStability) {
        _updateCalibrationStatus(AutoCalibrationStatus.collectingSamples);
      }
      
      onCalibrationMessage?.call('Hold steady... ${_stableFrameCount}/${STABLE_FRAMES_REQUIRED}');
      
      // Collect sample after enough stable frames
      if (_stableFrameCount >= STABLE_FRAMES_REQUIRED) {
        _addUprightSample(_filteredAccelX, _filteredAccelY, _filteredAccelZ);
        _stableFrameCount = 0; // Reset for next sample
        
        // Check if we have enough samples
        if (_uprightSamples.length >= MIN_SAMPLES_FOR_CALIBRATION) {
          // Check if this is a significantly different position
          if (_isCalibrated) {
            _checkForPositionChange();
          } else {
            _performAutoCalibration();
          }
        } else {
          onCalibrationMessage?.call(
            'Calibrating... ${_uprightSamples.length}/$MIN_SAMPLES_FOR_CALIBRATION samples'
          );
        }
      }
    } else {
      // Not stable - reset counter
      if (_stableFrameCount > 0) {
        _stableFrameCount = 0;
        if (_calibrationStatus == AutoCalibrationStatus.collectingSamples) {
          onCalibrationMessage?.call('Waiting for stable upright position...');
        }
      }
    }
  }
  
  /// Check if the phone position has changed significantly
/// Check if the phone position has changed significantly (Gravity AND Forward vector)
void _checkForPositionChange() {
  print('[DEBUG] _checkForPositionChange() called. Upright samples: ${_uprightSamples.length}');
  if (_uprightSamples.length < MIN_SAMPLES_FOR_CALIBRATION) {
    print('[DEBUG] Not enough samples to check for position change. Need $MIN_SAMPLES_FOR_CALIBRATION');
    return;
  }

  // 1. Calculate the new averaged upright vector (New Gravity Reference)
  double avgX = 0.0;
  double avgY = 0.0;
  double avgZ = 0.0;

  for (var sample in _uprightSamples) {
    avgX += sample.x;
    avgY += sample.y;
    avgZ += sample.z;
  }

  avgX /= _uprightSamples.length;
  avgY /= _uprightSamples.length;
  avgZ /= _uprightSamples.length;

  final currentRef = _Vector3(_calibrationRefX, _calibrationRefY, _calibrationRefZ);
  final newRef = _Vector3(avgX, avgY, avgZ);

  print('[DEBUG] currentRef=(${currentRef.x.toStringAsFixed(3)}, ${currentRef.y.toStringAsFixed(3)}, ${currentRef.z.toStringAsFixed(3)})');
  print('[DEBUG] newRef=(${newRef.x.toStringAsFixed(3)}, ${newRef.y.toStringAsFixed(3)}, ${newRef.z.toStringAsFixed(3)})');

  bool shouldRecalibrate = false;

  // --- A. Check Gravity Vector Change (Tilt) ---
  final dotProductG = currentRef.dot(newRef);
  final currentMagG = currentRef.magnitude();
  final newMagG = newRef.magnitude();

  if (currentMagG > 0.1 && newMagG > 0.1) {
    final cosAngleG = (dotProductG / (currentMagG * newMagG)).clamp(-1.0, 1.0);
    final angleDifferenceG = acos(cosAngleG) * (180 / pi);

    print('[DEBUG] Gravity angle difference = ${angleDifferenceG.toStringAsFixed(2)}°');

    // If tilt changed significantly (e.g., phone slipped)
    if (angleDifferenceG > POSITION_CHANGE_ANGLE_THRESHOLD) {
      print('[DEBUG] Tilt change above threshold (${POSITION_CHANGE_ANGLE_THRESHOLD}°).');
      onCalibrationMessage?.call('Major tilt change detected. Recalibrating...');
      shouldRecalibrate = true;
    }
  } else {
    print('[DEBUG] Gravity magnitude too small for reliable tilt check (currentMagG=$currentMagG, newMagG=$newMagG).');
  }

  // --- B. Check Forward Vector Change (Rotation/Flip) ---
  if (!shouldRecalibrate) {
    // If gravity hasn't changed, calculate the *new* forward vector
    final newForward = _calculateForwardVector(newRef);

    // The previously calibrated forward vector
    final oldForward = _Vector3(_calibrationForwardX, _calibrationForwardY, _calibrationForwardZ);

    print('[DEBUG] oldForward=(${oldForward.x.toStringAsFixed(3)}, ${oldForward.y.toStringAsFixed(3)}, ${oldForward.z.toStringAsFixed(3)})');
    print('[DEBUG] newForward=(${newForward.x.toStringAsFixed(3)}, ${newForward.y.toStringAsFixed(3)}, ${newForward.z.toStringAsFixed(3)})');

    final dotProductF = oldForward.dot(newForward);
    final oldMagF = oldForward.magnitude();
    final newMagF = newForward.magnitude();

    if (oldMagF > 0.01 && newMagF > 0.01) {
      final cosAngleF = (dotProductF / (oldMagF * newMagF)).clamp(-1.0, 1.0);
      final angleDifferenceF = acos(cosAngleF) * (180 / pi);

      print('[DEBUG] Forward angle difference = ${angleDifferenceF.toStringAsFixed(2)}°');

      // If the forward direction changed significantly (e.g., 90/180 degree flip)
      if (angleDifferenceF > POSITION_CHANGE_ANGLE_THRESHOLD) {
        print('[DEBUG] Forward change above threshold (${POSITION_CHANGE_ANGLE_THRESHOLD}°).');
        onCalibrationMessage?.call('Phone position/flip detected. Recalibrating...');
        shouldRecalibrate = true;
      }
    } else {
      print('[DEBUG] Forward magnitude too small for reliable forward check (oldMagF=$oldMagF, newMagF=$newMagF).');
    }
  }

  // --- C. Execute Recalibration or Confirm Status ---
  if (shouldRecalibrate) {
    print('[DEBUG] Triggering recalibration with newRef.');
    // We detected a significant change in either tilt OR rotation/flip
    _performAutoCalibration(newRef); // Use the new gravity vector for recalibration
    _uprightSamples.clear(); // Clear old samples as they are now invalid
    print('[DEBUG] Upright samples cleared after recalibration.');
  } else {
    // Position hasn't changed significantly, confirm calibration status
    print('[DEBUG] No significant position change detected.');
    if (_isCalibrated && _calibrationStatus != AutoCalibrationStatus.calibrated) {
      _updateCalibrationStatus(AutoCalibrationStatus.calibrated);
      onCalibrationMessage?.call('Calibration confirmed. Ready to ride.');
      print('[DEBUG] Calibration status updated to calibrated.');
    }
  }
}
  
  /// Add an upright sample to calibration data
  void _addUprightSample(double x, double y, double z) {
    _uprightSamples.add(_Vector3(x, y, z));
    
    // Don't limit samples anymore - keep collecting to detect position changes
    // Only keep last 50 to avoid memory issues
    if (_uprightSamples.length > MAX_UPRIGHT_SAMPLES) {
      _uprightSamples.removeAt(0);
    }
  }
  
  /// Perform automatic calibration from collected samples
 void _performAutoCalibration([_Vector3? refVector]) {
  
  // A. Determine the reference vector
  _Vector3 gravityVec;
  if (refVector != null) {
    // Use the vector passed in from _checkForPositionChange
    gravityVec = refVector;
  } else {
    // This is the original logic (used when first calibrating from all samples)
    if (_uprightSamples.length < MIN_SAMPLES_FOR_CALIBRATION) {
      return;
    }
    
    // Average all upright samples to get reference position
    double avgX = 0.0;
    double avgY = 0.0;
    double avgZ = 0.0;
    
    for (var sample in _uprightSamples) {
      avgX += sample.x;
      avgY += sample.y;
      avgZ += sample.z;
    }
    
    avgX /= _uprightSamples.length;
    avgY /= _uprightSamples.length;
    avgZ /= _uprightSamples.length;
    gravityVec = _Vector3(avgX, avgY, avgZ);
  }
  
  // B. Set Gravity Calibration
  _calibrationRefX = gravityVec.x;
  _calibrationRefY = gravityVec.y;
  _calibrationRefZ = gravityVec.z;
  
  // C. Calculate and Set Forward Direction (using the new helper function)
  final forwardNormalized = _calculateForwardVector(gravityVec);
  
  _calibrationForwardX = forwardNormalized.x;
  _calibrationForwardY = forwardNormalized.y;
  _calibrationForwardZ = forwardNormalized.z;
  
  _isCalibrated = true;
  _updateCalibrationStatus(AutoCalibrationStatus.calibrated);
  onCalibrationMessage?.call('✓ Auto-calibrated! Ready to ride.');
}
  /// Update calibration status and notify listeners
  void _updateCalibrationStatus(AutoCalibrationStatus newStatus) {
    _calibrationStatus = newStatus;
    onCalibrationStatusChanged?.call(newStatus);
  }
  
  /// Manual recalibration (clears samples and starts fresh)
  void recalibrate() {
    _uprightSamples.clear();
    _isCalibrated = false;
    _stableFrameCount = 0;
    _updateCalibrationStatus(AutoCalibrationStatus.waitingForStability);
    onCalibrationMessage?.call('Recalibrating... Hold upright and steady.');
  }
  
  /// Force recalibration when position changes detected
  void forceRecalibration() {
    print('Forcing recalibration due to position change');
    _isCalibrated = false;
    _stableFrameCount = 0;
    _updateCalibrationStatus(AutoCalibrationStatus.collectingSamples);
    // Keep the samples we already have for faster recalibration
  }
  
  /// Calculate lean angle relative to calibrated reference
  double _calculateLeanAngleWithCalibration(double accelX, double accelY, double accelZ) {
    if (!_isCalibrated) {
      // Return 0 until calibrated
      return 0.0;
    }
    
    final currentGravity = _Vector3(accelX, accelY, accelZ);
    final referenceGravity = _Vector3(_calibrationRefX, _calibrationRefY, _calibrationRefZ);
    
    final double dotProduct = currentGravity.dot(referenceGravity);
    final double currentMag = currentGravity.magnitude();
    final double refMag = referenceGravity.magnitude();
    
    if (currentMag < 0.1 || refMag < 0.1) {
      return 0.0;
    }
    
    final double cosAngle = (dotProduct / (currentMag * refMag)).clamp(-1.0, 1.0);
    final double totalTilt = acos(cosAngle) * (180 / pi);
    
    final referenceForward = _Vector3(
      _calibrationForwardX, 
      _calibrationForwardY, 
      _calibrationForwardZ
    );
    
    final cross = referenceForward.cross(currentGravity);
    final leanDirection = cross.dot(referenceGravity);
    
    return leanDirection > 0 ? totalTilt : -totalTilt;
  }
  
  /// Load saved calibration
  void loadSavedCalibration(double refX, double refY, double refZ, 
                            double fwdX, double fwdY, double fwdZ) {
    _calibrationRefX = refX;
    _calibrationRefY = refY;
    _calibrationRefZ = refZ;
    _calibrationForwardX = fwdX;
    _calibrationForwardY = fwdY;
    _calibrationForwardZ = fwdZ;
    _isCalibrated = true;
    _updateCalibrationStatus(AutoCalibrationStatus.calibrated);
  }
  
  void stopTracking() {
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _positionSubscription?.cancel();
  }
  
  void resetStats() {
    _totalDistance = 0.0;
    _maxSpeed = 0.0;
    _averageSpeed = 0.0;
    _speedReadings.clear();
    _lastPosition = null;
  }
  
  void dispose() {
    stopTracking();
  }
}

/// Auto-calibration status
enum AutoCalibrationStatus {
  notStarted,
  waitingForStability,
  collectingSamples,
  calibrated,
}

/// Simple 3D vector class
class _Vector3 {
  final double x;
  final double y;
  final double z;
  
  _Vector3(this.x, this.y, this.z);
  
  double magnitude() => sqrt(x * x + y * y + z * z);
  
  double dot(_Vector3 other) => x * other.x + y * other.y + z * other.z;
  
  _Vector3 cross(_Vector3 other) => _Vector3(
    y * other.z - z * other.y,
    z * other.x - x * other.z,
    x * other.y - y * other.x,
  );
  
  _Vector3 normalized() {
    final mag = magnitude();
    return mag > 0 ? _Vector3(x / mag, y / mag, z / mag) : _Vector3(0, 0, 0);
  }
}

/// Container for raw sensor data
class SensorData {
  final double accelX;
  final double accelY;
  final double accelZ;
  final double gyroX;
  final double gyroY;
  final double gyroZ;
  final double filteredAccelX;
  final double filteredAccelY;
  final double filteredAccelZ;
  final bool isLandscape;
  
  SensorData({
    required this.accelX,
    required this.accelY,
    required this.accelZ,
    required this.gyroX,
    required this.gyroY,
    required this.gyroZ,
    required this.filteredAccelX,
    required this.filteredAccelY,
    required this.filteredAccelZ,
    required this.isLandscape,
  });
  
  bool get isStable {
    return gyroX.abs() < 0.1 && gyroY.abs() < 0.1 && gyroZ.abs() < 0.1;
  }
}