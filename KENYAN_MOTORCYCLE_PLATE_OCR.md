# Kenyan Motorcycle Number Plate OCR Implementation

## Overview

This implementation provides robust OCR post-processing and validation specifically designed for Kenyan motorcycle registration plates. It solves the problem of fragmented and inaccurate text detection from Google ML Kit by implementing intelligent text reconstruction and validation.

## Problem Statement

Google ML Kit's OCR engine doesn't understand the structure of Kenyan motorcycle number plates, resulting in:
- **Fragmented text blocks**: e.g., "KMET" and "d650 L" detected separately
- **Character misreads**: Common OCR mistakes like O↔0, I↔1, S↔5, B↔8
- **Incorrect grouping**: Text grouped incorrectly, producing invalid plates like "D650 L"

## Solution

### Kenyan Motorcycle Plate Format

Motorcycles in Kenya follow a specific format different from cars:

**Format**: `KM[A-Z]{2} [0-9]{3}[A-Z]?`

**Components**:
- **Prefix**: Always starts with `KM`
- **Letters**: Exactly 2 letters after KM (e.g., FB, DD, EA, GD)
- **Space**: Optional space separator
- **Digits**: Exactly 3 digits (e.g., 123, 650, 001)
- **Suffix**: Optional single letter at the end (e.g., A, L, Z)

**Valid Examples**:
- `KMFB 123A` - Full format with suffix
- `KMDD 650L` - Full format with suffix
- `KMEA 001` - No suffix letter
- `KMGD 900Z` - Full format with suffix
- `KMAB320` - Compact format (no spaces)

**Invalid Examples** (Car plates, wrong format):
- `KBZ 456Y` - Car plate (missing motorcycle prefix KM)
- `KCA 123B` - Car plate
- `KMFB 12A` - Only 2 digits (needs 3)
- `KMFB 1234A` - Too many digits

## Implementation Details

### 1. Kenyan Plate Parser (`lib/utils/kenyan_plate_parser.dart`)

A specialized parser that handles ML Kit OCR output and extracts valid Kenyan motorcycle plates.

#### Key Features

**Multi-Strategy Text Extraction**:
1. **Individual lines**: Try each detected text line independently
2. **Adjacent merging**: Merge adjacent text blocks (e.g., "KMET" + "d650L")
3. **Space-based merging**: Try merging with spaces between blocks
4. **Full merging**: Combine all detected text

**Smart Text Normalization**:
- Uppercase conversion for consistency
- Special character removal
- Space normalization
- Noise filtering

**OCR Error Correction**:
- Position-aware corrections (letters in letter positions, digits in digit positions)
- Common misread mapping:
  - `O` → `0` (Letter to digit)
  - `I` → `1`
  - `L` → `1`
  - `S` → `5`
  - `B` → `8`
  - `Z` → `2`
  - `G` → `6`
- Reverse corrections for letter context (e.g., `0` → `O` in letter positions)

**Candidate Scoring**:
- Direct regex match: Higher confidence
- Reconstructed plates: Moderate confidence
- OCR-corrected plates: Slightly lower confidence
- Best candidate selection based on scoring

#### Usage Example

```dart
import 'package:pbak/utils/kenyan_plate_parser.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

// After getting RecognizedText from ML Kit
final recognizedText = await textRecognizer.processImage(inputImage);

// Parse motorcycle plate
final motorcyclePlate = KenyanPlateParser.parseMotorcyclePlate(recognizedText);

if (motorcyclePlate != null) {
  print('Detected: $motorcyclePlate'); // e.g., "KMFB 123A"
  
  // Validate format
  bool isValid = KenyanPlateParser.isValidMotorcyclePlate(motorcyclePlate);
}
```

### 2. Updated Bike Registration Verification Screen

The `BikeRegistrationVerificationScreen` has been updated to use the new parser for rear view images:

**Changes**:
- Imported `KenyanPlateParser`
- Replaced generic OCR extraction with specialized motorcycle plate parsing
- Updated validation to use Kenyan motorcycle format regex
- Enhanced debug logging for better troubleshooting

**Code Flow for Rear Images**:
```
1. Capture/select image
2. ML Kit Text Recognition
3. KenyanPlateParser.parseMotorcyclePlate()
   ├── Extract text blocks
   ├── Generate candidates with multiple strategies
   ├── Apply OCR corrections
   ├── Score candidates
   └── Return best match
4. Validate with KenyanPlateParser.isValidMotorcyclePlate()
5. Display result to user
```

### 3. Validation Logic

**Strict Regex Validation**:
```dart
RegExp motorcyclePattern = RegExp(
  r'^KM[A-Z]{2}\s*[0-9]{3}[A-Z]?$',
  caseSensitive: false,
);
```

This ensures only valid Kenyan motorcycle plates are accepted.

## Testing

Comprehensive test suite in `test/kenyan_plate_parser_test.dart`:

