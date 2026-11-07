import 'dart:async';
import 'dart:io';
import 'package:speakup_campus/data/repositories.dart';
import 'package:speakup_campus/main.dart';
import 'package:speakup_campus/models/app_user.dart';
import 'package:speakup_campus/models/incident.dart';
import 'package:speakup_campus/utils/constants.dart';
import 'seed_data.dart';

/// In-memory stand-ins for the Firebase repositories. They implement the
/// same interfaces, so providers and screens are tested without a network.

class _Account {
  final String password;
  AppUser user;
  _Account(this.password, this.user);
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository() {
    _accounts[demoStudentEmail] = _Account(
      'password123',
      const AppUser(
        uid: demoStudentEmail,
        name: 'Amina Hassan',
        email: demoStudentEmail,
        department: 'Computer Science',
        role: UserRole.student,
        emailVerified: true,
      ),
    );
    _accounts[demoStaffEmail] = _Account(
      'password123',
      const AppUser(
        uid: demoStaffEmail,
        name: 'Facilities Team',
        email: demoStaffEmail,
        department: 'Facilities Office',
        role: UserRole.staff,
        emailVerified: true,
      ),
    );
  }

  final _accounts = <String, _Account>{};
  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _current;

  /// Simulates the user clicking the link in the verification email.
  void verifyEmail(String email) {
    final a = _accounts[email]!;
    a.user = a.user.copyWith(emailVerified: true);
  }

  int verificationEmailsSent = 0;

  void _emit(AppUser? u) {
    _current = u;
    _controller.add(u);
  }

  @override
  Stream<AppUser?> userChanges() {
    // Like Firebase: a new listener immediately receives the current state.
    scheduleMicrotask(() => _controller.add(_current));
    return _controller.stream;
  }

  @override
  Future<void> signIn(String email, String password) async {
    final a = _accounts[email.trim().toLowerCase()];
    if (a == null || a.password != password) {
      throw const AppException('Incorrect email or password.');
    }
    _emit(a.user);
  }

  @override
  Future<void> register({
    required String name,
    required String department,
    required String email,
    required String password,
  }) async {
    final e = email.trim().toLowerCase();
    if (_accounts.containsKey(e)) {
      throw const AppException(
          'An account already exists for this email. Try signing in.');
    }
    final user = AppUser(
      uid: e,
      name: name.trim(),
      email: e,
      department: department,
      role: UserRole.student,
      emailVerified: false,
    );
    _accounts[e] = _Account(password, user);
    verificationEmailsSent++;
    _emit(user);
  }

  @override
  Future<void> sendEmailVerification() async => verificationEmailsSent++;

  @override
  Future<AppUser?> reloadUser() async {
    final c = _current;
    if (c == null) return null;
    final fresh = _accounts[c.email]!.user;
    _emit(fresh);
    return fresh;
  }

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> signOut() async => _emit(null);
}

class FakeIncidentRepository implements IncidentRepository {
  FakeIncidentRepository({List<Incident>? seed})
      : _items = [...(seed ?? seedIncidents())];

  final List<Incident> _items;
  final _controller = StreamController<List<Incident>>.broadcast();
  int _nextId = 1;

  /// When true the next write throws, to test error handling.
  bool failNextWrite = false;

  void _emit() => _controller.add(List.unmodifiable(_items));

  void _maybeFail() {
    if (failNextWrite) {
      failNextWrite = false;
      throw const AppException('You appear to be offline.');
    }
  }

  @override
  Stream<List<Incident>> watchIncidents() {
    scheduleMicrotask(_emit);
    return _controller.stream;
  }

  @override
  String newId() => 'new-${_nextId++}';

  @override
  Future<void> create(Incident incident) async {
    _maybeFail();
    _items.insert(0, incident);
    _emit();
  }

  @override
  Future<void> updateStatus(String id,
      {required IncidentStatus status, required StatusEntry entry}) async {
    _maybeFail();
    final i = _items.indexWhere((x) => x.id == id);
    _items[i] = _items[i]
        .copyWith(status: status, history: [..._items[i].history, entry]);
    _emit();
  }

  @override
  Future<void> setAffected(String id, String uid,
      {required bool affected}) async {
    _maybeFail();
    final i = _items.indexWhere((x) => x.id == id);
    final list = {..._items[i].affectedBy};
    affected ? list.add(uid) : list.remove(uid);
    _items[i] = _items[i].copyWith(affectedBy: list.toList());
    _emit();
  }

  @override
  Future<void> delete(String id) async {
    _maybeFail();
    _items.removeWhere((x) => x.id == id);
    _emit();
  }
}

class FakePhotoStorage implements PhotoStorage {
  final uploaded = <String>[];
  final deleted = <String>[];

  @override
  Future<({String url, String path})> uploadIncidentPhoto({
    required String uid,
    required String incidentId,
    required File file,
  }) async {
    final path = 'incident_photos/$uid/$incidentId.jpg';
    uploaded.add(path);
    return (url: 'https://example.test/$path', path: path);
  }

  @override
  Future<void> delete(String path) async => deleted.add(path);
}

/// The full app wired to fresh fakes.
CampusIncidentApp buildTestApp({
  FakeAuthRepository? auth,
  FakeIncidentRepository? incidents,
  FakePhotoStorage? photos,
}) =>
    CampusIncidentApp(
      authRepository: auth ?? FakeAuthRepository(),
      incidentRepository: incidents ?? FakeIncidentRepository(),
      photoStorage: photos ?? FakePhotoStorage(),
    );
