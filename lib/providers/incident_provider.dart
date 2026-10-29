import 'package:flutter/foundation.dart';
import '../data/mock_data.dart';
import '../models/app_user.dart';
import '../models/incident.dart';
import '../utils/constants.dart';

class IncidentStats {
  final int total, submitted, inProgress, resolved;
  const IncidentStats(this.total, this.submitted, this.inProgress, this.resolved);
}

/// MOCK in-memory store. Later, replace `_all` with a Firestore
/// `snapshots()` stream and make the mutators call an IncidentService.
class IncidentProvider extends ChangeNotifier {
  final List<Incident> _all = seedIncidents();

  IncidentStatus? _statusFilter;
  IncidentCategory? _categoryFilter;
  String _query = '';
  bool _submitting = false;

  IncidentStatus? get statusFilter => _statusFilter;
  IncidentCategory? get categoryFilter => _categoryFilter;
  String get query => _query;
  bool get submitting => _submitting;

  /// Students see only their own reports; staff see everything.
  List<Incident> scoped(AppUser u) {
    final list = u.isStaff
        ? List<Incident>.from(_all)
        : _all.where((i) => i.reporterId == u.uid).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<Incident> recent(AppUser u, {int count = 3}) =>
      scoped(u).take(count).toList();

  List<Incident> filtered(AppUser u) {
    final q = _query.trim().toLowerCase();
    return scoped(u).where((i) {
      if (_statusFilter != null && i.status != _statusFilter) return false;
      if (_categoryFilter != null && i.category != _categoryFilter) {
        return false;
      }
      if (q.isNotEmpty &&
          !i.title.toLowerCase().contains(q) &&
          !i.location.toLowerCase().contains(q)) {
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

  void setQuery(String q) {
    _query = q;
    notifyListeners();
  }

  void clearFilters() {
    _statusFilter = null;
    _categoryFilter = null;
    _query = '';
    notifyListeners();
  }

  // ---- mutations ----
  Future<void> submit({
    required AppUser user,
    required String title,
    required String description,
    required IncidentCategory category,
    required String location,
    String? localImagePath,
  }) async {
    _submitting = true;
    notifyListeners();
    try {
      await Future.delayed(const Duration(seconds: 1)); // simulate upload
      final now = DateTime.now();
      _all.insert(
        0,
        Incident(
          id: now.microsecondsSinceEpoch.toString(),
          title: title.trim(),
          description: description.trim(),
          category: category,
          location: location,
          status: IncidentStatus.submitted,
          reporterId: user.uid,
          reporterName: user.name,
          createdAt: now,
          history: [StatusEntry(IncidentStatus.submitted, now)],
          localImagePath: localImagePath,
        ),
      );
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  /// Staff only (UI guard here; enforce again in Firestore rules later).
  void updateStatus(String id, IncidentStatus status) {
    final idx = _all.indexWhere((i) => i.id == id);
    if (idx < 0 || _all[idx].status == status) return;
    final current = _all[idx];
    _all[idx] = current.copyWith(
      status: status,
      history: [...current.history, StatusEntry(status, DateTime.now())],
    );
    notifyListeners();
  }

  void delete(String id) {
    _all.removeWhere((i) => i.id == id);
    notifyListeners();
  }
}
