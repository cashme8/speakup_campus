import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../data/repositories.dart';
import '../models/app_user.dart';
import '../models/incident.dart';
import '../utils/constants.dart';

class IncidentStats {
  final int total, submitted, inProgress, resolved;
  const IncidentStats(this.total, this.submitted, this.inProgress, this.resolved);
}

/// Incident state shared by every screen.
///
/// Holds one real-time subscription to [IncidentRepository.watchIncidents];
/// all lists, counters and filters are derived from that single source, so a
/// status change made by staff on one phone updates the student's Home,
/// Reports and Detail screens on another phone automatically.
///
/// Firestore applies local writes to the stream immediately (latency
/// compensation), so the UI updates before the server round-trip finishes.
class IncidentProvider extends ChangeNotifier {
  IncidentProvider({
    required IncidentRepository repository,
    required PhotoStorage storage,
  })  : _repo = repository,
        _photoStorage = storage;

  final IncidentRepository _repo;
  final PhotoStorage _photoStorage;

  StreamSubscription<List<Incident>>? _sub;
  String? _boundUid;

  List<Incident> _all = const [];
  bool _loading = false;
  String? _loadError;

  IncidentStatus? _statusFilter;
  IncidentCategory? _categoryFilter;
  ReportScope _scope = ReportScope.mine;
  String _query = '';
  bool _submitting = false;

  bool get loading => _loading;
  String? get loadError => _loadError;
  IncidentStatus? get statusFilter => _statusFilter;
  IncidentCategory? get categoryFilter => _categoryFilter;
  ReportScope get scope => _scope;
  String get query => _query;
  bool get submitting => _submitting;
  bool get hasFilters =>
      _statusFilter != null || _categoryFilter != null || _query.isNotEmpty;

  // ---- session binding ----

  /// Called by the ProxyProvider whenever auth state changes. Listening
  /// starts only for verified users (the security rules would refuse anyone
  /// else) and stops on sign-out so no listener outlives the session.
  void bindUser(AppUser? user) {
    final uid = (user != null && user.emailVerified) ? user.uid : null;
    if (uid == _boundUid) return;
    _boundUid = uid;
    _sub?.cancel();
    _sub = null;
    _all = const [];
    _loadError = null;
    _statusFilter = null;
    _categoryFilter = null;
    _query = '';
    _scope = ReportScope.mine;

    if (uid == null) {
      _loading = false;
      notifyListeners();
      return;
    }
    _loading = true;
    notifyListeners();
    _subscribe();
  }

  void _subscribe() {
    _sub = _repo.watchIncidents().listen((items) {
      _all = items;
      _loading = false;
      _loadError = null;
      notifyListeners();
    }, onError: (Object e) {
      _loading = false;
      _loadError = e is AppException
          ? e.message
          : 'Could not load reports. Pull down to retry.';
      notifyListeners();
    });
  }

  /// Re-subscribes after an error (pull-to-refresh / retry button).
  Future<void> retry() async {
    if (_boundUid == null) return;
    await _sub?.cancel();
    _loading = true;
    _loadError = null;
    notifyListeners();
    _subscribe();
  }

  // ---- derived views ----

  List<Incident> _sorted(Iterable<Incident> items) =>
      items.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  /// A student's own reports, or every report for staff.
  List<Incident> scoped(AppUser u) => _sorted(
      u.isStaff ? _all : _all.where((i) => i.reporterId == u.uid));

  /// The Reports tab before filters: students switch mine/campus.
  List<Incident> browsable(AppUser u) =>
      (u.isStaff || _scope == ReportScope.campus) ? _sorted(_all) : scoped(u);

  List<Incident> recent(AppUser u, {int count = 3}) =>
      scoped(u).take(count).toList();

  List<Incident> filtered(AppUser u) {
    final q = _query.trim().toLowerCase();
    return browsable(u).where((i) {
      if (_statusFilter != null && i.status != _statusFilter) return false;
      if (_categoryFilter != null && i.category != _categoryFilter) {
        return false;
      }
      if (q.isNotEmpty &&
          !i.title.toLowerCase().contains(q) &&
          !i.fullLocation.toLowerCase().contains(q) &&
          !i.description.toLowerCase().contains(q)) {
        return false;
      }
      return true;
    }).toList();
  }

