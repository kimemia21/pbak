# Concrete & Demolition Material Detection AI Module

## Overview

This AI module provides automated detection and analysis of concrete structures and demolition materials using YOLOv8 segmentation model running on-device via TensorFlow Lite.

## Features

The module performs three main tasks:

### 1. **Concrete Structure Detection**
Detects whether the image contains concrete structures such as:
- Buildings and walls
- Structural elements
- Concrete foundations
- Other construction materials

**Detection Logic:**
- Uses object detection with confidence thresholds
- Requires minimum area coverage (5% of image)
- Looks for high-confidence structural elements (>40% confidence)

### 2. **Demolition Material Detection**
Identifies rubble, debris, and demolition waste materials:
- Scattered rubble piles
- Demolished construction materials
- Debris and waste

**Detection Logic:**
- Looks for scattered, moderate-confidence detections
- Requires multiple detection points (≥2)
- Filters by confidence range (25-70%)

### 3. **Volume Estimation**
Estimates the volume of demolition material/rubble in cubic meters (m³):

**Calculation Method:**
```
1. Extract segmentation mask for rubble regions
2. Calculate total rubble area in pixels
3. Convert to physical area: area_m² = pixels × (0.01 m)²
4. Apply depth coefficient: volume_m³ = area_m² × 0.3 m
```

**Assumptions:**
- Photo taken from standard distance (2-5 meters)
- Average rubble depth: 30 cm
- Flat/even rubble distribution
- 1 pixel ≈ 1 cm at typical distance

## Usage

### Basic Usage

```dart
import 'dart:io';
import 'package:pbak/ai/concrete_detection_service.dart';

// Initialize service
final service = ConcreteDetectionService();
await service.initialize();

// Analyze image
final imageFile = File('/path/to/image.jpg');
final result = await service.analyze(imageFile);

// Check results
if (result.isSuccessful) {
  print('Concrete detected: ${result.hasConcreteStructure}');
  print('Rubble detected: ${result.hasDemolitionMaterial}');
  print('Volume estimate: ${result.rubbleVolumeEstimate} m³');
  print('Confidence: ${(result.overallConfidence * 100).toStringAsFixed(1)}%');
  print('Detected objects: ${result.boundingBoxes.length}');
} else {
  print('Error: ${result.errorMessage}');
}

// Clean up
service.dispose();
```

### Result Object

```dart
class DetectionResult {
  final bool hasConcreteStructure;      // True if concrete detected
  final bool hasDemolitionMaterial;     // True if rubble detected
  final double rubbleVolumeEstimate;    // Volume in m³
  final List<BoundingBox> boundingBoxes; // All detected objects
  final Uint8List? segmentationMask;    // Binary mask
  final double overallConfidence;       // 0-1 confidence score
  final String? errorMessage;           // Warnings/errors
  final bool isSuccessful;              // Success flag
}
```

### Bounding Box

```dart
class BoundingBox {
  final double x, y;              // Top-left corner
  final double width, height;     // Dimensions
  final double confidence;        // 0-1 score
  final String? label;           // Class label
  final int? classId;            // COCO class ID
}
```

## Model Information

**Model:** YOLOv8s-seg (Segmentation)
**Format:** TensorFlow Lite (.tflite)
**Location:** `assets/ai/yolov8s-seg.tflite`

**Input:**
- Shape: [1, 640, 640, 3]
- Type: Float32
- Range: [0, 1] (normalized RGB)

**Output:**
- Detection output: [1, 116, 8400]
  - 8400 predictions with 116 values each
  - Format: [x, y, w, h, conf, class_scores..., mask_coeffs]
- Proto masks: [1, 32, 160, 160] (optional)

## Configuration & Thresholds

You can adjust detection behavior by modifying constants in `ConcreteDetectionService`:

```dart
// Detection thresholds
static const double _confidenceThreshold = 0.25;        // Minimum detection confidence
static const double _iouThreshold = 0.45;               // NMS IoU threshold
static const double _minConfidenceForStructure = 0.4;   // Concrete detection threshold
static const double _minAreaRatioForStructure = 0.05;   // 5% minimum coverage

// Volume estimation coefficients
static const double _pixelsToMetersRatio = 0.01;        // 1 pixel = 1 cm
static const double _rubbleDepthCoefficient = 0.3;      // 30 cm average depth
```

## Performance & Limitations

### Performance
- **On-device inference:** ~200-500ms per image (depending on device)
- **Model size:** ~25 MB (YOLOv8s-seg)
- **Memory usage:** ~100-200 MB during inference

### Limitations

⚠️ **Important Disclaimers:**

1. **Not structurally certified:** This tool is NOT a replacement for professional structural engineering assessment.

2. **Volume estimation is approximate:** Actual volume may vary significantly based on:
   - Camera distance and angle
   - Rubble pile shape (uneven surfaces)
   - Occlusions and hidden material
   - Lighting and image quality

