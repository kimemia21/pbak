# Bike Registration OCR & Verification Guide

## Overview

The Bike Registration Verification system provides automated OCR (Optical Character Recognition) and image verification for bike registration. This ensures that:

1. **Images are verified as motorcycles** using ML-based image labeling
2. **Registration numbers are automatically extracted** from license plates using OCR
3. **Users get real-time feedback** on image quality and detection results

## Features

### 🎯 Core Capabilities

1. **Motorcycle Verification**
   - Uses Google ML Kit Image Labeling
   - Detects vehicle types with confidence scores
   - Validates that uploaded images are actual motorcycles
   - Rejects non-motorcycle images

2. **OCR Registration Number Extraction**
   - Automatically extracts registration numbers from front/rear photos
   - Supports multiple registration formats:
     - `KBZ 456Y` (with spaces)
     - `ABC123D` (without spaces)
     - `AB 12 CDE` (multiple segments)
   - Auto-fills registration field when detected

3. **Smart Camera Interface**
   - Live camera preview with guide overlay
   - Different frame sizes for different angles:
     - Front/Rear: Square frame for license plate visibility
     - Side: Wide frame for full bike view
   - Gallery upload option
   - Real-time image analysis

4. **Visual Feedback**
   - Verification status indicators
   - Confidence scores
   - Detected labels display
   - Error messages and guidance

## How It Works

### User Flow

```
1. User taps "Upload Front/Side/Rear Photo" in Add Bike Screen
   ↓
2. Bike Registration Verification Screen opens
   ↓
3. User captures image or selects from gallery
   ↓
4. System analyzes image:
   - Verifies it's a motorcycle (Image Labeling)
   - Extracts registration number (OCR - front/rear only)
   ↓
5. Results displayed with visual feedback
   ↓
6. User confirms or retakes
   ↓
7. Image and data returned to Add Bike Screen
   ↓
8. Registration number auto-filled (if detected)
```

### Image Analysis Process

#### 1. Motorcycle Verification
```dart
// Detects labels in the image
ImageLabeler → Processes Image → Returns Labels with Confidence

// Checks for motorcycle-related labels
Motorcycle keywords: [
  'motorcycle', 'motorbike', 'motor scooter',
  'bike', 'two-wheeler', 'vehicle', 'wheel', 'tire'
]

// Verification Logic
if (any keyword matches with confidence > 50%)
  → ✅ Motorcycle Verified
else
  → ❌ Not a Motorcycle
```

#### 2. Registration Number OCR
```dart
// Only runs for front and rear images
TextRecognizer → Extracts Text → Applies RegEx Patterns

// Supported Patterns
Pattern 1: [A-Z]{2,3}\s*\d{2,4}\s*[A-Z]{0,2}  // KBZ 456Y
Pattern 2: [A-Z]{1,2}\s*\d{1,4}\s*[A-Z]{1,3}  // K 123 ABC
Pattern 3: [A-Z]{3}\d{3}[A-Z]                  // ABC123D

// Best match returned and normalized
```

## Usage

### For Users

1. **Capture Front Photo**
   - Position bike's front view in the frame
   - Ensure license plate is visible and clear
   - Good lighting is essential
   - Tap capture button
   - Review results
   - Confirm if motorcycle verified ✅

2. **Capture Side Photo**
   - Position full bike in horizontal frame
   - Show entire motorcycle profile
   - No license plate needed here
   - Confirm if motorcycle verified ✅

3. **Capture Rear Photo**
   - Position bike's rear view in frame
   - Ensure rear license plate is visible
   - Confirm if motorcycle verified ✅

### For Developers

#### Integration in Add Bike Screen

```dart
// When user taps upload button
Future<void> _pickAndUploadImage(String imageType) async {
  // Navigate to verification screen
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => BikeRegistrationVerificationScreen(
        imageType: imageType, // 'front', 'side', or 'rear'
      ),
    ),
  );
  
  if (result != null) {
    final imagePath = result['image'];
    final registrationNumber = result['registration_number'];
    final isMotorcycle = result['is_motorcycle'];
    
    // Use the results...
  }
}
```

#### Return Data Structure

```dart
{
  'image': String,              // File path to captured/selected image
  'registration_number': String?, // Extracted reg number (null if not found)
  'is_motorcycle': bool,         // Whether verified as motorcycle
  'vehicle_type': String?,       // Detected vehicle type label
  'confidence': double?,         // Confidence score (0.0 - 1.0)
}
```

## Configuration

### Adjusting OCR Patterns

To support different registration formats, edit the patterns in `bike_registration_verification_screen.dart`:

```dart
final regPatterns = [
  RegExp(r'\b[A-Z]{2,3}\s*\d{2,4}\s*[A-Z]{0,2}\b'),
  // Add your patterns here
];
```

### Adjusting Motorcycle Detection

Modify the keyword list to improve detection:

```dart
final motorcycleLabels = [
  'motorcycle',
  'motorbike',
  // Add more keywords
];
```

