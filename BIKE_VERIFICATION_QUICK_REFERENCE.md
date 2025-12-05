# Bike Verification Screen - Quick Reference

## 🚀 Quick Start

### Basic Usage
```dart
final result = await Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => BikeRegistrationVerificationScreen(
      imageType: 'rear', // 'front', 'side', or 'rear'
    ),
  ),
);

if (result != null) {
  final imagePath = result['image'] as String;
  final plateNumber = result['registration_number'] as String?;
  final isVerified = result['is_motorcycle'] as bool;
  
  if (isVerified) {
    // Upload and save
    await uploadImage(imagePath);
  }
}
```

## 📊 Return Data

| Field | Type | Description | Available For |
|-------|------|-------------|---------------|
| `image` | `String` | Path to captured image | All types |
| `registration_number` | `String?` | Extracted plate (e.g., "KBZ 456 Y") | Rear only |
| `is_motorcycle` | `bool` | Verification status | All types |
| `image_type` | `String` | Type used ('front', 'side', 'rear') | All types |

## ✅ Verification Criteria

| View | ML Kit Features | Success Criteria |
|------|----------------|------------------|
| **Front** | Object Detection + Image Labeling | Motorcycle detected (>30% confidence) |
| **Side** | Object Detection + Image Labeling | Motorcycle detected (>30% confidence) |
| **Rear** | OCR + Object Detection + Image Labeling | Valid plate extracted + format validated |

## 🎯 Confidence Thresholds

```dart
// Primary labels (motorcycle, bike, motorbike)
threshold: 30%

// Secondary labels (bicycle, scooter, moped)
threshold: 40%

// Vehicle labels (vehicle, motor, car)
threshold: 60%

// Component labels (wheel, tire)
threshold: 70%
```

## 🔍 Plate Format Validation

### Accepted Patterns
- `ABC 123 D` - Standard format
- `ABC123D` - Compact format
- `AB 1234 CD` - Generic format
- Minimum 6 characters (excluding spaces)
- Must contain both letters AND numbers

### OCR Corrections
```dart
O → 0  // Letter O to zero
I → 1  // Letter I to one
S → 5  // Letter S to five (in numbers)
Z → 2  // Letter Z to two
```

## 🖼️ Frame Sizes

```dart
Front:  80% width × 35% height (landscape)
Side:   85% width × 50% height (wide landscape)
Rear:   75% width × 25% height (narrow + crosshair)
```

## ⚡ Performance Metrics

| Operation | Average Time |
|-----------|-------------|
| ML Kit Init | ~500ms |
| Image Capture | ~100ms |
| Front/Side Analysis | 1-2s |
| Rear Analysis (OCR) | 2-3s |

## 🛠️ Common Integration Patterns

### Auto-fill Registration Number
```dart
final result = await Navigator.push(context, ...);

if (result != null && result['registration_number'] != null) {
  registrationController.text = result['registration_number'];
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Plate detected: ${result['registration_number']}'),
      backgroundColor: Colors.green,
    ),
  );
}
```

### Validate Before Upload
```dart
if (result != null && result['is_motorcycle'] == true) {
  final imagePath = result['image'];
  await uploadBikeImage(imagePath);
} else {
  showError('Please upload a valid motorcycle image');
}
```

### Upload All Three Views
```dart
Map<String, String?> bikePhotos = {
  'front': null,
  'side': null,
  'rear': null,
};

Future<void> captureView(String viewType) async {
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => BikeRegistrationVerificationScreen(
        imageType: viewType,
      ),
    ),
  );

  if (result != null && result['is_motorcycle'] == true) {
    setState(() {
      bikePhotos[viewType] = result['image'];
    });
  }
}

// Usage
await captureView('front');
await captureView('side');
await captureView('rear');

// Validate all captured
if (bikePhotos.values.every((path) => path != null)) {
  // All photos captured - proceed to upload
}
```

## 🚨 Error Handling

### Handle Null Results
```dart
final result = await Navigator.push(...);

if (result == null) {
  // User cancelled - do nothing
  return;
}

if (result['is_motorcycle'] != true) {
  showError('Motorcycle verification failed. Please try again.');
  return;
}
```

### Retry Logic
```dart
int attempts = 0;
const maxAttempts = 3;

while (attempts < maxAttempts) {
  final result = await Navigator.push(...);
  
  if (result != null && result['is_motorcycle'] == true) {
    // Success
    break;
  }
  
  attempts++;
  if (attempts < maxAttempts) {
    showMessage('Attempt $attempts/$maxAttempts. Please try again.');
  } else {
    showError('Unable to verify. Please check image quality.');
  }
}
```

