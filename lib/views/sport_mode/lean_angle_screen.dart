import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/sport_mode/sport_tracking_service.dart';
import '../../services/local_storage/local_storage_service.dart';

class LeanAngleScreen extends ConsumerStatefulWidget {
  const LeanAngleScreen({super.key});

  @override
  ConsumerState<LeanAngleScreen> createState() => _LeanAngleScreenState();
}

class _LeanAngleScreenState extends ConsumerState<LeanAngleScreen> with SingleTickerProviderStateMixin {
  double _leanAngle = 0.0;
  double _currentSpeed = 0.0;
  double _averageSpeed = 0.0;
  double _totalDistance = 0.0;
  double _altitude = 0.0;
  double _acceleration = 0.0;
  
  late AnimationController _pulseController;
  late SportTrackingService _trackingService;
  String _calibrationMessage = 'Starting...';
  AutoCalibrationStatus _calibrationStatus = AutoCalibrationStatus.notStarted;
  
  // Timers
  Timer? _rideTimer;
  Duration _activeRideTime = Duration.zero;
  Duration _totalTime = Duration.zero;
  bool _isRiding = false;
  
  // Calibration
  bool _isCalibrated = false;
  bool _showCalibrationDialog = false;
  double _calibrationOffsetX = 0.0;
  double _calibrationOffsetY = 0.0;
  double _calibrationOffsetZ = 0.0;
  LocalStorageService? _localStorage;
  
  // Orientation
  Orientation? _currentOrientation;
  bool _isOrientationLocked = false;
  bool _isLockedToLandscape = false;

  @override
  void initState() {
    super.initState();
    
    // Enable auto-rotation for this screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    // Initialize local storage and load calibration
    _initializeStorage();
    
    // Initialize tracking service
    _trackingService = SportTrackingService();
    
    // Set initial calibration if available
// In initState(), update the calibration status callback:
_trackingService.onCalibrationStatusChanged = (status) {
  setState(() {
    _calibrationStatus = status;
    _isCalibrated = status == AutoCalibrationStatus.calibrated; 
    // AUTO-SAVE when calibration completes
    if (status == AutoCalibrationStatus.calibrated) {
      _saveCalibration();
    }
  });
};

_trackingService.onCalibrationMessage = (message) {
  setState(() {
    _calibrationMessage = message;
  });
};

    // Set up callbacks
    _trackingService.onLeanAngleChanged = (angle) {
      setState(() => _leanAngle = angle);
    };
    
    _trackingService.onSpeedChanged = (speed) {
      setState(() {
        _currentSpeed = speed;
        // Consider riding if speed > 5 km/h
        if (speed > 5 && !_isRiding) {
          _isRiding = true;
        } else if (speed <= 5 && _isRiding) {
          _isRiding = false;
        }
      });
    };
    
    _trackingService.onAverageSpeedChanged = (avgSpeed) {
      setState(() => _averageSpeed = avgSpeed);
    };
    
    _trackingService.onDistanceChanged = (distance) {
      setState(() => _totalDistance = distance);
    };
    
    _trackingService.onAltitudeChanged = (altitude) {
      setState(() => _altitude = altitude);
    };
    
    _trackingService.onAccelerationChanged = (acceleration) {
      setState(() => _acceleration = acceleration);
    };
    
    // Start tracking
    _startTracking();
    
    // Start timer
    _startTimer();
  }
  
  Future<void> _initializeStorage() async {
    _localStorage = await LocalStorageService.getInstance();

    _loadCalibration();
  }
  
  // void _loadCalibration() async {
  //   if (_localStorage == null) return;
    
  //   final prefs = await SharedPreferences.getInstance();
  //   _calibrationOffsetX = prefs.getDouble('lean_calibration_x') ?? 0.0;
  //   _calibrationOffsetY = prefs.getDouble('lean_calibration_y') ?? 0.0;
  //   _calibrationOffsetZ = prefs.getDouble('lean_calibration_z') ?? 0.0;
  //   _isCalibrated = prefs.getBool('lean_is_calibrated') ?? false;
    
  //   if (mounted) {
  //     setState(() {});
      
  //     // Show calibration prompt if not calibrated
  //     if (!_isCalibrated) {
  //       Future.delayed(const Duration(seconds: 2), () {
  //         if (mounted) {
  //           _showCalibrationPrompt();
  //         }
  //       });
  //     }
  //   }
  // }
  
  // Future<void> _saveCalibration() async {
  //   if (_localStorage == null) return;
    
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.setDouble('lean_calibration_x', _calibrationOffsetX);
  //   await prefs.setDouble('lean_calibration_y', _calibrationOffsetY);
  //   await prefs.setDouble('lean_calibration_z', _calibrationOffsetZ);
  //   await prefs.setBool('lean_is_calibrated', _isCalibrated);
  // }
  
