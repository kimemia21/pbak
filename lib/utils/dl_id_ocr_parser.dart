/// Helpers for extracting Kenyan National ID and Driving License numbers
/// from OCR text.
///
/// This is heuristic-based: formats may vary and OCR can be noisy.
class DlIdOcrParser {
  /// Extracts a value for a given DL class code (e.g. A1, A2) from OCR text.
  ///
  /// Kenyan DL backs often list classes in a table, where the class code can be on
  /// the same line as its value/date, or on the line above it.
  ///
  /// Returns the extracted value (e.g. an issue/expiry date, "VALID", etc) or
  /// null if not found.
  static String? extractDlClassValue(String rawText, {required String classCode}) {
    final code = classCode.trim().toUpperCase();
    if (code.isEmpty) return null;

    final lines = rawText
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    // A filled row is typically a date, or an obvious status token.
    // We intentionally do NOT treat a single letter (e.g. "B") as a filled value.
    final valuePattern = RegExp(
      r'\b([0-9]{1,2}[./\-][0-9]{1,2}[./\-][0-9]{2,4}|[A-Z]{2,}|[A-Z]*[0-9]+[A-Z0-9]*)\b',
      caseSensitive: false,
    );

    bool isJustCode(String s) {
      final normalized = s.replaceAll(RegExp(r'[^A-Z0-9]'), '').toUpperCase();
      return normalized == code;
    }

    bool looksLikeAnotherClassRow(String line) {
      final parts = line.trim().split(RegExp(r'\s+'));
      if (parts.isEmpty) return false;
      final first = parts.first.replaceAll(RegExp(r'[^A-Z0-9]'), '').toUpperCase();
      if (first.isEmpty) return false;

      // Kenyan DL class codes are short tokens like A1, A2, A3, B, C, C1, CE, etc.
      // If we encounter another class token, stop searching for this class' value.
      final isClassToken = RegExp(r'^[A-Z]{1,2}[0-9]{0,2}$').hasMatch(first) && first.length <= 3;
      if (!isClassToken) return false;
      return first != code;
    }

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].toUpperCase();

      // Match whole-word A1/A2 (avoid matching within tokens).
      if (!RegExp(r'(?:^|\b)' + code + r'(?:\b|$)').hasMatch(line)) continue;

      // 1) Same line: "A1 12.01.2024" or "A1: VALID".
      final afterCode = line.replaceFirst(RegExp(r'(?:^|\b)' + code + r'(?:\b|$)'), ' ');
      final mSame = valuePattern.firstMatch(afterCode);
      if (mSame != null) {
        final v = mSame.group(1)?.trim();
        if (v != null && v.isNotEmpty && !isJustCode(v)) return v;
      }

