# 🚨 PBAK Crash Detection - Complete Guide

## Quick Start

### How to Test Crash Detection

1. **Open the App** → Navigate to **Profile** → **Settings**
2. **Enable Crash Detection** → Toggle the switch ON under "Safety"
3. **Open Test Screen** → Tap "Test Crash Detection"
4. **Simulate Crash** → Tap the "Simulate Crash" button
5. **Observe** → Screen turns RED with 30-second countdown
6. **Cancel or Wait** → Either cancel or let it reach 0

---

## 🎯 What You'll See

### When Crash is Detected

```
┌─────────────────────────────┐
│   🚨 RED SCREEN APPEARS 🚨  │
├─────────────────────────────┤
│                             │
│    ⚠️  CRASH DETECTED       │
│                             │
│  Emergency services will    │
│  be called in:              │
│                             │
│        ┌─────┐              │
│        │  30 │              │
│        └─────┘              │
│                             │
│  [I'M OK - CANCEL ALERT]    │
│                             │
│  Tap above if you're safe   │
│                             │
└─────────────────────────────┘
```

### Device Behavior

- ✅ Screen turns **BRIGHT RED**
- ✅ **Vibrates continuously**
- ✅ **Sound alert** plays (if configured)
- ✅ **Countdown** from 30 seconds
- ✅ **Cancel button** prominent
- ✅ **Auto-calls** emergency contact at 0

---

## 📱 Step-by-Step Testing Guide

### Step 1: Enable Crash Detection

1. Open **PBAK Kenya** app
2. Tap **Profile** tab (bottom right)
3. Tap **Settings** (gear icon)
4. Find **Safety** section at the top
5. Toggle **Crash Detection** switch **ON**
6. You'll see: "Active - Monitoring for crashes"

### Step 2: Access Test Screen

1. In Settings, under "Crash Detection"
2. Tap **Test Crash Detection**
3. You'll see the test interface with:
   - Status card showing monitoring state
   - Current state information
   - Test action buttons
   - Instructions

### Step 3: Start Testing

1. Ensure **Crash Detection** toggle is **ON** (green)
2. Read the status card:
   ```
   🟢 Crash Detection
   Active
   ✓ Monitoring accelerometer and gyroscope sensors
   ```
3. Tap the **"Simulate Crash"** button (red button)

### Step 4: Experience the Alert

**Immediately after tapping "Simulate Crash":**

1. **Screen Transformation**
   - Entire screen turns RED
   - Full-screen overlay appears
   - Warning icon displayed

2. **Visual Countdown**
   - Large circular timer shows seconds
   - Updates every second: 30, 29, 28...

3. **Device Feedback**
   - Phone vibrates in pattern
   - Alert sound may play (device dependent)

4. **Information Display**
   - "CRASH DETECTED" in large text
   - "Emergency services will be called in:"
   - Countdown timer
   - Cancel button
   - Crash details at bottom

### Step 5: Test Cancellation

1. **While countdown is active**, tap:
   ```
   [I'M OK - CANCEL ALERT]
   ```
2. Alert **disappears immediately**
3. Screen returns to normal
4. Status shows: "Alert cancelled by user"

### Step 6: Test Full Sequence

1. Tap **"Simulate Crash"** again
2. **DO NOT** tap cancel button
3. Wait for countdown to reach **0**
4. Phone will **automatically call** your emergency contact
5. Phone dialer opens with the number

**⚠️ WARNING**: This will actually initiate a phone call! Make sure your emergency contact knows you're testing.

### Step 7: Reset State

1. After testing, tap **"Reset Crash State"** button
2. Clears all crash detection data
3. Ready for next test

---

## 🔍 What's Being Monitored

### Sensors Used

1. **Accelerometer**
   - Measures acceleration in 3 axes (X, Y, Z)
   - Detects sudden impacts
   - Monitors changes in speed

2. **Gyroscope**
   - Measures rotation in 3 axes
   - Detects rollover/flipping
   - Monitors orientation changes

### Detection Criteria

The system triggers a crash alert when it detects:

