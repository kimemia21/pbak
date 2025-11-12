# Crash Detection System

## 🚨 Overview

A comprehensive crash detection system that monitors motorcycle crashes in real-time using device sensors (accelerometer and gyroscope). When a crash is detected, the system:

1. **Turns the screen RED** with a prominent crash alert overlay
2. **Starts a 30-second countdown** before calling emergency contacts
3. **Plays alert sounds** and vibrates the device
4. **Automatically calls emergency contacts** if not cancelled
5. **Allows user cancellation** if they're safe

---

## 📦 Architecture

### Components

1. **CrashDetectorService** (`crash_detector_service.dart`)
   - Background sensor monitoring
   - Crash detection algorithms
   - Crash event streaming

2. **CrashAlertService** (`crash_alert_service.dart`)
   - Alert countdown management
   - Audio and vibration alerts
   - Emergency contact calling

3. **CrashDetectionProvider** (`crash_detection_provider.dart`)
   - Riverpod state management
   - Integration between services
   - UI state updates

4. **CrashAlertOverlay** (`crash_alert_overlay.dart`)
   - Full-screen RED alert UI
   - Countdown display
   - Cancel button

5. **CrashDetectionTestScreen** (`crash_detection_test_screen.dart`)
   - Testing interface
   - Manual crash simulation
   - Real-time status monitoring

---

## 🔧 Dependencies

```yaml
sensors_plus: ^4.0.2              # Accelerometer & Gyroscope
flutter_phone_direct_caller: ^2.1.1  # Emergency calling
permission_handler: ^11.3.0        # Permissions management
flutter_background_service: ^5.0.5 # Background monitoring
audioplayers: ^5.2.1              # Alert sounds
vibration: ^1.8.4                 # Device vibration
```

---

## 🎯 Crash Detection Algorithms

### Detection Methods

1. **High Impact Detection**
   - Threshold: 30.0 m/s²
   - Detects sudden, severe impacts
   - Instant crash trigger

2. **Sudden Deceleration**
   - Threshold: 25.0 m/s² drop
   - Detects rapid braking/stops
   - Uses 3-sample moving average

3. **Sustained High Acceleration**
   - Threshold: 24.0 m/s² (80% of crash threshold)
   - Monitors sustained high forces
   - Uses 10-sample history

4. **Rotation Detection**
   - Uses gyroscope data
   - High rotation + acceleration = potential rollover
   - Threshold: 5.0 rad/s

### Sensor Configuration

- **Sample Rate**: 100ms (10 samples/second)
- **History Size**: 10 samples
- **Sensors Used**: Accelerometer, Gyroscope

---

## 🚀 Usage

### 1. Enable Crash Detection

```dart
import 'package:pbak/providers/crash_detection_provider.dart';

// In a ConsumerWidget
final crashNotifier = ref.read(crashDetectorProvider.notifier);
await crashNotifier.startMonitoring();
```

### 2. Monitor Crash State

```dart
final crashState = ref.watch(crashDetectorProvider);

if (crashState.crashDetected) {
  // Handle crash detection
}
```

### 3. Listen to Crash Events

```dart
CrashDetectorService().crashStream.listen((crashEvent) {
  print('Crash detected: ${crashEvent.description}');
  print('Magnitude: ${crashEvent.magnitude} m/s²');
});
```

### 4. Simulate Crash (Testing)

```dart
ref.read(crashDetectorProvider.notifier).simulateCrash();
```

---

## 🧪 Testing

### Accessing the Test Screen

1. Open the app
2. Go to **Profile** → **Settings**
3. Under **Safety**, toggle **Crash Detection ON**
4. Tap **Test Crash Detection**

### Test Procedure

1. **Enable Detection**: Toggle crash detection ON
2. **Simulate Crash**: Tap "Simulate Crash" button
3. **Observe Alert**: Screen turns RED with countdown
4. **Test Cancellation**: Tap "I'M OK - CANCEL ALERT" button
5. **Test Full Sequence**: Let countdown reach 0 to test calling

### What to Expect

✅ Screen turns **RED** immediately  
✅ Countdown starts from **30 seconds**  
✅ Device **vibrates** continuously  
✅ Alert **sound** plays (if configured)  
✅ **"I'M OK"** button allows cancellation  
✅ After countdown, **emergency contact is called**  

---

## 📱 User Flow

### Normal Operation

1. User enables crash detection in settings
2. Service runs in background monitoring sensors
3. No UI changes during normal riding

### Crash Detected

1. **Sensors detect crash** (impact/deceleration/rotation)
2. **Screen turns RED** with full-screen overlay
3. **Countdown begins** (30 seconds)
4. **Device vibrates** and plays alert sound
5. **Two outcomes**:
   - User taps "I'M OK" → Alert cancelled
   - Countdown reaches 0 → Emergency contact called

### After Emergency Call

1. Phone dialer opens with emergency contact
2. Alert overlay remains until call is made
3. User can reset crash state from test screen

---

## ⚙️ Configuration

### Adjusting Thresholds

Edit `crash_detector_service.dart`:

```dart
static const double crashThreshold = 30.0;        // Impact threshold
static const double suddenStopThreshold = 25.0;   // Deceleration threshold
static const int checkIntervalMs = 100;           // Sampling rate
```