  void _startTracking() async {
    try {
      await _trackingService.startTracking();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting tracking: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _startTimer() {
    _rideTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _totalTime += const Duration(seconds: 1);
        if (_isRiding) {
          _activeRideTime += const Duration(seconds: 1);
        }
      });
    });
  }

  void _toggleOrientationLock() {
    setState(() {
      if (_isOrientationLocked) {
        // Unlock - allow all orientations
        _isOrientationLocked = false;
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      } else {
        // Lock to current orientation
        _isOrientationLocked = true;
        final isLandscape = MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;
        _isLockedToLandscape = isLandscape;
        
        if (isLandscape) {
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ]);
        } else {
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown,
          ]);
        }
      }
    });
  }

  @override
  void dispose() {
    _trackingService.dispose();
    _pulseController.dispose();
    _rideTimer?.cancel();
    
    // Reset orientation to portrait only when leaving this screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    
    super.dispose();
  }

List<Color> _getCalibrationColors() {
  switch (_calibrationStatus) {
    case AutoCalibrationStatus.calibrated:
      return [Color(0xFF4CAF50), Color(0xFF388E3C)];
    case AutoCalibrationStatus.collectingSamples:
      return [Color(0xFF2196F3), Color(0xFF1976D2)];
    case AutoCalibrationStatus.waitingForStability:
      return [Color(0xFFFFA726), Color(0xFFF57C00)];
    default:
      return [Color(0xFF9E9E9E), Color(0xFF757575)];
  }
}

String _getCalibrationTitle() {
  switch (_calibrationStatus) {
    case AutoCalibrationStatus.calibrated:
      return 'Calibrated ✓';
    case AutoCalibrationStatus.collectingSamples:
      return 'Calibrating...';
    case AutoCalibrationStatus.waitingForStability:
      return 'Detecting...';
    default:
      return 'Starting...';
  }
}

Widget _buildCalibrationIcon() {
  switch (_calibrationStatus) {
    case AutoCalibrationStatus.calibrated:
      return Icon(Icons.check_circle, color: Colors.white, size: 20);
    case AutoCalibrationStatus.collectingSamples:
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    case AutoCalibrationStatus.waitingForStability:
      return Icon(Icons.sensors, color: Colors.white, size: 20);
    default:
      return Icon(Icons.hourglass_empty, color: Colors.white, size: 20);
  }
}

// Update _loadCalibration to load saved calibration:

void _loadCalibration() async {
  if (_localStorage == null) return;
  
  final prefs = await SharedPreferences.getInstance();
  
  // Load all calibration vectors
  final refX = prefs.getDouble('lean_calibration_ref_x') ?? 0.0;
  final refY = prefs.getDouble('lean_calibration_ref_y') ?? 0.0;
  final refZ = prefs.getDouble('lean_calibration_ref_z') ?? 9.81;
  final fwdX = prefs.getDouble('lean_calibration_fwd_x') ?? 0.0;
  final fwdY = prefs.getDouble('lean_calibration_fwd_y') ?? 1.0;
  final fwdZ = prefs.getDouble('lean_calibration_fwd_z') ?? 0.0;
  _isCalibrated = prefs.getBool('lean_is_calibrated') ?? false;
  
  if (mounted) {
    setState(() {});
    
    // Load saved calibration into service
    if (_isCalibrated) {
      _trackingService.loadSavedCalibration(refX, refY, refZ, fwdX, fwdY, fwdZ);
    }
  }
}

