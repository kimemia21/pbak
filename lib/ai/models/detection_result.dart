import 'dart:typed_data';
import 'bounding_box.dart';

/// Result of the concrete and demolition material detection analysis.
class DetectionResult {
  /// Whether a concrete structure was detected in the image
  final bool hasConcreteStructure;
  
  /// Whether demolition material/rubble was detected in the image
  final bool hasDemolitionMaterial;
  
  /// Estimated volume of rubble/demolition material in cubic meters (m³)
  /// This is an approximation based on segmentation mask area and depth coefficients.
  final double rubbleVolumeEstimate;
  
  /// List of detected bounding boxes for all objects
  final List<BoundingBox> boundingBoxes;
  
  /// Segmentation mask data (optional)
  /// For YOLOv8-seg, this contains the segmentation masks for detected objects.
  /// Format depends on model output (e.g., per-object masks or combined mask).
  final Uint8List? segmentationMask;
  
  /// Overall confidence score for the entire detection (0-1)
  /// Computed as average of all detection confidences or max confidence.
  final double overallConfidence;
  
  /// Width of the segmentation mask (in pixels)
  final int? maskWidth;
  
  /// Height of the segmentation mask (in pixels)
  final int? maskHeight;
  
  /// Additional metadata about the detection
  final Map<String, dynamic>? metadata;
  
  /// Error message if detection failed or has warnings
  final String? errorMessage;
  
  /// Whether the detection was successful (no critical errors)
  final bool isSuccessful;

  const DetectionResult({
    required this.hasConcreteStructure,
    required this.hasDemolitionMaterial,
    required this.rubbleVolumeEstimate,
    required this.boundingBoxes,
    this.segmentationMask,
    required this.overallConfidence,
    this.maskWidth,
    this.maskHeight,
    this.metadata,
    this.errorMessage,
    this.isSuccessful = true,
  });

  /// Creates an empty/failed detection result
  factory DetectionResult.empty({String? errorMessage}) {
    return DetectionResult(
      hasConcreteStructure: false,
      hasDemolitionMaterial: false,
      rubbleVolumeEstimate: 0.0,
      boundingBoxes: [],
      segmentationMask: null,
      overallConfidence: 0.0,
      errorMessage: errorMessage,
      isSuccessful: false,
    );
  }

  /// Creates a copy with optional field overrides
  DetectionResult copyWith({
    bool? hasConcreteStructure,
    bool? hasDemolitionMaterial,
    double? rubbleVolumeEstimate,
    List<BoundingBox>? boundingBoxes,
    Uint8List? segmentationMask,
    double? overallConfidence,
    int? maskWidth,
    int? maskHeight,
    Map<String, dynamic>? metadata,
    String? errorMessage,
    bool? isSuccessful,
  }) {
    return DetectionResult(
      hasConcreteStructure: hasConcreteStructure ?? this.hasConcreteStructure,
      hasDemolitionMaterial: hasDemolitionMaterial ?? this.hasDemolitionMaterial,
      rubbleVolumeEstimate: rubbleVolumeEstimate ?? this.rubbleVolumeEstimate,
      boundingBoxes: boundingBoxes ?? this.boundingBoxes,
      segmentationMask: segmentationMask ?? this.segmentationMask,
      overallConfidence: overallConfidence ?? this.overallConfidence,
      maskWidth: maskWidth ?? this.maskWidth,
      maskHeight: maskHeight ?? this.maskHeight,
      metadata: metadata ?? this.metadata,
      errorMessage: errorMessage ?? this.errorMessage,
      isSuccessful: isSuccessful ?? this.isSuccessful,
    );
  }

  /// Gets bounding boxes filtered by class label
  List<BoundingBox> getBoxesByLabel(String label) {
    return boundingBoxes.where((box) => box.label == label).toList();
  }

  /// Gets bounding boxes with confidence above threshold
  List<BoundingBox> getBoxesAboveConfidence(double threshold) {
    return boundingBoxes.where((box) => box.confidence >= threshold).toList();
  }

  /// Gets a human-readable summary of the detection
  String getSummary() {
    final buffer = StringBuffer();
    
    if (hasConcreteStructure) {
      buffer.writeln('✓ Concrete structure detected');
    } else {
      buffer.writeln('✗ No concrete structure detected');
    }
    
    if (hasDemolitionMaterial) {
      buffer.writeln('✓ Demolition material detected');
      buffer.writeln('  Estimated volume: ${rubbleVolumeEstimate.toStringAsFixed(2)} m³');
    } else {
      buffer.writeln('✗ No demolition material detected');
    }
    
    buffer.writeln('Overall confidence: ${(overallConfidence * 100).toStringAsFixed(1)}%');
    buffer.writeln('Detected objects: ${boundingBoxes.length}');
    
    if (errorMessage != null) {
      buffer.writeln('⚠ Warning: $errorMessage');
    }
    
    return buffer.toString();
  }

  @override
  String toString() {
    return 'DetectionResult(concrete: $hasConcreteStructure, '
        'demolition: $hasDemolitionMaterial, '
        'volume: ${rubbleVolumeEstimate.toStringAsFixed(2)} m³, '
        'confidence: ${(overallConfidence * 100).toStringAsFixed(1)}%, '
        'objects: ${boundingBoxes.length})';
  }

  Map<String, dynamic> toJson() {
    return {
      'hasConcreteStructure': hasConcreteStructure,
      'hasDemolitionMaterial': hasDemolitionMaterial,
      'rubbleVolumeEstimate': rubbleVolumeEstimate,
      'boundingBoxes': boundingBoxes.map((box) => box.toJson()).toList(),
      'overallConfidence': overallConfidence,
      'maskWidth': maskWidth,
      'maskHeight': maskHeight,
      'metadata': metadata,
      'errorMessage': errorMessage,
      'isSuccessful': isSuccessful,
    };
  }
}
