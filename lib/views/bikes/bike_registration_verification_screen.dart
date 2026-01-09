import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/utils/kenyan_plate_parser.dart';

/// Production-ready Bike Registration Verification using Google ML Kit
/// 
/// Features:
/// - Object Detection: Verifies motorcycle presence
/// - Image Labeling: Enhanced object classification
/// - Text Recognition: Extracts number plates from rear images
/// - Quality Validation: Ensures images are clear and usable
/// - Smart Error Handling: Provides actionable feedback
/// 
/// Usage:
/// ```dart
/// final result = await Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (context) => BikeRegistrationVerificationScreen(
///       imageType: 'rear', // 'front', 'side', or 'rear'
///     ),
///   ),
/// );
/// 
/// if (result != null) {
///   final imagePath = result['image'] as String;
///   final regNumber = result['registration_number'] as String?;
///   final isMotorcycle = result['is_motorcycle'] as bool;
/// }
/// ```
class BikeRegistrationVerificationScreen extends StatefulWidget {
  final String imageType; // 'front', 'side', 'rear'

  const BikeRegistrationVerificationScreen({
    super.key,
    required this.imageType,
  });

  @override
  State<BikeRegistrationVerificationScreen> createState() =>
      _BikeRegistrationVerificationScreenState();
}

class _BikeRegistrationVerificationScreenState
    extends State<BikeRegistrationVerificationScreen> {
  // Camera
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;

  // Captured data
  File? _capturedImage;
  String? _extractedRegistrationNumber;
  bool? _isMotorcycleVerified;
  String? _errorMessage;
  List<String> _detectedLabels = [];
  double _confidenceScore = 0.0;

  // Google ML Kit components
  late final TextRecognizer _textRecognizer;
  ObjectDetector? _objectDetector;
  ImageLabeler? _imageLabeler;
  bool _mlKitInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeMLKit();
    _initializeCamera();
  }

  /// Initialize all ML Kit components
  Future<void> _initializeMLKit() async {
    try {
      // Initialize Text Recognizer
      _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      
      // Initialize Object Detector with optimized settings
      final objectDetectorOptions = ObjectDetectorOptions(
        mode: DetectionMode.single,
        classifyObjects: true,
        multipleObjects: true,
      );
      _objectDetector = ObjectDetector(options: objectDetectorOptions);

      // Initialize Image Labeler for enhanced classification
      final imageLabelerOptions = ImageLabelerOptions(
        confidenceThreshold: 0.5,
      );
      _imageLabeler = ImageLabeler(options: imageLabelerOptions);

      setState(() {
        _mlKitInitialized = true;
      });

      debugPrint('✅ ML Kit initialized: Object Detection + Image Labeling + Text Recognition');
    } catch (e) {
      debugPrint('❌ Error initializing ML Kit: $e');
      setState(() {
        _errorMessage = 'Failed to initialize ML Kit: $e';
      });
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _errorMessage = 'No cameras available';
        });
        return;
      }

      _cameraController = CameraController(
        _cameras![0],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Camera initialization failed: $e';
      });
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose().catchError((error) {
      debugPrint('⚠️ Error disposing camera: $error');
    });
    _textRecognizer.close();
    _objectDetector?.close();
    _imageLabeler?.close();
    super.dispose();
  }

  Future<void> _captureImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final image = await _cameraController!.takePicture();
      final imageFile = File(image.path);

      setState(() {
        _capturedImage = imageFile;
      });

      await _analyzeImage(imageFile);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to capture image: $e';
        _isProcessing = false;
      });
    }
  }

  Future<void> _pickImageFromGallery() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final imageFile = File(pickedFile.path);

        setState(() {
          _capturedImage = imageFile;
        });

        await _analyzeImage(imageFile);
      } else {
        setState(() {
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick image: $e';
        _isProcessing = false;
      });
    }
  }

  /// Main image analysis orchestrator
  Future<void> _analyzeImage(File imageFile) async {
    if (!_mlKitInitialized || _objectDetector == null || _imageLabeler == null) {
      setState(() {
        _errorMessage = 'ML Kit not ready. Please wait...';
        _isProcessing = false;
      });
      return;
    }

    try {
      final inputImage = InputImage.fromFile(imageFile);

      // Step 1: Validate image quality
      final qualityCheck = await _validateImageQuality(imageFile);
      if (!qualityCheck.isValid) {
        setState(() {
          _errorMessage = qualityCheck.errorMessage;
          _isMotorcycleVerified = false;
          _isProcessing = false;
        });
        return;
      }

      // Step 2: Process based on image type
      if (widget.imageType == 'rear') {
        await _processRearImage(inputImage);
      } else {
        await _processFrontOrSideImage(inputImage);
      }
    } catch (e) {
      debugPrint('❌ Analysis error: $e');
      setState(() {
        _errorMessage = 'Analysis failed: ${e.toString()}';
        _isProcessing = false;
        _isMotorcycleVerified = false;
      });
    }
  }

  /// Process rear image: Extract plate and verify motorcycle
  Future<void> _processRearImage(InputImage inputImage) async {
    debugPrint('🔍 [REAR] Processing rear view with plate extraction...');

    // Step 1: Extract registration number
    final registrationNumber = await _extractRegistrationNumber(inputImage);

    // Step 2: Validate plate quality
    if (registrationNumber == null || registrationNumber.isEmpty) {
      setState(() {
        _errorMessage = 'Number plate not detected.\n\n'
            'Tips:\n'
            '• Ensure the plate is clearly visible\n'
            '• Avoid shadows and reflections\n'
            '• Keep the camera steady\n'
            '• Use good lighting\n\n'
            'You can enter the number manually below.';
        _isMotorcycleVerified = false;
        _isProcessing = false;
      });
      // Show manual entry dialog
      _showManualPlateEntryDialog();
      return;
    }

    // Step 3: Validate plate format
    if (!_isValidPlateFormat(registrationNumber)) {
      setState(() {
        _errorMessage = 'Invalid motorcycle plate format: $registrationNumber\n\n'
            'Kenyan motorcycles must have:\n'
            '• Start with KM\n'
            '• Followed by 2 letters (e.g., KMFB, KMDD)\n'
            '• Then 3 digits (e.g., 123, 650)\n'
            '• Optional letter at end (e.g., A, L, Z)\n\n'
            'Example: KMFB 123A or KMDD 650L\n\n'
            'Please ensure the motorcycle plate is clearly visible and try again.';
        _isMotorcycleVerified = false;
        _extractedRegistrationNumber = registrationNumber;
        _isProcessing = false;
      });
      return;
    }

    // Step 4: Optional - Verify it's a motorcycle (not a car)
    final isMotorcycle = await _verifyMotorcyclePresence(inputImage);

    setState(() {
      _isMotorcycleVerified = true;
      _extractedRegistrationNumber = registrationNumber;
      _confidenceScore = isMotorcycle.confidence;
      _detectedLabels = isMotorcycle.labels;
      _errorMessage = null;
      _isProcessing = false;
    });

    debugPrint('✅ [REAR] Plate extracted successfully: $registrationNumber');
  }

  /// Process front/side image: Verify motorcycle only
  Future<void> _processFrontOrSideImage(InputImage inputImage) async {
    debugPrint('🔍 [${widget.imageType.toUpperCase()}] Verifying motorcycle presence...');

    final result = await _verifyMotorcyclePresence(inputImage);

    if (result.isMotorcycle) {
      setState(() {
        _isMotorcycleVerified = true;
        _confidenceScore = result.confidence;
        _detectedLabels = result.labels;
        _errorMessage = null;
        _isProcessing = false;
      });
      debugPrint('✅ [${widget.imageType.toUpperCase()}] Motorcycle verified (${(result.confidence * 100).toStringAsFixed(1)}%)');
    } else {
      setState(() {
        _isMotorcycleVerified = false;
        _detectedLabels = result.labels;
        _errorMessage = 'No motorcycle detected.\n\n'
            'Detected: ${result.labels.isEmpty ? "nothing" : result.labels.take(3).join(", ")}\n\n'
            'Tips:\n'
            '• Capture the full motorcycle\n'
            '• Use good lighting\n'
            '• Avoid cluttered backgrounds\n'
            '• Ensure the bike is the main subject';
        _isProcessing = false;
      });
      debugPrint('❌ [${widget.imageType.toUpperCase()}] No motorcycle detected. Found: ${result.labels.join(", ")}');
    }
  }

  /// Validate image quality before processing
  Future<_QualityCheckResult> _validateImageQuality(File imageFile) async {
    try {
      final fileSize = await imageFile.length();
      
      // Check minimum file size (too small = low quality)
      if (fileSize < 50000) { // 50KB minimum
        return _QualityCheckResult(
          isValid: false,
          errorMessage: 'Image quality too low. Please capture a clearer photo.',
        );
      }

      // Check maximum file size (too large might indicate issues)
      if (fileSize > 10000000) { // 10MB maximum
        return _QualityCheckResult(
          isValid: false,
          errorMessage: 'Image file too large. Please try again.',
        );
      }

      return _QualityCheckResult(isValid: true);
    } catch (e) {
      debugPrint('⚠️ Quality check error: $e');
      return _QualityCheckResult(isValid: true); // Proceed anyway
    }
  }

  /// Verify motorcycle presence using Object Detection + Image Labeling
  Future<_MotorcycleVerificationResult> _verifyMotorcyclePresence(InputImage image) async {
    try {
      // Use both Object Detection and Image Labeling for better accuracy
      final objectResults = _objectDetector!.processImage(image);
      final labelResults = _imageLabeler!.processImage(image);

      final results = await Future.wait([objectResults, labelResults]);
      final detectedObjects = results[0] as List<DetectedObject>;
      final detectedLabels = results[1] as List<ImageLabel>;

      List<String> allLabels = [];
      double maxConfidence = 0.0;
      bool isMotorcycle = false;

      // Process Object Detection results
      for (var obj in detectedObjects) {
        for (var label in obj.labels) {
          final labelText = label.text.toLowerCase();
          final confidence = label.confidence;
          
          allLabels.add('${label.text} (${(confidence * 100).toStringAsFixed(1)}%)');
          
          if (_isMotorcycleLabel(labelText, confidence)) {
            isMotorcycle = true;
            maxConfidence = confidence > maxConfidence ? confidence : maxConfidence;
            debugPrint('  ✓ Object Detection: ${label.text} (${(confidence * 100).toStringAsFixed(1)}%)');
          }
        }
      }

      // Process Image Labeling results (more comprehensive)
      for (var label in detectedLabels) {
        final labelText = label.label.toLowerCase();
        final confidence = label.confidence;
        
        if (!allLabels.any((l) => l.toLowerCase().contains(labelText))) {
          allLabels.add('${label.label} (${(confidence * 100).toStringAsFixed(1)}%)');
        }
        
        if (_isMotorcycleLabel(labelText, confidence)) {
          isMotorcycle = true;
          maxConfidence = confidence > maxConfidence ? confidence : maxConfidence;
          debugPrint('  ✓ Image Labeling: ${label.label} (${(confidence * 100).toStringAsFixed(1)}%)');
        }
      }

      debugPrint('📊 Total labels detected: ${allLabels.length}');
      debugPrint('🏍️ Motorcycle detected: $isMotorcycle (confidence: ${(maxConfidence * 100).toStringAsFixed(1)}%)');

      return _MotorcycleVerificationResult(
        isMotorcycle: isMotorcycle,
        confidence: maxConfidence,
        labels: allLabels,
      );
    } catch (e) {
      debugPrint('❌ Motorcycle verification error: $e');
      return _MotorcycleVerificationResult(
        isMotorcycle: false,
        confidence: 0.0,
        labels: [],
      );
    }
  }

  /// Check if a label indicates a motorcycle
  bool _isMotorcycleLabel(String label, double confidence) {
    // Primary motorcycle labels (relaxed threshold)
    if ((label == 'motorcycle' || label == 'bike' || label == 'motorbike') && confidence > 0.3) {
      return true;
    }

    // Secondary labels (medium threshold)
    if ((label == 'bicycle' || label == 'scooter' || label == 'moped') && confidence > 0.4) {
      return true;
    }

    // Vehicle-related labels (higher threshold required)
    if ((label.contains('vehicle') || label.contains('motor') || 
         label == 'car' || label == 'automobile') && confidence > 0.6) {
      return true;
    }

    // Wheel/tire detection (indicates vehicle presence)
    if ((label.contains('wheel') || label.contains('tire')) && confidence > 0.7) {
      return true;
    }

    return false;
  }

  /// Extract registration number using OCR with Kenyan motorcycle plate parser
  Future<String?> _extractRegistrationNumber(InputImage image) async {
    try {
      final recognizedText = await _textRecognizer.processImage(image);

      debugPrint('📝 [OCR] Detected text blocks: ${recognizedText.blocks.length}');

      // Log all detected text for debugging
      for (var block in recognizedText.blocks) {
        for (var line in block.lines) {
          debugPrint('  📝 [OCR] Raw text: "${line.text}"');
        }
      }

      // Use Kenyan Plate Parser for motorcycle plates
      final motorcyclePlate = KenyanPlateParser.parseMotorcyclePlate(recognizedText);

      if (motorcyclePlate != null) {
        debugPrint('✅ [OCR] Kenyan motorcycle plate detected: $motorcyclePlate');
        return motorcyclePlate;
      }

      debugPrint('❌ [OCR] No valid Kenyan motorcycle plate found');
      return null;
    } catch (e) {
      debugPrint('❌ [OCR] Error extracting registration number: $e');
      return null;
    }
  }

  /// Validate registration plate format (Kenyan motorcycle format)
  bool _isValidPlateFormat(String plate) {
    // Use Kenyan Plate Parser for strict validation
    bool isValid = KenyanPlateParser.isValidMotorcyclePlate(plate);
    
    if (isValid) {
      debugPrint('✅ [Validation] Valid Kenyan motorcycle plate: $plate');
    } else {
      debugPrint('❌ [Validation] Invalid plate format: $plate (expected KM[A-Z]{2} [0-9]{3}[A-Z]?)');
    }
    
    return isValid;
  }

  void _retake() {
    setState(() {
      _capturedImage = null;
      _extractedRegistrationNumber = null;
      _isMotorcycleVerified = null;
      _errorMessage = null;
    });
  }

  void _confirm() {
    if (_capturedImage == null) return;
    
    // For rear images, require plate number (either detected or manually entered)
    if (widget.imageType == 'rear' && 
        (_extractedRegistrationNumber == null || _extractedRegistrationNumber!.isEmpty)) {
      _showManualPlateEntryDialog();
      return;
    }

    Navigator.pop(context, {
      'image': _capturedImage!.path,
      'registration_number': _extractedRegistrationNumber,
      'is_motorcycle': _isMotorcycleVerified ?? true, // Allow proceeding for front/side
      'image_type': widget.imageType,
    });
  }

  /// Show dialog for manual plate entry when OCR fails
  Future<void> _showManualPlateEntryDialog() async {
    final TextEditingController plateController = TextEditingController(
      text: _extractedRegistrationNumber ?? '',
    );

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Number Plate Not Detected',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.camera_alt, color: Colors.orange, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'We couldn\'t automatically detect the number plate from your photo.',
                          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'You can either:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.refresh, color: Colors.blue, size: 18),
                          SizedBox(width: 8),
                          Text(
                            '1. Retake the photo',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6),
                      Padding(
                        padding: EdgeInsets.only(left: 26),
                        child: Text(
                          '• Ensure the number plate is clearly visible\n'
                          '• Good lighting is essential\n'
                          '• Avoid glare or shadows\n'
                          '• Keep camera steady and focused',
                          style: TextStyle(color: Colors.white60, fontSize: 11, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.brightRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.brightRed.withOpacity(0.3)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.edit, color: AppTheme.brightRed, size: 18),
                          SizedBox(width: 8),
                          Text(
                            '2. Enter manually',
                            style: TextStyle(
                              color: AppTheme.brightRed,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6),
                      Padding(
                        padding: EdgeInsets.only(left: 26),
                        child: Text(
                          'Type the number plate below',
                          style: TextStyle(color: Colors.white60, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: plateController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Number Plate (Optional)',
                    labelStyle: const TextStyle(color: Colors.white60),
                    hintText: 'e.g., KMFB123A',
                    hintStyle: const TextStyle(color: Colors.white30),
                    prefixIcon: const Icon(Icons.tag, color: AppTheme.brightRed),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.brightRed.withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.brightRed, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.green, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Kenyan Motorcycle Format',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Format: KM + 2 letters + 3 digits + optional letter\n'
                        'Example: KMFB123A or KMDD650L',
                        style: TextStyle(color: Colors.white60, fontSize: 10, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () => Navigator.of(context).pop('RETAKE'),
              icon: const Icon(Icons.camera_alt, size: 20),
              label: const Text('Retake Photo'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final plate = plateController.text.trim().toUpperCase();
                if (plate.isEmpty) {
                  // Allow skipping if user wants to retake
                  Navigator.of(context).pop('RETAKE');
                  return;
                }
                Navigator.of(context).pop(plate);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brightRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty && mounted) {
      // Check if user wants to retake photo
      if (result == 'RETAKE') {
        debugPrint('🔄 User chose to retake photo');
        // Clear the current image and allow retake
        setState(() {
          _capturedImage = null;
          _extractedRegistrationNumber = null;
          _isMotorcycleVerified = false;
          _errorMessage = null;
        });
        
        // User will need to capture/select a new image
        // The UI will automatically show camera/gallery options when _capturedImage is null
        return;
      }
      
      final cleanedPlate = result.replaceAll(' ', '');
      
      // Validate the manually entered plate
      if (_isValidPlateFormat(cleanedPlate)) {
        setState(() {
          _extractedRegistrationNumber = cleanedPlate;
          _isMotorcycleVerified = true; // Accept manual entry
          _errorMessage = null;
          _confidenceScore = 0.0; // Manual entry has no confidence score
        });
        debugPrint('✅ [MANUAL] Plate entered manually: $cleanedPlate');
      } else {
        setState(() {
          _errorMessage = 'Invalid motorcycle plate format: $cleanedPlate\n\n'
              'Please ensure you enter a valid Kenyan motorcycle plate.\n'
              'Format: KM[A-Z]{2} [0-9]{3}[A-Z]?\n\n'
              'Example: KMFB123A or KMDD650L';
          _isMotorcycleVerified = false;
        });
        
        // Show error and allow retry
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invalid plate format: $cleanedPlate'),
              backgroundColor: AppTheme.brightRed,
              action: SnackBarAction(
                label: 'Try Again',
                textColor: Colors.white,
                onPressed: _showManualPlateEntryDialog,
              ),
            ),
          );
        }
      }
    }
  }

  String _getTitle() {
    switch (widget.imageType) {
      case 'front':
        return 'Front View';
      case 'side':
        return 'Side View';
      case 'rear':
        return 'Rear View + Number Plate';
      default:
        return 'Bike Photo';
    }
  }

  String _getInstructions() {
    switch (widget.imageType) {
      case 'front':
        return 'Capture front view - entire motorcycle in frame';
      case 'side':
        return 'Capture side view - entire motorcycle in frame';
      case 'rear':
        return '⚠️ IMPORTANT: Focus on NUMBER PLATE - must be clearly visible and readable';
      default:
        return 'Capture the motorcycle';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_getTitle()),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Camera capture is disabled on web. Please upload an image from your device instead.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: Text(
          _getTitle(),
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _capturedImage == null
                ? _buildCameraView()
                : _buildPreviewView(),
          ),
          _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildCameraView() {
    // Error state
    if (_errorMessage != null && _capturedImage == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.brightRed.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: AppTheme.brightRed,
                  size: 64,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Initialization Error',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go Back'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brightRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Loading state
    if (!_isCameraInitialized || !_mlKitInitialized) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.brightRed),
              strokeWidth: 3,
            ),
            const SizedBox(height: 24),
            Text(
              !_mlKitInitialized
                  ? 'Initializing ML Kit...'
                  : 'Initializing camera...',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please wait',
              style: TextStyle(color: Colors.white38, fontSize: 14),
            ),
          ],
        ),
      );
    }

    // Camera preview with overlay
    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera preview
        CameraPreview(_cameraController!),
        
        // Frame overlay with guidelines
        _buildFrameOverlay(),

        // Top gradient with tips
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black87, Colors.transparent],
              ),
            ),
            child: SafeArea(
              child: _buildCameraTips(),
            ),
          ),
        ),

        // Bottom instructions
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.brightRed.withOpacity(0.5), width: 1),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppTheme.brightRed, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getInstructions(),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCameraTips() {
    if (widget.imageType != 'rear') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lightbulb_outline, color: Colors.amber, size: 18),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Frame the entire motorcycle in view',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }
    
    // Special instructions for rear photo (number plate capture)
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.brightRed.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.brightRed.withOpacity(0.5), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.priority_high, color: AppTheme.brightRed, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'NUMBER PLATE CAPTURE',
                  style: TextStyle(
                    color: AppTheme.brightRed,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '✓ Number plate must be clearly visible\n'
            '✓ Ensure good lighting (no glare/shadows)\n'
            '✓ Keep camera steady and focused\n'
            '✓ Fill most of frame with the plate',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrameOverlay() {
    return CustomPaint(
      painter: SimpleCameraFramePainter(imageType: widget.imageType),
      child: Container(),
    );
  }

  Widget _buildPreviewView() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Image preview
        Image.file(_capturedImage!, fit: BoxFit.contain),

        // Processing overlay
        if (_isProcessing)
          Container(
            color: Colors.black87,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.brightRed.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.brightRed),
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Analyzing Image',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.imageType == 'rear'
                        ? 'Detecting motorcycle and extracting plate...'
                        : 'Verifying motorcycle presence...',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

        // Results overlay
        if (!_isProcessing)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // Main status banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: _isMotorcycleVerified == true
                            ? AppTheme.successGreen
                            : AppTheme.brightRed,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: (_isMotorcycleVerified == true
                                    ? AppTheme.successGreen
                                    : AppTheme.brightRed)
                                .withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isMotorcycleVerified == true
                                ? Icons.check_circle_rounded
                                : Icons.error_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isMotorcycleVerified == true
                                      ? 'Verification Successful'
                                      : 'Verification Failed',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (_isMotorcycleVerified == true &&
                                    widget.imageType == 'rear' &&
                                    _extractedRegistrationNumber != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Plate: $_extractedRegistrationNumber',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                                if (_isMotorcycleVerified == true &&
                                    _confidenceScore > 0) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Confidence: ${(_confidenceScore * 100).toStringAsFixed(0)}%',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Error details
                    if (_isMotorcycleVerified != true && _errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ],

                    // Detection labels (debug info)
                    if (_detectedLabels.isNotEmpty && _isMotorcycleVerified == true) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.label_outline, color: Colors.white70, size: 16),
                                SizedBox(width: 8),
                                Text(
                                  'Detected',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _detectedLabels.take(5).join(', '),
                              style: const TextStyle(color: Colors.white60, fontSize: 11),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black87,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: _capturedImage == null
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: _isProcessing ? null : _pickImageFromGallery,
                  icon: const Icon(
                    Icons.photo_library,
                    color: Colors.white,
                    size: 28,
                  ),
                  tooltip: 'Choose from gallery',
                ),
                GestureDetector(
                  onTap: _isProcessing ? null : _captureImage,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      color: AppTheme.brightRed,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.brightRed.withOpacity(0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(width: 48), // Placeholder for symmetry
              ],
            )
          : Column(
              children: [
                // Manual entry button for rear images when plate not detected
                if (widget.imageType == 'rear' && 
                    _isMotorcycleVerified != true &&
                    !_isProcessing) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _showManualPlateEntryDialog,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppTheme.goldAccent, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.edit, color: AppTheme.goldAccent),
                      label: const Text(
                        'Enter Number Plate Manually',
                        style: TextStyle(
                          color: AppTheme.goldAccent,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isProcessing ? null : _retake,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Colors.white, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Retake',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isProcessing 
                            ? null
                            : (widget.imageType == 'rear'
                                ? (_extractedRegistrationNumber != null && _extractedRegistrationNumber!.isNotEmpty)
                                    ? _confirm
                                    : null
                                : _confirm), // Front/side can proceed without verification
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successGreen,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          disabledBackgroundColor: Colors.grey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Confirm',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

// ============================================================================
// Custom Painter for Camera Frame Overlay
// ============================================================================

class SimpleCameraFramePainter extends CustomPainter {
  final String imageType;

  SimpleCameraFramePainter({required this.imageType});

  @override
  void paint(Canvas canvas, Size size) {
    // Dim background
    final dimPaint = Paint()..color = Colors.black.withOpacity(0.6);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), dimPaint);

    // Define frame based on image type
    Rect frame;
    if (imageType == 'side') {
      // Wider frame for side view
      frame = Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: size.width * 0.85,
        height: size.height * 0.5,
      );
    } else if (imageType == 'rear') {
      // Smaller frame focused on plate area
      frame = Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: size.width * 0.75,
        height: size.height * 0.25,
      );
    } else {
      // Front view - standard frame
      frame = Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: size.width * 0.8,
        height: size.height * 0.35,
      );
    }

    // Clear the frame area
    canvas.drawRect(frame, Paint()..blendMode = BlendMode.clear);

    // Draw frame border
    final borderPaint = Paint()
      ..color = AppTheme.brightRed
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRRect(
      RRect.fromRectAndRadius(frame, const Radius.circular(12)),
      borderPaint,
    );

    // Draw animated corner markers
    final cornerPaint = Paint()
      ..color = AppTheme.brightRed
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    final cornerLength = 30.0;

    // Define corners
    final corners = [
      // Top-left
      [
        Offset(frame.left, frame.top + cornerLength),
        Offset(frame.left, frame.top),
        Offset(frame.left + cornerLength, frame.top),
      ],
      // Top-right
      [
        Offset(frame.right - cornerLength, frame.top),
        Offset(frame.right, frame.top),
        Offset(frame.right, frame.top + cornerLength),
      ],
      // Bottom-left
      [
        Offset(frame.left, frame.bottom - cornerLength),
        Offset(frame.left, frame.bottom),
        Offset(frame.left + cornerLength, frame.bottom),
      ],
      // Bottom-right
      [
        Offset(frame.right - cornerLength, frame.bottom),
        Offset(frame.right, frame.bottom),
        Offset(frame.right, frame.bottom - cornerLength),
      ],
    ];

    // Draw corners
    for (var corner in corners) {
      canvas.drawLine(corner[0], corner[1], cornerPaint);
      canvas.drawLine(corner[1], corner[2], cornerPaint);
    }

    // Draw center crosshair for rear view (helps align plate)
    if (imageType == 'rear') {
      final crosshairPaint = Paint()
        ..color = AppTheme.brightRed.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      final centerX = frame.center.dx;
      final centerY = frame.center.dy;
      final crosshairSize = 20.0;

      canvas.drawLine(
        Offset(centerX - crosshairSize, centerY),
        Offset(centerX + crosshairSize, centerY),
        crosshairPaint,
      );
      canvas.drawLine(
        Offset(centerX, centerY - crosshairSize),
        Offset(centerX, centerY + crosshairSize),
        crosshairPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================================
// Helper Classes for ML Kit Results
// ============================================================================

/// Result from image quality validation
class _QualityCheckResult {
  final bool isValid;
  final String? errorMessage;

  _QualityCheckResult({
    required this.isValid,
    this.errorMessage,
  });
}

/// Result from motorcycle verification
class _MotorcycleVerificationResult {
  final bool isMotorcycle;
  final double confidence;
  final List<String> labels;

  _MotorcycleVerificationResult({
    required this.isMotorcycle,
    required this.confidence,
    required this.labels,
  });
}
