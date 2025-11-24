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
  
  // Device orientation for lean calculation
  bool _isLandscapeMode = false;
  
  // Calibration offsets
  double _calibrationOffsetX = 0.0;
  double _calibrationOffsetY = 0.0;
  double _calibrationOffsetZ = 0.0;
  
  // Raw sensor data for calibration UI
  double _rawAccelX = 0.0;
  double _rawAccelY = 0.0;
  double _rawAccelZ = 0.0;
  double _rawGyroX = 0.0;
  double _rawGyroY = 0.0;
  double _rawGyroZ = 0.0;
  
  // Calibration and filtering
  static const double SPEED_THRESHOLD = 1.5; // Minimum speed to consider moving (km/h)
  static const double ACCEL_NOISE_THRESHOLD = 0.5; // Ignore acceleration below this (m/s²)
  static const double MIN_DISTANCE_THRESHOLD = 10.0; // Minimum distance to update (meters)
  static const double GPS_ACCURACY_THRESHOLD = 20.0; // Only use GPS with accuracy better than 20m
  
  // Low-pass filter for accelerometer (smooth out noise)
  double _filteredAccelX = 0.0;
  double _filteredAccelY = 0.0;
  double _filteredAccelZ = 9.81;
  static const double ALPHA = 0.8; // Filter coefficient (higher = more smoothing)
  
  // Callbacks
  Function(double)? onLeanAngleChanged;
  Function(double)? onSpeedChanged;
  Function(double)? onDistanceChanged;
  Function(double)? onAltitudeChanged;
  Function(double)? onAccelerationChanged;
  Function(double)? onAverageSpeedChanged;
  Function(SensorData)? onRawSensorData;
  
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
  
  /// Initialize and start tracking
  Future<void> startTracking() async {
    // Request location permissions
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

    // Start GPS tracking
    _startGPSTracking();
    
    // Start sensor tracking
    _startSensorTracking();
  }
  
  /// Start GPS tracking for speed, distance, altitude
  void _startGPSTracking() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters to reduce GPS jitter
    );
    
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      // Only process if GPS accuracy is good enough
      if (position.accuracy > GPS_ACCURACY_THRESHOLD) {
        return; // Skip this reading, GPS is not accurate enough
      }
      
      // Update altitude
      _altitude = position.altitude;
      onAltitudeChanged?.call(_altitude);
      
      // Update speed (m/s to km/h) with threshold
      double rawSpeed = position.speed * 3.6;
      
      // Apply speed threshold - consider stationary if below threshold
      if (rawSpeed < SPEED_THRESHOLD) {
        _currentSpeed = 0.0;
      } else {
        _currentSpeed = rawSpeed;
        
        // Only update max speed if actually moving
        if (_currentSpeed > _maxSpeed) {
          _maxSpeed = _currentSpeed;
        }
        
        // Only add to average if actually moving
        _speedReadings.add(_currentSpeed);
        if (_speedReadings.length > 100) {
          _speedReadings.removeAt(0); // Keep only last 100 readings
        }
      }
      
      onSpeedChanged?.call(_currentSpeed);
      
      // Calculate average speed (only from actual readings)
      if (_speedReadings.isNotEmpty) {
        _averageSpeed = _speedReadings.reduce((a, b) => a + b) / _speedReadings.length;
        onAverageSpeedChanged?.call(_averageSpeed);
      }
      
      // Calculate distance with threshold
      if (_lastPosition != null) {
        double distance = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );
        
        // Only update distance if it's significant enough (reduces GPS drift)
        if (distance >= MIN_DISTANCE_THRESHOLD && _currentSpeed > 0) {
          _totalDistance += distance / 1000; // Convert to km
          onDistanceChanged?.call(_totalDistance);
        }
      }
      
      _lastPosition = position;
    });
  }
  
  /// Start sensor tracking for lean angle and acceleration
  void _startSensorTracking() {
    // Track accelerometer for lean angle and acceleration
    _accelerometerSubscription = accelerometerEventStream().listen(
      (AccelerometerEvent event) {
        // Store raw sensor data
        _rawAccelX = event.x;
        _rawAccelY = event.y;
        _rawAccelZ = event.z;
        
        // Apply low-pass filter to smooth out noise
        _filteredAccelX = ALPHA * _filteredAccelX + (1 - ALPHA) * event.x;
        _filteredAccelY = ALPHA * _filteredAccelY + (1 - ALPHA) * event.y;
        _filteredAccelZ = ALPHA * _filteredAccelZ + (1 - ALPHA) * event.z;
        
        // Calculate lean angle based on device orientation
        // The accelerometer measures gravity's effect on each axis
        // For motorcycle lean angle, we need the tilt from vertical
        
        double angleRad;
        
        if (_isLandscapeMode) {
          // In landscape mode (phone horizontal, screen facing you):
          // - Y axis is lean left/right
          // - Z axis is gravity (pointing toward you when upright)
          // - X axis is up/down
          angleRad = atan2(_filteredAccelY, sqrt(_filteredAccelX * _filteredAccelX + _filteredAccelZ * _filteredAccelZ));
        } else {
          // In portrait mode (phone vertical):
          // - X axis is lean left/right
          // - Y axis is forward/backward
          // - Z axis is gravity (pointing toward you when upright)
          angleRad = atan2(_filteredAccelX, sqrt(_filteredAccelY * _filteredAccelY + _filteredAccelZ * _filteredAccelZ));
        }
        
        _leanAngle = angleRad * (180 / pi);
        
        // Apply calibration offset
        _leanAngle -= _calibrationOffsetX;
        
        // Clamp to reasonable motorcycle lean angles (-65 to 65 degrees)
        _leanAngle = _leanAngle.clamp(-65.0, 65.0);
        
        onLeanAngleChanged?.call(_leanAngle);
        
        // Notify raw sensor data listeners
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
          isLandscape: _isLandscapeMode,
        ));
        
        // Calculate acceleration magnitude (total G-force)
        double totalAcceleration = sqrt(
          _filteredAccelX * _filteredAccelX + 
          _filteredAccelY * _filteredAccelY + 
          _filteredAccelZ * _filteredAccelZ
        );
        
        // Subtract gravity (9.81 m/s²) to get net acceleration
        double rawAcceleration = (totalAcceleration - 9.81).abs();
        
        // Apply threshold to filter out noise
        if (rawAcceleration < ACCEL_NOISE_THRESHOLD) {
          _acceleration = 0.0;
        } else {
          _acceleration = rawAcceleration;
        }
        
        onAccelerationChanged?.call(_acceleration);
      },
    );
    
    // Use gyroscope for sensor fusion
    _gyroscopeSubscription = gyroscopeEventStream().listen(
      (GyroscopeEvent event) {
        // Store raw gyroscope data
        _rawGyroX = event.x;
        _rawGyroY = event.y;
        _rawGyroZ = event.z;
      },
    );
  }
  
  /// Stop all tracking
  void stopTracking() {
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _positionSubscription?.cancel();
  }
  
  /// Reset all stats
  void resetStats() {
    _totalDistance = 0.0;
    _maxSpeed = 0.0;
    _averageSpeed = 0.0;
    _speedReadings.clear();
    _lastPosition = null;
  }
  
  /// Set device orientation mode
  void setLandscapeMode(bool isLandscape) {
    _isLandscapeMode = isLandscape;
  }
  
  /// Set calibration offsets
  void setCalibration(double offsetX, double offsetY, double offsetZ) {
    _calibrationOffsetX = offsetX;
    _calibrationOffsetY = offsetY;
    _calibrationOffsetZ = offsetZ;
  }
  
  /// Dispose and cleanup
  void dispose() {
    stopTracking();
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
  
  /// Calculate current lean angle from sensor data
  double calculateLeanAngle() {
    double angleRad;
    if (isLandscape) {
      angleRad = atan2(filteredAccelY, sqrt(filteredAccelX * filteredAccelX + filteredAccelZ * filteredAccelZ));
    } else {
      angleRad = atan2(filteredAccelX, sqrt(filteredAccelY * filteredAccelY + filteredAccelZ * filteredAccelZ));
    }
    return angleRad * (180 / pi);
  }
  
  /// Calculate pitch (forward/backward tilt)
  double calculatePitch() {
    return atan2(filteredAccelY, sqrt(filteredAccelX * filteredAccelX + filteredAccelZ * filteredAccelZ)) * (180 / pi);
  }
  
  /// Calculate roll (left/right tilt)
  double calculateRoll() {
    return atan2(filteredAccelX, sqrt(filteredAccelY * filteredAccelY + filteredAccelZ * filteredAccelZ)) * (180 / pi);
  }
  
  /// Check if device is relatively stable (not moving much)
  bool get isStable {
    return gyroX.abs() < 0.1 && gyroY.abs() < 0.1 && gyroZ.abs() < 0.1;
  }
}
