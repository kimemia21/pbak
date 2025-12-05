# Face Verification - Quick Reference Card

## 🚀 Quick Start

```dart
// Navigate to face verification
final result = await Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const FaceVerificationScreen(),
  ),
);

// Check result
if (result != null && result['liveness_verified'] == true) {
  String passportPhoto = result['image_path'];  // Use this!
  // Upload or save the passport photo
}
```

## 📸 What Gets Captured

- **Passport Photo:** Captured in **Stage 0** (Face Forward)
- **When:** After 10 stable frames of looking straight ahead
- **Used For:** Passport/ID photo, profile picture
- **Security:** Same face verified throughout all stages

## 🔒 Security Flow (Simple)

```
Stage 0: Capture reference face 📸
         ↓
Stage 1: Verify it's SAME face + Blink test
         ↓
Stage 2: Verify it's SAME face + Turn left
         ↓
Stage 3: Verify it's SAME face + Turn right
         ↓
Return passport photo from Stage 0 ✅
```

## ⚠️ Security Alerts

| Alert | Meaning | Action |
|-------|---------|--------|
| "Different face detected!" | Face switched | Resets to beginning |
| "Multiple faces detected" | >1 person in frame | Show only 1 face |
| "No face detected" | Face not visible | Position face in frame |

## 🎯 Key Features

✅ **Same face enforcement** - Prevents face switching attacks  
✅ **Passport photo from Stage 0** - First verified face becomes photo  
✅ **Multi-layer verification** - 3 independent checks per frame  
✅ **Liveness detection** - Blink + head movements required  
✅ **Anti-spoofing** - Detects photos and videos  

## 📦 Response Data

```dart
{
  'image_path': '/path/to/photo.jpg',    // Passport photo (Stage 0)
  'liveness_verified': true,              // All checks passed
  'verification_timestamp': '2024-...',   // ISO 8601
  'stages_completed': 4,                  // Should be 4
  'face_id': 12345,                       // For audit trail
}
```

## 🎨 UI Indicators

- 🟢 **"Face Detected"** - Face found in frame
- 🔴 **"Verifying Identity"** - Checking face consistency (Stages 1-3)
- Progress circles show stage completion

## ⚙️ Configuration

```dart
// Maximum face mismatch failures before reset
static const int _maxMatchFailures = 5;

// Stage requirements
Stage 0: 10 stable frames (face forward)
Stage 1: 2 natural blinks
Stage 2: 6 frames at 15° left
Stage 3: 6 frames at 15° right

// Verification tolerances
Landmarks variance: 20%
Bounding box variance: 40%
```

## 🧪 Testing Quick Check

### ✅ Pass Test
1. One person
2. Complete all 4 stages
3. Should succeed

### ❌ Fail Test
1. Person A starts (Stage 0)
2. Person B continues (Stage 1)
3. Should show "Different face detected!" and reset

## 🐛 Common Issues

| Issue | Solution |
|-------|----------|
| Keeps resetting | Same person throughout, good lighting |
| "Different face" error | Don't switch people, keep face visible |
| "Multiple faces" | Only one person in camera view |
| Slow detection | Ensure good lighting, face centered |

## 📋 Implementation Checklist

- [x] Face identity tracking implemented
- [x] Reference face capture in Stage 0
- [x] Multi-layer verification active
- [x] Security reset on mismatch
- [x] Visual feedback added
- [x] Passport photo returned from Stage 0
- [ ] **TODO: Test on physical device**
- [ ] **TODO: Test face switching attack**
- [ ] **TODO: Test with multiple people**

## 📞 Quick Debug

```dart
// Check console for debug messages:
print('Reference face captured - ID: $_referenceFaceId');
print('Face tracking ID mismatch: $currentId != $refId');
print('Facial landmarks mismatch detected');
print('Face bounding box mismatch detected');
```

## 🔐 Security Summary

**Before:** ❌ Could use different faces for each stage  
**After:** ✅ Same face required throughout entire verification

**Key Change:** Reference face captured in Stage 0, verified in all subsequent frames

---

## 📚 Full Documentation

- `README_FACE_VERIFICATION.md` - Complete documentation
- `FACE_VERIFICATION_SECURITY_IMPLEMENTATION.md` - Security details
- `FACE_VERIFICATION_USAGE_GUIDE.md` - Integration guide
- `FACE_VERIFICATION_SECURITY_FLOW.md` - Visual diagrams

---

**Status:** ✅ Production Ready (after device testing)  
**Security Level:** HIGH
