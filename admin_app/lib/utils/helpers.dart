import 'package:intl/intl.dart';

/// Form field validators — pass directly to TextFormField.validator.
class Validators {
  static String? required(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$field is required';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final re = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$');
    if (!re.hasMatch(value.trim())) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != original) return 'Passwords do not match';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Phone number is required';
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return 'Enter a valid phone number';
    return null;
  }

  static String? age(String? value) {
    if (value == null || value.trim().isEmpty) return 'Age is required';
    final age = int.tryParse(value.trim());
    if (age == null) return 'Enter a valid number';
    if (age < 18) return 'Donor must be at least 18 years old';
    if (age > 65) return 'Donor must be 65 years or younger';
    return null;
  }

  static String? weight(String? value) {
    if (value == null || value.trim().isEmpty) return 'Weight is required';
    final w = double.tryParse(value.trim());
    if (w == null) return 'Enter a valid weight';
    if (w < 50) return 'Minimum weight is 50 kg to donate';
    if (w > 300) return 'Please enter a realistic weight';
    return null;
  }

  static String? minLength(String? value, int min, {String field = 'Field'}) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    if (value.trim().length < min) return '$field must be at least $min characters';
    return null;
  }
}

/// Date / time helpers.
class DateHelpers {
  static final _dateFormat = DateFormat('MMMM d, yyyy');
  static final _shortFormat = DateFormat('MMM d, y');
  static final _timeFormat = DateFormat('h:mm a');
  static final _fullFormat = DateFormat('MMM d, y • h:mm a');

  static String formatFull(DateTime dt) => _fullFormat.format(dt);
  static String formatDate(DateTime dt) => _dateFormat.format(dt);
  static String formatShort(DateTime dt) => _shortFormat.format(dt);
  static String formatTime(DateTime dt) => _timeFormat.format(dt);

  /// "2 hours ago", "3 days ago", "just now"
  static String timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return formatShort(dt);
  }

  /// Returns true if 56+ days have passed since [lastDonation].
  static bool canDonateAgain(DateTime? lastDonation) {
    if (lastDonation == null) return true;
    return DateTime.now().difference(lastDonation).inDays >= 56;
  }

  /// Days remaining until donor can donate again.
  static int daysUntilEligible(DateTime lastDonation) {
    final daysPassed = DateTime.now().difference(lastDonation).inDays;
    return (56 - daysPassed).clamp(0, 56);
  }
}

/// String helpers.
class StringHelpers {
  /// "john doe" → "John Doe"
  static String titleCase(String text) {
    return text
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  /// Masks phone number: "03001234567" → "0300****567"
  static String maskPhone(String phone) {
    if (phone.length < 7) return phone;
    return '${phone.substring(0, 4)}****${phone.substring(phone.length - 3)}';
  }

  /// Returns initials from a full name: "Ali Hassan" → "AH"
  static String initials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
