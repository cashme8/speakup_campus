import 'package:flutter/foundation.dart';
import '../data/mock_data.dart';
import '../models/app_user.dart';
import '../utils/constants.dart';

/// MOCK implementation. Later, replace the bodies with FirebaseAuth calls
/// (signInWithEmailAndPassword, createUserWithEmailAndPassword,
/// sendEmailVerification, user.reload()) and read the role from
/// Firestore `users/{uid}`. The public API below should not change.
class AuthProvider extends ChangeNotifier {
  AppUser? _user;
  bool _loading = false;
  String? _error;

  AppUser? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get loading => _loading;
  String? get error => _error;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _begin();
    await Future.delayed(const Duration(milliseconds: 800));
    final e = email.trim().toLowerCase();

    // Demo rule: any 6+ character password works.
    if (password.length < 6) {
      return _fail('Incorrect email or password.');
    }

    final isStaff = e == demoStaffEmail;
    _user = AppUser(
      uid: e,
      name: _nameFromEmail(e),
      email: e,
      department: isStaff ? 'Facilities Office' : 'Computer Science',
      location: 'Kigali, Rwanda',
      role: isStaff ? UserRole.staff : UserRole.student,
      emailVerified: true,
    );
    _loading = false;
    notifyListeners();
    return true;
  }

  Future<bool> register({
    required String name,
    required String department,
    required String email,
    required String password,
  }) async {
    _begin();
    await Future.delayed(const Duration(milliseconds: 900));
    final e = email.trim().toLowerCase();
    _user = AppUser(
      uid: e,
      name: name.trim(),
      email: e,
      department: department,
      location: 'Kigali, Rwanda',
      role: UserRole.student, // staff accounts are created by an admin
      emailVerified: false,
    );
    _loading = false;
    notifyListeners();
    return true;
  }

  Future<bool> checkVerified() async {
    _begin();
    await Future.delayed(const Duration(milliseconds: 700));
    // Mock: treat the tap as "I clicked the link". Real app: reload user.
    _user = _user?.copyWith(emailVerified: true);
    _loading = false;
    notifyListeners();
    return true;
  }

  Future<void> resendVerification() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  void logout() {
    _user = null;
    _error = null;
    notifyListeners();
  }

  void _begin() {
    _loading = true;
    _error = null;
    notifyListeners();
  }

  bool _fail(String message) {
    _loading = false;
    _error = message;
    notifyListeners();
    return false;
  }

  String _nameFromEmail(String email) {
    if (email == demoStudentEmail) return 'Amina Hassan';
    if (email == demoStaffEmail) return 'Facilities Team';
    final local = email.split('@').first.replaceAll(RegExp(r'[._]'), ' ');
    return local
        .split(' ')
        .where((p) => p.isNotEmpty)
        .map((p) => p[0].toUpperCase() + p.substring(1))
        .join(' ');
  }
}