Future<void> _saveCalibration() async {
  if (_localStorage == null) return;
  
  final prefs = await SharedPreferences.getInstance();
  
  // Save reference and forward vectors
  await prefs.setDouble('lean_calibration_ref_x', _trackingService.calibrationRefX);
  await prefs.setDouble('lean_calibration_ref_y', _trackingService.calibrationRefY);
  await prefs.setDouble('lean_calibration_ref_z', _trackingService.calibrationRefZ);
  await prefs.setDouble('lean_calibration_fwd_x', _trackingService.calibrationForwardX);
  await prefs.setDouble('lean_calibration_fwd_y', _trackingService.calibrationForwardY);
  await prefs.setDouble('lean_calibration_fwd_z', _trackingService.calibrationForwardZ);
  await prefs.setBool('lean_is_calibrated', true);
}
  


  // void _startCalibration() async {
  //   setState(() {
  //     _showCalibrationDialog = true;
  //   });
    
  //   // Show calibration overlay
  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (context) => _CalibrationOverlay(
  //       onCalibrationComplete: (offsetX, offsetY, offsetZ) {
  //         setState(() {
  //           _calibrationOffsetX = offsetX;
  //           _calibrationOffsetY = offsetY;
  //           _calibrationOffsetZ = offsetZ;
  //           _isCalibrated = true;
  //           _showCalibrationDialog = false;
  //         });
          
  //         // Apply calibration to tracking service
  //         _trackingService.setCalibration(_calibrationOffsetX, _calibrationOffsetY, _calibrationOffsetZ);
          
  //         _saveCalibration();
  //         Navigator.pop(context);
          
  //         // Show success message
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(
  //             content: Row(
  //               children: [
  //                 Icon(Icons.check_circle, color: Colors.white),
  //                 const SizedBox(width: 12),
  //                 Text('Calibration completed successfully!'),
  //               ],
  //             ),
  //             backgroundColor: Colors.green,
  //             behavior: SnackBarBehavior.floating,
  //             shape: RoundedRectangleBorder(
  //               borderRadius: BorderRadius.circular(12),
  //             ),
  //           ),
  //         );
  //       },
  //     ),
  //   );
  // }
  
double _getAdjustedLeanAngle() {
  // Just return the calculated lean angle from the service
  return _leanAngle;
}

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  Color get _angleColor {
    final abs = _getAdjustedLeanAngle().abs();
    if (abs < 15) return Colors.white;
    if (abs < 35) return const Color(0xFFFFA500);
    return const Color(0xFFFF0000);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              Colors.black,
              const Color(0xFF0A0A0A),
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenHeight = constraints.maxHeight;
              final screenWidth = constraints.maxWidth;
              
              // Detect orientation and update tracking service
              final isLandscape = screenWidth > screenHeight;
              if (_currentOrientation != (isLandscape ? Orientation.landscape : Orientation.portrait)) {
                _currentOrientation = isLandscape ? Orientation.landscape : Orientation.portrait;
                // _trackingService.setLandscapeMode(isLandscape);
              }
              
              // Calculate responsive sizes
              final isSmallDevice = screenHeight < 700;
              final isMediumDevice = screenHeight >= 700 && screenHeight < 850;
              
              // Responsive spacing
              final topPadding = isSmallDevice ? screenHeight * 0.02 : screenHeight * 0.03;
              final sectionSpacing = isSmallDevice ? screenHeight * 0.01 : screenHeight * 0.015;
              final bottomSpacing = isSmallDevice ? screenHeight * 0.015 : screenHeight * 0.02;
              
              // Responsive font sizes
              final angleFontSize = isSmallDevice ? screenWidth * 0.11 : screenWidth * 0.13;
              final statFontSize = isSmallDevice ? screenWidth * 0.06 : screenWidth * 0.07;
              final timeFontSize = isSmallDevice ? screenWidth * 0.055 : screenWidth * 0.065;
              
              // Motorcycle size
              final motorcycleSize = isSmallDevice ? screenWidth * 0.38 : screenWidth * 0.45;
              final gaugeSize = isSmallDevice ? screenWidth * 0.75 : screenWidth * 0.8;
              
              return Stack(
                children: [
              // Animated background glow effect
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 0.8 + (_pulseController.value * 0.2),
                          colors: [
                            _angleColor.withOpacity(0.03 * _pulseController.value),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Calibration button top left
// Calibration button top left
Positioned(
  top: 12,
  left: 12,
  child: Container(
    constraints: BoxConstraints(maxWidth: screenWidth * 0.6),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: _getCalibrationColors(),
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: _getCalibrationColors()[1].withOpacity(0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCalibrationIcon(),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _getCalibrationTitle(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_calibrationStatus != AutoCalibrationStatus.calibrated)
                Text(
                  _calibrationMessage,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 10,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        // Manual recalibrate button (only show when calibrated)
        if (_isCalibrated) ...[
          const SizedBox(width: 100),
          GestureDetector(
            onTap: () {
              print('Manual recalibration triggered');
              _trackingService.forceRecalibration();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Recalibrating... Hold upright and steady'),
                  duration: Duration(seconds: 2),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: const Icon(
              Icons.refresh,
              color: Colors.white,
              size: 18,
            ),
          ),
        ],
      ],
    ),
  ),
),


              
              // Orientation lock button top center
              Positioned(
                top: 12,
                left: screenWidth / 2 - 30,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isOrientationLocked
                        ? [Color(0xFF4CAF50), Color(0xFF388E3C)]
                        : [Color(0xFF9E9E9E), Color(0xFF757575)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: (_isOrientationLocked ? Color(0xFF388E3C) : Color(0xFF757575)).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _toggleOrientationLock,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          _isOrientationLocked 
                            ? (_isLockedToLandscape ? Icons.screen_lock_landscape : Icons.screen_lock_portrait)
                            : Icons.screen_rotation,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Cancel button top right
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF4444), Color(0xFFD32F2F)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD32F2F).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.05,
                          vertical: 12,
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Main content - Responsive layout
              if (isLandscape)
                // Landscape layout: GAUGE-FOCUSED with compact side panels
                Padding(
                  padding: EdgeInsets.only(top: 60, left: 8, right: 8, bottom: 16),
                  child: Row(
                    children: [
                      // Left side - Compact Stats
                      SizedBox(
                        width: screenWidth * 0.14,
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildCompactLandscapeStat('Active', _formatDuration(_activeRideTime), Icons.timer),
                              SizedBox(height: 8),
                              _buildCompactLandscapeStat('Total', _formatDuration(_totalTime), Icons.access_time),
                              SizedBox(height: 8),
                              _buildCompactLandscapeStat('Speed', '${_currentSpeed.toStringAsFixed(0)}', Icons.speed),
                              SizedBox(height: 8),
                              _buildCompactLandscapeStat('Dist', '${_totalDistance.toStringAsFixed(1)}', Icons.route),
                              SizedBox(height: 8),
                              _buildCompactLandscapeStat('Avg', '${_averageSpeed.toStringAsFixed(0)}', Icons.trending_up),
                            ],
                          ),
                        ),
                      ),
                      
                      SizedBox(width: 8),
                      
                      // Center - MASSIVE GAUGE - THE STAR!
                      Expanded(
                        child: Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Gauge - Make it as big as possible
                              Container(
                                width: screenHeight * 0.9,
                                height: screenHeight * 0.85,
                                child: CustomPaint(
                                  painter: _GaugePainter(_getAdjustedLeanAngle(), _angleColor),
                                ),
                              ),
                              // Angle and motorcycle
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                    decoration: BoxDecoration(
                                      color: _angleColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: _angleColor.withOpacity(0.4), width: 2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _angleColor.withOpacity(0.3),
                                          blurRadius: 25,
                                          spreadRadius: 3,
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      '${_getAdjustedLeanAngle().abs().toStringAsFixed(0)}°',
                                      style: TextStyle(
                                        fontSize: screenHeight * 0.15,
                                        fontWeight: FontWeight.w200,
                                        color: _angleColor,
                                        letterSpacing: 4,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                  Transform.rotate(
                                    angle: _getAdjustedLeanAngle() * 0.0174533,
                                    child: Image.network(
                                      'https://www.sparkexhaust.com/images/prodotti-new/67444b1d95f45.png',
                                      width: screenHeight * 0.30,
                                      height: screenHeight * 0.30,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'LEAN ANGLE',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 14,
                                      letterSpacing: 3,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      SizedBox(width: 8),
                      
                      // Right side - Compact More stats
                      SizedBox(
                        width: screenWidth * 0.14,
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildCompactLandscapeStat('Alt', '${_altitude.toStringAsFixed(0)}', Icons.terrain),
                              SizedBox(height: 8),
                              _buildCompactLandscapeStat('G-Force', '${_acceleration.toStringAsFixed(1)}', Icons.flash_on),
                              SizedBox(height: 16),
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _isCalibrated ? Colors.green.withOpacity(0.1) : Colors.amber.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _isCalibrated ? Colors.green.withOpacity(0.3) : Colors.amber.withOpacity(0.3),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      _isCalibrated ? Icons.check_circle : Icons.warning,
                                      color: _isCalibrated ? Colors.green : Colors.amber,
                                      size: 14,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      _isCalibrated ? 'Cal' : 'Not Cal',
                                      style: TextStyle(
                                        color: _isCalibrated ? Colors.green : Colors.amber,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                // Portrait layout: Original vertical design
                Column(
                  children: [
                    SizedBox(height: topPadding),
                    
                    // Timers
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.06,
                        vertical: isSmallDevice ? screenHeight * 0.015 : screenHeight * 0.02,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildTimeDisplay(_formatDuration(_activeRideTime), 'Active ride', timeFontSize, screenWidth),
                          Container(width: 1, height: screenHeight * 0.04, color: Colors.white.withOpacity(0.2)),
                          _buildTimeDisplay(_formatDuration(_totalTime), 'Total time', timeFontSize, screenWidth),
                        ],
                      ),
                    ),

                    SizedBox(height: sectionSpacing),

                    // Gauge (centered)
                    Expanded(
                      child: Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(
                              size: Size(gaugeSize, gaugeSize),
                              painter: _GaugePainter(_getAdjustedLeanAngle(), _angleColor),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _angleColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: _angleColor.withOpacity(0.3), width: 1),
                                  ),
                                  child: Text(
                                    '${_getAdjustedLeanAngle().abs().toStringAsFixed(0)}°',
                                    style: TextStyle(
                                      fontSize: angleFontSize,
                                      fontWeight: FontWeight.w200,
                                      color: _angleColor,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 12),
                                Transform.rotate(
                                  angle: _getAdjustedLeanAngle() * 0.0174533,
                                  child: Image.network(
                                    'https://www.sparkexhaust.com/images/prodotti-new/67444b1d95f45.png',
                                    width: motorcycleSize,
                                    height: motorcycleSize,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Label
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Text(
                        'Lean Angle',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: screenWidth * 0.035,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    
                    SizedBox(height: sectionSpacing),

                    // Stats strip
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildCompactStat(_totalDistance.toStringAsFixed(1), 'km', 'Distance', statFontSize, screenWidth),
                        _buildStatDivider(screenHeight),
                        _buildCompactStat(_altitude.toStringAsFixed(0), 'm', 'Altitude', statFontSize, screenWidth),
                        _buildStatDivider(screenHeight),
                        _buildCompactStat(_currentSpeed.toStringAsFixed(0), 'km/h', 'Speed', statFontSize, screenWidth),
                        _buildStatDivider(screenHeight),
                        _buildCompactStat(_averageSpeed.toStringAsFixed(0), 'km/h', 'Avg', statFontSize, screenWidth),
                      ],
                    ),
                  ),

                  SizedBox(height: sectionSpacing),

                  // Acceleration bar with premium styling
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                    child: Container(
                      padding: EdgeInsets.all(isSmallDevice ? screenWidth * 0.035 : screenWidth * 0.04),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.08),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Acceleration',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: screenWidth * 0.035,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: isSmallDevice ? screenHeight * 0.008 : screenHeight * 0.012),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.05),
                                      Colors.white.withOpacity(0.15),
                                      Colors.white.withOpacity(0.05),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              Container(
                                width: screenWidth * 0.14,
                                height: screenHeight * 0.04,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFE91E63), Color(0xFFFF4081)],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFE91E63).withOpacity(0.4),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: screenHeight * 0.01),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _acceleration.toStringAsFixed(2),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: statFontSize,
                                  fontWeight: FontWeight.w200,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 3),
                                child: Text(
                                  'm/s²',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: screenWidth * 0.03,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.02),

                  // Finish button with premium gradient
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                    child: Container(
                      width: double.infinity,
                      height: screenHeight * 0.065,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.white, Color(0xFFE0E0E0)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {},
                          borderRadius: BorderRadius.circular(16),
                          child: Center(
                            child: Text(
                              'FINISH RIDE',
                              style: TextStyle(
                                fontSize: screenWidth * 0.045,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.015),
                ],
              ),
            ],
          );
        },
      ),
    ),
  ));
}

  Widget _buildTimeDisplay(String time, String label, double timeFontSize, double screenWidth) {
    return Column(
      children: [
        Text(
          time,
          style: TextStyle(
            color: Colors.white,
            fontSize: timeFontSize,
            fontWeight: FontWeight.w200,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: screenWidth * 0.028,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
  
  Widget _buildCompactTimeDisplay(String time, String label, double screenWidth) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          time,
          style: TextStyle(
            color: Colors.white,
            fontSize: screenWidth * 0.045,
            fontWeight: FontWeight.w300,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: screenWidth * 0.025,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
  
  Widget _buildMiniStat(String value, String label, String unit, double screenWidth) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: screenWidth * 0.055,
                fontWeight: FontWeight.w300,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(width: 2),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                unit,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: screenWidth * 0.025,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: screenWidth * 0.028,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  
  Widget _buildLandscapeStatCard(String label, String value, IconData icon, double screenWidth) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCompactLandscapeStat(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.7), size: 16),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 8,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStat(String value, String unit, String label, double statFontSize, double screenWidth) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: statFontSize,
                fontWeight: FontWeight.w300,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              unit,
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: screenWidth * 0.028,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.35),
            fontSize: screenWidth * 0.026,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider(double screenHeight) {
    return Container(
      width: 1,
      height: screenHeight * 0.04,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.white.withOpacity(0.15),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double angle;
  final Color color;

  _GaugePainter(this.angle, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;

    // Draw outer subtle glow
    final glowPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    
    canvas.drawCircle(center, radius + 10, glowPaint);

    // Draw tick marks with gradient effect
    for (int i = -60; i <= 60; i += 5) {
      final radians = (i / 60) * math.pi * 0.75 - math.pi / 2;
      final isMajor = i % 15 == 0;
      final outerRadius = radius + 15;
      final innerRadius = radius - (isMajor ? 28 : 15);

      final outer = Offset(
        center.dx + outerRadius * math.cos(radians),
        center.dy + outerRadius * math.sin(radians),
      );
      final inner = Offset(
        center.dx + innerRadius * math.cos(radians),
        center.dy + innerRadius * math.sin(radians),
      );

      // Gradient for tick marks
      final tickPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withOpacity(0.4),
            Colors.white.withOpacity(0.15),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromPoints(outer, inner))
        ..strokeWidth = isMajor ? 3 : 2
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(outer, inner, tickPaint);
    }

    // Draw white dots with glow
    final dotPaint = Paint()..color = Colors.white.withOpacity(0.6);
    final dotGlowPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    
    for (int i = -60; i <= 60; i += 5) {
      final radians = (i / 60) * math.pi * 0.75 - math.pi / 2;
      final dotRadius = radius - 50;
      final dotPos = Offset(
        center.dx + dotRadius * math.cos(radians),
        center.dy + dotRadius * math.sin(radians),
      );
      canvas.drawCircle(dotPos, 3, dotGlowPaint);
      canvas.drawCircle(dotPos, 2, dotPaint);
    }

    // Draw active needle with glow
    if (angle.abs() > 1) {
      final needleAngle = (angle / 60) * math.pi * 0.75 - math.pi / 2;
      final needleEnd = Offset(
        center.dx + (radius + 15) * math.cos(needleAngle),
        center.dy + (radius + 15) * math.sin(needleAngle),
      );

      // Needle glow
      final needleGlowPaint = Paint()
        ..color = color.withOpacity(0.4)
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      
      canvas.drawLine(center, needleEnd, needleGlowPaint);

      // Needle gradient
      final needlePaint = Paint()
        ..shader = LinearGradient(
          colors: [color, color.withOpacity(0.6)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromPoints(center, needleEnd))
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(center, needleEnd, needlePaint);
      
      // Center dot
      canvas.drawCircle(center, 8, Paint()..color = color.withOpacity(0.3));
      canvas.drawCircle(center, 5, Paint()..color = color);
    }

    // Draw horizontal line with gradient
    final horizontalPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          Colors.white.withOpacity(0.2),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(20, center.dy, size.width - 40, 1))
      ..strokeWidth = 1;
    
    canvas.drawLine(
      Offset(20, center.dy),
      Offset(size.width - 20, center.dy),
      horizontalPaint,
    );
  }

  @override
  bool shouldRepaint(_GaugePainter old) => 
      old.angle != angle || old.color != color;
}

// Calibration Overlay Widget
class _CalibrationOverlay extends StatefulWidget {
  final Function(double offsetX, double offsetY, double offsetZ) onCalibrationComplete;
  final bool isLandscape;

  const _CalibrationOverlay({
    required this.onCalibrationComplete,
    this.isLandscape = false,
  });

  @override
  State<_CalibrationOverlay> createState() => _CalibrationOverlayState();
}

class _CalibrationOverlayState extends State<_CalibrationOverlay> with TickerProviderStateMixin {
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  
  // Current sensor values (filtered)
  double _filteredAccelX = 0.0;
  double _filteredAccelY = 0.0;
  double _filteredAccelZ = 9.81;
  double _gyroX = 0.0;
  double _gyroY = 0.0;
  double _gyroZ = 0.0;
  
  // Raw sensor values
  double _rawAccelX = 0.0;
  double _rawAccelY = 0.0;
  double _rawAccelZ = 0.0;
  
  // Real-time angle calculations
  double _currentLeanAngle = 0.0;
  double _currentPitch = 0.0;
  double _currentRoll = 0.0;
  
  // Stability tracking
  bool _isStable = false;
  int _stableCount = 0;
  List<AccelerometerEvent> _samples = [];
  
  // Calibration state
  bool _isCalibrating = false;
  double _calibrationProgress = 0.0;
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  
  // Low-pass filter coefficient
  static const double ALPHA = 0.85;
  
  // Thresholds for stability (in m/s²)
  static const double _stabilityThreshold = 0.3;
  static const double _gyroStabilityThreshold = 0.08;
  static const int _requiredStableReadings = 40; // ~0.7 seconds at 60Hz
  static const int _calibrationSamples = 120;
  
  // Orientation tracking
  bool _detectedLandscape = false;

  @override
  void initState() {
    super.initState();
    
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    
    _startMonitoring();
  }

  void _startMonitoring() {
    // Monitor accelerometer for stability and real-time angle display
    _accelerometerSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
      if (!mounted) return;
      
      setState(() {
        // Store raw values
        double prevX = _rawAccelX;
        double prevY = _rawAccelY;
        double prevZ = _rawAccelZ;
        
        _rawAccelX = event.x;
        _rawAccelY = event.y;
        _rawAccelZ = event.z;
        
        // Apply low-pass filter for smoother readings
        _filteredAccelX = ALPHA * _filteredAccelX + (1 - ALPHA) * event.x;
        _filteredAccelY = ALPHA * _filteredAccelY + (1 - ALPHA) * event.y;
        _filteredAccelZ = ALPHA * _filteredAccelZ + (1 - ALPHA) * event.z;
        
        // Detect orientation based on gravity
        _detectedLandscape = _filteredAccelZ.abs() < _filteredAccelY.abs();
        
        // Calculate real-time angles for visual feedback
        _currentRoll = math.atan2(_filteredAccelX, math.sqrt(_filteredAccelY * _filteredAccelY + _filteredAccelZ * _filteredAccelZ)) * 180 / math.pi;
        _currentPitch = math.atan2(_filteredAccelY, math.sqrt(_filteredAccelX * _filteredAccelX + _filteredAccelZ * _filteredAccelZ)) * 180 / math.pi;
        
        // Calculate lean angle based on detected orientation
        if (_detectedLandscape) {
          _currentLeanAngle = _currentRoll;
        } else {
          _currentLeanAngle = _currentRoll;
        }
        
        // Check if device is stable (minimal movement)
        double deltaX = (event.x - prevX).abs();
        double deltaY = (event.y - prevY).abs();
        double deltaZ = (event.z - prevZ).abs();
        
        bool currentlyStable = deltaX < _stabilityThreshold && 
                               deltaY < _stabilityThreshold && 
                               deltaZ < _stabilityThreshold &&
                               _gyroX.abs() < _gyroStabilityThreshold &&
                               _gyroY.abs() < _gyroStabilityThreshold &&
                               _gyroZ.abs() < _gyroStabilityThreshold;
        
        if (currentlyStable) {
          _stableCount++;
          if (_stableCount >= _requiredStableReadings && !_isStable) {
            _isStable = true;
            _onDeviceStable();
          }
        } else {
          _stableCount = 0;
          _isStable = false;
        }
        
        // Collect samples during calibration
        if (_isCalibrating) {
          _samples.add(event);
          _calibrationProgress = (_samples.length / _calibrationSamples).clamp(0.0, 1.0);
          _progressController.animateTo(_calibrationProgress);
          
          if (_samples.length >= _calibrationSamples) {
            _completeCalibration();
          }
        }
      });
    });
    
    // Monitor gyroscope for rotation
    _gyroscopeSubscription = gyroscopeEvents.listen((GyroscopeEvent event) {
      if (!mounted) return;
      setState(() {
        _gyroX = event.x;
        _gyroY = event.y;
        _gyroZ = event.z;
      });
    });
  }

  void _onDeviceStable() {
    // Device became stable, user can now start calibration
    if (mounted && !_isCalibrating) {
      setState(() {});
    }
  }

  void _startCalibrating() {
    if (!_isStable) return;
    
    setState(() {
      _isCalibrating = true;
      _samples.clear();
      _calibrationProgress = 0.0;
    });
  }

  void _completeCalibration() {
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    
    if (_samples.isEmpty) {
      widget.onCalibrationComplete(0.0, 0.0, 0.0);
      return;
    }

    // Calculate average values
    double avgX = 0.0;
    double avgY = 0.0;
    double avgZ = 0.0;

    for (var sample in _samples) {
      avgX += sample.x;
      avgY += sample.y;
      avgZ += sample.z;
    }

    avgX /= _samples.length;
    avgY /= _samples.length;
    avgZ /= _samples.length;

    // Calculate lean angle offset
    // When phone is upright in landscape: X axis is lean, Z is gravity
    double leanAngleOffset = math.atan2(avgX, math.sqrt(avgY * avgY + avgZ * avgZ)) * 180 / math.pi;

    widget.onCalibrationComplete(leanAngleOffset, avgY, avgZ);
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _progressController.dispose();
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  Color _getStatusColor() {
    if (_isCalibrating) return Colors.green;
    if (_isStable) return Colors.blue;
    return Colors.amber;
  }

  String _getStatusText() {
    if (_isCalibrating) return 'Calibrating...';
    if (_isStable) return 'Device Stable - Ready!';
    return 'Hold Device Still';
  }

  IconData _getStatusIcon() {
    if (_isCalibrating) return Icons.check_circle;
    if (_isStable) return Icons.verified;
    return Icons.pan_tool;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Material(
      color: Colors.black.withOpacity(0.95),
      child: SafeArea(
        child: Stack(
          children: [
            
            // Animated background gradient
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 0.8 + (_pulseController.value * 0.3),
                        colors: [
                          statusColor.withOpacity(0.1 * _pulseController.value),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Close button
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.close, color: Colors.white, size: 28),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            
            // Main content
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      'CALIBRATION',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Find Your Zero Point',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 14,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Real-time visual angle indicator
                    _buildAngleVisualizer(statusColor),
                    
                    const SizedBox(height: 32),
                    
                    // Status indicator
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor, width: 2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_getStatusIcon(), color: statusColor, size: 24),
                          const SizedBox(width: 12),
                          Text(
                            _getStatusText(),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  
                    // Instructions
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Tilt device to find your zero angle',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '• Hold phone as you would while riding\n'
                            '• Adjust tilt until angle shows ~0°\n'
                            '• Keep still until stable indicator turns blue\n'
                            '• Tap calibrate when ready',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Orientation indicator
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (_detectedLandscape ? Colors.green : Colors.orange).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: (_detectedLandscape ? Colors.green : Colors.orange).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _detectedLandscape ? Icons.stay_current_landscape : Icons.stay_current_portrait,
                            color: _detectedLandscape ? Colors.green : Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Detected: ${_detectedLandscape ? 'LANDSCAPE' : 'PORTRAIT'}',
                            style: TextStyle(
                              color: _detectedLandscape ? Colors.green : Colors.orange,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  
                  // Real-time stability indicator
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Stability:',
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                            Text(
                              '${(_stableCount / _requiredStableReadings * 100).clamp(0, 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                color: _isStable ? Colors.green : Colors.amber,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: (_stableCount / _requiredStableReadings).clamp(0.0, 1.0),
                            backgroundColor: Colors.white.withOpacity(0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _isStable ? Colors.green : Colors.amber,
                            ),
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Calibration progress
                  if (_isCalibrating) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Calibration Progress:',
                                style: TextStyle(color: Colors.green, fontSize: 14),
                              ),
                              Text(
                                '${(_calibrationProgress * 100).toStringAsFixed(0)}%',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: AnimatedBuilder(
                              animation: _progressController,
                              builder: (context, child) {
                                return LinearProgressIndicator(
                                  value: _progressController.value,
                                  backgroundColor: Colors.white.withOpacity(0.1),
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                                  minHeight: 8,
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Samples: ${_samples.length}/$_calibrationSamples',
                            style: TextStyle(color: Colors.green.shade200, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                    // Action Button
                    if (!_isCalibrating)
                      Container(
                        width: double.infinity,
                        constraints: BoxConstraints(maxWidth: 400),
                        child: ElevatedButton(
                          onPressed: _isStable ? _startCalibrating : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isStable ? Colors.blue : Colors.grey.shade700,
                            disabledBackgroundColor: Colors.grey.shade800,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                            elevation: _isStable ? 8 : 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isStable ? Icons.check_circle : Icons.access_time,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _isStable ? 'START CALIBRATION' : 'WAITING...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAngleVisualizer(Color statusColor) {
    return Container(
      width: 280,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer circle with angle marks
          CustomPaint(
            size: Size(280, 280),
            painter: _AngleGaugePainter(statusColor),
          ),
          
          // Center alignment target
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 100 + (_pulseController.value * 10),
                height: 100 + (_pulseController.value * 10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: statusColor.withOpacity(0.5),
                    width: 2,
                  ),
                ),
              );
            },
          ),
          
          // Inner target circle
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isStable ? Colors.green.withOpacity(0.2) : Colors.amber.withOpacity(0.2),
              border: Border.all(
                color: _isStable ? Colors.green : Colors.amber,
                width: 3,
              ),
            ),
            child: Center(
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isStable ? Colors.green : Colors.amber,
                ),
              ),
            ),
          ),
          
          // Device indicator (tilts with actual device)
          Transform.rotate(
            angle: _currentLeanAngle * math.pi / 180,
            child: Container(
              width: 80,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue, width: 3),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 50,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Angle display
          Positioned(
            bottom: 20,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor, width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_currentLeanAngle.toStringAsFixed(1)}°',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for angle gauge
class _AngleGaugePainter extends CustomPainter {
  final Color color;
  
  _AngleGaugePainter(this.color);
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Draw outer circle
    final outerPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius - 10, outerPaint);
    
    // Draw angle markers every 15 degrees
    for (int angle = 0; angle < 360; angle += 15) {
      final isCardinal = angle % 90 == 0;
      final isMajor = angle % 30 == 0;
      
      final angleRad = angle * math.pi / 180;
      final startRadius = radius - (isCardinal ? 25 : (isMajor ? 20 : 15));
      final endRadius = radius - 10;
      
      final start = Offset(
        center.dx + startRadius * math.cos(angleRad - math.pi / 2),
        center.dy + startRadius * math.sin(angleRad - math.pi / 2),
      );
      
      final end = Offset(
        center.dx + endRadius * math.cos(angleRad - math.pi / 2),
        center.dy + endRadius * math.sin(angleRad - math.pi / 2),
      );
      
      final linePaint = Paint()
        ..color = color.withOpacity(isCardinal ? 0.8 : (isMajor ? 0.6 : 0.3))
        ..strokeWidth = isCardinal ? 3 : (isMajor ? 2 : 1);
      
      canvas.drawLine(start, end, linePaint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


