# Face Verification Usage Guide

## How to Use in Your App

### 1. Navigate to Face Verification Screen

```dart
// From your KYC or registration flow
final result = await Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const FaceVerificationScreen(),
  ),
);

if (result != null && result['liveness_verified'] == true) {
  // Verification successful!
  final imagePath = result['image_path'];  // Passport photo from stage 0
  final timestamp = result['verification_timestamp'];
  final faceId = result['face_id'];
  
  // Use the image as passport photo
  await uploadPassportPhoto(imagePath);
} else {
  // User cancelled or verification failed
  print('Verification cancelled or failed');
}
```

### 2. What Happens During Verification

#### Stage 1: Face Forward (Reference Capture)
- User looks straight ahead
- System captures **passport photo** here ✅
- Face landmarks and tracking data stored
- This face becomes the reference for all subsequent stages

#### Stage 2: Blink Test
- User blinks naturally twice
- System verifies it's the **SAME face** from stage 1
- If different face detected → security alert & reset

#### Stage 3: Turn Left
- User slowly turns head left
- Continues verifying **SAME face**
- Prevents face substitution attack

#### Stage 4: Turn Right
- User turns head right
- Final verification with **SAME face**
- On success, returns passport photo from stage 1

### 3. Security Features

✅ **Reference Face Tracking**
- First verified face becomes the reference
- All subsequent stages must use SAME face

✅ **Multi-Layer Identity Verification**
- Face tracking ID matching
- Facial landmarks comparison
- Face size consistency checks

✅ **Anti-Spoofing**
- Liveness detection (blink, head movement)
- Face area variance checking
- Real-time verification required

✅ **Attack Prevention**
- Detects face switching between stages
- Rejects multiple faces in frame
- Handles face substitution attempts

### 4. Response Data

```dart
{
  'image_path': String,           // Path to passport photo (from stage 0)
  'liveness_verified': bool,      // true if all stages passed
  'verification_timestamp': String, // ISO 8601 timestamp
  'stages_completed': int,        // Should be 4 for full verification
  'face_id': int,                 // ML Kit face tracking ID
}
```

### 5. Error Handling

```dart
final result = await Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const FaceVerificationScreen()),
);

if (result == null) {
  // User cancelled verification
  showError('Face verification cancelled');
  return;
}

if (result['liveness_verified'] != true) {
  // Verification failed
  showError('Face verification failed. Please try again.');
  return;
}

// Success - process the image
final imagePath = result['image_path'];
await processPassportPhoto(imagePath);
```

### 6. User Experience Flow

```
┌─────────────────────────────────┐
│  User presses "Verify Face"     │
└────────────┬────────────────────┘
             ↓
┌─────────────────────────────────┐
│  Camera initializes              │
│  Shows circular preview          │
└────────────┬────────────────────┘
             ↓
┌─────────────────────────────────┐
│  Stage 1: Face Forward           │
│  • Instruction: "Look straight"  │
│  • Detects face                  │
│  • Holds for 10 frames           │
│  • 📸 CAPTURES PASSPORT PHOTO    │
│  • Stores reference data         │
└────────────┬────────────────────┘
             ↓
┌─────────────────────────────────┐
│  Stage 2: Blink                  │
│  • Shows "Verifying Identity" 🔒 │
│  • Checks SAME face              │
│  • Detects 2 blinks              │
└────────────┬────────────────────┘
             ↓
┌─────────────────────────────────┐
│  Stage 3: Turn Left              │
│  • Verifies SAME face            │
│  • Detects left head turn        │
│  • Holds for 6 frames            │
└────────────┬────────────────────┘
             ↓
┌─────────────────────────────────┐
│  Stage 4: Turn Right             │
│  • Verifies SAME face            │
│  • Detects right head turn       │
│  • Holds for 6 frames            │
└────────────┬────────────────────┘
             ↓
┌─────────────────────────────────┐
│  ✅ Verification Complete         │
│  Returns passport photo          │
│  (from Stage 1)                  │
└─────────────────────────────────┘
```

### 7. Visual Indicators

| Indicator | When Shown | Meaning |
|-----------|-----------|---------|
| 🟢 "Face Detected" | Face found in frame | Camera sees a face |
| 🔴 "Verifying Identity" | Stages 2-4 | Checking it's the same face |
| ⚠️ "Different face detected!" | Face mismatch | Security alert - must restart |
| Progress circles | All stages | Shows completion progress |

### 8. Troubleshooting

**"Different face detected" error:**
- Same person must complete all stages
- Don't switch between people
- Keep face visible throughout
- Ensure good lighting

**"Multiple faces detected":**
- Only one person in camera view
- Remove other people from frame
- Check for reflections or photos in background

**Verification keeps resetting:**
- Maintain stable lighting
- Keep face centered in frame
- Don't move too quickly
- Ensure face is clearly visible

### 9. Best Practices

✅ **Do:**
- Use in well-lit environment
- Keep face centered in circle
- Make natural movements
- Complete all stages with same person

❌ **Don't:**
- Switch faces between stages
- Use photos or videos
- Have multiple people in frame
- Move too quickly during verification

### 10. Integration Example

```dart
class KYCUploadScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        // Start face verification
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const FaceVerificationScreen(),
          ),
        );
        
        if (result != null && result['liveness_verified'] == true) {
          // Success! Upload passport photo
          final imagePath = result['image_path'];
          final faceId = result['face_id'];
          
          // Save to KYC documents
          await kycProvider.uploadDocument(
            type: 'PASSPORT_PHOTO',
            imagePath: imagePath,
            metadata: {
              'liveness_verified': true,
              'face_id': faceId,
              'timestamp': result['verification_timestamp'],
            },
          );
          
          showSuccess('Face verified and passport photo uploaded!');
        }
      },
      child: Text('Verify Face & Take Photo'),
    );
  }
}
```

---

## Summary

The updated face verification system:
- ✅ Captures passport photo in **Stage 1** (Face Forward)
- ✅ Verifies **SAME face** throughout all stages
- ✅ Prevents face substitution attacks
- ✅ Returns the **first captured image** as passport photo
- ✅ Includes liveness verification with multiple checks
- ✅ Provides clear visual feedback to users
- ✅ Resets on security violations

**Result:** Secure, user-friendly face verification with passport photo capture.