| Condition | Threshold | Description |
|-----------|-----------|-------------|
| **High Impact** | 30.0 m/s² | Sudden severe collision |
| **Sudden Stop** | 25.0 m/s² drop | Rapid deceleration/braking |
| **Sustained Force** | 24.0 m/s² avg | Continuous high acceleration |
| **High Rotation** | 5.0 rad/s | Vehicle rollover/flip |

### Monitoring Frequency

- **Checks every**: 100 milliseconds (10 times per second)
- **History tracked**: Last 10 samples (1 second)
- **Always active**: When enabled, runs continuously

---

## 🎮 Test Screen Features

### Status Indicators

```
┌─────────────────────────────────┐
│ 🟢 Crash Detection             │
│    Active                       │
│    ✓ Monitoring sensors         │
└─────────────────────────────────┘

Current State:
├─ Crash Detected: NO
├─ Alert Active: NO
├─ Emergency Called: NO
└─ Countdown: 30s
```

### Available Actions

1. **Simulate Crash**
   - Red button with warning icon
   - Triggers test crash event
   - Starts full alert sequence

2. **Reset Crash State**
   - Outlined button
   - Clears crash data
   - Returns to normal state

### Real-Time Updates

The test screen updates automatically showing:
- Current monitoring status
- Crash detection state
- Last crash event details
- Alert countdown progress

---

## 📊 Understanding the Display

### Last Crash Event Information

When a crash is detected, you'll see:

```
Last Crash Event
├─ Type: impact / suddenStop / sustained
├─ Time: HH:MM:SS
├─ Magnitude: XX.XX m/s²
└─ Description: Detailed explanation
```

### Detection Thresholds Display

```
Detection Thresholds
├─ Impact Threshold: 30.0 m/s²
├─ Sudden Stop Threshold: 25.0 m/s²
├─ Check Interval: 100 ms
└─ Alert Countdown: 30 seconds
```

---

## ⚙️ Settings Integration

### Accessing from Settings

```
Settings
└─ Safety
   ├─ Crash Detection [Toggle]
   │  └─ Active - Monitoring for crashes
   └─ Test Crash Detection [Button]
      └─ Opens test screen
```

### Quick Toggle

- **ON**: Green, "Active - Monitoring for crashes"
- **OFF**: Grey, "Inactive - Tap to enable"

---

## 🔔 What Happens in a Real Crash

### Automatic Sequence

1. **Detection** (< 1 second)
   - Sensors detect crash conditions
   - System analyzes data
   - Crash confirmed

2. **Alert Phase** (30 seconds)
   - Screen turns RED
   - Countdown starts
   - Vibration and sound
   - User can cancel

3. **Emergency Call** (at 0 seconds)
   - Phone dialer opens
   - Calls emergency contact
   - Alert indicates "Calling..."

4. **After Call**
   - Alert remains active
   - User can reset state
   - Crash logged for history

---

## 🛡️ Safety Features

### False Positive Prevention

- Multiple detection algorithms
- Sustained acceleration check
- History-based analysis
- 30-second cancel window

### User Control

- Easy ON/OFF toggle
- Large cancel button
- 30 seconds to respond
- Manual reset available

### Privacy & Data

- No data sent to servers
- Local processing only
- No crash history stored remotely
- User controls all settings

---

## ⚠️ Important Testing Notes

### Before Testing

- ✅ Inform emergency contact you're testing
- ✅ Ensure phone has signal
- ✅ Test in safe, stationary location
- ✅ Have phone readily accessible
- ❌ DON'T test while riding
- ❌ DON'T test in moving vehicle

### During Testing

- Watch the entire countdown once
- Test the cancel button
- Observe all visual changes
- Note vibration patterns
- Check if sound plays

### After Testing

- Reset crash state
- Verify normal operation
- Toggle detection OFF if not riding
- Review crash event details

---

## 🐛 Troubleshooting

### "Crash Detection" Toggle Grayed Out

**Solution**: Grant sensor permissions
- Go to phone Settings → Apps → PBAK Kenya
- Enable all permissions
- Restart app

### Alert Doesn't Show

**Solution**: Check integration
- Ensure app is latest version
- Restart app
- Check for error messages in test screen

