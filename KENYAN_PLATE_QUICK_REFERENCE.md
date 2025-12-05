# Kenyan Motorcycle Plate OCR - Quick Reference

## 🎯 Format

**Kenyan Motorcycle Plates**: `KM[A-Z]{2} [0-9]{3}[A-Z]?`

```
KM + 2 letters + 3 digits + optional letter
│  │           │           │
│  │           │           └─ Optional suffix (A-Z)
│  │           └─────────────── Exactly 3 digits (000-999)
│  └─────────────────────────── Exactly 2 letters (AA-ZZ)
└────────────────────────────── Always "KM" for motorcycles
```

## ✅ Valid Examples

```
KMFB 123A  ✓  Standard format with suffix
KMDD 650L  ✓  Standard format with suffix
KMEA 001   ✓  No suffix letter
KMGD 900Z  ✓  Standard format with suffix
KMAB320    ✓  Compact (no space)
KMFB123A   ✓  Compact with suffix
kmfb123a   ✓  Case insensitive
```

## ❌ Invalid Examples (Car Plates / Wrong Format)

```
KBZ 456Y     ✗  Car plate (wrong prefix)
KCA 123B     ✗  Car plate (wrong prefix)
KMFB 12A     ✗  Only 2 digits (needs 3)
KMFB 1234A   ✗  Too many digits
KMA 123A     ✗  Only 1 letter after KM (needs 2)
KMFB 123AB   ✗  Too many suffix letters
```

## 🚀 Usage

### Basic Usage

```dart
import 'package:pbak/utils/kenyan_plate_parser.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

// After ML Kit text recognition
final recognizedText = await textRecognizer.processImage(inputImage);

// Parse motorcycle plate
final plate = KenyanPlateParser.parseMotorcyclePlate(recognizedText);

// Validate
if (plate != null) {
  bool isValid = KenyanPlateParser.isValidMotorcyclePlate(plate);
  print('Detected: $plate - ${isValid ? "VALID" : "INVALID"}');
}
```

### Complete Example

```dart
Future<String?> scanMotorcyclePlate(File imageFile) async {
  final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  
  try {
    // 1. Create input image
    final inputImage = InputImage.fromFile(imageFile);
    
    // 2. Run OCR
    final recognizedText = await textRecognizer.processImage(inputImage);
    
    // 3. Parse Kenyan motorcycle plate
    final plate = KenyanPlateParser.parseMotorcyclePlate(recognizedText);
    
    // 4. Validate
    if (plate != null && KenyanPlateParser.isValidMotorcyclePlate(plate)) {
      print('✅ Valid motorcycle plate: $plate');
      return plate;
    } else {
      print('❌ No valid motorcycle plate detected');
      return null;
    }
  } finally {
    textRecognizer.close();
  }
}
```

## 🔧 How It Handles Fragmented OCR

### Problem Example

OCR detects:
```
Block 1: "KMET"
Block 2: "d650 L"
```

### Solution Process

```
1. Normalize text:
   "KMET" → "KMET"
   "d650 L" → "D650L"

2. Try merging strategies:
   - Individual: ✗ "KMET" (too short), ✗ "D650L" (wrong prefix)
   - Adjacent: "KMET" + "D650L" → "KMETD650L"
   - Smart reconstruction: Extract KM + 2 letters + 3 digits + letter
     Result: "KMET650L"

3. Format properly:
   "KMET650L" → "KMET 650L"

4. Validate:
   "KMET 650L" matches KM[A-Z]{2}\s*[0-9]{3}[A-Z]? ✓

5. Return: "KMET 650L"
```

## 📊 OCR Error Corrections

The parser automatically corrects common OCR misreads:

| OCR Sees | Should Be | Context |
|----------|-----------|---------|
| O | 0 | In digit positions |
| I | 1 | In digit positions |
| L | 1 | In digit positions |
| S | 5 | In digit positions |
| B | 8 | In digit positions |
| Z | 2 | In digit positions |
| 0 | O | In letter positions |
| 1 | I | In letter positions |
| 5 | S | In letter positions |

Example:
```
OCR: "KMFBIO5A"  (I and O in wrong places)
Corrected: "KMFB105A"
Formatted: "KMFB 105A"
```

## 🧪 Testing

### Run Tests

```bash
flutter test test/kenyan_plate_parser_test.dart
```

### Test Coverage

- ✓ Valid motorcycle plates
- ✓ Invalid formats
- ✓ Case insensitivity
- ✓ OCR corrections
- ✓ Edge cases (spaces, lengths)
- ✓ Real-world examples

## 🐛 Debugging

Enable debug logging in your console:

