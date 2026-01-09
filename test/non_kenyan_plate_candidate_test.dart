import 'package:flutter_test/flutter_test.dart';
import 'package:pbak/utils/kenyan_plate_parser.dart';

void main() {
  group('KenyanPlateParser - non-Kenyan candidate detection', () {
    test('Extracts a sensible non-Kenyan candidate from fragmented OCR text', () {
      const raw = 'DG73\nYEE';
      final candidate = KenyanPlateParser.parseNonKenyanPlateCandidateFromRawText(raw);
      expect(candidate, isNotNull);
      expect(candidate!.replaceAll(' ', ''), 'DG73YEE');
    });

    test('Does not return Kenyan motorcycle plates as non-Kenyan candidates', () {
      const raw = 'KMFB 123A';
      final candidate = KenyanPlateParser.parseNonKenyanPlateCandidateFromRawText(raw);
      expect(candidate, isNull);
    });
  });
}
