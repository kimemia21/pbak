# Testing Registration with Hardcoded IDs

## Overview
The validation has been updated to only check for upload IDs, not the actual file uploads. This allows bypassing image uploads during testing by hardcoding the IDs.

---

## How to Bypass Uploads for Testing

### Option 1: Set IDs in initState (Already in Code)

The current code has test data in `initState`:
```dart
@override
void initState() {
  super.initState();
  _registrationService.initialize();
  _initializeLocalStorage();
  _loadMakes();
  
  // Test data is already there if you want to add IDs:
  // _dlPicId = 1764937219347;
  // _passportPhotoId = 1764937239888;
  // _bikeFrontPhotoId = 1764937259123;
  // _bikeSidePhotoId = 1764937279456;
  // _bikeRearPhotoId = 1764937299789;
  // _insuranceLogbookId = 1764937319012;
  // _passportPhotoVerified = true; // Skip face verification
}
```

### Option 2: Add a Debug Mode Toggle

Create a debug flag to enable test mode:
```dart
// At the top of the class
static const bool DEBUG_MODE = true; // Set to false for production

@override
void initState() {
  super.initState();
  _registrationService.initialize();
  _initializeLocalStorage();
  _loadMakes();
  
  if (DEBUG_MODE) {
    _loadTestData();
  }
}

void _loadTestData() {
  // Hardcoded IDs for testing
  _dlPicId = 1764937219347;
  _passportPhotoId = 1764937239888;
  _passportPhotoVerified = true;
  
  _bikeFrontPhotoId = 1764937259123;
  _bikeSidePhotoId = 1764937279456;
  _bikeRearPhotoId = 1764937299789;
  
  _insuranceLogbookId = 1764937319012;
  
  print('🧪 Test mode enabled - Image IDs hardcoded');
}
```

---

## Updated Validation Logic

### Documents Step (Step 3)
**Before:**
```dart
if (_dlPicFile == null || _dlPicId == null) {
  // Required BOTH file and ID
}
```

**After:**
```dart
if (_dlPicId == null) {
  // Only requires ID (can be hardcoded)
}
```

### Bike Photos Step (Step 4)
**Before:**
```dart
if (_bikeFrontPhoto == null || _bikeFrontPhotoId == null) {
  // Required BOTH file and ID
}
```

**After:**
```dart
if (_bikeFrontPhotoId == null) {
  // Only requires ID (can be hardcoded)
}
```

### Face Verification
**Before:**
```dart
if (!_passportPhotoVerified) {
  // Always required verification
}
```

**After:**
```dart
if (_passportPhotoFile != null && !_passportPhotoVerified) {
  // Only checks if file was uploaded
  // Can bypass by setting _passportPhotoVerified = true
}
```

---

## What Gets Validated

### Always Validated (Cannot Bypass)
- ✅ Email, phone, password
- ✅ First name, last name, DOB, gender
- ✅ National ID, driving license number
- ✅ Home address, club selection
- ✅ Bike make, model, color, plate number
- ✅ Emergency contact details
- ✅ Blood type

### Can Be Bypassed with Hardcoded IDs
- 🔧 Driving license photo (just set `_dlPicId`)
- 🔧 Passport photo (set `_passportPhotoId` + `_passportPhotoVerified = true`)
- 🔧 Bike front photo (set `_bikeFrontPhotoId`)
- 🔧 Bike side photo (set `_bikeSidePhotoId`)
- 🔧 Bike rear photo (set `_bikeRearPhotoId`)
- 🔧 Insurance logbook (set `_insuranceLogbookId`)

---

## Testing Scenarios

### Scenario 1: Test Full Flow Without Uploads
```dart
// In initState or test method
_dlPicId = 1764937219347;
_passportPhotoId = 1764937239888;
_passportPhotoVerified = true;

_bikeFrontPhotoId = 1764937259123;
_bikeSidePhotoId = 1764937279456;
_bikeRearPhotoId = 1764937299789;

_insuranceLogbookId = 1764937319012;
```

**Result:**
- ✅ Can skip all upload steps
- ✅ Validation passes
- ✅ JSON includes hardcoded IDs
- ✅ Registration completes

### Scenario 2: Test Upload Validation
```dart
// Don't set any IDs
// Try to proceed through steps
```

**Result:**
- ❌ Step 3 blocks without DL/passport IDs
- ❌ Step 4 blocks without bike photo IDs
- ✅ Proper error messages shown

### Scenario 3: Test Partial Upload
```dart
// Upload DL and passport normally
// Hardcode bike photo IDs
_bikeFrontPhotoId = 1764937259123;
_bikeSidePhotoId = 1764937279456;
_bikeRearPhotoId = 1764937299789;
```

**Result:**
- ✅ Step 3 requires actual uploads
- ✅ Step 4 accepts hardcoded IDs
- ✅ Mixed testing approach works

---

## JSON Payload

With hardcoded IDs, the payload will include:
```json
{
  "email": "test@example.com",
  "dl_pic": 1764937219347,
  "passport_photo": 1764937239888,
  "bike": {
    "photo_front_id": 1764937259123,
    "photo_side_id": 1764937279456,
    "photo_rear_id": 1764937299789,
    "insurance_logbook_id": 1764937319012
  }
}
```

The server will accept these IDs as long as they reference valid uploads in the database.

---

## Important Notes

### For Testing
- ✅ Use hardcoded IDs to skip uploads
- ✅ Faster testing of registration flow
- ✅ Test JSON format without uploading
- ✅ Test validation logic

### For Production
- ❌ Remove all hardcoded IDs
- ❌ Set DEBUG_MODE = false
- ✅ Require actual uploads
- ✅ Enforce face verification

### Validation Order
1. Check if ID exists (either uploaded or hardcoded)
2. If file uploaded, check verification status
3. If ID missing, show error

---

## Quick Test Setup

Add this to `register_screen.dart` for quick testing:

```dart
// Add at the top of _RegisterScreenState class
static const bool BYPASS_UPLOADS = true; // SET TO FALSE FOR PRODUCTION!

@override
void initState() {
  super.initState();
  _registrationService.initialize();
  _initializeLocalStorage();
  _loadMakes();
  
  if (BYPASS_UPLOADS) {
    Future.delayed(Duration.zero, () {
      setState(() {
        // Document IDs
        _dlPicId = 1764937219347;
        _passportPhotoId = 1764937239888;
        _passportPhotoVerified = true;
        
        // Bike photo IDs
        _bikeFrontPhotoId = 1764937259123;
        _bikeSidePhotoId = 1764937279456;
        _bikeRearPhotoId = 1764937299789;
        
        // Insurance logbook ID
        _insuranceLogbookId = 1764937319012;
      });
    });
    
    print('⚠️ WARNING: Upload bypass is ENABLED - for testing only!');
  }
}
```

---

## Cleanup Before Production

Before deploying to production:

1. **Remove all hardcoded IDs**
   ```dart
   // Remove these lines:
   _dlPicId = 1764937219347;
   _passportPhotoId = 1764937239888;
   // etc.
   ```

2. **Set debug flags to false**
   ```dart
   static const bool BYPASS_UPLOADS = false;
   static const bool DEBUG_MODE = false;
   ```

3. **Test with actual uploads**
   - Upload all required photos
   - Verify face verification works
   - Confirm IDs are extracted from API response

4. **Verify validation**
   - Try to skip uploads → should show errors
   - Try to proceed without photos → should block
   - Confirm all validation messages work

---

**Status**: ✅ Validation updated to allow hardcoded IDs for testing

**Warning**: Remember to disable bypass mode before production deployment!
