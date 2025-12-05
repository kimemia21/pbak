import 'package:flutter_test/flutter_test.dart';
import 'package:pbak/utils/kenyan_plate_parser.dart';

void main() {
  group('KenyanPlateParser - Validation Tests', () {
    test('Valid motorcycle plates should pass validation', () {
      expect(KenyanPlateParser.isValidMotorcyclePlate('KMFB 123A'), true);
      expect(KenyanPlateParser.isValidMotorcyclePlate('KMDD 650L'), true);
      expect(KenyanPlateParser.isValidMotorcyclePlate('KMEA 001'), true);
      expect(KenyanPlateParser.isValidMotorcyclePlate('KMGD 900Z'), true);
      expect(KenyanPlateParser.isValidMotorcyclePlate('KMAB320'), true); // No space
      expect(KenyanPlateParser.isValidMotorcyclePlate('KMFB123A'), true); // No space
      expect(KenyanPlateParser.isValidMotorcyclePlate('KMEA001'), true); // No space, no suffix
    });

    test('Invalid motorcycle plates should fail validation', () {
      expect(KenyanPlateParser.isValidMotorcyclePlate('KBZ 456Y'), false); // Wrong prefix
      expect(KenyanPlateParser.isValidMotorcyclePlate('KM 123A'), false); // Missing letters
      expect(KenyanPlateParser.isValidMotorcyclePlate('KMFB 12A'), false); // Only 2 digits
      expect(KenyanPlateParser.isValidMotorcyclePlate('KMFB 1234A'), false); // Too many digits
      expect(KenyanPlateParser.isValidMotorcyclePlate('KMFB 123AB'), false); // Too many suffix letters
      expect(KenyanPlateParser.isValidMotorcyclePlate('KMA 123A'), false); // Only 1 letter after KM
      expect(KenyanPlateParser.isValidMotorcyclePlate(''), false); // Empty
    });

    test('Case insensitive validation', () {
      expect(KenyanPlateParser.isValidMotorcyclePlate('kmfb 123a'), true);
      expect(KenyanPlateParser.isValidMotorcyclePlate('KmFb 123A'), true);
      expect(KenyanPlateParser.isValidMotorcyclePlate('KMFB 123a'), true);
    });
  });

  group('KenyanPlateParser - OCR Correction Tests', () {
    test('Should handle common OCR misreads', () {
      // These would be tested with actual RecognizedText objects
      // For now, we test the validation accepts corrected outputs
      
      // O -> 0 corrections
      expect(KenyanPlateParser.isValidMotorcyclePlate('KMFB 001'), true);
      
      // Letter corrections should result in valid plates
      expect(KenyanPlateParser.isValidMotorcyclePlate('KMFB 123A'), true);
    });
  });

  group('KenyanPlateParser - Edge Cases', () {
    test('Plates with extra spaces should be handled', () {
      expect(KenyanPlateParser.isValidMotorcyclePlate('KMFB  123A'), true); // Multiple spaces between parts
      expect(KenyanPlateParser.isValidMotorcyclePlate('KMFB123A'), true); // No spaces
    });

    test('Minimum and maximum valid lengths', () {
      expect(KenyanPlateParser.isValidMotorcyclePlate('KMFB123'), true); // 7 chars (min)
      expect(KenyanPlateParser.isValidMotorcyclePlate('KMFB123A'), true); // 8 chars (max)
      expect(KenyanPlateParser.isValidMotorcyclePlate('KMFB12'), false); // Too short
      expect(KenyanPlateParser.isValidMotorcyclePlate('KMFB123AB'), false); // Too long
    });

    test('All letters should be uppercase in validation', () {
      // Parser should handle case insensitivity
      expect(KenyanPlateParser.isValidMotorcyclePlate('kmfb123a'), true);
      expect(KenyanPlateParser.isValidMotorcyclePlate('KmFb123A'), true);
    });
  });

  group('KenyanPlateParser - Format Tests', () {
    test('Various valid motorcycle formats', () {
      // With suffix letter
      expect(KenyanPlateParser.isValidMotorcyclePlate('KMAA 001A'), true);
      expect(KenyanPlateParser.isValidMotorcyclePlate('KMZZ 999Z'), true);
      
      // Without suffix letter
      expect(KenyanPlateParser.isValidMotorcyclePlate('KMAA 001'), true);
      expect(KenyanPlateParser.isValidMotorcyclePlate('KMZZ 999'), true);
      
      // Without spaces
      expect(KenyanPlateParser.isValidMotorcyclePlate('KMAA001A'), true);
      expect(KenyanPlateParser.isValidMotorcyclePlate('KMAA001'), true);
    });

    test('Prefix must be KM followed by exactly 2 letters', () {
      expect(KenyanPlateParser.isValidMotorcyclePlate('KMAB 123'), true); // Valid
      expect(KenyanPlateParser.isValidMotorcyclePlate('KMA 123'), false); // Only 1 letter
      expect(KenyanPlateParser.isValidMotorcyclePlate('KMABC 123'), false); // 3 letters
      expect(KenyanPlateParser.isValidMotorcyclePlate('KB 123'), false); // Wrong prefix
      expect(KenyanPlateParser.isValidMotorcyclePlate('KM 123'), false); // No letters
    });

    test('Must have exactly 3 digits', () {
      expect(KenyanPlateParser.isValidMotorcyclePlate('KMAB 123'), true);
      expect(KenyanPlateParser.isValidMotorcyclePlate('KMAB 12'), false); // Only 2 digits
      expect(KenyanPlateParser.isValidMotorcyclePlate('KMAB 1234'), false); // 4 digits
      expect(KenyanPlateParser.isValidMotorcyclePlate('KMAB 001'), true); // Leading zeros OK
    });

    test('Optional suffix must be exactly 1 letter', () {
      expect(KenyanPlateParser.isValidMotorcyclePlate('KMAB 123A'), true); // 1 letter
      expect(KenyanPlateParser.isValidMotorcyclePlate('KMAB 123'), true); // No letter
      expect(KenyanPlateParser.isValidMotorcyclePlate('KMAB 123AB'), false); // 2 letters
      expect(KenyanPlateParser.isValidMotorcyclePlate('KMAB 1231'), false); // Digit instead
    });
  });

  group('KenyanPlateParser - Real World Examples', () {
    test('Common Kenyan motorcycle plates', () {
      // Real examples from the requirement
      expect(KenyanPlateParser.isValidMotorcyclePlate('KMFB 123A'), true);
      expect(KenyanPlateParser.isValidMotorcyclePlate('KMDD 650L'), true);
      expect(KenyanPlateParser.isValidMotorcyclePlate('KMEA 001'), true);
      expect(KenyanPlateParser.isValidMotorcyclePlate('KMGD 900Z'), true);
      expect(KenyanPlateParser.isValidMotorcyclePlate('KMAB320'), true);
    });

    test('Should reject car plates (different format)', () {
      // Kenyan car plates: KBZ 456Y, KCA 123B, etc.
      expect(KenyanPlateParser.isValidMotorcyclePlate('KBZ 456Y'), false);
      expect(KenyanPlateParser.isValidMotorcyclePlate('KCA 123B'), false);
      expect(KenyanPlateParser.isValidMotorcyclePlate('KAA 001A'), false);
    });
  });
}
