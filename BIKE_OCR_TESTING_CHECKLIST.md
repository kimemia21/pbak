# Bike Registration OCR - Testing Checklist

## Pre-Testing Setup

### 1. Dependencies Installed
- [ ] Run `flutter pub get`
- [ ] Verify `google_mlkit_image_labeling: ^0.14.1` is installed
- [ ] Check no dependency conflicts

### 2. Permissions Configured
**Android:**
- [ ] Camera permission in AndroidManifest.xml
- [ ] Storage permission in AndroidManifest.xml

**iOS:**
- [ ] NSCameraUsageDescription in Info.plist
- [ ] NSPhotoLibraryUsageDescription in Info.plist

### 3. Test Images Ready
Prepare test images with:
- [ ] Clear motorcycle front view with visible license plate
- [ ] Clear motorcycle side view
- [ ] Clear motorcycle rear view with visible license plate
- [ ] Blurry motorcycle image
- [ ] Non-motorcycle image (car, bicycle, etc.)
- [ ] Multiple registration formats (if applicable)

---

## Functional Testing

### Camera Functionality
- [ ] **Test 1.1**: App launches camera screen successfully
- [ ] **Test 1.2**: Camera preview displays correctly
- [ ] **Test 1.3**: Camera guide overlay appears (frame with corners)
- [ ] **Test 1.4**: Frame size adjusts based on image type (front/side/rear)
- [ ] **Test 1.5**: Capture button is enabled
- [ ] **Test 1.6**: Back button returns to Add Bike screen

### Gallery Upload
- [ ] **Test 2.1**: Gallery icon is visible and clickable
- [ ] **Test 2.2**: Gallery opens on tap
- [ ] **Test 2.3**: Selected image displays for review
- [ ] **Test 2.4**: Can cancel gallery selection

### Motorcycle Verification
- [ ] **Test 3.1**: Real motorcycle image is verified ✅
- [ ] **Test 3.2**: Confidence score displays correctly
- [ ] **Test 3.3**: Vehicle type is detected and shown
- [ ] **Test 3.4**: Non-motorcycle image is rejected ❌
- [ ] **Test 3.5**: Detected labels display (top 5)
- [ ] **Test 3.6**: Verification badge shows correct status

### OCR Registration Extraction
- [ ] **Test 4.1**: Front image with clear plate extracts registration
- [ ] **Test 4.2**: Rear image with clear plate extracts registration
- [ ] **Test 4.3**: Side image doesn't trigger OCR (as expected)
- [ ] **Test 4.4**: Extracted number displays in results
- [ ] **Test 4.5**: Multiple registration formats are recognized:
  - [ ] Format: KBZ 456Y (spaces)
  - [ ] Format: ABC123D (no spaces)
  - [ ] Format: AB 12 CDE (multiple segments)
- [ ] **Test 4.6**: Blurry plate shows no extraction (graceful failure)

### Results Display
- [ ] **Test 5.1**: Verification status card displays
- [ ] **Test 5.2**: Registration number card displays (when found)
- [ ] **Test 5.3**: Detected labels display with confidence %
- [ ] **Test 5.4**: Results overlay is readable
- [ ] **Test 5.5**: Icons and colors match status (green/red)

### User Actions
- [ ] **Test 6.1**: Retake button works correctly
- [ ] **Test 6.2**: Retake clears previous results
- [ ] **Test 6.3**: Confirm button enabled only when motorcycle verified
- [ ] **Test 6.4**: Confirm button disabled for non-motorcycle
- [ ] **Test 6.5**: Confirming returns to Add Bike screen

### Integration with Add Bike Screen
- [ ] **Test 7.1**: Tapping "Upload Front Photo" opens verification screen
- [ ] **Test 7.2**: Tapping "Upload Side Photo" opens verification screen
- [ ] **Test 7.3**: Tapping "Upload Rear Photo" opens verification screen
- [ ] **Test 7.4**: Logbook upload still uses regular picker (not verification)
- [ ] **Test 7.5**: Captured image appears in Add Bike form
- [ ] **Test 7.6**: Registration number auto-fills in form (if extracted)
- [ ] **Test 7.7**: Success message shows extracted registration
- [ ] **Test 7.8**: Error message shows if not a motorcycle
- [ ] **Test 7.9**: Can manually edit auto-filled registration
- [ ] **Test 7.10**: Image uploads successfully after confirmation

### Analysis Progress
- [ ] **Test 8.1**: "Analyzing image..." message displays
- [ ] **Test 8.2**: Progress indicator shows during analysis
- [ ] **Test 8.3**: Analysis completes within 5-10 seconds
- [ ] **Test 8.4**: UI remains responsive during analysis

---

## Edge Cases & Error Handling

### Poor Image Quality
- [ ] **Test 9.1**: Very dark image - shows appropriate message
- [ ] **Test 9.2**: Very bright/overexposed image
- [ ] **Test 9.3**: Blurry image - OCR fails gracefully
- [ ] **Test 9.4**: Partially visible motorcycle - may still verify

### License Plate Issues
- [ ] **Test 10.1**: Dirty/obscured plate - OCR fails gracefully
- [ ] **Test 10.2**: Angled plate - OCR may fail but doesn't crash
- [ ] **Test 10.3**: No plate visible - OCR returns null, no error
- [ ] **Test 10.4**: Foreign/unusual format - may not match, doesn't crash

