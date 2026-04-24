/// Form validation utilities for common input patterns
class AppValidators {
  AppValidators._();

  /// Validates email format
  static String? email(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(value!)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Validates phone number (10 digits)
  static String? phone(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Phone number is required';
    }
    final phoneRegex = RegExp(r'^[0-9]{10}$');
    if (!phoneRegex.hasMatch(value!.replaceAll(RegExp(r'\D'), ''))) {
      return 'Please enter a valid 10-digit phone number';
    }
    return null;
  }

  /// Validates non-empty field
  static String? required(String? value) {
    if (value?.isEmpty ?? true) {
      return 'This field is required';
    }
    return null;
  }

  /// Validates minimum length
  static String? minLength(String? value, int min) {
    if (value?.isEmpty ?? true) {
      return 'This field is required';
    }
    if (value!.length < min) {
      return 'Minimum $min characters required';
    }
    return null;
  }

  /// Validates password (min 8 chars, at least 1 number)
  static String? password(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Password is required';
    }
    if (value!.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    return null;
  }

  /// Validates password confirmation
  static String? confirmPassword(String? value, String password) {
    if (value?.isEmpty ?? true) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Validates URL format
  static String? url(String? value) {
    if (value?.isEmpty ?? true) {
      return 'URL is required';
    }
    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&/=]*)$',
    );
    if (!urlRegex.hasMatch(value!)) {
      return 'Please enter a valid URL';
    }
    return null;
  }
}