  IncidentStats stats(AppUser u) {
    final list = scoped(u);
    int c(IncidentStatus s) => list.where((i) => i.status == s).length;
    return IncidentStats(
      list.length,
      c(IncidentStatus.submitted),
      c(IncidentStatus.inProgress),
      c(IncidentStatus.resolved),
    );
  }

  /// Open reports at a location - used to discourage duplicates.
  List<Incident> openAt(String location) => _sorted(_all.where((i) =>
      i.location == location && i.status != IncidentStatus.resolved));

  Incident? byId(String id) {
    for (final i in _all) {
      if (i.id == id) return i;
    }
    return null;
  }

  // ---- filters ----

  void setStatusFilter(IncidentStatus? s) {
    _statusFilter = s;
    notifyListeners();
  }

  void setCategoryFilter(IncidentCategory? c) {
    _categoryFilter = c;
    notifyListeners();
  }

  void setScope(ReportScope s) {
    _scope = s;
    notifyListeners();
  }

  void setQuery(String q) {
    _query = q;
    notifyListeners();
  }

  /// Dashboard shortcut: own reports, optionally one status. One rebuild.
  void showOwnReports({IncidentStatus? status}) {
    _scope = ReportScope.mine;
    _categoryFilter = null;
    _query = '';
    _statusFilter = status;
    notifyListeners();
  }

  void clearFilters() {
    _statusFilter = null;
    _categoryFilter = null;
    _query = '';
    notifyListeners();
  }

  // ---- mutations ----

  /// Uploads the optional photo first, then writes the report. If the write
  /// fails, the uploaded photo is deleted so no orphan files are left.
  Future<void> submit({
    required AppUser user,
    required String title,
    required String description,
    required IncidentCategory category,
    required String location,
    String? locationDetail,
    bool isAnonymous = false,
    File? photo,
  }) async {
    _submitting = true;
    notifyListeners();
    String? uploadedPath;
    try {
      final id = _repo.newId();
      String? url;
      if (photo != null) {
        final up = await _photoStorage.uploadIncidentPhoto(
            uid: user.uid, incidentId: id, file: photo);
        url = up.url;
        uploadedPath = up.path;
      }
      final now = DateTime.now();
      final detail = locationDetail?.trim();
      await _repo.create(Incident(
        id: id,
        title: title.trim(),
        description: description.trim(),
        category: category,
        location: location,
        locationDetail: (detail == null || detail.isEmpty) ? null : detail,
        status: IncidentStatus.submitted,
        reporterId: user.uid,
        reporterName: user.name,
        isAnonymous: isAnonymous,
        createdAt: now,
        history: [StatusEntry(IncidentStatus.submitted, now)],
        imageUrl: url,
        imagePath: uploadedPath,
      ));
    } catch (_) {
      if (uploadedPath != null) await _photoStorage.delete(uploadedPath);
      rethrow;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  /// Staff only. Hidden from students in the UI, checked here, and enforced
  /// on the server by Firestore security rules.
  Future<void> updateStatus(
    String id,
    IncidentStatus status, {
    required AppUser by,
    String? note,
  }) async {
    if (!by.isStaff) throw StateError('Only staff can update status');
    final current = byId(id);
    if (current == null) return;
    final trimmed = note?.trim();
    final hasNote = trimmed != null && trimmed.isNotEmpty;
    if (current.status == status && !hasNote) return;
    await _repo.updateStatus(
      id,
      status: status,
      entry: StatusEntry(status, DateTime.now(),
          note: hasNote ? trimmed : null, byName: by.name),
    );
  }

  /// "This affects me too" - toggles the user's confirmation.
  Future<void> toggleAffected(String id, AppUser user) async {
    final current = byId(id);
    if (current == null || current.isOwnedBy(user)) return;
    await _repo.setAffected(id, user.uid,
        affected: !current.isConfirmedBy(user));
  }

  /// Reporters may withdraw a report while it is still "Submitted".
  Future<void> delete(String id) async {
    final current = byId(id);
    await _repo.delete(id);
    final path = current?.imagePath;
    if (path != null) await _photoStorage.delete(path);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
