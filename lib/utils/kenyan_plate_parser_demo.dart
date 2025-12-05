import 'package:pbak/utils/kenyan_plate_parser.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Demo and testing utilities for Kenyan Plate Parser
/// 
/// This file demonstrates how the parser handles various OCR scenarios
class KenyanPlateParserDemo {
  
  /// Simulate ML Kit OCR output for testing
  /// 
  /// In real usage, you get RecognizedText from ML Kit's processImage()
  /// This helper creates mock RecognizedText for demonstration
  static void demonstrateParser() {
    print('═══════════════════════════════════════════════════════');
    print('Kenyan Motorcycle Plate Parser - Demonstration');
    print('═══════════════════════════════════════════════════════\n');

    // Scenario 1: Fragmented text (the reported issue)
    print('📋 Scenario 1: Fragmented OCR Output');
    print('   OCR detects: "KMET" and "d650 L" (separate blocks)');
    print('   Expected: KMET 650L or KMED 650L\n');
    testScenario(['KMET', 'd650 L']);

    print('\n' + '─' * 55 + '\n');

    // Scenario 2: Clean detection
    print('📋 Scenario 2: Clean OCR Output');
    print('   OCR detects: "KMFB 123A"\n');
    testScenario(['KMFB 123A']);

    print('\n' + '─' * 55 + '\n');

    // Scenario 3: All together, no spaces
    print('📋 Scenario 3: Compact Format');
    print('   OCR detects: "KMDD650L"\n');
    testScenario(['KMDD650L']);

    print('\n' + '─' * 55 + '\n');

    // Scenario 4: Split at different position
    print('📋 Scenario 4: Different Split Pattern');
    print('   OCR detects: "KM" and "EA001"\n');
    testScenario(['KM', 'EA001']);

    print('\n' + '─' * 55 + '\n');

    // Scenario 5: OCR mistakes
    print('📋 Scenario 5: Common OCR Mistakes');
    print('   OCR detects: "KMGDGO0Z" (O instead of 0)\n');
    testScenario(['KMGDGO0Z']);

    print('\n' + '─' * 55 + '\n');

    // Scenario 6: Multiple fragments
    print('📋 Scenario 6: Multiple Fragments');
    print('   OCR detects: "KM", "AB", "320"\n');
    testScenario(['KM', 'AB', '320']);

    print('\n' + '─' * 55 + '\n');

    // Scenario 7: Noisy input
    print('📋 Scenario 7: Noisy Input with Special Characters');
    print('   OCR detects: "KM-FB" and "123.A"\n');
    testScenario(['KM-FB', '123.A']);

    print('\n═══════════════════════════════════════════════════════');
    print('Demo Complete!');
    print('═══════════════════════════════════════════════════════\n');
  }

  /// Test a specific scenario with mock text blocks
  static void testScenario(List<String> textBlocks) {
    print('   Input blocks: $textBlocks');
    
    // Create mock RecognizedText
    final mockRecognizedText = _createMockRecognizedText(textBlocks);
    
    // Parse
    final result = KenyanPlateParser.parseMotorcyclePlate(mockRecognizedText);
    
    if (result != null) {
      // Validate
      final isValid = KenyanPlateParser.isValidMotorcyclePlate(result);
      
      print('   ✅ Result: "$result"');
      print('   Validation: ${isValid ? "✓ VALID" : "✗ INVALID"}');
      
      if (isValid) {
        print('   Format: ${_describePlate(result)}');
      }
    } else {
      print('   ❌ No valid plate detected');
    }
  }

  /// Describe the structure of a detected plate
  static String _describePlate(String plate) {
    String cleaned = plate.replaceAll(' ', '');
    
    if (cleaned.length < 7) return 'Unknown format';
    
    String prefix = cleaned.substring(0, 2); // KM
    String letters = cleaned.substring(2, 4); // 2 letters
    String digits = cleaned.substring(4, 7); // 3 digits
    String suffix = cleaned.length > 7 ? cleaned.substring(7) : 'none';
    
    return 'KM($prefix) + Letters($letters) + Digits($digits) + Suffix($suffix)';
  }