### Confidence Threshold

Adjust in `_initializeImageLabeler()`:

```dart
final options = ImageLabelerOptions(
  confidenceThreshold: 0.5, // Adjust this (0.0 - 1.0)
);
```

## Dependencies

```yaml
dependencies:
  camera: ^0.11.3
  google_mlkit_text_recognition: ^0.15.0
  google_mlkit_image_labeling: ^0.13.0
  image_picker: ^1.0.7
```

## Permissions Required

### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

### iOS (`ios/Runner/Info.plist`)
```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access to capture bike photos</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>We need photo library access to select bike images</string>
```

## Troubleshooting

### OCR Not Detecting Registration Number

**Possible Causes:**
- Poor lighting conditions
- Blurry image
- License plate not in frame
- Dirty or damaged license plate
- Registration format not in regex patterns

**Solutions:**
1. Ensure good lighting
2. Keep camera steady
3. Frame license plate properly
4. Clean the plate before capture
5. Add custom regex patterns for your region

### Motorcycle Not Verified

**Possible Causes:**
- Image too dark/blurry
- Non-motorcycle object in frame
- ML model confidence too low
- Bike partially visible

**Solutions:**
1. Improve lighting
2. Capture clearer photo
3. Show more of the motorcycle
4. Lower confidence threshold if needed
5. Adjust motorcycle keywords list

### Camera Not Initializing

**Possible Causes:**
- Missing permissions
- Camera already in use
- Device incompatibility

**Solutions:**
1. Check permissions in manifest
2. Request permissions at runtime
3. Close other camera-using apps
4. Test on different device

## Best Practices

### For Best OCR Results

1. **Lighting**: Natural daylight or bright artificial light
2. **Distance**: 2-3 meters from the bike
3. **Angle**: Straight-on view of license plate
4. **Focus**: Ensure camera focuses before capture
5. **Steadiness**: Hold device steady or use timer

### For Best Motorcycle Detection

1. **Framing**: Include entire motorcycle or major parts
2. **Background**: Minimize clutter in background
3. **Clarity**: Use high-resolution images
4. **Angle**: Side view shows most features

## Performance Tips

1. **Image Quality**: Balance quality vs file size
   - Current: 1920x1920 max, 85% quality
   - Adjust in `ImagePicker` configuration

2. **Processing Time**: 
   - Image labeling: ~1-2 seconds
   - OCR: ~2-3 seconds
   - Total: ~3-5 seconds per image

3. **Memory**: Large images may cause memory issues on low-end devices
   - Implement image compression if needed

## Future Enhancements

### Planned Features

1. **Multi-language OCR** - Support for non-Latin scripts
2. **Real-time OCR** - Extract registration while camera is live
3. **Plate detection** - Auto-detect license plate region
4. **VIN extraction** - Extract VIN from chassis photos
5. **Make/Model detection** - Auto-detect bike make/model from image
6. **Damage detection** - Identify visible damage for insurance
7. **Color detection** - Auto-fill bike color from image analysis

### Possible Integrations

1. **Vehicle registration API** - Verify extracted numbers against database
2. **Insurance validation** - Check if registration is insured
3. **Stolen bike database** - Check against stolen vehicle reports

## Testing

### Test Scenarios

1. ✅ Capture motorcycle with visible front plate
2. ✅ Capture motorcycle side view
3. ✅ Capture motorcycle with visible rear plate
4. ✅ Upload from gallery
5. ✅ Capture in low light
6. ✅ Capture with blurry plate
7. ✅ Capture non-motorcycle (should reject)
8. ✅ Capture with obscured plate
9. ✅ Test different registration formats
10. ✅ Test retake functionality

### Manual Testing Checklist

- [ ] Camera permissions work
- [ ] Gallery upload works
- [ ] Motorcycle detection accurate
- [ ] OCR extracts registration correctly
- [ ] Auto-fill works in Add Bike form
- [ ] Retake functionality works
- [ ] Confirm button enables only when verified
- [ ] Error messages display correctly
- [ ] UI responsive on different screen sizes
- [ ] Works on Android
- [ ] Works on iOS

## API Integration (Future)

When backend OCR service is available:

```dart
// Send image to backend for processing
final response = await apiService.verifyBikeImage(
  imageFile: capturedImage,
  imageType: imageType,
);

// Response structure
{
  'is_motorcycle': true,
  'registration_number': 'KBZ 456Y',
  'confidence': 0.95,
  'make': 'Yamaha',
  'model': 'R15',
  'color': 'Blue'
}
```

## Support

For issues or questions:
1. Check this guide first
2. Review code comments in `bike_registration_verification_screen.dart`
3. Check ML Kit documentation: https://developers.google.com/ml-kit
4. File issue in project repository

## License & Credits

- Google ML Kit for image labeling and OCR
- Flutter Camera plugin for camera integration
- Built following face verification pattern

---

**Last Updated**: 2024
**Version**: 1.0.0
