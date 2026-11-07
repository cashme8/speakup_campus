import '../utils/constants.dart';
import 'app_user.dart';

/// One step in an incident's history. Staff can attach a note that the
/// reporter sees (e.g. "Plumber booked for Thursday").
class StatusEntry {
  final IncidentStatus status;
  final DateTime at;
  final String? note;
  final String? byName;

  const StatusEntry(this.status, this.at, {this.note, this.byName});
}

class Incident {
  final String id;
  final String title;
  final String description;
  final IncidentCategory category;

  /// Campus area picked from a fixed list (keeps filtering/search reliable).
  final String location;

  /// Optional free text, e.g. "Room 204, 2nd floor".
  final String? locationDetail;

  final IncidentStatus status;
  final String reporterId;
  final String reporterName;

  /// When true, staff and other students see "Anonymous student".
  /// The reporterId is still stored so the owner keeps access and misuse
  /// can be traced by an administrator.
  final bool isAnonymous;

  /// uids of other students who confirmed "this affects me too".
  final List<String> affectedBy;

  final DateTime createdAt;
  final List<StatusEntry> history;

  /// Firebase Storage download URL (shown in the app).
  final String? imageUrl;

  /// Firebase Storage object path (used to delete the photo).
  final String? imagePath;

  const Incident({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    this.locationDetail,
    required this.status,
    required this.reporterId,
    required this.reporterName,
    this.isAnonymous = false,
    this.affectedBy = const [],
    required this.createdAt,
    required this.history,
    this.imageUrl,
    this.imagePath,
  });

  bool get hasImage => imageUrl != null;

  String get fullLocation =>
      (locationDetail == null || locationDetail!.trim().isEmpty)
          ? location
          : '$location · ${locationDetail!.trim()}';

  DateTime get lastUpdated => history.isEmpty ? createdAt : history.last.at;

  bool isOwnedBy(AppUser u) => reporterId == u.uid;

  bool isConfirmedBy(AppUser u) => affectedBy.contains(u.uid);

  /// What name a given viewer is allowed to see.
  String reporterLabelFor(AppUser viewer) {
    if (isOwnedBy(viewer)) return isAnonymous ? 'You (anonymous)' : 'You';
    if (isAnonymous) return 'Anonymous student';
    if (viewer.isStaff) return reporterName;
    return 'A student';
  }

  /// The latest time this status was reached (a report can be reopened).
  DateTime? timeFor(IncidentStatus s) {
    for (final e in history.reversed) {
      if (e.status == s) return e.at;
    }
    return null;
  }

  Incident copyWith({
    IncidentStatus? status,
    List<StatusEntry>? history,
    List<String>? affectedBy,
    String? imageUrl,
    String? imagePath,
  }) =>
      Incident(
        id: id,
        title: title,
        description: description,
        category: category,
        location: location,
        locationDetail: locationDetail,
        status: status ?? this.status,
        reporterId: reporterId,
        reporterName: reporterName,
        isAnonymous: isAnonymous,
        affectedBy: affectedBy ?? this.affectedBy,
        createdAt: createdAt,
        history: history ?? this.history,
        imageUrl: imageUrl ?? this.imageUrl,
        imagePath: imagePath ?? this.imagePath,
      );
}
