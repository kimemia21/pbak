# Face Verification Security Flow Diagram

## Complete Verification Process

```
┌─────────────────────────────────────────────────────────────┐
│                    INITIALIZATION                            │
│  - Camera starts                                             │
│  - Front camera selected                                     │
│  - ML Kit face detector initialized                          │
│  - No reference face yet                                     │
└──────────────────────┬──────────────────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────────────────┐
│              STAGE 0: FACE FORWARD                           │
│  Instructions: "Look straight ahead"                         │
│                                                              │
│  1. Detect face in frame                                     │
│  2. Check face is centered (Y < 25°, Z < 25°)               │
│  3. Hold stable for 10 frames                                │
│  4. 📸 CAPTURE REFERENCE FACE                                │
│     ├─ Save image as passport photo                         │
│     ├─ Store face tracking ID                               │
│     ├─ Store facial landmarks                               │
│     └─ Store bounding box                                   │
│                                                              │
│  ✅ Reference Face = ESTABLISHED                             │
└──────────────────────┬──────────────────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────────────────┐
│               STAGE 1: BLINK TEST                            │
│  Instructions: "Blink naturally twice"                       │
│  UI: 🔒 "Verifying Identity" badge shown                     │
│                                                              │
│  FOR EACH FRAME:                                             │
│  ┌─────────────────────────────────────┐                    │
│  │ 🔐 SECURITY CHECK (3 LAYERS)        │                    │
│  │                                      │                    │
│  │ 1️⃣ Face Tracking ID Match           │                    │
│  │    Current ID == Reference ID?      │                    │
│  │                                      │                    │
│  │ 2️⃣ Facial Landmarks Match           │                    │
│  │    Normalize positions by face box  │                    │
│  │    Compare relative positions       │                    │
│  │    Allow 20% variance               │                    │
│  │                                      │                    │
│  │ 3️⃣ Face Size Consistency            │                    │
│  │    Current size ≈ Reference size?   │                    │
│  │    Allow 40% variance               │                    │
│  │                                      │                    │
│  │ ❌ ANY MISMATCH?                     │                    │
│  │    ├─ Increment failure counter     │                    │
│  │    ├─ If failures < 5: Continue     │                    │
│  │    └─ If failures >= 5: RESET ALL   │                    │
│  └─────────────────────────────────────┘                    │
│                                                              │
│  ✅ SAME FACE VERIFIED                                       │
│  Then detect blinks (eyes closed → open)                    │
│  Need 2 blinks to proceed                                    │
└──────────────────────┬──────────────────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────────────────┐
│              STAGE 2: TURN LEFT                              │
│  Instructions: "Turn your head left"                         │
│  UI: 🔒 "Verifying Identity" badge shown                     │
│                                                              │
│  FOR EACH FRAME:                                             │
│  ┌─────────────────────────────────────┐                    │
│  │ 🔐 SECURITY CHECK (3 LAYERS)        │                    │
│  │    Same checks as Stage 1           │                    │
│  │    ✅ Verify SAME face               │                    │
│  └─────────────────────────────────────┘                    │
│                                                              │
│  Detect head turn left (Y angle > 15°)                       │
│  Hold for 6 frames                                           │
│  ✅ SAME FACE VERIFIED                                       │
└──────────────────────┬──────────────────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────────────────┐
│              STAGE 3: TURN RIGHT                             │
│  Instructions: "Turn your head right"                        │
│  UI: 🔒 "Verifying Identity" badge shown                     │
│                                                              │
│  FOR EACH FRAME:                                             │
│  ┌─────────────────────────────────────┐                    │
│  │ 🔐 SECURITY CHECK (3 LAYERS)        │                    │
│  │    Same checks as Stage 1 & 2       │                    │
│  │    ✅ Verify SAME face               │                    │
│  └─────────────────────────────────────┘                    │
│                                                              │
│  Detect head turn right (Y angle < -15°)                     │
│  Hold for 6 frames                                           │
│  ✅ SAME FACE VERIFIED                                       │
└──────────────────────┬──────────────────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────────────────┐
│                  ✅ VERIFICATION COMPLETE                     │
│                                                              │
│  Return data:                                                │
│  {                                                           │
│    'image_path': '/path/to/stage0/photo.jpg', ← PASSPORT!  │
│    'liveness_verified': true,                               │
│    'verification_timestamp': '2024-01-15T10:30:00Z',        │
│    'stages_completed': 4,                                    │
│    'face_id': 12345                                         │
│  }                                                           │
└─────────────────────────────────────────────────────────────┘
```

## Security Failure Scenario