### Test Categories

1. **Validation Tests**
   - Valid motorcycle plates
   - Invalid plates (wrong format, car plates)
   - Case insensitivity

2. **OCR Correction Tests**
   - Common misreads handling
   - Character position-aware corrections

3. **Edge Cases**
   - Extra spaces
   - Minimum/maximum lengths
   - Case variations

4. **Format Tests**
   - Prefix validation (must be KM + 2 letters)
   - Digit validation (must be exactly 3 digits)
   - Suffix validation (0 or 1 letter)

5. **Real World Examples**
   - Common Kenyan motorcycle plates
   - Car plate rejection

### Running Tests

```bash
flutter test test/kenyan_plate_parser_test.dart
```

## How It Handles Fragmented OCR

### Example: "KMET" + "d650 L"

**Step 1: Text Detection**
```
Block 1: "KMET"
Block 2: "d650 L"
```

**Step 2: Normalization**
```
Block 1: "KMET" → "KMET"
Block 2: "d650 L" → "D650 L"
```

**Step 3: Candidate Generation**

Strategy 1 - Individual lines:
- "KMET" → No match (too short)
- "D650 L" → No match (doesn't start with KM)

Strategy 2 - Adjacent merging:
- "KMET" + "D650 L" → "KMETD650L"

Strategy 3 - Apply corrections:
- Position 0-3: "KMET" (should be KM + 2 letters) ✓
- Position 4-6: "D65" (should be 3 digits) → Apply corrections
  - "D" at position 4 (digit expected) → Keep as error
- Position 7: "0" (digit) → OK
- Position 8: "L" (optional letter) → OK

Strategy 4 - Smart reconstruction:
- Starts with "KM" ✓
- Extract next 2 chars: "ET" ✓
- Extract 3 digits: Need to find in remaining text "D650L"
  - "D" → Not a digit, try correction (no valid correction)
  - Look at "650" → Valid digits ✓
- Extract optional letter: "L" ✓
- Result: "KMET650L" → Format as "KMET 650L"

**Step 4: Validation**
- "KMET 650L" matches `^KM[A-Z]{2}\s*[0-9]{3}[A-Z]?$` ✓

**Step 5: Return**
```
Output: "KMET 650L"
```

## Integration Points

### In BikeRegistrationVerificationScreen

**Import**:
```dart
import 'package:pbak/utils/kenyan_plate_parser.dart';
```

**OCR Extraction** (line ~456):
```dart
Future<String?> _extractRegistrationNumber(InputImage image) async {
  final recognizedText = await _textRecognizer.processImage(image);
  final motorcyclePlate = KenyanPlateParser.parseMotorcyclePlate(recognizedText);
  return motorcyclePlate;
}
```

**Validation** (line ~487):
```dart
bool _isValidPlateFormat(String plate) {
  return KenyanPlateParser.isValidMotorcyclePlate(plate);
}
```

## Error Messages

The implementation provides user-friendly error messages:

**No plate detected**:
```
Number plate not detected.

Tips:
• Ensure the plate is clearly visible
• Avoid shadows and reflections
• Keep the camera steady
• Use good lighting
```

**Invalid format**:
```
Invalid plate format detected: [detected_text]

Please ensure the plate is clearly visible and try again.
```

## Performance Considerations

- **Multiple strategies**: Tries various approaches to maximize detection
- **Confidence scoring**: Returns the most likely candidate
- **Early exit**: Stops processing if a high-confidence match is found
- **Efficient regex**: Uses optimized patterns for fast validation

## Future Enhancements

1. **ML-based confidence**: Integrate ML Kit's confidence scores
2. **Region detection**: Identify plate region in image first
3. **Character segmentation**: Advanced per-character analysis
4. **Learning system**: Improve corrections based on user feedback
5. **Support for multiple formats**: Add car plate support if needed

## Debugging

Enable detailed logging by checking console output:

```
🔍 [KenyanPlateParser] Starting motorcycle plate detection...
  📝 Detected: "KMET"
  📝 Detected: "d650 L"
  🎯 KMET 650L (score: 0.85)
✅ [KenyanPlateParser] Found 1 candidates
✅ [OCR] Kenyan motorcycle plate detected: KMET 650L
✅ [Validation] Valid Kenyan motorcycle plate: KMET 650L
```

## Dependencies

- `google_mlkit_text_recognition` - OCR engine
- Flutter framework for mobile app development

## Summary

This implementation provides:
✅ **Accurate detection** of Kenyan motorcycle plates  
✅ **Robust handling** of fragmented OCR output  
✅ **Smart reconstruction** from partial text blocks  
✅ **OCR error correction** with position-aware logic  
✅ **Strict validation** against Kenyan motorcycle format  
✅ **Production-ready** code with comprehensive tests  
✅ **Clear documentation** and debugging support  

The solution ensures reliable motorcycle plate detection even with noisy camera input and imperfect OCR results.
