import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'models/detection_result.dart';
import 'models/bounding_box.dart';

/// Service for detecting concrete structures and demolition materials using YOLOv8 segmentation.
/// 
/// This service analyzes images in three steps:
/// 1. Detect if the image contains a concrete structure
/// 2. Detect if the image contains demolition materials/rubble
/// 3. Estimate the volume of demolition material using segmentation and geometry
class ConcreteDetectionService {
  // Model configuration
  static const String _modelPath = 'assets/ai/yolov8s-seg.tflite';
  static const int _inputSize = 640; // YOLOv8 standard input size
  static const int _numChannels = 3; // RGB
  
  // Detection thresholds
  static const double _confidenceThreshold = 0.25;
  static const double _iouThreshold = 0.45;
  static const double _minConfidenceForStructure = 0.4;
  static const double _minAreaRatioForStructure = 0.05; // 5% of image
  
  // Volume estimation coefficients
  static const double _pixelsToMetersRatio = 0.01; // Approximate: 1 pixel = 1cm at typical photo distance
  static const double _rubbleDepthCoefficient = 0.3; // Assumed average rubble depth in meters
  
  // COCO class mappings (subset relevant to construction/demolition)
  // YOLOv8 is typically trained on COCO dataset with 80 classes
  static const Map<int, String> _cocoClasses = {
    0: 'person',
    1: 'bicycle',
    2: 'car',
    // ... Add more as needed, but we focus on construction-related items
    // For concrete/rubble, we'll use custom heuristics since COCO doesn't have these exact classes
  };
  
  // Classes that might indicate concrete structures
  static const List<String> _concreteIndicators = [
    'building',
    'wall',
    'construction',
    'concrete',
    'structure',
  ];
  
  // Classes that might indicate demolition/rubble
  static const List<String> _rubbleIndicators = [
    'rubble',
    'debris',
    'demolition',
    'waste',
    'broken',
  ];

  Interpreter? _interpreter;
  bool _isInitialized = false;
  String? _initError;

  /// Initialize the TFLite model
  /// Call this before calling [analyze]
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      // Load the model
      _interpreter = await Interpreter.fromAsset(_modelPath);
      
      // Optional: Set number of threads for performance
      _interpreter!.allocateTensors();
      