```
┌─────────────────────────────────────────────────────────────┐
│  STAGE 0: Person A looks forward                            │
│  📸 Reference face captured (Person A)                       │
└──────────────────────┬──────────────────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────────────────┐
│  STAGE 1: Person B tries to blink                           │
│                                                              │
│  🔐 Security Check:                                          │
│     ❌ Tracking ID mismatch (Person B ≠ Person A)           │
│     ❌ Landmarks don't match                                 │
│     ❌ Face size different                                   │
│                                                              │
│  Failure counter: 1                                          │
│  Show: "Keep your face steady"                              │
└──────────────────────┬──────────────────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────────────────┐
│  Person B continues (failures 2, 3, 4, 5...)               │
└──────────────────────┬──────────────────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────────────────┐
│  ⚠️ SECURITY ALERT - 5 FAILURES REACHED                     │
│                                                              │
│  Show: "⚠️ Different face detected!"                        │
│  Error: "Security Alert: Face mismatch detected"            │
│                                                              │
│  ACTION: RESET TO BEGINNING                                 │
│  - Clear reference face                                      │
│  - Clear all tracking data                                   │
│  - Return to Stage 0                                         │
│  - User must start over                                      │
└─────────────────────────────────────────────────────────────┘
```

## Multi-Layer Face Verification Details

### Layer 1: Tracking ID Match
```
Reference Face ID: 12345
Current Frame ID:  12345  ✅ MATCH
Current Frame ID:  67890  ❌ MISMATCH → Increment failure counter
```

### Layer 2: Facial Landmarks Comparison
```
Reference Nose Position (normalized): (0.50, 0.55)
Current Nose Position (normalized):   (0.52, 0.54)  ✅ MATCH (diff < 20%)
Current Nose Position (normalized):   (0.70, 0.80)  ❌ MISMATCH (diff > 20%)
```

### Layer 3: Bounding Box Size
```
Reference Face Area: 10000 pixels²
Current Face Area:   9500 pixels²   ✅ MATCH (5% difference)
Current Face Area:   15000 pixels²  ❌ MISMATCH (50% difference)
```

## Anti-Spoofing Mechanisms

```
┌─────────────────────────────────────────────────────────────┐
│  SPOOFING ATTEMPT           DETECTION METHOD                │
├─────────────────────────────────────────────────────────────┤
│  Static Photo               - No blink detected             │
│                             - Face area doesn't vary         │
│                             - No head movement               │
├─────────────────────────────────────────────────────────────┤
│  Video Replay               - Face area too stable           │
│                             - Tracking ID changes            │
│                             - Landmarks inconsistent         │
├─────────────────────────────────────────────────────────────┤
│  Face Switching             - Tracking ID mismatch           │
│                             - Landmarks change               │
│                             - Face size different            │
│                             → SECURITY ALERT & RESET         │
├─────────────────────────────────────────────────────────────┤
│  Multiple Faces             - Face count > 1                 │
│                             - Rejected immediately           │
│                             - Show "Multiple faces" error    │
└─────────────────────────────────────────────────────────────┘
```

## Timeline Example

```
Time    Event                           Action
────────────────────────────────────────────────────────────
00:00   User starts verification        Show Stage 0 instructions
00:02   Face detected                   "Face Detected" badge
00:04   Face stable (10 frames)         📸 Capture reference photo
        Reference established:
        - ID: 12345
        - Landmarks: [(250,300), ...]
        - Box: Rect(100, 150, 200, 250)
        
00:05   Move to Stage 1                 Show "Blink" instructions
                                        Show "Verifying Identity" 🔒
        
00:06   Frame 1: Verify face            ✅ ID matches (12345)
                                        ✅ Landmarks match
                                        ✅ Box size similar
                                        
00:07   Frame 2: Verify face            ✅ All checks pass
        Eyes closed detected
        
00:08   Frame 3: Verify face            ✅ All checks pass
        Eyes open detected
        Blink 1 counted ✓
        
00:09   Blink 2 detected                Stage 1 complete
        
00:10   Move to Stage 2                 Show "Turn Left"
                                        Continue verifying identity
                                        
... (continues for all stages)
        
00:25   Stage 3 complete                Return passport photo
                                        (from 00:04 timestamp)
```

## Code Architecture

```
_analyzeFaces(faces)
    │
    ├─→ Check face count
    │   ├─ 0 faces → Show error
    │   ├─ >1 faces → Show error
    │   └─ 1 face → Continue
    │
    ├─→ IF (_currentStage > 0)  ← CRITICAL SECURITY CHECK
    │   │
    │   └─→ _verifyFaceIdentity(face)
    │       │
    │       ├─→ Check Tracking ID
    │       ├─→ _compareFacialLandmarks(face)
    │       ├─→ _compareFaceBoundingBox(box)
    │       │
    │       └─→ IF any mismatch:
    │           └─→ _handleFaceIdentityMismatch()
    │               └─→ IF failures >= 5:
    │                   └─→ _resetToBeginning()
    │
    └─→ _processStage(face)
        └─→ IF stage complete:
            └─→ _completeStage()
                ├─→ IF stage 0: _captureReferenceFace() 📸
                └─→ IF stage 3: _completeVerification()
```

---

## Summary

**Key Security Feature:** Every frame after Stage 0 undergoes a 3-layer identity verification to ensure the SAME face is used throughout the entire verification process.

**Result:** Prevents face switching attacks while maintaining smooth user experience with clear visual feedback.
