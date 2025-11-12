# 📳 Vibration Package Usage

## Package: `vibration: ^1.8.4`

---

## 🔧 Implementation

### Import
```dart
import 'package:vibration/vibration.dart';
```

### Check Device Support
```dart
final hasVibrator = await Vibration.hasVibrator();
if (hasVibrator == true) {
  // Device supports vibration
}
```

### Vibration Pattern
```dart
// Pattern: [wait, vibrate, wait, vibrate, ...]
// Times in milliseconds
final pattern = [
  0,    // Start immediately
  200,  // Short vibration (200ms)
  100,  // Pause (100ms)
  500,  // Long vibration (500ms)
  100,  // Pause (100ms)
  200,  // Short vibration (200ms)
  100,  // Pause (100ms)
  500,  // Long vibration (500ms)
];

await Vibration.vibrate(pattern: pattern);
```

### Stop Vibration
```dart
await Vibration.cancel();
```

---

## 🎵 Our Pattern Explained

### Visual Representation
```
Time:   0ms   200ms  300ms  800ms  900ms  1100ms 1200ms 1700ms
        ▼     ▼      ▼      ▼      ▼      ▼      ▼      ▼
Action: START SHORT  PAUSE  LONG   PAUSE  SHORT  PAUSE  LONG
        |     ████   -      ████████ -    ████   -      ████████
```

### Pattern Breakdown
1. **0ms**: Start immediately (no initial delay)
2. **200ms**: Short vibration pulse (attention grabber)
3. **100ms**: Brief pause (creates rhythm)
4. **500ms**: Long vibration pulse (emphasis)
5. **100ms**: Brief pause
6. **200ms**: Short vibration pulse (repetition)
7. **100ms**: Brief pause
8. **500ms**: Long vibration pulse (finale)

**Total Duration**: 1.7 seconds  
**Repeats**: Every 2 seconds while alert active

---

## 🎯 Why This Pattern?

### SOS-Inspired Design
- **Short-Long rhythm** similar to SOS morse code
- **Distinctive** from normal notifications
- **Urgent** but not overwhelming
- **Attention-grabbing** without being annoying

### User Experience
- ✅ **Felt immediately** through short pulses
- ✅ **Unmistakable urgency** with long pulses
- ✅ **Rhythmic pattern** prevents habituation
- ✅ **Not continuous** to save battery

---

## 🔄 Continuous Operation

### How It Repeats
```dart
Timer.periodic(const Duration(seconds: 2), (timer) async {
  if (!_alertActive) {
    timer.cancel();
    await Vibration.cancel();
    return;
  }
  
  // Vibrate with pattern every 2 seconds
  await Vibration.vibrate(pattern: pattern);
});
```

### Timeline
```
0s:  Pattern starts (1.7s duration)
1.7s: Pattern ends
2.0s: Pattern starts again
3.7s: Pattern ends
4.0s: Pattern starts again
...
30s: Countdown ends or user cancels
```

---

## 🔋 Battery Impact

### Power Consumption
```
Pattern Duration: 1.7 seconds
Active Vibration: 1.4 seconds (200+500+200+500)
Pause Time: 0.3 seconds
Active Ratio: 82% (1.4/1.7)

Vibration Power:
~0.8% battery per hour of continuous vibration
30-second alert: ~0.007% battery

Negligible impact on battery life!
```

---

## 📱 Platform Support

### Android
```
✅ Full support
✅ Custom patterns
✅ Pattern array [wait, vibrate, wait, ...]
✅ Cancel vibration
✅ Check if device has vibrator
```

### iOS
```
✅ Basic support
✅ Simple patterns work
⚠️  Complex patterns may simplify
✅ Cancel vibration
✅ Check support
```

### Permission Required

**Android:**
```xml
<uses-permission android:name="android.permission.VIBRATE"/>
```

**iOS:**
No permission needed (automatically granted)

---

## 🧪 Testing Vibration

### Test Code
```dart
// Check if device can vibrate
final hasVibrator = await Vibration.hasVibrator();
print('Has vibrator: $hasVibrator');

if (hasVibrator == true) {
  // Test simple vibration (500ms)
  await Vibration.vibrate(duration: 500);
  
  // Wait a bit
  await Future.delayed(Duration(seconds: 2));
  
  // Test pattern
  await Vibration.vibrate(pattern: [0, 200, 100, 500]);
  
  // Wait a bit
  await Future.delayed(Duration(seconds: 2));
  
  // Cancel any ongoing vibration
  await Vibration.cancel();
}
```

### What to Check
- ✅ Device vibrates when function called
- ✅ Pattern is distinctive and noticeable
- ✅ Vibration stops when cancelled
- ✅ Pattern repeats correctly
- ✅ No vibration after alert dismissed

---

## 🎨 Alternative Patterns

### Option 1: Continuous Strong Vibration
```dart
// Simple, maximum urgency
await Vibration.vibrate(duration: 2000); // 2 seconds solid
```

