import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Kenyan Number Plate Parser
/// 
/// Specialized parser for Kenyan motorcycle registration plates.
/// Handles ML Kit OCR output fragmentation and normalization.
/// 
/// Kenyan Motorcycle Format: KM[A-Z]{2} [0-9]{3}[A-Z]?
/// Examples: KMFB 123A, KMDD 650L, KMEA 001, KMAB320
class KenyanPlateParser {
  /// Valid Kenyan motorcycle plate regex
  /// Format: KM + 2 letters + optional space + 3 digits + optional letter
  static final RegExp motorcyclePattern = RegExp(
    r'^KM[A-Z]{2}\s*[0-9]{3}[A-Z]?$',
    caseSensitive: false,
  );

  /// Common OCR character misreads mapping
  static const Map<String, String> ocrCorrections = {
    'O': '0', // Letter O -> Digit 0
    'I': '1', // Letter I -> Digit 1
    'L': '1', // Letter L -> Digit 1 (in numeric context)
    'S': '5', // Letter S -> Digit 5
    'B': '8', // Letter B -> Digit 8
    'Z': '2', // Letter Z -> Digit 2 (sometimes)
    'G': '6', // Letter G -> Digit 6 (sometimes)
  };

  /// Reverse corrections for letter context
  static const Map<String, String> digitToLetter = {
    '0': 'O',
    '1': 'I',
    '5': 'S',
    '8': 'B',
  };

  /// Parse ML Kit recognized text and extract Kenyan motorcycle plate
  /// 
  /// Returns the best matching plate or null if no valid plate found
  static String? parseMotorcyclePlate(RecognizedText recognizedText) {
    print('🔍 [KenyanPlateParser] Starting motorcycle plate detection...');
    
    // Extract all text blocks
    List<String> allTextBlocks = [];
    for (var block in recognizedText.blocks) {
      for (var line in block.lines) {
        allTextBlocks.add(line.text);
        print('  📝 Detected: "${line.text}"');
      }
    }

    if (allTextBlocks.isEmpty) {
      print('❌ [KenyanPlateParser] No text detected');
      return null;
    }

    // Generate all possible plate candidates
    List<_PlateCandidate> candidates = [];

    // Strategy 1: Try individual lines first
    for (var text in allTextBlocks) {
      candidates.addAll(_extractCandidatesFromText(text));
    }

    // Strategy 2: Try merging adjacent text blocks
    for (int i = 0; i < allTextBlocks.length - 1; i++) {
      String merged = allTextBlocks[i] + allTextBlocks[i + 1];
      candidates.addAll(_extractCandidatesFromText(merged));
    }

    // Strategy 3: Try merging with spaces
    for (int i = 0; i < allTextBlocks.length - 1; i++) {
      String merged = '${allTextBlocks[i]} ${allTextBlocks[i + 1]}';
      candidates.addAll(_extractCandidatesFromText(merged));
    }

    // Strategy 4: Try merging all text
    String allMerged = allTextBlocks.join('');
    candidates.addAll(_extractCandidatesFromText(allMerged));

    String allMergedWithSpace = allTextBlocks.join(' ');
    candidates.addAll(_extractCandidatesFromText(allMergedWithSpace));

    if (candidates.isEmpty) {
      print('❌ [KenyanPlateParser] No valid candidates found');
      return null;
    }

    // Sort by confidence score (best first)
    candidates.sort((a, b) => b.confidence.compareTo(a.confidence));

    print('✅ [KenyanPlateParser] Found ${candidates.length} candidates');
    for (var candidate in candidates.take(3)) {
      print('  🎯 ${candidate.plate} (score: ${candidate.confidence.toStringAsFixed(2)})');
    }

    // Return the best candidate
    return candidates.first.plate;
  }

  /// Extract possible plate candidates from a text string
  static List<_PlateCandidate> _extractCandidatesFromText(String text) {
    List<_PlateCandidate> candidates = [];

    // Step 1: Clean and normalize text
    String normalized = _normalizeText(text);
    
    // Step 2: Try to extract plates with various strategies
    
    // Strategy A: Direct pattern match
    candidates.addAll(_tryDirectMatch(normalized));
    
    // Strategy B: Smart reconstruction for fragmented text
    candidates.addAll(_trySmartReconstruction(normalized));
    
    // Strategy C: Fix common OCR errors and retry
    candidates.addAll(_tryWithOCRCorrections(normalized));

    return candidates;
  }