```dart
// Parser logs automatically with print statements
// Look for these prefixes:
🔍 [KenyanPlateParser] - Parsing status
📝 Detected - Raw OCR text
🎯 Candidate - Potential matches
✅ Result - Final output
❌ Error - Failures
```

Example output:
```
🔍 [KenyanPlateParser] Starting motorcycle plate detection...
  📝 Detected: "KMET"
  📝 Detected: "d650 L"
  🎯 KMET 650L (score: 0.85)
✅ [KenyanPlateParser] Found 1 candidates
✅ [OCR] Kenyan motorcycle plate detected: KMET 650L
✅ [Validation] Valid Kenyan motorcycle plate: KMET 650L
```

## 📝 API Reference

### `KenyanPlateParser.parseMotorcyclePlate(RecognizedText)`

**Description**: Parse ML Kit OCR output and extract Kenyan motorcycle plate

**Parameters**:
- `recognizedText` (RecognizedText): Output from ML Kit's `processImage()`

**Returns**: `String?`
- Valid plate string (e.g., "KMFB 123A") if found
- `null` if no valid plate detected

**Example**:
```dart
final plate = KenyanPlateParser.parseMotorcyclePlate(recognizedText);
```

---

### `KenyanPlateParser.isValidMotorcyclePlate(String)`

**Description**: Validate if a string matches Kenyan motorcycle plate format

**Parameters**:
- `plate` (String): Plate string to validate

**Returns**: `bool`
- `true` if valid Kenyan motorcycle plate
- `false` otherwise

**Example**:
```dart
bool isValid = KenyanPlateParser.isValidMotorcyclePlate('KMFB 123A');
// Returns: true
```

## 🎨 User-Facing Error Messages

When validation fails, show clear guidance:

```dart
if (!isValid) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Invalid Motorcycle Plate'),
      content: Text(
        'Kenyan motorcycles must have:\n\n'
        '• Start with KM\n'
        '• Followed by 2 letters (e.g., KMFB, KMDD)\n'
        '• Then 3 digits (e.g., 123, 650)\n'
        '• Optional letter at end (e.g., A, L, Z)\n\n'
        'Examples: KMFB 123A, KMDD 650L\n\n'
        'Please ensure the motorcycle plate is clearly visible.'
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Retry'),
        ),
      ],
    ),
  );
}
```

## 📱 UI Tips for Better OCR Results

**Camera Guidelines**:
1. **Good lighting** - Avoid shadows on the plate
2. **Steady camera** - Hold phone still or use tripod
3. **Clear focus** - Ensure plate is sharp and in focus
4. **Proper distance** - Not too close, not too far
5. **Straight angle** - Face the plate directly
6. **Clean plate** - Remove dirt or obstructions

**Frame Overlay** (already implemented):
```dart
// The BikeRegistrationVerificationScreen has a rear view frame
// that helps users align the plate properly
```

## 🔄 Integration Checklist

- [x] Import `kenyan_plate_parser.dart`
- [x] Replace generic OCR with `parseMotorcyclePlate()`
- [x] Update validation with `isValidMotorcyclePlate()`
- [x] Add user-friendly error messages
- [x] Test with real motorcycle images
- [x] Add debug logging
- [x] Handle null returns gracefully
- [x] Provide retry mechanism

## 📚 Related Files

- `lib/utils/kenyan_plate_parser.dart` - Main parser
- `lib/views/bikes/bike_registration_verification_screen.dart` - Integration
- `test/kenyan_plate_parser_test.dart` - Tests
- `lib/utils/kenyan_plate_parser_demo.dart` - Demo & examples
- `KENYAN_MOTORCYCLE_PLATE_OCR.md` - Full documentation

## 🆘 Troubleshooting

| Problem | Solution |
|---------|----------|
| No plate detected | Improve lighting, ensure plate is visible |
| Wrong plate extracted | Check if it's a car plate (KBZ, KCA, etc.) |
| Fragmented detection | Parser handles this automatically |
| OCR mistakes | Parser corrects common errors automatically |
| Validation fails | Ensure it's a motorcycle (KM prefix), not car |

## 💡 Pro Tips

1. **Test with real images**: Use actual motorcycle photos from Kenya
2. **Check console logs**: Debug messages show the parsing process
3. **Handle null gracefully**: Always check if result is null
4. **Provide feedback**: Tell users why detection failed
5. **Allow retries**: Let users capture again if it fails
6. **Save raw OCR**: Log raw OCR output for debugging production issues

---

**Need Help?** Check the full documentation in `KENYAN_MOTORCYCLE_PLATE_OCR.md`
