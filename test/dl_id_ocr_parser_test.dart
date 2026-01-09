import 'package:flutter_test/flutter_test.dart';
import 'package:pbak/utils/dl_id_ocr_parser.dart';

void main() {
  group('DlIdOcrParser - Anchor based extraction', () {
    test('Extracts National ID from line below NATIONAL ID NO', () {
      const text = '''
KENYA
DRIVING LICENCE
NATIONAL ID NO
12345678
''';
      expect(DlIdOcrParser.extractNationalIdFromDlAnchors(text), '12345678');
    });

    test('Extracts Licence No from line below LICENCE NO', () {
      const text = '''
REPUBLIC OF KENYA
LICENCE NO
DL-12345-678
NAME
JOHN DOE
''';
      expect(
        DlIdOcrParser.extractDrivingLicenceFromDlAnchors(text),
        'DL-12345-678',
      );
    });

    test('Does not accidentally return label text for licence', () {
      const text = '''
LICENCE NO
LICENCE
NAME
JANE
''';
      expect(DlIdOcrParser.extractDrivingLicenceFromDlAnchors(text), isNull);
    });

    test('Prefers line below even if same line contains other numbers', () {
      const text = '''
NATIONAL ID NO 99999999
12345678
''';
      // We force below-anchor for this method.
      expect(DlIdOcrParser.extractNationalIdFromDlAnchors(text), '12345678');
    });
  });

  group('DlIdOcrParser - DL back motorcycle class detection', () {
    test('Detects A1 value on the same line', () {
      const text = '''
CLASSES
A1 12.01.2024
A2
''';
      expect(DlIdOcrParser.hasMotorcycleClassA1OrA2(text), true);
      expect(DlIdOcrParser.extractDlClassValue(text, classCode: 'A1'), isNotNull);
    });

    test('Detects A2 value on the next line', () {
      const text = '''
CLASSES
A2
15/02/2023
B
01/01/2020
''';
      expect(DlIdOcrParser.hasMotorcycleClassA1OrA2(text), true);
      expect(DlIdOcrParser.extractDlClassValue(text, classCode: 'A2'), '15/02/2023');
    });

    test('Returns false when A1/A2 are present but not filled', () {
      const text = '''
CLASSES
A1
A2
B 01/01/2020
''';
      expect(DlIdOcrParser.hasMotorcycleClassA1OrA2(text), false);
    });
  });
}
