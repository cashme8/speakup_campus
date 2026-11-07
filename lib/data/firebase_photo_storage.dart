import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'repositories.dart';

/// Firebase Storage implementation of [PhotoStorage].
///
/// Photos live at `incident_photos/{uid}/{incidentId}.jpg`. Putting the
/// owner's uid in the path lets the Storage rules check ownership without
/// reading Firestore, and allows uploading before the report document exists.
class FirebasePhotoStorage implements PhotoStorage {
  FirebasePhotoStorage([FirebaseStorage? storage])
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  @override
  Future<({String url, String path})> uploadIncidentPhoto({
    required String uid,
    required String incidentId,
    required File file,
  }) async {
    final path = 'incident_photos/$uid/$incidentId.jpg';
    try {
      final ref = _storage.ref(path);
      await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
      return (url: await ref.getDownloadURL(), path: path);
    } on FirebaseException catch (e) {
      throw AppException(switch (e.code) {
        'unauthorized' => 'Photo upload was refused. '
            'Photos must be images under 5 MB.',
        'retry-limit-exceeded' ||
        'unknown' =>
          'Photo upload failed. Check your connection and try again.',
        _ => 'Photo upload failed (${e.code}).',
      });
    }
  }

  @override
  Future<void> delete(String path) async {
    try {
      await _storage.ref(path).delete();
    } on FirebaseException {
      // Best effort: the report is already gone; an orphaned photo is harmless.
    }
  }
}