### Option 2: Rapid Pulses
```dart
final pattern = [0, 100, 50, 100, 50, 100, 50, 100];
// Fast pulse pattern
```

### Option 3: SOS Morse Code (Exact)
```dart
// S = ··· (3 short), O = ─── (3 long), S = ··· (3 short)
final pattern = [
  0,
  200, 200, 200, 200, 200, 400,  // S (···)
  600, 200, 600, 200, 600, 400,  // O (─── )
  200, 200, 200, 200, 200,       // S (···)
];
```

### Option 4: Escalating Intensity
```dart
// Note: vibration package doesn't support intensity
// But you can simulate with increasing duration
final pattern = [0, 100, 100, 200, 100, 300, 100, 400];
```

---

## 🔧 Advanced Usage

### Vibrate Once (Simple)
```dart
// Single 500ms vibration
await Vibration.vibrate(duration: 500);
```

### Check Amplitude Support
```dart
// Check if device supports custom amplitude
final hasAmplitudeControl = await Vibration.hasAmplitudeControl();
if (hasAmplitudeControl == true) {
  // Can control vibration strength
  await Vibration.vibrate(
    duration: 500,
    amplitude: 128, // 0-255
  );
}
```

### Cancel All Vibrations
```dart
// Stop any ongoing vibration
await Vibration.cancel();
```

---

## 🐛 Troubleshooting

### Vibration Not Working

**Check 1: Permission**
```dart
// Android: Add to AndroidManifest.xml
<uses-permission android:name="android.permission.VIBRATE"/>
```

**Check 2: Device Support**
```dart
final hasVibrator = await Vibration.hasVibrator();
if (hasVibrator != true) {
  print('Device does not have vibrator');
}
```

**Check 3: Do Not Disturb Mode**
- Some devices disable vibration in DND mode
- Check device settings

**Check 4: Battery Saver**
- Battery saver may limit vibration
- Disable for testing

**Check 5: Physical Device**
- Emulator doesn't support vibration
- Must test on real device

---

## 📊 Comparison with Other Packages

| Feature | vibration | flutter_vibrate | haptic_feedback |
|---------|-----------|-----------------|-----------------|
| Custom Patterns | ✅ | ✅ | ❌ |
| Amplitude Control | ✅ | ✅ | ❌ |
| iOS Support | ✅ | ✅ | ✅ |
| Android Support | ✅ | ✅ | ✅ |
| Simple API | ✅ | ❌ | ✅ |
| Pattern Array | ✅ [ms] | ✅ [Duration] | ❌ |
| **Best For** | Emergency alerts | Complex patterns | UI feedback |

**Why We Use `vibration`:**
- ✅ Simple pattern array format
- ✅ Excellent documentation
- ✅ Reliable on both platforms
- ✅ Perfect for our use case

---

## 💡 Best Practices

### DO:
- ✅ Test on real devices
- ✅ Keep patterns under 2 seconds
- ✅ Include pauses between vibrations
- ✅ Cancel vibration when alert dismissed
- ✅ Check device support before vibrating

### DON'T:
- ❌ Use continuous vibration (battery drain)
- ❌ Make patterns too long (annoying)
- ❌ Forget to cancel vibration
- ❌ Vibrate in background without notification
- ❌ Test on emulator (won't work)

---

## 📝 Code Example (Complete)

```dart
import 'package:vibration/vibration.dart';

class VibrationService {
  Timer? _vibrationTimer;
  bool _isVibrating = false;

  Future<void> startEmergencyVibration() async {
    // Check support
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator != true) return;

    // Pattern
    final pattern = [0, 200, 100, 500, 100, 200, 100, 500];

    // Start repeating
    _isVibrating = true;
    _vibrationTimer = Timer.periodic(
      const Duration(seconds: 2),
      (timer) async {
        if (!_isVibrating) {
          timer.cancel();
          await Vibration.cancel();
          return;
        }
        await Vibration.vibrate(pattern: pattern);
      },
    );
  }

  Future<void> stopVibration() async {
    _isVibrating = false;
    _vibrationTimer?.cancel();
    await Vibration.cancel();
  }

  void dispose() {
    stopVibration();
  }
}
```

---

## ✅ Summary

### Our Implementation
- ✅ Uses `vibration: ^1.8.4` package
- ✅ Short-long pattern (SOS-inspired)
- ✅ Repeats every 2 seconds
- ✅ Cancellable by user
- ✅ Stops automatically when alert ends
- ✅ Battery efficient
- ✅ Cross-platform compatible

### User Experience
```
Crash Detected
    ↓
🔊 Alert Sound
📳 Vibration Pattern (short-long-short-long)
🔴 RED Screen
    ↓
Repeats every 2 seconds
    ↓
User feels vibration → Checks phone → Sees RED screen
    ↓
Cancels or waits for emergency call
```

---

**🏍️ Feel the Alert, Stay Safe!**
