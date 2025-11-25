import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_exif_rotation/flutter_exif_rotation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:io';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(MyApp(cameras: cameras));
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  const MyApp({Key? key, required this.cameras}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rider Verification Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: VerificationTestPage(cameras: cameras),
    );
  }
}

class VerificationTestPage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const VerificationTestPage({Key? key, required this.cameras}) : super(key: key);

  @override
  State<VerificationTestPage> createState() => _VerificationTestPageState();
}

class _VerificationTestPageState extends State<VerificationTestPage> {
  final ImagePicker _picker = ImagePicker();
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableLandmarks: true,
      enableContours: true,
      enableClassification: true,
    ),
  );
  final TextRecognizer _textRecognizer = TextRecognizer();

  File? _currentImage;
  String _resultText = 'No results yet';
  bool _isProcessing = false;

  @override
  void dispose() {
    _faceDetector.close();
    _textRecognizer.close();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.camera,
      Permission.storage,
    ].request();
  }

  // 1️⃣ ENHANCED PASSPORT PHOTO TEST - With Liveness Detection
  Future<void> _testPassportPhoto() async {
    await _requestPermissions();
    
    if (!mounted) return;
    
    // Navigate to liveness detection screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LivenessDetectionScreen(
          camera: widget.cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
            orElse: () => widget.cameras.first,
          ),
          faceDetector: _faceDetector,
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _currentImage = result['image'];
        _resultText = result['resultText'];
      });
    }
  }

  // 2️⃣ REGISTRATION PLATE TEST - OCR
  Future<void> _testRegistrationPlate() async {
    setState(() {
      _isProcessing = true;
      _resultText = 'Processing registration plate...';
    });

    try {
      await _requestPermissions();

      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
      );

      if (photo == null) {
        setState(() {
          _resultText = 'No photo captured';
          _isProcessing = false;
        });
        return;
      }

      File rotatedImage = await FlutterExifRotation.rotateImage(path: photo.path);
      setState(() => _currentImage = rotatedImage);

      final inputImage = InputImage.fromFile(rotatedImage);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

      String result = '✅ REGISTRATION PLATE TEST\n\n';
      result += 'Text blocks found: ${recognizedText.blocks.length}\n\n';

      List<String> potentialPlates = [];
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          String text = line.text.replaceAll(' ', '').toUpperCase();
          if (text.length >= 5 && text.length <= 10) {
            potentialPlates.add(text);
          }
        }
      }

      result += '📋 Full detected text:\n${recognizedText.text}\n\n';
      result += '🔍 Potential plate numbers:\n';
      if (potentialPlates.isEmpty) {
        result += '❌ No plate patterns detected\n';
      } else {
        for (String plate in potentialPlates) {
          result += '• $plate\n';
        }
      }

      setState(() {
        _resultText = result;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _resultText = '❌ Error: $e';
        _isProcessing = false;
      });
    }
  }

  // 3️⃣ INSURANCE DOCUMENT TEST - OCR
  Future<void> _testInsuranceDocument() async {
    setState(() {
      _isProcessing = true;
      _resultText = 'Processing insurance document...';
    });

    try {
      await _requestPermissions();

      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
      );

      if (photo == null) {
        setState(() {
          _resultText = 'No document selected';
          _isProcessing = false;
        });
        return;
      }

      File rotatedImage = await FlutterExifRotation.rotateImage(path: photo.path);
      setState(() => _currentImage = rotatedImage);

      final inputImage = InputImage.fromFile(rotatedImage);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

      String result = '✅ INSURANCE DOCUMENT TEST\n\n';
      result += 'Text blocks found: ${recognizedText.blocks.length}\n\n';

      String fullText = recognizedText.text.toLowerCase();
      List<String> insuranceKeywords = ['insurance', 'policy', 'cover', 'premium'];
      List<String> foundKeywords = [];

      for (String keyword in insuranceKeywords) {
        if (fullText.contains(keyword)) {
          foundKeywords.add(keyword);
        }
      }

      result += '📋 Insurance keywords found: ${foundKeywords.join(", ")}\n\n';

      RegExp policyPattern = RegExp(r'[A-Z0-9]{8,}');
      List<String> potentialPolicies = [];

      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          Iterable<Match> matches = policyPattern.allMatches(line.text);
          for (Match match in matches) {
            potentialPolicies.add(match.group(0)!);
          }
        }
      }

      result += '🔍 Potential policy numbers:\n';
      if (potentialPolicies.isEmpty) {
        result += '❌ No policy numbers detected\n';
      } else {
        for (String policy in potentialPolicies.take(5)) {
          result += '• $policy\n';
        }
      }

      result += '\n📄 Full text preview:\n${recognizedText.text.substring(0, recognizedText.text.length > 200 ? 200 : recognizedText.text.length)}...';

      setState(() {
        _resultText = result;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _resultText = '❌ Error: $e';
        _isProcessing = false;
      });
    }
  }

  // 4️⃣ IMAGE CAPTURE TEST
  Future<void> _testImageCapture() async {
    setState(() {
      _isProcessing = true;
      _resultText = 'Testing image capture...';
    });

    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.gallery);

      if (photo == null) {
        setState(() {
          _resultText = 'No image selected';
          _isProcessing = false;
        });
        return;
      }

      File imageFile = File(photo.path);
      final fileSize = await imageFile.length();
      
      setState(() => _currentImage = imageFile);

      String result = '✅ IMAGE CAPTURE TEST\n\n';
      result += 'File path: ${photo.path}\n';
      result += 'File size: ${(fileSize / 1024).toStringAsFixed(2)} KB\n';
      result += 'Name: ${photo.name}\n';
      result += '✅ Image captured successfully';

      setState(() {
        _resultText = result;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _resultText = '❌ Error: $e';
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rider Verification Tests'),
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_currentImage != null)
              Container(
                height: 250,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(_currentImage!, fit: BoxFit.cover),
                ),
              ),

            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _testPassportPhoto,
              icon: const Icon(Icons.face),
              label: const Text('Test Passport Photo (Live Detection)'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _testRegistrationPlate,
              icon: const Icon(Icons.motorcycle),
              label: const Text('Test Registration Plate (OCR)'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _testInsuranceDocument,
              icon: const Icon(Icons.description),
              label: const Text('Test Insurance Document (OCR)'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _testImageCapture,
              icon: const Icon(Icons.image),
              label: const Text('Test Image Capture'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: _isProcessing
                  ? const Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Processing...'),
                        ],
                      ),
                    )
                  : Text(
                      _resultText,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// 🎯 LIVENESS DETECTION SCREEN
class LivenessDetectionScreen extends StatefulWidget {
  final CameraDescription camera;
  final FaceDetector faceDetector;

  const LivenessDetectionScreen({
    Key? key,
    required this.camera,
    required this.faceDetector,
  }) : super(key: key);

  @override
  State<LivenessDetectionScreen> createState() => _LivenessDetectionScreenState();
}

class _LivenessDetectionScreenState extends State<LivenessDetectionScreen> {
  CameraController? _controller;
  bool _isDetecting = false;
  String _instructions = 'Position your face in the frame';
  Color _frameColor = Colors.orange;
  
  // Liveness detection stages
  int _currentStage = 0;
  final List<String> _stages = [
    'Look straight at the camera',
    'Turn your head LEFT',
    'Turn your head RIGHT',
    'Smile!',
  ];
  
  List<bool> _stagesCompleted = [false, false, false, false];
  int _stableFrameCount = 0;
  double? _lastHeadAngle;
  
  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21, // Android compatible format
    );

    await _controller!.initialize();
    
    if (!mounted) return;
    
    setState(() {
      _instructions = _stages[_currentStage];
    });

    // Start image stream for face detection
    _controller!.startImageStream(_processCameraImage);
  }

  void _processCameraImage(CameraImage image) async {
    if (_isDetecting) return;
    _isDetecting = true;

    try {
      final inputImage = _convertCameraImage(image);
      if (inputImage == null) {
        _isDetecting = false;
        return;
      }

      final List<Face> faces = await widget.faceDetector.processImage(inputImage);

      if (mounted) {
        _analyzeFaces(faces);
      }
    } catch (e) {
      print('Detection error: $e');
    }

    _isDetecting = false;
  }

  InputImage? _convertCameraImage(CameraImage image) {
    final camera = widget.camera;
    
    // Determine rotation
    InputImageRotation rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotation.rotation270deg;
    } else {
      // Android
      final sensorOrientation = camera.sensorOrientation;
      if (camera.lensDirection == CameraLensDirection.front) {
        rotation = InputImageRotation.rotation270deg;
      } else {
        rotation = InputImageRotation.rotation90deg;
      }
    }

    // Determine format
    InputImageFormat format;
    if (Platform.isAndroid) {
      format = InputImageFormat.nv21;
    } else if (Platform.isIOS) {
      format = InputImageFormat.bgra8888;
    } else {
      return null;
    }

    // Get plane data
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final inputImageData = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: format,
      bytesPerRow: image.planes.isNotEmpty ? image.planes[0].bytesPerRow : 0,
    );

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: inputImageData,
    );
  }

  void _analyzeFaces(List<Face> faces) {
    if (faces.isEmpty) {
      setState(() {
        _instructions = '❌ No face detected\nMove closer to camera';
        _frameColor = Colors.red;
      });
      _stableFrameCount = 0;
      return;
    }

    if (faces.length > 1) {
      setState(() {
        _instructions = '❌ Multiple faces detected!\nOnly one person allowed';
        _frameColor = Colors.red;
      });
      _stableFrameCount = 0;
      return;
    }

    final face = faces.first;
    final leftEye = face.leftEyeOpenProbability ?? 0;
    final rightEye = face.rightEyeOpenProbability ?? 0;
    
    // Check if eyes are open (basic liveness check)
    if (leftEye < 0.3 || rightEye < 0.3) {
      setState(() {
        _instructions = '❌ Keep both eyes open\n${_stages[_currentStage]}';
        _frameColor = Colors.orange;
      });
      _stableFrameCount = 0;
      return;
    }

    bool stageCompleted = false;

    switch (_currentStage) {
      case 0: // Look straight
        final headY = face.headEulerAngleY?.abs() ?? 999;
        final headZ = face.headEulerAngleZ?.abs() ?? 999;
        if (headY < 15 && headZ < 15) {
          _stableFrameCount++;
          setState(() {
            _instructions = 'Hold still... ${_stableFrameCount}/15';
            _frameColor = Colors.yellow;
          });
          if (_stableFrameCount >= 15) {
            stageCompleted = true;
          }
        } else {
          _stableFrameCount = 0;
          setState(() {
            _instructions = 'Face the camera directly\nY: ${headY.toStringAsFixed(1)}° Z: ${headZ.toStringAsFixed(1)}°';
            _frameColor = Colors.orange;
          });
        }
        break;

      case 1: // Turn LEFT (positive angle)
        final headY = face.headEulerAngleY ?? 0;
        if (headY > 25) {
          _stableFrameCount++;
          setState(() {
            _instructions = 'Good! Hold it... ${_stableFrameCount}/10';
            _frameColor = Colors.yellow;
          });
          if (_stableFrameCount >= 10) {
            stageCompleted = true;
          }
        } else {
          _stableFrameCount = 0;
          setState(() {
            _instructions = 'Turn your head LEFT more\nAngle: ${headY.toStringAsFixed(1)}° (need >25°)';
            _frameColor = Colors.orange;
          });
        }
        break;

      case 2: // Turn RIGHT (negative angle)
        final headY = face.headEulerAngleY ?? 0;
        if (headY < -25) {
          _stableFrameCount++;
          setState(() {
            _instructions = 'Good! Hold it... ${_stableFrameCount}/10';
            _frameColor = Colors.yellow;
          });
          if (_stableFrameCount >= 10) {
            stageCompleted = true;
          }
        } else {
          _stableFrameCount = 0;
          setState(() {
            _instructions = 'Turn your head RIGHT more\nAngle: ${headY.toStringAsFixed(1)}° (need <-25°)';
            _frameColor = Colors.orange;
          });
        }
        break;

      case 3: // Smile
        final smiling = face.smilingProbability ?? 0;
        if (smiling > 0.5) {
          _stableFrameCount++;
          setState(() {
            _instructions = 'Keep smiling! ${_stableFrameCount}/10';
            _frameColor = Colors.yellow;
          });
          if (_stableFrameCount >= 10) {
            stageCompleted = true;
          }
        } else {
          _stableFrameCount = 0;
          setState(() {
            _instructions = 'SMILE! 😊\nSmile level: ${(smiling * 100).toStringAsFixed(0)}% (need >50%)';
            _frameColor = Colors.orange;
          });
        }
        break;
    }

    if (stageCompleted) {
      _stagesCompleted[_currentStage] = true;
      _stableFrameCount = 0;
      
      if (_currentStage < _stages.length - 1) {
        setState(() {
          _currentStage++;
          _instructions = '✅ Perfect!\n${_stages[_currentStage]}';
          _frameColor = Colors.green;
        });
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _instructions = _stages[_currentStage];
            });
          }
        });
      } else {
        // All stages completed - capture photo
        setState(() {
          _instructions = '✅ All steps complete!\nCapturing...';
          _frameColor = Colors.green;
        });
        _captureVerifiedPhoto();
      }
    }
  }

  Future<void> _captureVerifiedPhoto() async {
    try {
      await _controller?.stopImageStream();
      
      final XFile photo = await _controller!.takePicture();
      final File imageFile = File(photo.path);

      // Perform final verification
      final inputImage = InputImage.fromFile(imageFile);
      final List<Face> faces = await widget.faceDetector.processImage(inputImage);

      String result = '✅ LIVENESS VERIFICATION PASSED\n\n';
      result += '🎯 All challenges completed:\n';
      result += '✅ Face forward detected\n';
      result += '✅ Head turn left verified\n';
      result += '✅ Head turn right verified\n';
      result += '✅ Smile detected\n\n';

      if (faces.isNotEmpty) {
        final face = faces.first;
        result += '📊 Final Face Analysis:\n';
        result += 'Head rotation Y: ${face.headEulerAngleY?.toStringAsFixed(2)}°\n';
        result += 'Head rotation Z: ${face.headEulerAngleZ?.toStringAsFixed(2)}°\n';
        result += 'Smiling: ${((face.smilingProbability ?? 0) * 100).toStringAsFixed(1)}%\n';
        result += 'Left eye open: ${((face.leftEyeOpenProbability ?? 0) * 100).toStringAsFixed(1)}%\n';
        result += 'Right eye open: ${((face.rightEyeOpenProbability ?? 0) * 100).toStringAsFixed(1)}%\n';
        result += '\n✅ VERIFIED LIVE PERSON';
      }

      if (mounted) {
        Navigator.pop(context, {
          'image': imageFile,
          'resultText': result,
        });
      }
    } catch (e) {
      setState(() {
        _instructions = '❌ Error capturing photo: $e';
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview
          CameraPreview(_controller!),

          // Face frame overlay
          Center(
            child: Container(
              width: 250,
              height: 350,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _frameColor,
                  width: 4,
                ),
                borderRadius: BorderRadius.circular(150),
              ),
            ),
          ),

          // Instructions overlay
          Positioned(
            top: 60,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    _instructions,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Progress indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_stages.length, (index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 40,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _stagesCompleted[index]
                              ? Colors.green
                              : (index == _currentStage ? Colors.orange : Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),

          // Cancel button
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text('Cancel'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}