### No Vibration

**Solution**: Check device settings
- Enable vibration in phone settings
- Check "Do Not Disturb" mode
- Some devices may not support

### Emergency Call Doesn't Work

**Solution**: Check permissions
- Grant CALL_PHONE permission
- Ensure emergency contact is valid phone number
- Format: +254XXXXXXXXX or 07XXXXXXXX

---

## 📈 Interpreting Results

### Good Test Results

✅ Alert appears immediately  
✅ Countdown accurate (1 per second)  
✅ Cancel button responsive  
✅ Device vibrates  
✅ Call initiates at 0 seconds  

### Issues to Report

❌ Delay in alert appearing  
❌ Countdown jumps/skips  
❌ Cancel doesn't work  
❌ No vibration  
❌ Call doesn't initiate  

---

## 💡 Pro Tips

1. **Test Regularly**: Monthly tests ensure system works
2. **Update Emergency Contact**: Keep it current
3. **Explain to Contact**: Let them know about the feature
4. **Toggle OFF When Not Riding**: Saves battery
5. **Test New Phone Mounts**: Ensure sensors work correctly

---

## 📞 Emergency Contact Setup

### Setting Your Emergency Contact

1. Go to **Profile** → **Edit Profile**
2. Update **Emergency Contact** field
3. Use format: `+254712345678` or `0712345678`
4. Save changes
5. Test the crash detection

### Best Practices

- Use someone who answers quickly
- Explain the app feature to them
- Keep multiple contacts (future feature)
- Update if contact changes

---

## 🎓 Understanding Sensor Data

### What Accelerometer Measures

- **X-axis**: Left/Right acceleration
- **Y-axis**: Forward/Backward acceleration  
- **Z-axis**: Up/Down acceleration
- **Magnitude**: Combined force from all axes

### What Gyroscope Measures

- **X-axis**: Pitch (nose up/down)
- **Y-axis**: Roll (lean left/right)
- **Z-axis**: Yaw (turn left/right)
- **Magnitude**: Combined rotation

### Normal vs Crash Values

| Scenario | Acceleration | Rotation |
|----------|--------------|----------|
| Normal Riding | 5-15 m/s² | 0-2 rad/s |
| Hard Braking | 15-25 m/s² | 0-1 rad/s |
| **Crash** | **> 30 m/s²** | **> 5 rad/s** |

---

## ✅ Testing Checklist

Print this and check off during testing:

- [ ] Enabled crash detection in settings
- [ ] Opened test screen successfully
- [ ] Status shows "Active - Monitoring"
- [ ] Tapped "Simulate Crash" button
- [ ] Screen turned RED immediately
- [ ] Warning icon appeared
- [ ] "CRASH DETECTED" title visible
- [ ] Countdown started at 30
- [ ] Countdown decremented correctly
- [ ] Device vibrated continuously
- [ ] Cancel button clearly visible
- [ ] Tapped cancel button
- [ ] Alert dismissed successfully
- [ ] Simulated crash again
- [ ] Let countdown reach 0
- [ ] Emergency contact called
- [ ] Phone dialer opened
- [ ] Crash details displayed
- [ ] Reset crash state button worked
- [ ] Toggle OFF/ON worked correctly
- [ ] No errors or crashes occurred

---

## 🆘 Need Help?

If you encounter issues:

1. **Check Permissions**: Settings → Apps → PBAK Kenya
2. **Restart App**: Force close and reopen
3. **Update App**: Ensure latest version
4. **Check Device**: Ensure sensors work (tilt phone, should respond)
5. **Contact Support**: Report specific issues

---

## 🎉 Success!

You've successfully tested the crash detection system!

**Key Takeaways:**
- ✅ System monitors continuously when enabled
- ✅ Detects crashes using multiple algorithms
- ✅ Gives 30 seconds to cancel false alerts
- ✅ Automatically calls emergency contact
- ✅ Full control through settings

**Remember:**
- Test monthly to ensure functionality
- Keep emergency contact updated
- Enable before rides
- Disable when not riding

**Stay Safe!** 🏍️
