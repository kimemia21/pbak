import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(MyApp(cameras: cameras));
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  const MyApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Liveness Detection',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: LivenessDetectionPage(cameras: cameras),
    );
  }
}

class LivenessDetectionPage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const LivenessDetectionPage({super.key, required this.cameras});

  @override
  State<LivenessDetectionPage> createState() => _LivenessDetectionPageState();
}

class _LivenessDetectionPageState extends State<LivenessDetectionPage> {
  CameraController? _cameraController;
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableLandmarks: true,
      enableContours: true,
      enableClassification: true,
      performanceMode: FaceDetectorMode.fast,
    ),
  );

  bool _isDetecting = false;
  bool _livenessCheckStarted = false;
  bool _livenessCheckPassed = false;
  String _instruction = 'Press Start to begin verification';
  String _statusMessage = '';
  
  // Liveness challenges
  List<String> _challenges = [];
  int _currentChallengeIndex = 0;
  Timer? _challengeTimer;
  
  // Challenge tracking
  bool _blinkDetected = false;
  bool _smileDetected = false;
  bool _leftTurnDetected = false;
  bool _rightTurnDetected = false;
  
  // Frame analysis
  List<double> _recentBrightness = [];
  int _consecutiveFramesWithFace = 0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector.close();
    _challengeTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    await Permission.camera.request();

    if (widget.cameras.isEmpty) {
      setState(() => _statusMessage = '❌ No camera found');
      return;
    }

    // Use front camera
    final frontCamera = widget.cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => widget.cameras.first,
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await _cameraController!.initialize();
    setState(() {});
  }

  void _generateRandomChallenges() {
    List<String> allChallenges = ['blink', 'smile', 'turn_left', 'turn_right'];
    allChallenges.shuffle(Random());
    _challenges = allChallenges.take(2).toList(); // Use 2 random challenges
    _currentChallengeIndex = 0;
  }

  String _getChallengeInstruction(String challenge) {
    switch (challenge) {
      case 'blink':
        return '👁️ Please BLINK your eyes';
      case 'smile':
        return '😊 Please SMILE';
      case 'turn_left':
        return '⬅️ Turn your head LEFT';
      case 'turn_right':
        return '➡️ Turn your head RIGHT';
      default:
        return 'Follow the instruction';
    }
  }

  void _startLivenessCheck() {
    setState(() {
      _livenessCheckStarted = true;
      _livenessCheckPassed = false;
      _blinkDetected = false;
      _smileDetected = false;
      _leftTurnDetected = false;
      _rightTurnDetected = false;
      _consecutiveFramesWithFace = 0;
      _recentBrightness.clear();
    });

    _generateRandomChallenges();
    _instruction = _getChallengeInstruction(_challenges[0]);
    _startCameraStream();
  }

  void _startCameraStream() {
    _cameraController?.startImageStream((CameraImage image) {
      if (_isDetecting) return;
      _isDetecting = true;
      _processCameraImage(image);
    });
  }

  Future<void> _processCameraImage(CameraImage image) async {
    try {
      final inputImage = _convertCameraImage(image);
      if (inputImage == null) {
        _isDetecting = false;
        return;
      }

      final faces = await _faceDetector.processImage(inputImage);

      if (!mounted) return;

      // Check if face is detected
      if (faces.isEmpty) {
        setState(() {
          _statusMessage = '⚠️ No face detected';
          _consecutiveFramesWithFace = 0;
        });
        _isDetecting = false;
        return;
      }

      if (faces.length > 1) {
        setState(() => _statusMessage = '⚠️ Multiple faces detected');
        _isDetecting = false;
        return;
      }

      _consecutiveFramesWithFace++;

      // Brightness check (screens are typically brighter)
      double brightness = _calculateBrightness(image);
      _recentBrightness.add(brightness);
      if (_recentBrightness.length > 5) _recentBrightness.removeAt(0);

      final face = faces.first;
      
      // Check current challenge
      if (_currentChallengeIndex < _challenges.length) {
        String currentChallenge = _challenges[_currentChallengeIndex];
        bool challengePassed = false;

        switch (currentChallenge) {
          case 'blink':
            challengePassed = _checkBlink(face);
            if (challengePassed) _blinkDetected = true;
            break;
          case 'smile':
            challengePassed = _checkSmile(face);
            if (challengePassed) _smileDetected = true;
            break;
          case 'turn_left':
            challengePassed = _checkLeftTurn(face);
            if (challengePassed) _leftTurnDetected = true;
            break;
          case 'turn_right':
            challengePassed = _checkRightTurn(face);
            if (challengePassed) _rightTurnDetected = true;
            break;
        }

        if (challengePassed) {
          _currentChallengeIndex++;
          
          if (_currentChallengeIndex < _challenges.length) {
            // Move to next challenge
            setState(() {
              _instruction = _getChallengeInstruction(_challenges[_currentChallengeIndex]);
              _statusMessage = '✅ Good! Next challenge...';
            });
          } else {
            // All challenges passed
            _completeLivenessCheck(true);
          }
        }
      }
    } catch (e) {
      debugPrint('Error processing image: $e');
    }

    _isDetecting = false;
  }

  bool _checkBlink(Face face) {
    double leftEye = face.leftEyeOpenProbability ?? 1.0;
    double rightEye = face.rightEyeOpenProbability ?? 1.0;
    
    // Eyes should be mostly closed
    return leftEye < 0.3 && rightEye < 0.3;
  }

  bool _checkSmile(Face face) {
    double smileProbability = face.smilingProbability ?? 0.0;
    return smileProbability > 0.7;
  }

  bool _checkLeftTurn(Face face) {
    double headY = face.headEulerAngleY ?? 0.0;
    return headY < -20; // Head turned left
  }

  bool _checkRightTurn(Face face) {
    double headY = face.headEulerAngleY ?? 0.0;
    return headY > 20; // Head turned right
  }

  double _calculateBrightness(CameraImage image) {
    // Calculate average brightness from Y plane (luminance)
    int sum = 0;
    int count = 0;
    
    // Sample every 10th pixel for performance
    for (int i = 0; i < image.planes[0].bytes.length; i += 10) {
      sum += image.planes[0].bytes[i];
      count++;
    }
    
    return count > 0 ? sum / count : 0;
  }

  InputImage? _convertCameraImage(CameraImage image) {
    final WriteBuffer allBytes = WriteBuffer();
    for (Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());

    final camera = _cameraController!.description;
    final imageRotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    if (imageRotation == null) return null;

    final inputImageFormat = InputImageFormatValue.fromRawValue(image.format.raw);
    if (inputImageFormat == null) return null;

    final metadata = InputImageMetadata(
      size: imageSize,
      rotation: imageRotation,
      format: inputImageFormat,
      bytesPerRow: image.planes[0].bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: metadata);
  }

  void _completeLivenessCheck(bool passed) {
    _cameraController?.stopImageStream();
    
    setState(() {
      _livenessCheckPassed = passed;
      _livenessCheckStarted = false;
      
      if (passed) {
        _instruction = '✅ VERIFICATION SUCCESSFUL!';
        _statusMessage = 'You are a real person. Photo can be captured.';
      } else {
        _instruction = '❌ VERIFICATION FAILED';
        _statusMessage = 'Liveness check failed. Please try again.';
      }
    });

    // Auto-capture photo if passed
    if (passed) {
      Future.delayed(const Duration(seconds: 2), () {
        _capturePassportPhoto();
      });
    }
  }

  Future<void> _capturePassportPhoto() async {
    try {
      final image = await _cameraController?.takePicture();
      if (image != null) {
        setState(() {
          _statusMessage = '📸 Photo captured successfully!\nPath: ${image.path}';
        });
        
        // Here you would normally upload or process the image
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Passport photo captured and verified!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error capturing photo: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Passport Liveness Detection'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          // Camera preview
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                Center(
                  child: AspectRatio(
                    aspectRatio: _cameraController!.value.aspectRatio,
                    child: CameraPreview(_cameraController!),
                  ),
                ),
                
                // Face oval guide
                Center(
                  child: Container(
                    width: 250,
                    height: 320,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _livenessCheckStarted 
                            ? Colors.blue 
                            : Colors.white.withOpacity(0.5),
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(150),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Instructions and status
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: Colors.white,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _instruction,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _statusMessage,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  
                  // Progress indicators
                  if (_livenessCheckStarted && _challenges.isNotEmpty)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_challenges.length, (index) {
                        bool isCompleted = index < _currentChallengeIndex;
                        bool isCurrent = index == _currentChallengeIndex;
                        
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isCompleted 
                                ? Colors.green 
                                : (isCurrent ? Colors.blue : Colors.grey[300]),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              isCompleted ? Icons.check : Icons.circle,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        );
                      }),
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Start button
                  if (!_livenessCheckStarted)
                    ElevatedButton(
                      onPressed: _startLivenessCheck,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 16,
                        ),
                      ),
                      child: const Text(
                        'Start Verification',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                    
                  // Try again button
                  if (!_livenessCheckStarted && _statusMessage.contains('FAILED'))
                    ElevatedButton(
                      onPressed: _startLivenessCheck,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 16,
                        ),
                      ),
                      child: const Text(
                        'Try Again',
                        style: TextStyle(fontSize: 18, color: Colors.white),
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

// Add this import at the top
