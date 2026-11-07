import 'dart:io';
import '../models/app_user.dart';
import '../models/incident.dart';
import '../utils/constants.dart';

/// Contracts between the state layer (providers) and the backend.
///
/// Providers depend only on these interfaces, so:
///  * the Firebase implementations can be swapped without touching the UI;
///  * tests use in-memory fakes with no network or emulator.

/// Thrown by repositories with a message that is safe to show to users.
class AppException implements Exception {
  final String message;
  const AppException(this.message);
  @override
  String toString() => message;
}

abstract class AuthRepository {
  /// Emits the signed-in user (with profile + role), or null when signed out.
  Stream<AppUser?> userChanges();

  Future<void> signIn(String email, String password);

  Future<void> register({
    required String name,
    required String department,
    required String email,
    required String password,
  });

  Future<void> sendEmailVerification();

  /// Reloads the auth user and returns the refreshed profile.
  Future<AppUser?> reloadUser();

  Future<void> sendPasswordReset(String email);

  Future<void> signOut();
}

abstract class IncidentRepository {
  /// Live list of incidents, newest first.
  Stream<List<Incident>> watchIncidents();

  /// Generates an id before writing, so the photo can be uploaded first.
  String newId();

  Future<void> create(Incident incident);

  Future<void> updateStatus(
    String id, {
    required IncidentStatus status,
    required StatusEntry entry,
  });

  Future<void> setAffected(String id, String uid, {required bool affected});

  Future<void> delete(String id);
}

abstract class PhotoStorage {
  /// Uploads [file] and returns (downloadUrl, storagePath).
  Future<({String url, String path})> uploadIncidentPhoto({
    required String uid,
    required String incidentId,
    required File file,
  });

  Future<void> delete(String path);
}