  /// Create mock RecognizedText for testing
  /// 
  /// Note: This creates a simplified mock. Real RecognizedText has more properties.
  static RecognizedText _createMockRecognizedText(List<String> textBlocks) {
    // This would need actual RecognizedText construction
    // For now, we'll note this is a demo placeholder
    
    // In real testing, you'd need to create proper TextBlock, TextLine objects
    // This is just for demonstration purposes
    
    throw UnimplementedError(
      'Mock RecognizedText creation requires ML Kit objects. '
      'Use real images for actual testing. '
      'This demo shows the expected behavior.'
    );
  }

  /// Manual validation test without ML Kit
  static void testValidation() {
    print('═══════════════════════════════════════════════════════');
    print('Validation Tests');
    print('═══════════════════════════════════════════════════════\n');

    final testCases = [
      // Valid cases
      TestCase('KMFB 123A', true, 'Standard format with suffix'),
      TestCase('KMDD 650L', true, 'Standard format with suffix'),
      TestCase('KMEA 001', true, 'Standard format without suffix'),
      TestCase('KMGD 900Z', true, 'Standard format with suffix'),
      TestCase('KMAB320', true, 'Compact format without spaces'),
      TestCase('KMFB123A', true, 'Compact format with suffix'),
      TestCase('kmfb123a', true, 'Lowercase (should be case-insensitive)'),
      
      // Invalid cases
      TestCase('KBZ 456Y', false, 'Car plate (wrong prefix)'),
      TestCase('KMFB 12A', false, 'Only 2 digits (needs 3)'),
      TestCase('KMFB 1234A', false, 'Too many digits (4 instead of 3)'),
      TestCase('KMA 123A', false, 'Only 1 letter after KM (needs 2)'),
      TestCase('KMFB 123AB', false, 'Too many suffix letters'),
      TestCase('', false, 'Empty string'),
      TestCase('123KMFB', false, 'Wrong order'),
    ];

    for (var testCase in testCases) {
      final result = KenyanPlateParser.isValidMotorcyclePlate(testCase.plate);
      final passed = result == testCase.expected;
      
      print('${passed ? "✅" : "❌"} "${testCase.plate}"');
      print('   Expected: ${testCase.expected ? "VALID" : "INVALID"}');
      print('   Got: ${result ? "VALID" : "INVALID"}');
      print('   Note: ${testCase.description}');
      
      if (!passed) {
        print('   ⚠️  TEST FAILED!');
      }
      print('');
    }

    print('═══════════════════════════════════════════════════════');
  }

  /// Example: How to use in your app
  static String usageExample() {
    return '''
// ═══════════════════════════════════════════════════════
// Usage Example in Your Flutter App
// ═══════════════════════════════════════════════════════

import 'package:pbak/utils/kenyan_plate_parser.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class YourScreen extends StatefulWidget {
  @override
  State<YourScreen> createState() => _YourScreenState();
}

class _YourScreenState extends State<YourScreen> {
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin
  );

  Future<void> scanMotorcyclePlate(File imageFile) async {
    try {
      // Step 1: Create InputImage from file
      final inputImage = InputImage.fromFile(imageFile);
      
      // Step 2: Process with ML Kit
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      // Step 3: Parse Kenyan motorcycle plate
      final motorcyclePlate = KenyanPlateParser.parseMotorcyclePlate(
        recognizedText
      );
      
      if (motorcyclePlate != null) {
        // Step 4: Validate format
        final isValid = KenyanPlateParser.isValidMotorcyclePlate(
          motorcyclePlate
        );
        
        if (isValid) {
          print('✅ Detected valid plate: \$motorcyclePlate');
          
          // Use the plate number (e.g., save to database, display to user)
          setState(() {
            registrationNumber = motorcyclePlate;
          });
          
          return motorcyclePlate;
        } else {
          print('❌ Invalid plate format: \$motorcyclePlate');
          // Show error to user
        }
      } else {
        print('❌ No plate detected');
        // Show error to user
      }
    } catch (e) {
      print('❌ Error: \$e');
    }
  }
  
  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }
}

// ═══════════════════════════════════════════════════════
// That's it! The parser handles all the complexity:
// - Fragmented text reconstruction
// - OCR error correction
// - Format validation
// - Candidate scoring
// ═══════════════════════════════════════════════════════
''';
  }
}

/// Test case structure
class TestCase {
  final String plate;
  final bool expected;
  final String description;

  TestCase(this.plate, this.expected, this.description);
}

/// Run validation demo
void main() {
  print('\n');
  KenyanPlateParserDemo.testValidation();
  print('\n');
  print(KenyanPlateParserDemo.usageExample());
}
