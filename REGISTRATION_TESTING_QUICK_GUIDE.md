# Registration Testing Quick Guide

## Quick Test Scenarios

### ✅ Scenario 1: Complete Registration Flow
1. Open app → Tap "Register"
2. Fill Account Info → Tap Next (should validate email, phone, password)
3. Fill Personal Info → Tap Next (should validate all fields)
4. Select Home Location & Club → Tap Next
5. Upload DL & Passport Photo → Tap Next (check IDs extracted)
6. Fill Bike Details & Upload Photos → Tap Next
7. Fill Emergency & Medical → Submit
8. **Expected**: Registration successful, JSON matches server format

### ✅ Scenario 2: Save & Resume
1. Fill steps 1-3
2. Upload some photos
3. Close app (or tap back)
4. **Expected**: "Progress saved" dialog
5. Reopen app → Tap "Register"
6. **Expected**: "Welcome back! Resuming from step 4"
7. Check all data is restored
8. Check uploaded images are still shown
9. Continue and complete registration

### ✅ Scenario 3: Step Validation
1. Try to proceed from step 1 without filling email
2. **Expected**: Error "Email address is required"
3. Try to proceed from step 3 without uploading DL
4. **Expected**: Error "Please upload your driving license photo"
5. Each step should block progression until complete

### ✅ Scenario 4: ANPR Dialog (Rear Photo)
1. Navigate to bike details step
2. Capture rear photo with unclear number plate
3. **Expected**: Interactive dialog appears with:
   - Warning message
   - "Retake Photo" option
   - Manual entry field
   - Format guide
4. Test "Retake Photo" → returns to camera
5. Test manual entry → validates format

### ✅ Scenario 5: Insurance Logbook
1. Navigate to bike details
2. Check "Has Bike Insurance"
3. **Expected**: Insurance fields appear including logbook upload
4. Fill insurance company and policy
5. Upload logbook document
6. **Expected**: Shows filename, uploaded badge, green border
7. Try to proceed without logbook
8. **Expected**: Error "Please upload insurance logbook"

### ✅ Scenario 6: Rear Photo Instructions
1. Navigate to bike photo capture
2. Tap "Front" → **Expected**: "Frame the entire motorcycle in view"
3. Tap "Side" → **Expected**: "Frame the entire motorcycle in view"
4. Tap "Rear" → **Expected**: Red box with "NUMBER PLATE CAPTURE" and checklist
5. Verify instructions are clear and visible

## Quick Checks

### Image Upload IDs
After each upload, check console logs:
```
✓ Uploaded successfully, ID: 1764924068428
✓ Extracted ID from filename: 1764924068428.jpg -> 1764924068428
```

### JSON Format (Console Log)
Before submission, check the JSON structure:
```dart
{
  "email": "...",
  "bike": { ... },      // Nested object
  "emergency": { ... }, // Nested object
  "medical": { ... }    // Nested object
}
```

### Progress Save (Console Log)
```
Progress saved with current_step: 4
Restored progress from step: 4
```

## Common Issues to Check

❌ **Image ID is null after upload**
- Check console for "Extracted ID from filename"
- Verify API response includes filename field

❌ **Can't proceed to next step**
- Check validation errors
- Ensure all required fields filled
- Verify images uploaded (not just selected)

❌ **Progress not restored**
- Check local storage permissions
- Verify _localStorage initialized
- Check console for "Welcome back" message

❌ **ANPR dialog not appearing**
- Ensure rear photo has unclear plate
- Check if detection service is running
- Verify dialog shows after processing

❌ **Insurance logbook not showing**
- Check "Has Bike Insurance" is checked
- Verify conditional rendering works
- Check _hasBikeInsurance state

## Debug Console Commands

```bash
# Check for validation errors
flutter logs | grep "validation"

# Check for upload IDs
flutter logs | grep "Uploaded successfully"

# Check for progress save/restore
flutter logs | grep "Progress saved\|Restored progress"

# Check ANPR detection
flutter logs | grep "ANPR\|plate"
```

## Success Criteria

✅ All validations work correctly
✅ Images upload and IDs extracted
✅ Progress saves and restores properly
✅ ANPR dialog is interactive
✅ Rear photo instructions are clear
✅ Insurance logbook field visible and functional
✅ JSON matches server.http format
✅ Registration completes successfully

## Test Data

**Valid Kenyan Motorcycle Plates:**
- KMFB123A
- KMDD650L
- KMAA111Z
- KMBC999X

**Test User:**
- Email: test@example.com
- Phone: +254712345678
- Password: Test@1234

---

**Ready to Test!** 🚀