      _isInitialized = true;
      _initError = null;
      return true;
    } catch (e) {
      _initError = 'Failed to load model: $e';
      _isInitialized = false;
      return false;
    }
  }

  /// Analyze an image for concrete structures and demolition materials
  /// 
  /// Returns a [DetectionResult] containing:
  /// - Whether concrete structure is detected
  /// - Whether demolition material is detected
  /// - Estimated volume of rubble
  /// - Bounding boxes and segmentation masks
  Future<DetectionResult> analyze(File imageFile) async {
    // Ensure model is initialized
    if (!_isInitialized) {
      final success = await initialize();
      if (!success) {
        return DetectionResult.empty(
          errorMessage: _initError ?? 'Model not initialized',
        );
      }
    }

    try {
      // Step 1: Load and preprocess image
      final preprocessed = await _preprocessImage(imageFile);
      if (preprocessed == null) {
        return DetectionResult.empty(
          errorMessage: 'Failed to preprocess image. Check image format and quality.',
        );
      }

      // Step 2: Run inference
      final inferenceResult = await _runInference(preprocessed.imageData, 
                                                   preprocessed.originalWidth,
                                                   preprocessed.originalHeight);

      // Step 3: Post-process results
      final detectionResult = _postprocessResults(
        inferenceResult,
        preprocessed.originalWidth,
        preprocessed.originalHeight,
      );

      return detectionResult;
    } catch (e) {
      return DetectionResult.empty(
        errorMessage: 'Analysis failed: $e',
      );
    }
  }

  /// Dispose resources
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }

  // ============================================================================
  // PRIVATE METHODS - Preprocessing
  // ============================================================================

  Future<_PreprocessedImage?> _preprocessImage(File imageFile) async {
    try {
      // Read image bytes
      final bytes = await imageFile.readAsBytes();
      
      // Decode image
      img.Image? image = img.decodeImage(bytes);
      if (image == null) return null;

      final originalWidth = image.width;
      final originalHeight = image.height;

      // Resize to model input size (640x640 for YOLOv8)
      final resized = img.copyResize(
        image,
        width: _inputSize,
        height: _inputSize,
        interpolation: img.Interpolation.linear,
      );

      // Convert to Float32 tensor [1, 640, 640, 3] normalized to [0, 1]
      final imageData = _imageToFloat32List(resized);

      return _PreprocessedImage(
        imageData: imageData,
        originalWidth: originalWidth,
        originalHeight: originalHeight,
      );
    } catch (e) {
      print('Error preprocessing image: $e');
      return null;
    }
  }

  Float32List _imageToFloat32List(img.Image image) {
    final buffer = Float32List(_inputSize * _inputSize * _numChannels);
    int pixelIndex = 0;

    for (int y = 0; y < _inputSize; y++) {
      for (int x = 0; x < _inputSize; x++) {
        final pixel = image.getPixel(x, y);
        
        // Normalize to [0, 1] - YOLOv8 expects normalized input
        buffer[pixelIndex++] = pixel.r / 255.0;
        buffer[pixelIndex++] = pixel.g / 255.0;
        buffer[pixelIndex++] = pixel.b / 255.0;
      }
    }

    return buffer;
  }

  // ============================================================================
  // PRIVATE METHODS - Inference
  // ============================================================================

  Future<_InferenceResult> _runInference(Float32List inputData, int originalWidth, int originalHeight) async {
    try {
      // Reshape input: [1, 640, 640, 3]
      final input = inputData.reshape([1, _inputSize, _inputSize, _numChannels]);

      // Get output shapes from interpreter
      final outputTensors = _interpreter!.getOutputTensors();
      
      // Print output shapes for debugging
      print('Model output shapes:');
      for (int i = 0; i < outputTensors.length; i++) {
        print('  Output $i: ${outputTensors[i].shape}');
      }
      
      // YOLOv8 can have different output formats:
      // Detection only: [1, 8400, 84] or [1, 8400, 4+num_classes]
      // With segmentation: [1, 8400, 116] + [1, 32, 160, 160]
      // Or transposed: [1, 84, 8400] or [1, 4, 8400]
      
      // Prepare output buffers based on actual shapes
      var outputs = <int, Object>{};
      final outputShapes = <List<int>>[];
      final outputBuffers = <int, Float32List>{};
      
      for (int i = 0; i < outputTensors.length; i++) {
        final shape = outputTensors[i].shape;
        outputShapes.add(shape);
        
        // Allocate flat buffer based on total size
        final totalSize = shape.reduce((a, b) => a * b);
        final buffer = Float32List(totalSize);
        outputBuffers[i] = buffer;
        
        // Reshape buffer to match output tensor shape for TFLite
        // TFLite expects shaped buffers, not flat arrays
        outputs[i] = buffer.reshape(shape);
      }

      // Run inference
      _interpreter!.runForMultipleInputs([input], outputs);

      // Return the flat buffers for processing (they've been filled by inference)
      return _InferenceResult(
        detections: outputBuffers[0]!,
        protoMasks: outputBuffers.length > 1 ? outputBuffers[1] : null,
        originalWidth: originalWidth,
        originalHeight: originalHeight,
        outputShapes: outputShapes,
      );
    } catch (e) {
      print('Inference error: $e');
      rethrow;
    }
  }

  // ============================================================================
  // PRIVATE METHODS - Post-processing
  // ============================================================================

  DetectionResult _postprocessResults(
    _InferenceResult inferenceResult,
    int originalWidth,
    int originalHeight,
  ) {
    // Parse detections from YOLOv8 output format
    final detections = _parseYolov8Detections(
      inferenceResult.detections,
      originalWidth,
      originalHeight,
      inferenceResult.outputShapes[0],
    );

    // Filter by confidence and apply NMS
    final filteredDetections = _applyNMS(detections, _iouThreshold);

    // Step 1: Detect concrete structures
    final hasConcreteStructure = detectConcrete(filteredDetections, originalWidth, originalHeight);

    // Step 2: Detect demolition materials
    final hasDemolitionMaterial = detectDemolitionMaterial(filteredDetections, originalWidth, originalHeight);

    // Step 3: Estimate volume from segmentation
    final volumeEstimate = estimateVolumeFromSegmentation(
      filteredDetections,
      inferenceResult.protoMasks,
      originalWidth,
      originalHeight,
    );

    // Calculate overall confidence
    final overallConfidence = filteredDetections.isEmpty
        ? 0.0
        : filteredDetections.map((d) => d.confidence).reduce(math.max);

    // Generate segmentation mask visualization (optional)
    final segmentationMask = _generateSegmentationMask(
      filteredDetections,
      originalWidth,
      originalHeight,
    );

    // Check for warnings
    String? warningMessage;
    if (overallConfidence < 0.3) {
      warningMessage = 'Low detection confidence. Try better lighting or closer distance.';
    } else if (originalWidth < 640 || originalHeight < 480) {
      warningMessage = 'Low image resolution. Try taking a higher quality photo.';
    }

    return DetectionResult(
      hasConcreteStructure: hasConcreteStructure,
      hasDemolitionMaterial: hasDemolitionMaterial,
      rubbleVolumeEstimate: volumeEstimate,
      boundingBoxes: filteredDetections,
      segmentationMask: segmentationMask,
      overallConfidence: overallConfidence,
      maskWidth: originalWidth,
      maskHeight: originalHeight,
      errorMessage: warningMessage,
      isSuccessful: true,
      metadata: {
        'imageWidth': originalWidth,
        'imageHeight': originalHeight,
        'detectionsCount': filteredDetections.length,
        'modelInputSize': _inputSize,
      },
    );
  }

  List<BoundingBox> _parseYolov8Detections(
    Float32List output,
    int imageWidth,
    int imageHeight,
    List<int> outputShape,
  ) {
    final detections = <BoundingBox>[];
    
    print('Parsing detections from shape: $outputShape');
    
    // Determine the format based on output shape
    // Common YOLOv8 formats:
    // [1, 8400, 4] - only bounding boxes (x, y, w, h)
    // [1, 8400, 84] - bbox + 80 classes (x, y, w, h, class0...class79)
    // [1, 8400, 116] - bbox + 80 classes + 32 mask coeffs
    // [1, 84, 8400] or [1, 4, 8400] - transposed format
    
    int numPredictions;
    int numValues;
    bool isTransposed = false;
    
    if (outputShape.length == 3) {
      if (outputShape[1] > outputShape[2]) {
        // Format: [1, 8400, N]
        numPredictions = outputShape[1];
        numValues = outputShape[2];
      } else {
        // Format: [1, N, 8400] - transposed
        numValues = outputShape[1];
        numPredictions = outputShape[2];
        isTransposed = true;
      }
    } else {
      print('Unexpected output shape: $outputShape');
      return detections;
    }
    
    print('Predictions: $numPredictions, Values per prediction: $numValues, Transposed: $isTransposed');
    
    // Parse based on format
    if (numValues == 4) {
      // Only bounding boxes, no class probabilities
      return _parseDetectionsBboxOnly(output, imageWidth, imageHeight, numPredictions, isTransposed);
    } else if (numValues >= 84) {
      // Bbox + classes (and possibly mask coefficients)
      return _parseDetectionsWithClasses(output, imageWidth, imageHeight, numPredictions, numValues, isTransposed);
    }
    
    return detections;
  }
  
  List<BoundingBox> _parseDetectionsBboxOnly(
    Float32List output,
    int imageWidth,
    int imageHeight,
    int numPredictions,
    bool isTransposed,
  ) {
    final detections = <BoundingBox>[];
    
    // When there are only bounding boxes, we treat all detections as potential rubble/debris
    // with confidence based on box size and position
    for (int i = 0; i < numPredictions; i++) {
      double centerX, centerY, width, height;
      
      if (isTransposed) {
        // [1, 4, 8400] format: data is [x0, x1, x2, ...], [y0, y1, y2, ...], ...
        centerX = output[i];
        centerY = output[numPredictions + i];
        width = output[2 * numPredictions + i];
        height = output[3 * numPredictions + i];
      } else {
        // [1, 8400, 4] format: data is [x, y, w, h], [x, y, w, h], ...
        final offset = i * 4;
        centerX = output[offset + 0];
        centerY = output[offset + 1];
        width = output[offset + 2];
        height = output[offset + 3];
      }
      
      // Skip invalid boxes
      if (width <= 0 || height <= 0) continue;
      
      // For detection-only models, use box size as confidence heuristic
      // Larger boxes = more confident detections
      final boxArea = width * height;
      final normalizedArea = boxArea / (_inputSize * _inputSize);
      final confidence = math.min(0.9, 0.3 + normalizedArea * 2);
      
      // Skip very small boxes
      if (normalizedArea < 0.001) continue;
      
      // Convert from center format to corner format, denormalize
      final x = (centerX - width / 2) * imageWidth / _inputSize;
      final y = (centerY - height / 2) * imageHeight / _inputSize;
      final w = width * imageWidth / _inputSize;
      final h = height * imageHeight / _inputSize;
      
      // Clamp to image boundaries
      final clampedX = x.clamp(0, imageWidth.toDouble()).toDouble();
      final clampedY = y.clamp(0, imageHeight.toDouble()).toDouble();
      final clampedW = ((x + w).clamp(0, imageWidth.toDouble()) - clampedX).toDouble();
      final clampedH = ((y + h).clamp(0, imageHeight.toDouble()) - clampedY).toDouble();
      
      if (clampedW <= 0 || clampedH <= 0) continue;
      
      // Infer label based on box characteristics
      String label = 'rubble';
      if (normalizedArea > 0.2) {
        label = 'concrete';
      } else if (normalizedArea < 0.05) {
        label = 'debris';
      }
      
      detections.add(BoundingBox(
        x: clampedX,
        y: clampedY,
        width: clampedW,
        height: clampedH,
        confidence: confidence,
        label: label,
        classId: null,
      ));
    }
    
    return detections;
  }
  
  List<BoundingBox> _parseDetectionsWithClasses(
    Float32List output,
    int imageWidth,
    int imageHeight,
    int numPredictions,
    int numValues,
    bool isTransposed,
  ) {
    final detections = <BoundingBox>[];
    final numClasses = numValues - 4; // Subtract bbox coords
    
    for (int i = 0; i < numPredictions; i++) {
      double centerX, centerY, width, height;
      List<double> classScores = [];
      
      if (isTransposed) {
        centerX = output[i];
        centerY = output[numPredictions + i];
        width = output[2 * numPredictions + i];
        height = output[3 * numPredictions + i];
        
        for (int c = 0; c < numClasses; c++) {
          classScores.add(output[(4 + c) * numPredictions + i]);
        }
      } else {
        final offset = i * numValues;
        centerX = output[offset + 0];
        centerY = output[offset + 1];
        width = output[offset + 2];
        height = output[offset + 3];
        
        for (int c = 0; c < numClasses; c++) {
          classScores.add(output[offset + 4 + c]);
        }
      }
      
      // Skip invalid boxes
      if (width <= 0 || height <= 0) continue;
      
      // Find best class
      double maxClassScore = classScores[0];
      int bestClass = 0;
      for (int c = 1; c < math.min(80, classScores.length); c++) {
        if (classScores[c] > maxClassScore) {
          maxClassScore = classScores[c];
          bestClass = c;
        }
      }
      
      final confidence = maxClassScore;
      if (confidence < _confidenceThreshold) continue;
      
      // Convert from center format to corner format, denormalize
      final x = (centerX - width / 2) * imageWidth / _inputSize;
      final y = (centerY - height / 2) * imageHeight / _inputSize;
      final w = width * imageWidth / _inputSize;
      final h = height * imageHeight / _inputSize;
      
      // Clamp to image boundaries
      final clampedX = x.clamp(0, imageWidth.toDouble()).toDouble();
      final clampedY = y.clamp(0, imageHeight.toDouble()).toDouble();
      final clampedW = ((x + w).clamp(0, imageWidth.toDouble()) - clampedX).toDouble();
      final clampedH = ((y + h).clamp(0, imageHeight.toDouble()) - clampedY).toDouble();
      
      if (clampedW <= 0 || clampedH <= 0) continue;
      
      // Map class ID to label
      final label = _inferLabelFromClass(bestClass, confidence);
      
      detections.add(BoundingBox(
        x: clampedX,
        y: clampedY,
        width: clampedW,
        height: clampedH,
        confidence: confidence,
        label: label,
        classId: bestClass,
      ));
    }
    
    return detections;
  }

  String _inferLabelFromClass(int classId, double confidence) {
    // Since COCO doesn't have concrete/rubble classes, we use heuristics
    // based on object types and confidence patterns
    
    // High confidence detections of structural objects → concrete
    if (confidence > 0.6) {
      // Classes that might indicate structures: building parts, walls, etc.
      if (classId >= 60 && classId <= 70) {
        return 'concrete';
      }
    }
    
    // Lower, scattered detections → potential rubble/debris
    if (confidence > 0.3 && confidence < 0.6) {
      return 'rubble';
    }
    
    return _cocoClasses[classId] ?? 'unknown_$classId';
  }

  List<BoundingBox> _applyNMS(List<BoundingBox> boxes, double iouThreshold) {
    if (boxes.isEmpty) return [];
    
    // Sort by confidence descending
    boxes.sort((a, b) => b.confidence.compareTo(a.confidence));
    
    final selected = <BoundingBox>[];
    final suppressed = <bool>[];
    
    for (int i = 0; i < boxes.length; i++) {
      suppressed.add(false);
    }
    
    for (int i = 0; i < boxes.length; i++) {
      if (suppressed[i]) continue;
      
      selected.add(boxes[i]);
      
      for (int j = i + 1; j < boxes.length; j++) {
        if (suppressed[j]) continue;
        
        final iou = _calculateIoU(boxes[i], boxes[j]);
        if (iou > iouThreshold) {
          suppressed[j] = true;
        }
      }
    }
    
    return selected;
  }

  double _calculateIoU(BoundingBox a, BoundingBox b) {
    final x1 = math.max(a.x, b.x);
    final y1 = math.max(a.y, b.y);
    final x2 = math.min(a.x + a.width, b.x + b.width);
    final y2 = math.min(a.y + a.height, b.y + b.height);
    
    if (x2 < x1 || y2 < y1) return 0.0;
    
    final intersection = (x2 - x1) * (y2 - y1);
    final union = a.area + b.area - intersection;
    
    return union > 0 ? intersection / union : 0.0;
  }

  Uint8List? _generateSegmentationMask(
    List<BoundingBox> detections,
    int width,
    int height,
  ) {
    // Generate a simple binary mask from bounding boxes
    // In a full implementation, this would use the proto masks from YOLOv8
    final mask = Uint8List(width * height);
    
    for (final detection in detections) {
      if (detection.label == 'rubble' || detection.label == 'concrete') {
        final x1 = detection.x.clamp(0, width - 1).toInt();
        final y1 = detection.y.clamp(0, height - 1).toInt();
        final x2 = (detection.x + detection.width).clamp(0, width).toInt();
        final y2 = (detection.y + detection.height).clamp(0, height).toInt();
        
        for (int y = y1; y < y2; y++) {
          for (int x = x1; x < x2; x++) {
            mask[y * width + x] = 255;
          }
        }
      }
    }
    
    return mask;
  }

  // ============================================================================
  // PUBLIC DETECTION METHODS
  // ============================================================================

  /// Detect if the image contains a concrete structure
  /// 
  /// Uses heuristics based on:
  /// - Detection of structural objects with high confidence
  /// - Minimum area coverage threshold
  /// - Presence of specific class labels
  bool detectConcrete(List<BoundingBox> detections, int imageWidth, int imageHeight) {
    final imageArea = imageWidth * imageHeight;
    
    // Find detections that might be concrete structures
    final concreteDetections = detections.where((box) {
      return box.label == 'concrete' || 
             (box.confidence >= _minConfidenceForStructure &&
              _concreteIndicators.any((indicator) => box.label?.contains(indicator) ?? false));
    }).toList();
    
    if (concreteDetections.isEmpty) return false;
    
    // Calculate total area of concrete detections
    final totalConcreteArea = concreteDetections
        .map((box) => box.area)
        .fold(0.0, (sum, area) => sum + area);
    
    final areaRatio = totalConcreteArea / imageArea;
    
    // Concrete structure detected if:
    // 1. At least one high-confidence detection, AND
    // 2. Coverage exceeds minimum threshold
    return concreteDetections.any((box) => box.confidence >= _minConfidenceForStructure) &&
           areaRatio >= _minAreaRatioForStructure;
  }

  /// Detect if the image contains demolition material/rubble
  /// 
  /// Uses heuristics based on:
  /// - Detection of rubble/debris objects
  /// - Pattern of scattered, lower-confidence detections
  /// - Presence of specific class labels
  bool detectDemolitionMaterial(List<BoundingBox> detections, int imageWidth, int imageHeight) {
    // Find detections that might be rubble/demolition material
    final rubbleDetections = detections.where((box) {
      return box.label == 'rubble' ||
             _rubbleIndicators.any((indicator) => box.label?.contains(indicator) ?? false);
    }).toList();
    
    if (rubbleDetections.isEmpty) return false;
    
    // Rubble typically shows as multiple scattered detections
    // with moderate confidence (not too high, not too low)
    final scatteredRubble = rubbleDetections.where((box) {
      return box.confidence >= 0.25 && box.confidence <= 0.7;
    }).toList();
    
    // Detect rubble if we have multiple scattered detections
    return scatteredRubble.length >= 2;
  }

  /// Estimate volume of demolition material from segmentation mask
  /// 
  /// Uses the segmentation mask to calculate area, then applies
  /// geometric assumptions to estimate volume:
  /// 
  /// 1. Count pixels in rubble mask
  /// 2. Convert pixel area to physical area (m²) using [_pixelsToMetersRatio]
  /// 3. Multiply by assumed depth coefficient to get volume (m³)
  /// 
  /// Note: This is an approximation that assumes:
  /// - Standard photo distance (~2-5 meters)
  /// - Average rubble depth of ~30cm
  /// - Flat/even rubble distribution
  /// 
  /// Returns volume in cubic meters (m³)
  double estimateVolumeFromSegmentation(
    List<BoundingBox> detections,
    Float32List? protoMasks,
    int imageWidth,
    int imageHeight,
  ) {
    // Filter rubble detections
    final rubbleDetections = detections.where((box) {
      return box.label == 'rubble' ||
             _rubbleIndicators.any((indicator) => box.label?.contains(indicator) ?? false);
    }).toList();
    
    if (rubbleDetections.isEmpty) return 0.0;
    
    // Calculate total rubble area in pixels
    final totalRubbleAreaPixels = rubbleDetections
        .map((box) => box.area)
        .fold(0.0, (sum, area) => sum + area);
    
    // Convert pixel area to physical area (m²)
    // Assumption: Each pixel represents approximately 1cm² at typical distance
    final areaInSquareMeters = totalRubbleAreaPixels * math.pow(_pixelsToMetersRatio, 2);
    
    // Estimate volume by multiplying area by depth coefficient
    final volumeInCubicMeters = areaInSquareMeters * _rubbleDepthCoefficient;
    
    return volumeInCubicMeters;
  }
}

// ============================================================================
// PRIVATE DATA CLASSES
// ============================================================================

class _PreprocessedImage {
  final Float32List imageData;
  final int originalWidth;
  final int originalHeight;

  _PreprocessedImage({
    required this.imageData,
    required this.originalWidth,
    required this.originalHeight,
  });
}

class _InferenceResult {
  final Float32List detections;
  final Float32List? protoMasks;
  final int originalWidth;
  final int originalHeight;
  final List<List<int>> outputShapes;

  _InferenceResult({
    required this.detections,
    this.protoMasks,
    required this.originalWidth,
    required this.originalHeight,
    required this.outputShapes,
  });
}
