import '../utils/constants.dart';

class StatusEntry {
  final IncidentStatus status;
  final DateTime at;
  const StatusEntry(this.status, this.at);
}

class Incident {
  final String id;
  final String title;
  final String description;
  final IncidentCategory category;
  final String location;
  final IncidentStatus status;
  final String reporterId;
  final String reporterName;
  final DateTime createdAt;
  final List<StatusEntry> history;

  /// Firebase Storage download URL (later).
  final String? imageUrl;

  /// Local file path while mocking / before upload completes.
  final String? localImagePath;

  const Incident({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.status,
    required this.reporterId,
    required this.reporterName,
    required this.createdAt,
    required this.history,
    this.imageUrl,
    this.localImagePath,
  });

  bool get hasImage => imageUrl != null || localImagePath != null;

  DateTime? timeFor(IncidentStatus s) {
    for (final e in history) {
      if (e.status == s) return e.at;
    }
    return null;
  }

  Incident copyWith({IncidentStatus? status, List<StatusEntry>? history}) =>
      Incident(
        id: id,
        title: title,
        description: description,
        category: category,
        location: location,
        status: status ?? this.status,
        reporterId: reporterId,
        reporterName: reporterName,
        createdAt: createdAt,
        history: history ?? this.history,
        imageUrl: imageUrl,
        localImagePath: localImagePath,
      );
}