### Multiple Objects
- [ ] **Test 11.1**: Multiple motorcycles in frame
- [ ] **Test 11.2**: Motorcycle with other vehicles
- [ ] **Test 11.3**: Cluttered background doesn't prevent detection

### Camera/Permission Issues
- [ ] **Test 12.1**: First launch requests camera permission
- [ ] **Test 12.2**: Permission denied shows appropriate error
- [ ] **Test 12.3**: Can navigate away if permission denied
- [ ] **Test 12.4**: Re-requesting permission works
- [ ] **Test 12.5**: No camera available shows error message

### Memory & Performance
- [ ] **Test 13.1**: Large image doesn't cause crash
- [ ] **Test 13.2**: Multiple captures don't cause memory leak
- [ ] **Test 13.3**: Switching between camera/gallery works smoothly
- [ ] **Test 13.4**: App remains responsive during processing

---

## UI/UX Testing

### Layout & Responsiveness
- [ ] **Test 14.1**: UI adapts to phone screen
- [ ] **Test 14.2**: UI adapts to tablet screen
- [ ] **Test 14.3**: Portrait orientation works
- [ ] **Test 14.4**: Landscape orientation works (if applicable)
- [ ] **Test 14.5**: No UI overflow or clipping
- [ ] **Test 14.6**: Text is readable on all backgrounds

### Visual Design
- [ ] **Test 15.1**: Camera frame overlay is clear
- [ ] **Test 15.2**: Corner accents are visible
- [ ] **Test 15.3**: Results cards are well-styled
- [ ] **Test 15.4**: Icons are appropriate and clear
- [ ] **Test 15.5**: Colors match app theme
- [ ] **Test 15.6**: Loading indicators are visible

### User Experience
- [ ] **Test 16.1**: Instructions are clear and helpful
- [ ] **Test 16.2**: Feedback messages are informative
- [ ] **Test 16.3**: Button labels are clear
- [ ] **Test 16.4**: Flow feels natural and intuitive
- [ ] **Test 16.5**: No confusing or unexpected behavior

---

## Platform-Specific Testing

### Android
- [ ] **Test 17.1**: Works on Android 8.0+
- [ ] **Test 17.2**: Camera permission dialog shows correctly
- [ ] **Test 17.3**: Gallery picker works
- [ ] **Test 17.4**: Back button behavior is correct
- [ ] **Test 17.5**: No Android-specific crashes

### iOS
- [ ] **Test 18.1**: Works on iOS 12.0+
- [ ] **Test 18.2**: Camera permission dialog shows correctly
- [ ] **Test 18.3**: Photo library picker works
- [ ] **Test 18.4**: Back swipe gesture works
- [ ] **Test 18.5**: No iOS-specific crashes

---

## Performance Benchmarks

### Timing (Target: < 10 seconds total)
- [ ] Camera initialization: _____ seconds (Target: < 2s)
- [ ] Image capture: _____ seconds (Target: < 1s)
- [ ] Motorcycle verification: _____ seconds (Target: < 3s)
- [ ] OCR extraction: _____ seconds (Target: < 3s)
- [ ] Total process: _____ seconds (Target: < 10s)

### Accuracy
- [ ] Motorcycle detection rate: _____ % (Target: > 90%)
- [ ] OCR accuracy: _____ % (Target: > 80%)
- [ ] False positives (non-motorcycle as motorcycle): _____ % (Target: < 5%)
- [ ] False negatives (motorcycle not detected): _____ % (Target: < 10%)

---

## Regression Testing

### Existing Functionality Not Broken
- [ ] **Test 19.1**: Add Bike without new verification still works
- [ ] **Test 19.2**: Edit Bike functionality intact
- [ ] **Test 19.3**: Logbook upload unchanged
- [ ] **Test 19.4**: Manual registration entry still works
- [ ] **Test 19.5**: Form validation unchanged
- [ ] **Test 19.6**: Bike submission works end-to-end

---

## Accessibility Testing

- [ ] **Test 20.1**: Screen reader support (if applicable)
- [ ] **Test 20.2**: Sufficient color contrast
- [ ] **Test 20.3**: Touch targets are adequate size
- [ ] **Test 20.4**: Text is readable without zoom

---

## Documentation Review

- [ ] **Test 21.1**: README is updated
- [ ] **Test 21.2**: Code comments are clear
- [ ] **Test 21.3**: User guide is accurate
- [ ] **Test 21.4**: Technical documentation is complete

---

## Sign-Off

### Tested By
- **Name**: _______________
- **Date**: _______________
- **Device**: _______________
- **OS Version**: _______________
- **App Version**: _______________

### Results Summary
- **Total Tests**: _____
- **Passed**: _____
- **Failed**: _____
- **Blocked**: _____
- **Skipped**: _____

### Critical Issues Found
1. _______________________________________________
2. _______________________________________________
3. _______________________________________________

### Approval
- [ ] All critical tests passed
- [ ] No critical bugs found
- [ ] Ready for production

**Approved By**: _______________
**Date**: _______________

---

## Notes & Observations

```
Add any additional notes, observations, or feedback here:




```

---

**Version**: 1.0.0
**Last Updated**: 2024
