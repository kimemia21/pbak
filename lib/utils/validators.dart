class Validators {
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final phoneRegex = RegExp(r'^\+?[0-9]{10,13}$');
    if (!phoneRegex.hasMatch(value.replaceAll(' ', ''))) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  /// Validates M-Pesa phone numbers (Kenyan format)
  /// Accepts: 07XXXXXXXX, 01XXXXXXXX, 254XXXXXXXXX, +254XXXXXXXXX
  static String? validateMpesaPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    
    String cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    // Kenyan M-Pesa formats
    // 07XXXXXXXX or 01XXXXXXXX (10 digits starting with 0)
    // 2547XXXXXXXX or 2541XXXXXXXX (12 digits starting with 254)
    // +2547XXXXXXXX or +2541XXXXXXXX (13 chars with +)
    
    final kenyanMobileRegex = RegExp(r'^(?:(?:\+?254)|0)?([17]\d{8})$');
    
    if (!kenyanMobileRegex.hasMatch(cleaned)) {
      return 'Enter a valid Kenyan phone number (e.g., 0712345678)';
    }
    
    return null;
  }

  /// Validates international phone numbers with country code
  /// Uses E.164 format validation
  static String? validateInternationalPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    
    String cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    // Must start with + and country code, followed by 7-14 digits
    // E.164 format: +[country code][subscriber number]
    final internationalRegex = RegExp(r'^\+[1-9]\d{7,14}$');
    
    // Also allow without + for convenience
    final withoutPlusRegex = RegExp(r'^[1-9]\d{9,14}$');
    
    if (!internationalRegex.hasMatch(cleaned) && !withoutPlusRegex.hasMatch(cleaned)) {
      return 'Enter a valid phone number with country code';
    }
    
    return null;
  }

  /// Validates phone numbers - supports both Kenyan and international formats
  static String? validateMobilePhone(String? value, {bool allowInternational = true}) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    
    String cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    // Check Kenyan format first
    final kenyanResult = validateMpesaPhone(cleaned);
    if (kenyanResult == null) {
      return null; // Valid Kenyan number
    }
    
    // If international allowed, check that format
    if (allowInternational) {
      final intlResult = validateInternationalPhone(cleaned);
      if (intlResult == null) {
        return null; // Valid international number
      }
    }
    
    return allowInternational 
        ? 'Enter a valid phone number (e.g., 0712345678 or +1234567890)'
        : 'Enter a valid Kenyan phone number (e.g., 0712345678)';
  }

  static String? validateIdNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'ID Number is required';
    }
    if (value.length < 6 || value.length > 10) {
      return 'Enter a valid ID number';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    // Check for uppercase letter
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    // Check for lowercase letter
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    // Check for number
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Confirm password is required';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  static String? validateRegistrationNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Registration number is required';
    }
    // Kenyan format: KXX 123X or similar
    if (value.length < 5) {
      return 'Enter a valid registration number';
    }
    return null;
  }

  static String? validateEngineNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Engine number is required';
    }
    if (value.length < 5) {
      return 'Enter a valid engine number';
    }
    return null;
  }

  static String? validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Amount is required';
    }
    final amount = double.tryParse(value);
    if (amount == null || amount <= 0) {
      return 'Enter a valid amount';
    }
    return null;
  }

  static String? validateYear(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Year is required';
    }
    final year = int.tryParse(value);
    final currentYear = DateTime.now().year;
    if (year == null || year < 1900 || year > currentYear + 1) {
      return 'Enter a valid year';
    }
    return null;
  }

  static String? validateDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Date is required';
    }
    return null;
  }

  static String? validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // URL is optional
    }
    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );
    if (!urlRegex.hasMatch(value)) {
      return 'Enter a valid URL';
    }
    return null;
  }
}