3. **Environmental sensitivity:**
   - Poor lighting reduces accuracy
   - Motion blur affects detection
   - Extreme angles cause distortion
   - Occlusions hide material

4. **Model limitations:**
   - YOLOv8 trained on COCO dataset (general objects)
   - Uses heuristics for concrete/rubble (not trained specifically)
   - May not recognize all construction materials
   - False positives/negatives possible

5. **Distance assumptions:**
   - Volume calculation assumes standard photo distance (2-5m)
   - Closer/farther distances will affect accuracy
   - No automatic distance calibration

## Tips for Better Results

### 📸 Image Capture Best Practices

1. **Lighting:**
   - Use natural daylight when possible
   - Avoid harsh shadows or direct sunlight
   - Ensure even illumination

2. **Camera Position:**
   - Maintain 2-5 meter distance from subject
   - Use overhead/elevated angle for rubble piles
   - Keep camera parallel to ground for structures
   - Avoid extreme angles (>45°)

3. **Image Quality:**
   - Use minimum 1280x720 resolution
   - Ensure focus is sharp (no blur)
   - Clean camera lens
   - Avoid digital zoom

4. **Subject Framing:**
   - Include entire rubble pile in frame
   - Minimize background clutter
   - Show clear boundaries
   - Include reference objects (optional) for scale

5. **Multiple Shots:**
   - Take photos from multiple angles
   - Capture different sections for large areas
   - Use consistent distance across shots

### 🔍 Interpreting Results

**High Confidence (>70%):**
- Very reliable detection
- Good lighting and clarity
- Clear object boundaries

**Medium Confidence (40-70%):**
- Acceptable detection
- May need verification
- Consider retaking photo

**Low Confidence (<40%):**
- Unreliable detection
- Retake photo with better conditions
- Check for warnings in `errorMessage`

**Volume Estimates:**
- Treat as rough approximation (±50% error margin)
- Compare multiple photos for consistency
- Use professional surveying for critical measurements

## Error Handling

The service provides user-friendly error messages:

```dart
// Low confidence warning
"Low detection confidence. Try better lighting or closer distance."

// Low resolution warning
"Low image resolution. Try taking a higher quality photo."

// Initialization errors
"Failed to load model: [error details]"
"Model not initialized"

// Processing errors
"Failed to preprocess image. Check image format and quality."
"Analysis failed: [error details]"
```

## Dependencies

Required packages (already in `pubspec.yaml`):

```yaml
dependencies:
  tflite_flutter: ^0.12.1  # TensorFlow Lite inference
  image: ^4.2.0            # Image processing
  image_picker: ^1.0.7     # Camera/gallery access
```

## File Structure

```
lib/ai/
├── concrete_detection_service.dart   # Main service class
├── models/
│   ├── bounding_box.dart             # BoundingBox model
│   └── detection_result.dart         # DetectionResult model
└── README.md                          # This file

assets/ai/
└── yolov8s-seg.tflite                # YOLOv8 segmentation model
```

## Integration Example

See `lib/views/ai/concrete_detection_screen.dart` for a complete UI implementation that demonstrates:
- Image capture/selection
- Progress indication
- Results display
- Error handling

## Future Improvements

Potential enhancements:

1. **Custom model training:**
   - Train on construction-specific dataset
   - Add concrete/rubble/debris classes
   - Improve detection accuracy

2. **Advanced volume estimation:**
   - Integrate depth sensors (LiDAR)
   - Use stereo vision for depth mapping
   - Camera calibration for distance

3. **Multi-image analysis:**
   - Stitch multiple photos
   - 3D reconstruction
   - Panoramic scanning

4. **Real-time analysis:**
   - Live camera feed processing
   - Augmented reality overlay
   - Continuous tracking

5. **Cloud integration:**
   - Server-side processing for complex models
   - Historical data analysis
   - Report generation

## Support & Troubleshooting

### Common Issues

**Model fails to load:**
- Verify `assets/ai/yolov8s-seg.tflite` exists
- Check `pubspec.yaml` has asset entry
- Run `flutter pub get` and `flutter clean`

**Low accuracy:**
- Improve image quality (see tips above)
- Adjust confidence thresholds
- Consider custom model training

**Slow performance:**
- Use smaller model variant (nano/small)
- Reduce input resolution
- Enable GPU acceleration (if available)

**Memory issues:**
- Process images at lower resolution
- Clear cache between analyses
- Monitor device memory

## License & Attribution

This module uses:
- **YOLOv8:** Ultralytics AGPL-3.0 License
- **TensorFlow Lite:** Apache 2.0 License
- **Flutter packages:** Various open-source licenses

## Version History

- **v1.0.0** (2024): Initial implementation
  - YOLOv8-seg integration
  - Basic concrete/rubble detection
  - Volume estimation with heuristics
