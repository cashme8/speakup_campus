import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';
import '../utils/constants.dart';
import 'repositories.dart';

/// Firebase Auth + Firestore `users/{uid}` implementation of [AuthRepository].
///
/// Auth holds credentials and the email-verified flag; Firestore holds the
/// profile and the role. Roles are never chosen by the client: registration
/// always writes `role: 'student'` (enforced by security rules) and staff are
/// promoted by an administrator in the Firebase console.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? auth, FirebaseFirestore? db})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _db.collection('users').doc(uid);

  AppUser _build(User u, Map<String, dynamic>? data) => AppUser.fromMap(
        u.uid,
        data ?? {'name': u.displayName},
        email: u.email ?? '',
        emailVerified: u.emailVerified,
      );

  /// Combines the auth state with a live listener on the profile document.
  /// When the auth user changes, the previous profile listener is cancelled
  /// ("switchMap"), so signing out never leaves a dangling listener.
  @override
  Stream<AppUser?> userChanges() {
    late StreamController<AppUser?> controller;
    StreamSubscription<User?>? authSub;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? docSub;

    controller = StreamController<AppUser?>(
      onListen: () {
        authSub = _auth.userChanges().listen((u) {
          docSub?.cancel();
          docSub = null;
          if (u == null) {
            controller.add(null);
            return;
          }
          docSub = _doc(u.uid).snapshots().listen(
                (snap) => controller.add(_build(u, snap.data())),
                // e.g. permission-denied while signing out: fall back to
                // the auth data instead of breaking the stream.
                onError: (_) => controller.add(_build(u, null)),
              );
        }, onError: controller.addError);
      },
      onCancel: () async {
        await docSub?.cancel();
        await authSub?.cancel();
      },
    );
    return controller.stream;
  }

  @override
  Future<void> signIn(String email, String password) => _guard(() =>
      _auth.signInWithEmailAndPassword(
          email: email.trim().toLowerCase(), password: password));

  @override
  Future<void> register({
    required String name,
    required String department,
    required String email,
    required String password,
  }) =>
      _guard(() async {
        final cred = await _auth.createUserWithEmailAndPassword(
            email: email.trim().toLowerCase(), password: password);
        final u = cred.user!;
        await u.updateDisplayName(name.trim());
        await _doc(u.uid).set({
          'name': name.trim(),
          'email': u.email,
          'department': department,
          'role': UserRole.student.name,
          'createdAt': FieldValue.serverTimestamp(),
        });
        await u.sendEmailVerification();
      });

  @override
  Future<void> sendEmailVerification() =>
      _guard(() async => _auth.currentUser?.sendEmailVerification());

  @override
  Future<AppUser?> reloadUser() => _guard(() async {
        final current = _auth.currentUser;
        if (current == null) return null;
        await current.reload();
        final u = _auth.currentUser!;
        // Force a fresh ID token so Firestore/Storage rules see
        // email_verified == true straight away (otherwise the cached token
        // keeps the old claim for up to an hour).
        if (u.emailVerified) await u.getIdToken(true);
        final snap = await _doc(u.uid).get();
        return _build(u, snap.data());
      });

  @override
  Future<void> sendPasswordReset(String email) => _guard(
      () => _auth.sendPasswordResetEmail(email: email.trim().toLowerCase()));

  @override
  Future<void> signOut() => _auth.signOut();

  static Future<T> _guard<T>(Future<T> Function() op) async {
    try {
      return await op();
    } on FirebaseAuthException catch (e) {
      throw AppException(_authMessage(e.code));
    } on FirebaseException catch (e) {
      throw AppException('Something went wrong (${e.code}). Please try again.');
    }
  }

  static String _authMessage(String code) => switch (code) {
        'invalid-credential' ||
        'wrong-password' ||
        'user-not-found' ||
        'invalid-login-credentials' =>
          'Incorrect email or password.',
        'email-already-in-use' =>
          'An account already exists for this email. Try signing in.',
        'weak-password' => 'Choose a stronger password (at least 6 characters).',
        'invalid-email' => 'That email address is not valid.',
        'user-disabled' => 'This account has been disabled. Contact support.',
        'too-many-requests' =>
          'Too many attempts. Wait a few minutes and try again.',
        'network-request-failed' =>
          'No internet connection. Check your network and try again.',
        'operation-not-allowed' =>
          'Email/password sign-in is not enabled for this Firebase project.',
        _ => 'Authentication failed ($code).',
      };
}
