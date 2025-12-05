# Bike Registration OCR - Quick Start Guide

## What's New? 🎉

When adding a bike, the app now:
1. **Verifies uploaded images are motorcycles** using AI
2. **Automatically extracts registration numbers** from license plates
3. **Auto-fills the registration field** for you

## How to Use

### Step 1: Add a New Bike
Navigate to: **Bikes Screen → Add New Bike**

### Step 2: Upload Photos
When you tap "Upload Front/Side/Rear Photo", you'll see a new camera screen with:
- Live camera preview with guide frame
- Option to capture or select from gallery

### Step 3: Capture the Image
- **Front Photo**: Frame the license plate clearly
- **Side Photo**: Show the full motorcycle profile
- **Rear Photo**: Frame the rear license plate

### Step 4: Review Results
After capturing, you'll see:
- ✅ Motorcycle verification status
- 🔢 Extracted registration number (if found)
- 📊 Confidence score and detected labels

### Step 5: Confirm or Retake
- If verified ✅: Tap **Confirm** to proceed
- If not verified ❌: Tap **Retake** to try again

### Step 6: Auto-Fill Magic ✨
- Registration number automatically fills in the form
- You can edit it if needed

## Tips for Best Results

### For Clear License Plates 📸
- Use good lighting (daylight works best)
- Keep the camera steady
- Position 2-3 meters from the bike
- Ensure plate is clean and visible

### For Motorcycle Verification ✅
- Show the entire bike or major parts
- Avoid too much background clutter
- Use clear, well-lit images

## What If...?

### Registration Not Detected?
- **Solution**: Retake with better lighting and clearer view of plate
- You can still manually enter it in the form

### Motorcycle Not Verified?
- **Solution**: Retake showing more of the motorcycle
- Ensure the bike is the main subject in the frame

### Want to Use Gallery Instead?
- Tap the gallery icon in the bottom left
- Select a clear photo from your library

## Supported Registration Formats

The OCR recognizes various formats:
- `KBZ 456Y` (with spaces)
- `ABC123D` (no spaces)
- `AB 12 CDE` (multiple segments)

## Technical Details

**Image Analysis includes:**
- Motorcycle verification using ML Kit Image Labeling
- OCR text extraction using ML Kit Text Recognition
- Pattern matching for registration numbers
- Confidence scoring for reliability

**Processing time:** 3-5 seconds per image

---

**Need Help?** See the full guide in `BIKE_REGISTRATION_OCR_GUIDE.md`
