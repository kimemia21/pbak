# Face Verification Screen - Quick Start Guide

## Basic Usage

### 1. Navigate to Face Verification
```dart
import 'package:pbak/views/auth/face_verification_screen.dart';

// In your widget
ElevatedButton(
  onPressed: () async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FaceVerificationScreen(),
      ),
    );
    
    if (result == true) {
      print('✅ Passport photo uploaded successfully');
    } else {
      print('❌ User cancelled or upload failed');
    }
  },
  child: const Text('Verify Face'),
);
```

### 2. That's It! 🎉

The screen handles everything:
- Camera initialization
- Real-time face detection
- Passport frame validation
- Image capture
- Post-capture verification
- Upload via `uploadPassportPhoto()`

## How It Works

### User Experience Flow

1. **Screen Opens** → Camera initializes with passport frame overlay
2. **User Positions Face** → Real-time feedback guides positioning
3. **Validation Passes** → Capture button turns gold, user can tap
4. **Image Captured** → Post-verification runs automatically
5. **Upload Starts** → Shows "Uploading..." overlay
6. **Success** → Screen closes, returns `true`
7. **Failure** → Error message shown, user can retry

### Validation Rules (All Must Pass)

| Rule | Requirement | User Feedback |
|------|-------------|---------------|
| Face Count | Exactly 1 face | "No face detected" / "Multiple faces detected" |
| Position | Centered in frame | "Center your face in the frame" |
| Distance | 35-75% of frame | "Move closer" / "Move back" |
| Head Pose | ±15° tolerance | "Look straight ahead" / "Keep your head straight" |
| Eyes | Both open | "Keep your eyes open" |
| Stability | 5 stable frames | "Hold still... 3" |

## Visual States

### Frame Border Colors
- **White**: Validating position
- **Yellow**: Stabilizing (almost ready)
- **Green**: Ready to capture! ✓
- **Red**: Error occurred

### UI Elements
- **Top Panel**: Current instruction with status icon
- **Frame Overlay**: Passport-sized guide with corner markers
- **Bottom Button**: Large circular capture button
- **Processing**: Full-screen overlay during upload

## Configuration Constants

Located in `_FaceVerificationScreenState`:

```dart
// Frame dimensions (percentage of screen)
static const double _frameWidthRatio = 0.65;   // 65% width
static const double _frameHeightRatio = 0.75;  // 75% height
static const double _frameCenterY = 0.45;       // Slightly above center

// Validation thresholds
static const double _minFaceAreaRatio = 0.35;   // Min face size
static const double _maxFaceAreaRatio = 0.75;   // Max face size
static const double _centerTolerance = 0.15;    // Centering tolerance
static const int _stableFramesRequired = 5;     // Stability frames

// Performance
static const Duration _detectionThrottle = Duration(milliseconds: 300);
```

## Error Handling

### Automatic Retry
If capture fails validation:
1. Shows error message in SnackBar
2. Restarts camera stream automatically
3. User can immediately retry

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| "Camera initialization failed" | No camera permission | Check permissions |
| "No face detected in captured image" | User moved during capture | Retry capture |
| "Upload failed" | Network/server issue | Check connection, retry |
| Black screen | Camera not available | Check device camera |

## Integration Points

### KYC Provider
```dart
// Called automatically by the screen
await kycNotifier.uploadPassportPhoto(
  filePath: imageFile.path,
  livenessVerified: true,  // Always true from this screen
);
```

### Backend API
The upload goes through:
1. `KycProvider.uploadPassportPhoto()`
2. `KycService.uploadVerifiedPassportPhoto()`
3. Your backend endpoint

## Testing Checklist

- [ ] Camera opens on both Android and iOS
- [ ] Face detection works in real-time
- [ ] Frame overlay displays correctly
- [ ] All validation rules trigger appropriate messages
- [ ] Capture button enables only when valid
- [ ] Post-verification works on captured image
- [ ] Upload integrates with your backend
- [ ] Error handling and retry works
- [ ] Screen closes on success
- [ ] Return value is correct (true/false)

## Customization Tips

### Adjust Frame Size
```dart
// Make frame bigger
static const double _frameWidthRatio = 0.75;  // 75% instead of 65%
static const double _frameHeightRatio = 0.85; // 85% instead of 75%
```

### Adjust Validation Strictness
```dart
// More lenient face size
static const double _minFaceAreaRatio = 0.30;  // Smaller face OK
static const double _maxFaceAreaRatio = 0.80;  // Larger face OK

// More lenient head pose
if (headEulerAngleY != null && headEulerAngleY.abs() > 20) {  // 20° instead of 15°
```

### Change Throttle Speed
```dart
// Faster detection (more battery/CPU)
static const Duration _detectionThrottle = Duration(milliseconds: 200);

// Slower detection (less battery/CPU)
static const Duration _detectionThrottle = Duration(milliseconds: 500);
```

## Requirements

### Permissions (AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-feature android:name="android.hardware.camera" />
```

### Permissions (Info.plist)
```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access to verify your identity</string>
```

### Packages
```yaml
dependencies:
  camera: ^0.10.5+9
  google_mlkit_face_detection: ^0.13.1
  flutter_riverpod: ^2.x.x
```

## Performance Notes

- **Memory**: ~50-100MB during active detection
- **Battery**: Moderate usage during detection
- **CPU**: Optimized with 300ms throttling
- **Detection Speed**: ~3-4 FPS (sufficient for UX)

## Troubleshooting

### Issue: Camera preview is rotated
**Solution**: Handled automatically by `InputImageRotation` based on device orientation

### Issue: Face detection is slow
**Solution**: Increase throttle duration or reduce camera resolution

### Issue: Too many false negatives
**Solution**: Adjust validation thresholds (make less strict)

### Issue: Upload fails
**Solution**: Check `KycProvider` and backend connectivity

## Support

For issues or questions:
1. Check analyzer: `flutter analyze lib/views/auth/face_verification_screen.dart`
2. Review logs with: `flutter run --verbose`
3. Test face detection with: ML Kit's sample apps
4. Verify camera with: Flutter camera example app

---

✨ **That's all you need to know!** The screen is self-contained and handles everything automatically.
