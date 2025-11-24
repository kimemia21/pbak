# Lean Angle Screen Improvements

## Summary
Successfully implemented comprehensive improvements to the lean angle screen with full orientation support, interactive calibration, and responsive UI/UX.

## Key Features Implemented

### 1. **Orientation Support**
- ✅ Auto-rotation enabled for both portrait and landscape modes
- ✅ Orientation lock button (center top) to lock current orientation
- ✅ Proper lean angle calculation for both orientations
- ✅ Visual indicator showing locked orientation (landscape/portrait icon)

### 2. **Interactive Calibration System**
- ✅ Real-time stability detection using accelerometer and gyroscope
- ✅ Visual feedback with progress bars showing device stability
- ✅ Automatic detection of landscape vs portrait mode during calibration
- ✅ Instructions guide users to hold phone upright in riding position
- ✅ Collects 100 samples when device is stable
- ✅ Calculates proper lean angle offset based on device orientation
- ✅ Saves calibration to SharedPreferences for persistence
- ✅ Calibration status indicator (green when calibrated, amber when not)

### 3. **Responsive UI/UX**

#### Portrait Mode:
- Vertical layout with gauge centered
- Timers at top
- Stats strip at bottom
- Optimized for one-handed viewing

#### Landscape Mode:
- Three-column layout:
  - **Left column**: Active stats (Active Ride, Total Time, Speed, Distance, Avg Speed)
  - **Center column**: Large gauge with lean angle (70% of screen height)
  - **Right column**: Additional stats (Altitude, G-Force, Calibration status)
- All information visible without scrolling
- Perfect for mounting on bike handlebars

### 4. **Gauge Improvements**
- ✅ Gauge properly rotated and sized for orientation
- ✅ Centered in viewport
- ✅ Color-coded angle display (white < 15°, orange 15-35°, red > 35°)
- ✅ Motorcycle icon rotates with lean angle
- ✅ Applied calibration offsets for accurate readings

### 5. **Technical Improvements**

#### Sport Tracking Service Updates:
```dart
// Added orientation awareness
bool _isLandscapeMode = false;

// Calibration support
double _calibrationOffsetX = 0.0;
double _calibrationOffsetY = 0.0;
double _calibrationOffsetZ = 0.0;

// Methods
void setLandscapeMode(bool isLandscape)
void setCalibration(double offsetX, double offsetY, double offsetZ)
```

#### Lean Angle Screen Updates:
- Orientation detection in build method
- Auto-updates tracking service when orientation changes
- Calibration button (top left) with visual status
- Orientation lock button (top center)
- Cancel button (top right)

### 6. **Calibration Process**
1. User prompted if not calibrated
2. Instructions displayed with clear steps
3. Real-time stability monitoring (30 readings at 60Hz)
4. Progress bar shows stability percentage
5. Once stable, user taps "START CALIBRATION"
6. Collects 100 accelerometer samples
7. Calculates average and determines offset
8. Saves to preferences
9. Success message displayed

### 7. **Orientation Lock Feature**
- Toggle button in center top
- Locks to current orientation (portrait or landscape)
- Icon changes based on lock state:
  - 🔄 `screen_rotation` - Unlocked (gray)
  - 📱 `screen_lock_portrait` - Locked portrait (green)
  - 📱 `screen_lock_landscape` - Locked landscape (green)

## Files Modified

### 1. `lib/services/sport_mode/sport_tracking_service.dart`
- Added orientation mode tracking
- Added calibration offset support
- Updated lean angle calculation to handle both orientations
- Added methods: `setLandscapeMode()`, `setCalibration()`

### 2. `lib/views/sport_mode/lean_angle_screen.dart`
- Added orientation lock state management
- Implemented responsive layout (portrait vs landscape)
- Created interactive calibration overlay widget
- Added landscape stat cards
- Added orientation detection and auto-update
- Implemented calibration persistence

### 3. `lib/services/local_storage/local_storage_service.dart`
- No changes needed (already supports SharedPreferences)

## Calibration Keys in SharedPreferences
```dart
'lean_calibration_x' - X-axis offset (lean angle)
'lean_calibration_y' - Y-axis offset
'lean_calibration_z' - Z-axis offset  
'lean_is_calibrated' - Boolean flag
```

## Usage Instructions

### For Users:
1. **First Time Setup**: Calibrate your device
   - Hold phone in riding position (upright, screen facing you)
   - For landscape: hold phone horizontally
   - Wait for stability indicator to reach 100%
   - Tap "START CALIBRATION"
   - Keep still for 2 seconds

2. **Lock Orientation**: Tap center button to lock/unlock rotation

3. **Recalibrate**: Tap calibration button (top left) anytime

4. **Best Experience**: Use landscape mode for mounted riding

### For Developers:
- Calibration data persists across app restarts
- Orientation changes are detected automatically
- Tracking service receives real-time orientation updates
- All sensor calculations account for device orientation

## Testing Recommendations
1. Test calibration in both portrait and landscape
2. Verify orientation lock works correctly
3. Test rotation while monitoring lean angles
4. Verify calibration persists after app restart
5. Test on different device sizes
6. Test landscape layout on tablets

## Future Enhancements
- [ ] Add visual guide for calibration position
- [ ] Gyroscope fusion for improved accuracy
- [ ] Record max lean angles per session
- [ ] Export calibration settings
- [ ] Multiple bike profiles with different calibrations
