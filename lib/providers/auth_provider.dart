import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/repositories.dart';
import '../models/app_user.dart';
import '../utils/validators.dart';

/// Authentication state for the whole app.
///
/// Listens to [AuthRepository.userChanges], so the session survives app
/// restarts (Firebase persists it) and role changes made by an admin in the
/// console reach the app in real time. Screens only call the methods below
/// and never touch Firebase directly.
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._repo) {
    _sub = _repo.userChanges().listen((u) {
      _user = u;
      _initializing = false;
      notifyListeners();
    }, onError: (Object e) {
      _initializing = false;
      _error = e.toString();
      notifyListeners();
    });
  }

  final AuthRepository _repo;
  StreamSubscription<AppUser?>? _sub;

  AppUser? _user;
  bool _initializing = true;
  bool _loading = false;
  String? _error;

  AppUser? get user => _user;
  bool get isLoggedIn => _user != null;

  /// True until the first auth event arrives (show a splash, not login).
  bool get initializing => _initializing;
  bool get loading => _loading;
  String? get error => _error;

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  Future<bool> login(String email, String password) =>
      _run(() => _repo.signIn(email, password));

  Future<bool> register({
    required String name,
    required String department,
    required String email,
    required String password,
  }) {
    // Defence in depth: the form validates this too, and the security rules
    // refuse non-ALU accounts.
    final domainError = Validators.aluEmail(email);
    if (domainError != null) return Future.value(_fail(domainError));
    return _run(() => _repo.register(
          name: name,
          department: department,
          email: email,
          password: password,
        ));
  }

  /// Called from the verify screen after the user clicks the email link.
  Future<bool> checkVerified() => _run(() async {
        final refreshed = await _repo.reloadUser();
        if (refreshed != null) _user = refreshed;
        if (refreshed?.emailVerified != true) {
          throw const AppException(
              'Your email isn’t verified yet. Open the link we sent, '
              'then try again.');
        }
      });

  Future<bool> resendVerification() =>
      _run(() => _repo.sendEmailVerification());

  Future<bool> sendPasswordReset(String email) =>
      _run(() => _repo.sendPasswordReset(email));

  Future<void> logout() async {
    _error = null;
    await _repo.signOut();
  }

  Future<bool> _run(Future<void> Function() op) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await op();
      _loading = false;
      notifyListeners();
      return true;
    } on AppException catch (e) {
      return _fail(e.message);
    } catch (e) {
      return _fail('Something went wrong. Please try again.');
    }
  }

  bool _fail(String message) {
    _loading = false;
    _error = message;
    notifyListeners();
    return false;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
