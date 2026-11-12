/// CeylonGo Client-Side Validation Rules
/// Strictly conforms to Section 3 of the Common Specification v1.0
class FormValidators {
  /// Validates full_name: Required; trim; 2–100 characters
  static String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }
    final trimmed = value.trim();
    if (trimmed.length < 2 || trimmed.length > 100) {
      return 'Full name must be between 2 and 100 characters';
    }
    return null;
  }

  /// Validates email: Required; trim; valid email syntax; maximum 254 characters
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final trimmed = value.trim();
    if (trimmed.length > 254) {
      return 'Email must not exceed 254 characters';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(trimmed)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Validates password: Required; 8–128 characters; at least one uppercase letter,
  /// one lowercase letter, one digit; NO whitespace trimming of passwords
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8 || value.length > 128) {
      return 'Password must be between 8 and 128 characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one digit';
    }
    return null;
  }

  /// Validates confirm_password: Required on client; must exactly match password;
  /// never sent to backend
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Validates login password field: Required
  static String? validateLoginPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    return null;
  }
}