## 🎨 UI Feedback Examples

### Loading State
```dart
bool isCapturing = false;

// Before navigation
setState(() => isCapturing = true);

final result = await Navigator.push(...);

setState(() => isCapturing = false);
```

### Success Feedback
```dart
if (result['is_motorcycle'] == true) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.white),
          SizedBox(width: 8),
          Text('Motorcycle verified successfully!'),
        ],
      ),
      backgroundColor: Colors.green,
    ),
  );
}
```

## 🔧 Troubleshooting Quick Fixes

### ML Kit Not Loading
```dart
// Check initialization state
if (!mounted) return;

// Add error boundary
try {
  final result = await Navigator.push(...);
} catch (e) {
  showError('ML Kit error: $e');
}
```

### Camera Permission Denied
```dart
// Request permission before navigation
final status = await Permission.camera.request();

if (status.isGranted) {
  final result = await Navigator.push(...);
} else {
  showError('Camera permission required');
}
```

### Memory Leaks
```dart
// Screen properly disposes resources
// No action needed - ML Kit models are auto-closed
```

## 📱 Platform-Specific Notes

### Android
- Requires Google Play Services
- Min SDK: 21 (Android 5.0)
- Permissions: `CAMERA`, `READ_EXTERNAL_STORAGE`

### iOS
- Min iOS: 12.0
- Permissions: Camera, Photo Library (Info.plist)
- Works without Google Services

## 🧪 Testing Tips

```dart
// Test with mock data
final mockResult = {
  'image': '/path/to/test/image.jpg',
  'registration_number': 'KBZ 456 Y',
  'is_motorcycle': true,
  'image_type': 'rear',
};

// Test without verification (dev only)
if (kDebugMode) {
  return mockResult;
}
```

## 📊 Key Methods Reference

| Method | Purpose | Returns |
|--------|---------|---------|
| `_initializeMLKit()` | Initialize all ML components | `Future<void>` |
| `_analyzeImage(File)` | Main analysis orchestrator | `Future<void>` |
| `_processRearImage(InputImage)` | Process rear + OCR | `Future<void>` |
| `_processFrontOrSideImage(InputImage)` | Process front/side | `Future<void>` |
| `_verifyMotorcyclePresence(InputImage)` | Dual-method detection | `Future<_MotorcycleVerificationResult>` |
| `_extractRegistrationNumber(InputImage)` | OCR extraction | `Future<String?>` |
| `_validateImageQuality(File)` | Pre-check quality | `Future<_QualityCheckResult>` |
| `_isValidPlateFormat(String)` | Validate plate format | `bool` |
| `_isMotorcycleLabel(String, double)` | Check label match | `bool` |

## 🎯 Common Mistakes to Avoid

❌ **Don't** assume registration_number is always present
```dart
// Wrong
final plate = result['registration_number'];
registrationController.text = plate; // Can be null!

// Right
final plate = result['registration_number'];
if (plate != null) {
  registrationController.text = plate;
}
```

❌ **Don't** skip verification check
```dart
// Wrong
await uploadImage(result['image']);

// Right
if (result['is_motorcycle'] == true) {
  await uploadImage(result['image']);
}
```

❌ **Don't** block UI during analysis
```dart
// Analysis happens on background - UI remains responsive
// No additional handling needed
```

✅ **Do** handle null results (user cancel)
```dart
if (result == null) {
  // User pressed back/cancel
  return;
}
```

## 🌟 Pro Tips

1. **Cache for better UX**: Store captured images temporarily
2. **Batch upload**: Collect all three views before uploading
3. **Validation feedback**: Show real-time tips if verification fails
4. **Retry mechanism**: Allow users to retry with guidance
5. **Quality hints**: Show preview before analysis
6. **Auto-fill**: Use extracted plate to pre-fill forms
7. **Analytics**: Track verification success rates
8. **Offline support**: Works completely offline (no API calls)

## 📞 Support

For issues or questions:
1. Check `BIKE_REGISTRATION_VERIFICATION_IMPLEMENTATION.md` for detailed docs
2. Review error messages - they include actionable tips
3. Test on physical device (emulator cameras are limited)
4. Verify Google Play Services on Android

---

**Quick Reference Version**: 1.0.0  
**Last Updated**: 2024