  /// Normalize text: uppercase, remove special chars
  static String _normalizeText(String text) {
    return text
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9\s]'), '') // Remove special chars
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize spaces
        .trim();
  }

  /// Try direct pattern matching
  static List<_PlateCandidate> _tryDirectMatch(String text) {
    List<_PlateCandidate> candidates = [];

    // Try with spaces
    if (motorcyclePattern.hasMatch(text)) {
      double score = _calculateConfidence(text, isDirectMatch: true);
      candidates.add(_PlateCandidate(
        plate: _formatPlate(text),
        confidence: score,
      ));
    }

    // Try without spaces
    String noSpaces = text.replaceAll(' ', '');
    if (motorcyclePattern.hasMatch(noSpaces)) {
      double score = _calculateConfidence(noSpaces, isDirectMatch: true);
      candidates.add(_PlateCandidate(
        plate: _formatPlate(noSpaces),
        confidence: score,
      ));
    }

    return candidates;
  }

  /// Smart reconstruction for fragmented OCR output
  /// Example: "KMET" + "d650 L" -> "KMED 650L"
  static List<_PlateCandidate> _trySmartReconstruction(String text) {
    List<_PlateCandidate> candidates = [];
    String cleaned = text.replaceAll(' ', '');

    // Check if starts with KM
    if (!cleaned.startsWith('KM')) {
      return candidates;
    }

    // Try to extract: KM + 2 letters + 3 digits + optional letter
    if (cleaned.length >= 7 && cleaned.length <= 8) {
      // Pattern: KMAA###X or KMAA###
      String prefix = cleaned.substring(0, 4); // KM + 2 letters
      String rest = cleaned.substring(4);

      // Validate prefix (should be KM + 2 letters)
      if (_isValidPrefix(prefix)) {
        // Try to parse rest as digits + optional letter
        String reconstructed = _reconstructSuffix(prefix, rest);
        if (reconstructed.isNotEmpty && motorcyclePattern.hasMatch(reconstructed)) {
          double score = _calculateConfidence(reconstructed, isReconstructed: true);
          candidates.add(_PlateCandidate(
            plate: _formatPlate(reconstructed),
            confidence: score,
          ));
        }
      }
    }

    // Handle split patterns like "KM" + "FB123A" or "KMFB" + "123A"
    if (cleaned.length >= 7) {
      for (int split = 2; split <= 6; split++) {
        if (split >= cleaned.length) break;
        
        String part1 = cleaned.substring(0, split);
        String part2 = cleaned.substring(split);
        String merged = part1 + part2;

        if (motorcyclePattern.hasMatch(merged)) {
          double score = _calculateConfidence(merged, isReconstructed: true);
          candidates.add(_PlateCandidate(
            plate: _formatPlate(merged),
            confidence: score * 0.95, // Slightly lower confidence
          ));
        }
      }
    }

    return candidates;
  }

  /// Try with OCR corrections applied
  static List<_PlateCandidate> _tryWithOCRCorrections(String text) {
    List<_PlateCandidate> candidates = [];
    
    // Apply corrections to different parts of the plate
    String corrected = _applyCorrectionsByPosition(text);
    
    if (corrected != text) {
      candidates.addAll(_tryDirectMatch(corrected));
      candidates.addAll(_trySmartReconstruction(corrected));
      
      // Reduce confidence for corrected versions
      for (var candidate in candidates) {
        candidate.confidence *= 0.9;
      }
    }

    return candidates;
  }

  /// Apply OCR corrections based on position in plate
  /// Format: KM[LETTERS][DIGITS][OPTIONAL_LETTER]
  static String _applyCorrectionsByPosition(String text) {
    String cleaned = text.replaceAll(' ', '');
    
    if (cleaned.length < 7) return text;

    StringBuffer result = StringBuffer();

    for (int i = 0; i < cleaned.length; i++) {
      String char = cleaned[i];
      
      if (i < 4) {
        // Position 0-3: Should be letters (KM + 2 letters)
        if (RegExp(r'[0-9]').hasMatch(char)) {
          // Convert digit to letter
          result.write(digitToLetter[char] ?? char);
        } else {
          result.write(char);
        }
      } else if (i >= 4 && i < 7) {
        // Position 4-6: Should be digits
        if (RegExp(r'[A-Z]').hasMatch(char)) {
          // Convert letter to digit
          result.write(ocrCorrections[char] ?? char);
        } else {
          result.write(char);
        }
      } else {
        // Position 7+: Optional letter (keep as is)
        result.write(char);
      }
    }

    return result.toString();
  }

  /// Validate prefix (should be KM + 2 letters)
  static bool _isValidPrefix(String prefix) {
    if (prefix.length != 4) return false;
    if (!prefix.startsWith('KM')) return false;
    
    String letters = prefix.substring(2);
    return RegExp(r'^[A-Z]{2}$').hasMatch(letters);
  }

  /// Reconstruct suffix (3 digits + optional letter)
  static String _reconstructSuffix(String prefix, String suffix) {
    // Clean suffix
    String cleaned = suffix.replaceAll(' ', '');
    
    if (cleaned.length < 3) return '';

    StringBuffer result = StringBuffer(prefix);

    // Extract digits (should be first 3 characters)
    for (int i = 0; i < cleaned.length && i < 3; i++) {
      String char = cleaned[i];
      if (RegExp(r'[0-9]').hasMatch(char)) {
        result.write(char);
      } else if (RegExp(r'[A-Z]').hasMatch(char)) {
        // Convert letter to digit
        result.write(ocrCorrections[char] ?? char);
      }
    }

    // Check if we have enough digits
    String current = result.toString();
    if (current.length < 7) return ''; // KM + 2 letters + 3 digits minimum

    // Optional letter at the end
    if (cleaned.length > 3) {
      String lastChar = cleaned.substring(3, 4);
      if (RegExp(r'[A-Z]').hasMatch(lastChar)) {
        result.write(lastChar);
      }
    }

    return result.toString();
  }

  /// Format plate with proper spacing: KMAA###X -> KMAA ###X
  static String _formatPlate(String plate) {
    String cleaned = plate.replaceAll(' ', '');
    
    if (cleaned.length < 7) return plate;

    // Format: KM + 2 letters + space + 3 digits + optional letter
    String prefix = cleaned.substring(0, 4); // KMAA
    String digits = cleaned.substring(4, 7); // ###
    String suffix = cleaned.length > 7 ? cleaned.substring(7) : ''; // X (optional)

    return '$prefix $digits$suffix';
  }

  /// Calculate confidence score for a candidate
  static double _calculateConfidence(
    String plate, {
    bool isDirectMatch = false,
    bool isReconstructed = false,
  }) {
    double score = 0.5;

    // Bonus for direct regex match
    if (isDirectMatch) {
      score += 0.3;
    }

    // Penalty for reconstruction
    if (isReconstructed) {
      score -= 0.1;
    }

    // Bonus for correct length (7-8 chars without spaces)
    String cleaned = plate.replaceAll(' ', '');
    if (cleaned.length == 7 || cleaned.length == 8) {
      score += 0.2;
    }

    // Bonus for having correct structure
    if (motorcyclePattern.hasMatch(cleaned)) {
      score += 0.3;
    }

    // Bonus for starting with KM
    if (cleaned.startsWith('KM')) {
      score += 0.1;
    }

    // Ensure score is between 0 and 1
    return score.clamp(0.0, 1.0);
  }

  /// Validate if a plate matches Kenyan motorcycle format
  static bool isValidMotorcyclePlate(String plate) {
    String cleaned = plate.replaceAll(' ', '');
    return motorcyclePattern.hasMatch(cleaned);
  }
}

/// Internal class for plate candidates
class _PlateCandidate {
  final String plate;
  double confidence;

  _PlateCandidate({
    required this.plate,
    required this.confidence,
  });

  @override
  String toString() => '$plate (${confidence.toStringAsFixed(2)})';
}