      // 2) Next line: "A1" then value on the next non-empty line.
      for (var j = i + 1; j < lines.length; j++) {
        final nextRaw = lines[j];
        final next = nextRaw.toUpperCase();

        if (looksLikeAnotherClassRow(nextRaw)) break;

        final m = valuePattern.firstMatch(next);
        if (m != null) {
          final v = m.group(1)?.trim();
          if (v != null && v.isNotEmpty && !isJustCode(v)) return v;
        }
      }
    }

    return null;
  }

  /// True if OCR text indicates the DL includes a motorcycle class (A1 or A2)
  /// and that class row appears to have a value/date filled.
  static bool hasMotorcycleClassA1OrA2(String rawText) {
    final a1 = extractDlClassValue(rawText, classCode: 'A1');
    final a2 = extractDlClassValue(rawText, classCode: 'A2');
    return (a1 != null && a1.isNotEmpty) || (a2 != null && a2.isNotEmpty);
  }

  /// Anchor-based extraction.
  ///
  /// We look for an anchor line containing [anchor] (case-insensitive, tolerant of
  /// extra spaces), then take the number/token from the *next non-empty line*.
  static String? extractBelowAnchor(
    String rawText, {
    required RegExp anchor,
    required RegExp valuePattern,
    bool allowSameLine = true,
  }) {
    final lines = rawText
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].toUpperCase();
      if (!anchor.hasMatch(line)) continue;

      if (allowSameLine) {
        // Common case: anchor and value on the SAME line, e.g.
        // "NATIONAL ID NO: 12345678".
        // NOTE: For some Kenyan DL layouts, the value is *under* the label, so
        // callers can set [allowSameLine] to false.
        final sameLineMatch = valuePattern.firstMatch(line);
        if (sameLineMatch != null) {
          return sameLineMatch.group(1);
        }
      }

      // Otherwise, take the value from the next non-empty line.
      for (var j = i + 1; j < lines.length; j++) {
        final next = lines[j].toUpperCase();
        final m = valuePattern.firstMatch(next);
        if (m != null) {
          return m.group(1);
        }

        // If the next line is another label-like line, stop searching for this anchor.
        if (RegExp(
          r'\b(NO\.?|NUMBER|NAME|DATE|BLOOD|SEX|GENDER|ADDRESS)\b',
        ).hasMatch(next)) {
          break;
        }
      }
    }

    return null;
  }

  /// Kenyan National ID extraction using the DL anchor "NATIONAL ID NO".
  static String? extractNationalIdFromDlAnchors(String rawText) {
    // Accept variants: NATIONAL ID NO, NATIONALIDNO, NATIONAL ID NO.
    final anchor = RegExp(r'NATIONAL\s*ID\s*NO', caseSensitive: false);
    final valuePattern = RegExp(r'\b([0-9]{6,10})\b');
    return extractBelowAnchor(
      rawText,
      anchor: anchor,
      valuePattern: valuePattern,
      allowSameLine: false,
    );
  }

  /// Kenyan Driving Licence number extraction using the anchor "LICENCE NO".
  static String? extractDrivingLicenceFromDlAnchors(String rawText) {
    // Accept variants: LICENCE NO, LICENSE NO.
    final anchor = RegExp(r'LICEN[CS]E\s*NO', caseSensitive: false);
    final valuePattern = RegExp(r'\b([A-Z0-9\-]{5,20})\b');
    final result = extractBelowAnchor(
      rawText,
      anchor: anchor,
      valuePattern: valuePattern,
      allowSameLine: false,
    );
    final cleaned = _cleanDlToken(result);
    // Avoid returning the label itself or other words (must contain a digit).
    if (cleaned != null && RegExp(r'[0-9]').hasMatch(cleaned)) {
      return cleaned;
    }
    return null;
  }

  /// Returns a likely Kenyan National ID number.
  ///
  /// Kenyan IDs are commonly 7–9 digits (often 8). We accept 6–10 digits to be
  /// tolerant of OCR artifacts.
  static String? extractNationalId(String rawText) {
    return extractNationalIdWithConfidence(rawText).value;
  }

  static ({String? value, int confidence}) extractNationalIdWithConfidence(
    String rawText,
  ) {
    final text = _normalize(rawText);

    // Prefer explicit labels (highest confidence).
    final labeled = RegExp(
      r'(NATIONAL\s*ID|ID\s*NO\.?|ID\s*NUMBER|ID\s*NO)\s*[:#-]?\s*([0-9]{6,10})',
      caseSensitive: false,
    ).firstMatch(text);
    if (labeled != null) {
      return (value: labeled.group(2), confidence: 100);
    }

    // Common near-labels on documents.
    final nearLabel = RegExp(
      r'(IDENTITY\s*CARD|SERIAL\s*NO\.?|PERSONAL\s*NO\.?)\s*[:#-]?\s*([0-9]{6,10})',
      caseSensitive: false,
    ).firstMatch(text);
    if (nearLabel != null) {
      return (value: nearLabel.group(2), confidence: 80);
    }

    // Fallback: digit blocks.
    final candidates = RegExp(
      r'\b([0-9]{6,10})\b',
    ).allMatches(text).map((m) => m.group(1)!).toList();
    if (candidates.isEmpty) return (value: null, confidence: 0);

    // Prefer 8 digits (common), then 7/9.
    int score(String s) {
      if (s.length == 8) return 0;
      if (s.length == 7) return 1;
      if (s.length == 9) return 2;
      return 3;
    }

    candidates.sort((a, b) => score(a).compareTo(score(b)));
    final chosen = candidates.first;
    final conf = chosen.length == 8 ? 60 : 45;
    return (value: chosen, confidence: conf);
  }

  /// Returns a likely Driving License number.
  static String? extractDrivingLicenseNumber(String rawText) {
    return extractDrivingLicenseNumberWithConfidence(rawText).value;
  }

  static ({String? value, int confidence})
  extractDrivingLicenseNumberWithConfidence(String rawText) {
    final text = _normalize(rawText);

    // Labeled patterns.
    final labeled = RegExp(
      r'(DRIVING\s*LICEN[CS]E|DL\s*NO\.?|LICEN[CS]E\s*NO\.?)\s*[:#-]?\s*([A-Z0-9\-]{5,20})',
      caseSensitive: false,
    ).firstMatch(text);
    if (labeled != null) {
      return (value: _cleanDlToken(labeled.group(2)), confidence: 100);
    }

    // DL token forms: "DL123456" or "DL-123456".
    final dlToken = RegExp(
      r'\bDL\s*[-:]?\s*([A-Z0-9\-]{5,20})\b',
      caseSensitive: false,
    ).firstMatch(text);
    if (dlToken != null) {
      return (value: _cleanDlToken(dlToken.group(1)), confidence: 85);
    }

    // Some cards show "LICENCE" alone; pick following token.
    final loose = RegExp(
      r'\bLICEN[CS]E\b\s*[:#-]?\s*([A-Z0-9\-]{5,20})\b',
    ).firstMatch(text);
    if (loose != null) {
      return (value: _cleanDlToken(loose.group(1)), confidence: 70);
    }

    // Fallback: alphanumeric candidates length 6–18.
    final candidates = RegExp(r'\b([A-Z0-9\-]{6,18})\b')
        .allMatches(text)
        .map((m) => _cleanDlToken(m.group(1)))
        .whereType<String>()
        .toList();

    if (candidates.isEmpty) return (value: null, confidence: 0);

    bool looksLikeDl(String s) {
      final hasDigit = RegExp(r'[0-9]').hasMatch(s);
      final hasLetter = RegExp(r'[A-Z]').hasMatch(s);
      return hasDigit && hasLetter;
    }

    candidates.sort((a, b) {
      final aScore = looksLikeDl(a) ? 0 : 1;
      final bScore = looksLikeDl(b) ? 0 : 1;
      if (aScore != bScore) return aScore.compareTo(bScore);
      return b.length.compareTo(a.length);
    });

    return (value: candidates.first, confidence: 40);
  }

  static String? _cleanDlToken(String? token) {
    if (token == null) return null;
    final t = token
        .toUpperCase()
        // Remove obvious OCR punctuation around the token.
        .replaceAll(RegExp(r'[^A-Z0-9\-]'), '')
        // Collapse multiple dashes.
        .replaceAll(RegExp(r'-+'), '-')
        .trim();

    if (t.isEmpty) return null;
    return t;
  }

  static String _normalize(String raw) {
    // Uppercase and collapse whitespace; keep digits/letters/some separators.
    // Also fix common OCR confusions in labels (O/0, I/1) by leaving digits as-is
    // but simplifying noisy punctuation.
    return raw
        .toUpperCase()
        .replaceAll(RegExp(r'[\u2018\u2019\u201C\u201D]'), ' ')
        .replaceAll(RegExp(r'[^A-Z0-9\s:/#\-\.]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
