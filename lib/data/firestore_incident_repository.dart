import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/incident.dart';
import '../utils/constants.dart';
import 'repositories.dart';

/// Cloud Firestore implementation of [IncidentRepository].
///
/// Data model - one document per report in `incidents/{id}`:
/// ```
/// title, description        string
/// category                  'facilities' | 'water' | ... (enum name)
/// location, locationDetail  string, string?
/// status                    'submitted' | 'inProgress' | 'resolved'
/// reporterId                uid of the author (used by security rules)
/// reporterName              string, or null when isAnonymous
/// isAnonymous               bool
/// affectedBy                [uid]   ("me too" confirmations)
/// imageUrl, imagePath       Firebase Storage URL + object path
/// createdAt, updatedAt      server timestamps
/// history                   [{status, at, note?, byName?}]
/// ```
/// History is an embedded array (not a subcollection): it is small and
/// bounded (a handful of entries), always read together with the report,
/// and this keeps every screen to a single real-time listener.
class FirestoreIncidentRepository implements IncidentRepository {
  FirestoreIncidentRepository([FirebaseFirestore? db])
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const _maxLoaded = 300;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('incidents');

  @override
  Stream<List<Incident>> watchIncidents() => _col
      .orderBy('createdAt', descending: true)
      .limit(_maxLoaded)
      .snapshots()
      .map((snap) => snap.docs.map(_fromDoc).toList());

  @override
  String newId() => _col.doc().id;

  @override
  Future<void> create(Incident i) => _guard(() => _col.doc(i.id).set({
        'title': i.title,
        'description': i.description,
        'category': i.category.name,
        'location': i.location,
        'locationDetail': i.locationDetail,
        'status': i.status.name,
        'reporterId': i.reporterId,
        // Data minimisation: an anonymous report never stores the name.
        'reporterName': i.isAnonymous ? null : i.reporterName,
        'isAnonymous': i.isAnonymous,
        'affectedBy': <String>[],
        'imageUrl': i.imageUrl,
        'imagePath': i.imagePath,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'history': i.history.map(_entryToMap).toList(),
      }));

  @override
  Future<void> updateStatus(
    String id, {
    required IncidentStatus status,
    required StatusEntry entry,
  }) =>
      _guard(() => _col.doc(id).update({
            'status': status.name,
            'history': FieldValue.arrayUnion([_entryToMap(entry)]),
            'updatedAt': FieldValue.serverTimestamp(),
          }));

  @override
  Future<void> setAffected(String id, String uid, {required bool affected}) =>
      _guard(() => _col.doc(id).update({
            'affectedBy': affected
                ? FieldValue.arrayUnion([uid])
                : FieldValue.arrayRemove([uid]),
          }));

  @override
  Future<void> delete(String id) => _guard(() => _col.doc(id).delete());

  // ---- mapping ----

  static Map<String, dynamic> _entryToMap(StatusEntry e) => {
        'status': e.status.name,
        'at': Timestamp.fromDate(e.at),
        if (e.note != null) 'note': e.note,
        if (e.byName != null) 'byName': e.byName,
      };

  static StatusEntry _entryFromMap(Map<String, dynamic> m) => StatusEntry(
        _status(m['status']),
        _date(m['at']),
        note: m['note'] as String?,
        byName: m['byName'] as String?,
      );

  static Incident _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    final history = ((d['history'] as List?) ?? const [])
        .whereType<Map>()
        .map((m) => _entryFromMap(Map<String, dynamic>.from(m)))
        .toList()
      ..sort((a, b) => a.at.compareTo(b.at));
    return Incident(
      id: doc.id,
      title: d['title'] as String? ?? '',
      description: d['description'] as String? ?? '',
      category: IncidentCategory.values.firstWhere(
          (c) => c.name == d['category'],
          orElse: () => IncidentCategory.facilities),
      location: d['location'] as String? ?? '',
      locationDetail: d['locationDetail'] as String?,
      status: _status(d['status']),
      reporterId: d['reporterId'] as String? ?? '',
      reporterName: d['reporterName'] as String? ?? '',
      isAnonymous: d['isAnonymous'] as bool? ?? false,
      affectedBy: List<String>.from(d['affectedBy'] as List? ?? const []),
      createdAt: _date(d['createdAt']),
      history: history,
      imageUrl: d['imageUrl'] as String?,
      imagePath: d['imagePath'] as String?,
    );
  }

  static IncidentStatus _status(Object? v) => IncidentStatus.values
      .firstWhere((s) => s.name == v, orElse: () => IncidentStatus.submitted);

  /// A just-written server timestamp is null in the local snapshot until the
  /// server confirms it; treat it as "now".
  static DateTime _date(Object? v) =>
      v is Timestamp ? v.toDate() : DateTime.now();

  static Future<T> _guard<T>(Future<T> Function() op) async {
    try {
      return await op();
    } on FirebaseException catch (e) {
      throw AppException(switch (e.code) {
        'permission-denied' =>
          'You don’t have permission to do that. Make sure your email is verified.',
        'unavailable' => 'You appear to be offline. Try again when connected.',
        'not-found' => 'This report no longer exists.',
        _ => 'Something went wrong (${e.code}). Please try again.',
      });
    }
  }
}
