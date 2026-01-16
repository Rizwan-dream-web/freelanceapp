/// Reusable form field validators
///
/// This class provides common validation functions for form fields
/// to ensure data integrity and provide user-friendly error messages.
class Validators {
  /// Validates email format
  /// Returns null if valid, error message if invalid
  /// Empty values are considered valid (use required validator separately)
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    // RFC 5322 compliant email regex (simplified version)
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  /// Validates phone number format
  /// Returns null if valid, error message if invalid
  /// Accepts formats: +1234567890, (123) 456-7890, 123-456-7890, etc.
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    // Remove all non-digit characters except '+'
    final digitsOnly = value.replaceAll(RegExp(r'[^\d+]'), '');

    // Check minimum length (10 digits)
    final digitCount = digitsOnly.replaceAll('+', '').length;
    if (digitCount < 10) {
      return 'Phone number must be at least 10 digits';
    }

    // Check maximum length (15 digits for international)
    if (digitCount > 15) {
      return 'Phone number is too long';
    }

    return null;
  }

  /// Validates required fields
  /// Returns error message if field is empty
  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? "This field"} is required';
    }
    return null;
  }

  /// Validates minimum length
  /// Returns error message if value is shorter than min
  static String? minLength(String? value, int min, {String? fieldName}) {
    if (value == null || value.isEmpty) return null;

    if (value.length < min) {
      return '${fieldName ?? "This field"} must be at least $min characters';
    }
    return null;
  }

  /// Validates maximum length
  /// Returns error message if value is longer than max
  static String? maxLength(String? value, int max, {String? fieldName}) {
    if (value == null || value.isEmpty) return null;

    if (value.length > max) {
      return '${fieldName ?? "This field"} must be at most $max characters';
    }
    return null;
  }

  /// Validates positive numbers
  /// Returns error message if value is not a positive number
  static String? positiveNumber(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    final number = double.tryParse(value.trim());
    if (number == null) {
      return 'Must be a valid number';
    }

    if (number <= 0) {
      return 'Must be a positive number';
    }

    return null;
  }

  /// Validates non-negative numbers (0 or greater)
  /// Returns error message if value is negative
  static String? nonNegativeNumber(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    final number = double.tryParse(value.trim());
    if (number == null) {
      return 'Must be a valid number';
    }

    if (number < 0) {
      return 'Must be 0 or greater';
    }

    return null;
  }

  /// Validates integer values
  /// Returns error message if value is not an integer
  static String? integer(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    final number = int.tryParse(value.trim());
    if (number == null) {
      return 'Must be a whole number';
    }

    return null;
  }

  /// Validates URL format
  /// Returns error message if value is not a valid URL
  static String? url(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );

    if (!urlRegex.hasMatch(value.trim())) {
      return 'Please enter a valid URL';
    }

    return null;
  }

  /// Validates password strength
  /// Requires at least 8 characters, 1 uppercase, 1 lowercase, 1 number
  static String? password(String? value) {
    if (value == null || value.isEmpty) return null;

    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }

    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }

    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }

    return null;
  }

  /// Validates password confirmation matches original password
  static String? passwordMatch(String? value, String? originalPassword) {
    if (value == null || value.isEmpty) return null;

    if (value != originalPassword) {
      return 'Passwords do not match';
    }

    return null;
  }

  /// Validates required fields (alias for required method)
  /// Returns error message if field is empty
  static String? validateRequired(String? value, String fieldName) {
    return required(value, fieldName: fieldName);
  }

  /// Validates budget values (positive numbers only)
  /// Returns error message if value is not a valid positive number
  static String? validateBudget(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    final number = double.tryParse(value.trim());
    if (number == null) {
      return 'Please enter a valid budget amount';
    }

    if (number < 0) {
      return 'Budget cannot be negative';
    }

    return null;
  }
}