### Adjusting Countdown Time

Edit `crash_alert_service.dart`:

```dart
int _countdown = 30; // Seconds before calling
```

### Emergency Contacts

Fetched from user profile:

```dart
final user = authState.value;
final emergencyContact = user.emergencyContact; // From registration
```

---

## 🔒 Permissions Required

### Android (`AndroidManifest.xml`)

```xml
<uses-permission android:name="android.permission.CALL_PHONE"/>
<uses-permission android:name="android.permission.VIBRATE"/>
```

### iOS (`Info.plist`)

```xml
<key>NSMotionUsageDescription</key>
<string>We need access to motion sensors to detect crashes</string>
<key>NSPhoneUsageDescription</key>
<string>We need to call your emergency contact if a crash is detected</string>
```

---

## 🎨 UI Components

### CrashAlertOverlay Features

- **Full-screen RED background** (95% opacity)
- **Large warning icon** with shadow
- **Bold "CRASH DETECTED" title**
- **Circular countdown timer**
- **Prominent cancel button**
- **Crash details card**
- **Progress indicator** when calling

### Responsive Design

- Works on all screen sizes
- Safe area aware
- Portrait and landscape support

---

## 🧩 Integration Points

### With User Profile

```dart
// Emergency contact from user registration
final emergencyContact = user.emergencyContact;
```

### With Main App

```dart
// Overlay integrated in main.dart
builder: (context, child) {
  return Stack(
    children: [
      child ?? const SizedBox(),
      if (crashState.alertActive) const CrashAlertOverlay(),
    ],
  );
}
```

### With Settings Screen

- Toggle crash detection ON/OFF
- Access test screen
- View current status

---

## 📊 State Management

### CrashDetectionState

```dart
{
  isMonitoring: bool,        // Sensor monitoring active
  crashDetected: bool,       // Crash event detected
  lastCrashEvent: CrashEvent?, // Last crash details
  alertActive: bool,         // Alert overlay showing
  countdown: int,            // Seconds remaining
  emergencyCalled: bool,     // Call initiated
}
```

### CrashEvent

```dart
{
  type: CrashType,          // impact/suddenStop/sustained
  timestamp: DateTime,      // When crash occurred
  description: String,      // Human-readable description
  magnitude: double,        // Force magnitude (m/s²)
  location: String?,        // GPS coordinates (optional)
}
```

---

## 🔄 Background Service (Future Enhancement)

Currently runs in foreground. For true background operation:

1. Implement `flutter_background_service`
2. Run sensor monitoring in isolate
3. Show notification for active monitoring
4. Handle app in background/killed state

---

## ⚠️ Important Notes

### Testing Precautions

- **Use test mode** - Don't test while actually riding
- **Inform emergency contacts** - Let them know you're testing
- **Cancel alerts quickly** - Avoid unnecessary emergency calls
- **Test in safe environment** - Not on the road

### Production Considerations

1. **Battery Impact**: Continuous sensor monitoring uses battery
2. **False Positives**: May trigger on rough roads, potholes
3. **Phone Requirement**: Needs CALL_PHONE permission
4. **Network**: SMS backup requires cellular connection

### Limitations

- Requires device to be mounted securely
- May not detect all crash types
- Relies on sensor accuracy
- User must grant permissions

---

## 🚀 Future Enhancements

- [ ] GPS location sharing with emergency contacts
- [ ] SMS sending in addition to calling
- [ ] Multiple emergency contacts (sequential calling)
- [ ] Crash history and analytics
- [ ] Integration with insurance providers
- [ ] Video recording before/after crash
- [ ] Integration with nearby club members
- [ ] Medical information sharing
- [ ] Crash severity classification
- [ ] Machine learning for better detection

---

## 🆘 Troubleshooting

### Crash Detection Not Starting

- Check sensor permissions
- Verify phone permission granted
- Ensure device has required sensors
- Check for error logs

### False Positives

- Adjust crash thresholds
- Mount phone more securely
- Avoid testing on rough terrain
- Check sensor calibration

### Alert Not Showing

- Verify `CrashAlertOverlay` in main.dart
- Check crash detection is enabled
- Ensure provider is properly initialized
- Look for console errors

### Emergency Call Not Working

- Verify CALL_PHONE permission
- Check emergency contact format
- Ensure phone dialer exists
- Test on real device (not emulator)

---

## 📝 Testing Checklist

- [ ] Enable crash detection in settings
- [ ] Toggle ON/OFF works correctly
- [ ] Simulate crash triggers alert
- [ ] Screen turns RED
- [ ] Countdown displays correctly
- [ ] Countdown decrements each second
- [ ] Cancel button works
- [ ] Alert cancels successfully
- [ ] Full countdown triggers call
- [ ] Emergency contact is called
- [ ] Vibration works
- [ ] Status updates correctly
- [ ] Reset crash state works
- [ ] Test screen shows correct info

---

## 👥 Credits

Built for **PBAK Kenya** Motorcycle Community  
Part of the PBAK Super App  
Designed for rider safety and emergency response

---

## 📄 License

Part of PBAK Kenya Mobile Application
