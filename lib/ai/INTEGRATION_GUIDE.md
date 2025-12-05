# AI Module Integration Guide

## Quick Start

### 1. Add the Model File

Place your YOLOv8 model at:
```
assets/ai/yolov8s-seg.tflite
```

See `assets/ai/README.md` for download instructions.

### 2. Add to Your App Router

Add the concrete detection screen to your app's router:

```dart
// In lib/utils/router.dart or your routing configuration
import 'package:pbak/views/ai/concrete_detection_screen.dart';

// Add route
GoRoute(
  path: '/concrete-detection',
  name: 'concrete-detection',
  builder: (context, state) => const ConcreteDetectionScreen(),
),
```

### 3. Add Navigation Button

Add a button to navigate to the detection screen from anywhere in your app:

```dart
ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ConcreteDetectionScreen(),
      ),
    );
  },
  child: const Text('Analyze Construction Site'),
)
```

Or with GoRouter:

```dart
ElevatedButton(
  onPressed: () => context.go('/concrete-detection'),
  child: const Text('Analyze Construction Site'),
)
```

### 4. Test the Integration

Run the app and navigate to the concrete detection screen:

```bash
flutter run
```

## Using the Service Programmatically

### Basic Usage

```dart
import 'package:pbak/ai/ai_module.dart';
import 'dart:io';

// Initialize service
final service = ConcreteDetectionService();
await service.initialize();

// Analyze image
final imageFile = File('path/to/image.jpg');
final result = await service.analyze(imageFile);

// Check results
if (result.isSuccessful) {
  if (result.hasConcreteStructure) {
    print('Concrete structure detected!');
  }
  
  if (result.hasDemolitionMaterial) {
    print('Rubble detected!');
    print('Estimated volume: ${result.rubbleVolumeEstimate} m³');
  }
  
  print('Confidence: ${result.overallConfidence}');
  print('Objects detected: ${result.boundingBoxes.length}');
}

// Clean up
service.dispose();
```

### With Error Handling

```dart
try {
  final service = ConcreteDetectionService();
  
  final initialized = await service.initialize();
  if (!initialized) {
    print('Failed to initialize AI model');
    return;
  }
  
  final result = await service.analyze(imageFile);
  
  if (!result.isSuccessful) {
    print('Analysis failed: ${result.errorMessage}');
    return;
  }
  
  // Handle warnings
  if (result.errorMessage != null) {
    print('Warning: ${result.errorMessage}');
  }
  
  // Use results...
  
} catch (e) {
  print('Error: $e');
} finally {
  service.dispose();
}
```

### Integration with State Management

If you're using Riverpod (already in your project):

```dart
// Create a provider
final concreteDetectionServiceProvider = Provider<ConcreteDetectionService>((ref) {
  final service = ConcreteDetectionService();
  ref.onDispose(() => service.dispose());
  return service;
});

// Use in a widget
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(concreteDetectionServiceProvider);
    
    return ElevatedButton(
      onPressed: () async {
        await service.initialize();
        final result = await service.analyze(imageFile);
        // Handle result...
      },
      child: const Text('Analyze'),
    );
  }
}
```

## Integration Examples

### Example 1: Add to Home Screen

```dart
// In lib/views/home_screen.dart

Card(
  child: ListTile(
    leading: const Icon(Icons.construction),
    title: const Text('Site Analysis'),
    subtitle: const Text('Detect concrete & estimate rubble'),
    trailing: const Icon(Icons.chevron_right),
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ConcreteDetectionScreen(),
        ),
      );
    },
  ),
)
```

### Example 2: Add to Drawer Menu

```dart
// In your drawer widget

ListTile(
  leading: const Icon(Icons.analytics),
  title: const Text('Construction Analysis'),
  onTap: () {
    Navigator.pop(context); // Close drawer
    Navigator.pushNamed(context, '/concrete-detection');
  },
)
```

### Example 3: Integration with Existing Bike/Document Features

You can integrate the concrete detection with existing features:

```dart
// Example: Add analysis to a construction project model
class ConstructionProject {
  final String id;
  final String name;
  final List<File> photos;
  DetectionResult? analysisResult;
  
  Future<void> analyzePhotos() async {
    final service = ConcreteDetectionService();
    await service.initialize();
    
    for (final photo in photos) {
      final result = await service.analyze(photo);
      // Store or aggregate results
      if (result.hasDemolitionMaterial) {
        // Update project stats
      }
    }
    
    service.dispose();
  }
}
```

## Customization

### Adjust Detection Thresholds

Edit constants in `lib/ai/concrete_detection_service.dart`:

```dart
// Lower value = more detections (less strict)
// Higher value = fewer detections (more strict)
static const double _confidenceThreshold = 0.25;

// Minimum confidence for concrete structures
static const double _minConfidenceForStructure = 0.4;

// Minimum image coverage to detect concrete (5%)
static const double _minAreaRatioForStructure = 0.05;
```

### Adjust Volume Estimation

```dart
// Pixel to meter conversion (depends on camera distance)
static const double _pixelsToMetersRatio = 0.01; // 1 pixel = 1 cm

// Average rubble depth in meters
static const double _rubbleDepthCoefficient = 0.3; // 30 cm
```

### Customize UI

The detection screen is in `lib/views/ai/concrete_detection_screen.dart`.

You can customize:
- Colors and styling
- Button layout
- Results display format
- Add save/share functionality
- Add history/logging

## Testing

### Test with Demo Image

1. Place a test image at `assets/ai/demo.jpg`
2. Run the test script:

```bash
# Run the standalone test
flutter run -t lib/ai/test_detection.dart
```

### Test in App

1. Run the app: `flutter run`
2. Navigate to concrete detection screen
3. Take or select a photo
4. View results

### Debug Mode

The service prints debug information. Check console output:
```
Model output shapes:
  Output 0: [1, 8400, 4]
Parsing detections from shape: [1, 8400, 4]
Predictions: 8400, Values per prediction: 4, Transposed: false
```

## Troubleshooting

### Model Not Loading

**Error:** `Failed to load model`

**Solutions:**
- Verify model file exists: `assets/ai/yolov8s-seg.tflite`
- Check `pubspec.yaml` has asset entry
- Run `flutter clean` and `flutter pub get`
- Rebuild app: `flutter run`

### No Detections

**Error:** `overallConfidence: 0.0`, no objects detected

**Solutions:**
- Check image quality (not too dark/blurry)
- Try different camera distance (2-5 meters)
- Ensure model file is correct format
- Lower `_confidenceThreshold` for testing

### Low Confidence

**Warning:** `Low detection confidence`

**Solutions:**
- Improve lighting conditions
- Use higher resolution image
- Get closer to subject
- Ensure subject is in focus

### Wrong Detections

**Issue:** Detecting wrong objects as concrete/rubble

**Solutions:**
- Adjust heuristics in `_inferLabelFromClass()`
- Use custom-trained model (see AI README)
- Adjust confidence thresholds
- Filter by object size/position

### Performance Issues

**Issue:** Slow inference (>1 second)

**Solutions:**
- Use smaller model variant (nano instead of small)
- Reduce input image resolution before analysis
- Enable GPU acceleration (if available)
- Run on newer device

## Performance Tips

1. **Initialize Once:** Keep service instance alive instead of recreating
2. **Resize Images:** Downscale very large images before analysis
3. **Background Processing:** Run analysis in isolate for UI responsiveness
4. **Cache Results:** Store analysis results to avoid re-processing

## Next Steps

1. ✅ Integrate into your app navigation
2. ✅ Test with real construction photos
3. ✅ Customize thresholds for your use case
4. ✅ Add result saving/sharing functionality
5. ✅ Consider training custom model for better accuracy

## Support

For issues or questions:
- Check `lib/ai/README.md` for model information
- Review console debug output
- Test with `lib/ai/test_detection.dart`
- Verify model file integrity
