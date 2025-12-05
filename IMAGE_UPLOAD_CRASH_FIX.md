# Image Upload Crash Fix

## Problem
The app was crashing when users tried to upload images from their device gallery. This was caused by:
1. Missing Android permissions for accessing photos (especially Android 13+)
2. Missing iOS permissions for camera and photo library
3. Lack of error handling in image picker calls

## Solution Implemented

### 1. Android Permissions (android/app/src/main/AndroidManifest.xml)

Added the following permissions:
```xml
<!-- Camera and Gallery Permissions -->
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>

<!-- Android 13+ (API 33+) Photo picker permissions -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO"/>
```

**Why these are needed:**
- `CAMERA`: Required for taking photos with camera
- `READ_EXTERNAL_STORAGE`: For reading photos from gallery (Android 12 and below)
- `WRITE_EXTERNAL_STORAGE`: For saving photos
- `READ_MEDIA_IMAGES`: Required for Android 13+ (API 33+) to access images
- `READ_MEDIA_VIDEO`: Required for Android 13+ to access videos

### 2. iOS Permissions (ios/Runner/Info.plist)

Added the following permissions:
```xml
<!-- Camera and Photo Library permissions -->
<key>NSCameraUsageDescription</key>
<string>We need access to your camera to take photos of your documents and bike.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to your photo library to upload documents and bike photos.</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>We need permission to save photos to your library.</string>
```

**Why these are needed:**
- iOS requires explicit permission descriptions
- Without these, the app will crash when trying to access camera or gallery
- Users must see why the app needs these permissions

### 3. Error Handling in Image Picker Calls

Updated the following files with try-catch blocks:

#### lib/views/auth/register_screen.dart
- `_pickImage()` method - wrapped in try-catch
- `_pickInsuranceLogbook()` method - wrapped in try-catch
- Shows user-friendly error message if permission denied or picker fails

#### lib/views/bikes/add_bike_screen.dart
- Image picker for insurance logbook - wrapped in try-catch
- Shows error message on failure

#### lib/views/documents/upload_document_screen.dart
- Already had error handling ✓

## Testing Steps

### Android Testing
1. Clean and rebuild the app:
   ```bash
   flutter clean
   flutter pub get
   cd android && ./gradlew clean && cd ..
   flutter run
   ```

2. Test image upload from:
   - Gallery (should request permission first time)
   - Camera (should request camera permission)

3. Test permission denial:
   - Deny permission and verify error message shows
   - Grant permission in settings and retry

### iOS Testing
1. Clean and rebuild:
   ```bash
   flutter clean
   flutter pub get
   cd ios && rm -rf Pods Podfile.lock && pod install && cd ..
   flutter run
   ```

2. Test permissions:
   - First time camera access should show permission dialog
   - First time gallery access should show permission dialog
   - Check permission messages are clear

## Files Modified

1. `android/app/src/main/AndroidManifest.xml` - Added Android permissions
2. `ios/Runner/Info.plist` - Added iOS permission descriptions
3. `lib/views/auth/register_screen.dart` - Added error handling
4. `lib/views/bikes/add_bike_screen.dart` - Added error handling
5. `lib/services/comms/registration_service.dart` - ID extraction fix
6. `lib/services/upload_service.dart` - ID extraction fix

## Common Error Messages

### Android
- **"Permission denied"**: User denied storage/camera permission
- **"No Activity found to handle Intent"**: Missing camera app or gallery app

### iOS
- **"User denied access"**: User denied photo library or camera access
- **App crash without error**: Missing permission descriptions in Info.plist

## User Impact

✅ **Before Fix:**
- App crashes when selecting images
- No error messages
- Poor user experience

✅ **After Fix:**
- Smooth image selection from gallery
- Camera works properly
- Clear error messages if permissions denied
- Prompts user to check permissions
- App doesn't crash

## Runtime Permission Handling

The app will now:
1. Request permission when user first tries to access camera/gallery
2. Show system permission dialog
3. Handle permission denial gracefully
4. Show helpful error message guiding user to settings if needed

## Notes for Users

If image upload still doesn't work after this fix:
1. Go to device Settings
2. Find the app (PBAK)
3. Enable Camera and Storage/Photos permissions manually
4. Restart the app and try again
