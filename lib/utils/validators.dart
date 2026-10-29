import 'constants.dart';

class Validators {
  static String? required(String? v, [String field = 'This field']) =>
      (v == null || v.trim().isEmpty) ? '$field is required' : null;

  static String? aluEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    final email = v.trim().toLowerCase();
    final ok = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$').hasMatch(email);
    if (!ok) return 'Enter a valid email address';
    final domain = email.split('@').last;
    if (!allowedEmailDomains.contains(domain)) {
      return 'Use your ALU email (${allowedEmailDomains.map((d) => '@$d').join(' or ')})';
    }
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 6) return 'Use at least 6 characters';
    return null;
  }

  static String? minLength(String? v, int min, String field) {
    if (v == null || v.trim().isEmpty) return '$field is required';
    if (v.trim().length < min) return '$field needs at least $min characters';
    return null;
  }
}
