import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_config.dart';
import 'repositories.dart';

/// Supabase Storage implementation of [PhotoStorage].
///
/// Used instead of Firebase Storage because new Firebase Storage buckets now
/// require the paid Blaze plan. Thanks to the [PhotoStorage] interface this
/// is the only class that knows about Supabase; switching back is a one-line
/// change in `main.dart` (see [FirebasePhotoStorage]).
///
/// Authentication is still Firebase: `Supabase.initialize(accessToken: ...)`
/// forwards the Firebase ID token, and the bucket policies check its claims
/// (uid, email_verified, ALU domain).
///
/// Objects are stored at `{bucket}/{uid}/{incidentId}.jpg`.
class SupabasePhotoStorage implements PhotoStorage {
  SupabasePhotoStorage([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  StorageFileApi get _bucket => _client.storage.from(supabasePhotoBucket);

  @override
  Future<({String url, String path})> uploadIncidentPhoto({
    required String uid,
    required String incidentId,
    required File file,
  }) async {
    final path = '$uid/$incidentId.jpg';
    try {
      await _bucket.upload(
        path,
        file,
        fileOptions: const FileOptions(contentType: 'image/jpeg'),
      );
      return (url: _bucket.getPublicUrl(path), path: path);
    } on StorageException catch (e) {
      final code = e.statusCode ?? '';
      throw AppException(switch (code) {
        '403' || '401' => 'Photo upload was refused. '
            'Make sure your email is verified, then try again.',
        '413' => 'That photo is too large (max 5 MB).',
        '409' => 'This photo was already uploaded. Please try again.',
        _ => 'Photo upload failed. Check your connection and try again.',
      });
    } on SocketException {
      throw const AppException(
          'No internet connection. Your report was not sent.');
    }
  }

  @override
  Future<void> delete(String path) async {
    try {
      await _bucket.remove([path]);
    } catch (_) {
      // Best effort: an orphaned photo is harmless.
    }
  }
}
