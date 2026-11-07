import 'package:flutter_test/flutter_test.dart';
import 'package:speakup_campus/data/mock_data.dart';
import 'package:speakup_campus/models/app_user.dart';
import 'package:speakup_campus/providers/incident_provider.dart';
import 'package:speakup_campus/utils/constants.dart';

AppUser _user(String email, UserRole role, {String name = 'Test User'}) =>
    AppUser(
      uid: email,
      name: name,
      email: email,
      department: 'Business',
      location: 'Kigali, Rwanda',
      role: role,
      emailVerified: true,
    );

void main() {
  final student = _user(demoStudentEmail, UserRole.student);
  final other = _user('other@alustudent.com', UserRole.student);
  final staff = _user(demoStaffEmail, UserRole.staff, name: 'Facilities Team');

  test('students only see their own reports, staff see all', () {
    final provider = IncidentProvider();

    final mine = provider.scoped(student);
    expect(mine, isNotEmpty);
    expect(mine.every((i) => i.reporterId == student.uid), isTrue);
    expect(provider.scoped(staff).length, greaterThan(mine.length));
  });

  test('campus scope lets students browse every report', () {
    final provider = IncidentProvider();
    final mineCount = provider.browsable(student).length;

    provider.setScope(ReportScope.campus);

    expect(provider.browsable(student).length, provider.scoped(staff).length);
    expect(provider.browsable(student).length, greaterThan(mineCount));
    // Dashboard stats stay personal regardless of the browse scope.
    expect(provider.stats(student).total, mineCount);
  });

  test('submit adds a Submitted report at the top', () async {
    final provider = IncidentProvider();
    final before = provider.scoped(student).length;

    await provider.submit(
      user: student,
      title: '  Broken window  ',
      description: 'The window in Room 204 will not close.',
      category: IncidentCategory.facilities,
      location: 'Block B',
      locationDetail: '  Room 204 ',
      isAnonymous: true,
    );

    final created = provider.scoped(student).first;
    expect(provider.scoped(student).length, before + 1);
    expect(created.title, 'Broken window');
    expect(created.fullLocation, 'Block B · Room 204');
    expect(created.status, IncidentStatus.submitted);
    expect(created.isAnonymous, isTrue);
    expect(provider.submitting, isFalse);
  });

  test('staff updateStatus changes status, appends history and note',
      () async {
    final provider = IncidentProvider();
    final id = provider
        .scoped(staff)
        .firstWhere((i) => i.status == IncidentStatus.submitted)
        .id;
    final historyBefore = provider.byId(id)!.history.length;

    await provider.updateStatus(id, IncidentStatus.inProgress,
        by: staff, note: 'Electrician on the way');

    final updated = provider.byId(id)!;
    expect(updated.status, IncidentStatus.inProgress);
    expect(updated.history.length, historyBefore + 1);
    expect(updated.history.last.note, 'Electrician on the way');
    expect(updated.history.last.byName, 'Facilities Team');
  });

  test('students cannot update status', () async {
    final provider = IncidentProvider();
    final id = provider.scoped(student).first.id;

    expect(
      () => provider.updateStatus(id, IncidentStatus.resolved, by: student),
      throwsStateError,
    );
  });

  test('reopened report hides the old resolved time', () async {
    final provider = IncidentProvider();
    final resolved = provider
        .scoped(staff)
        .firstWhere((i) => i.status == IncidentStatus.resolved);

    await provider.updateStatus(resolved.id, IncidentStatus.inProgress,
        by: staff);

    final reopened = provider.byId(resolved.id)!;
    expect(reopened.status, IncidentStatus.inProgress);
    expect(reopened.timeFor(IncidentStatus.inProgress),
        reopened.history.last.at);
  });

  test('"Me too" toggles on and off and ignores the owner', () async {
    final provider = IncidentProvider();
    final id = provider.scoped(student).first.id;

    await provider.toggleAffected(id, other);
    expect(provider.byId(id)!.isConfirmedBy(other), isTrue);

    await provider.toggleAffected(id, other);
    expect(provider.byId(id)!.isConfirmedBy(other), isFalse);

    final before = provider.byId(id)!.affectedBy.length;
    await provider.toggleAffected(id, student); // owner
    expect(provider.byId(id)!.affectedBy.length, before);
  });

  test('reporter name is hidden according to role and anonymity', () async {
    final provider = IncidentProvider();
    await provider.submit(
      user: student,
      title: 'Leaking pipe',
      description: 'Water is leaking under the sink.',
      category: IncidentCategory.water,
      location: 'Cafeteria',
      isAnonymous: true,
    );
    final anon = provider.scoped(student).first;
    expect(anon.reporterLabelFor(student), 'You (anonymous)');
    expect(anon.reporterLabelFor(staff), 'Anonymous student');
    expect(anon.reporterLabelFor(other), 'Anonymous student');

    final named = provider
        .scoped(student)
        .firstWhere((i) => !i.isAnonymous);
    expect(named.reporterLabelFor(staff), named.reporterName);
    expect(named.reporterLabelFor(other), 'A student');
  });

  test('filters narrow results and clearFilters resets them', () {
    final provider = IncidentProvider();
    final all = provider.filtered(staff).length;

    provider.setStatusFilter(IncidentStatus.resolved);
    expect(
        provider
            .filtered(staff)
            .every((i) => i.status == IncidentStatus.resolved),
        isTrue);

    provider.setQuery('zzz-no-match');
    expect(provider.filtered(staff), isEmpty);
    expect(provider.hasFilters, isTrue);

    provider.clearFilters();
    expect(provider.filtered(staff).length, all);
  });

  test('showOwnReports resets filters and applies one status', () {
    final provider = IncidentProvider()
      ..setScope(ReportScope.campus)
      ..setQuery('water')
      ..setCategoryFilter(IncidentCategory.water);

    provider.showOwnReports(status: IncidentStatus.resolved);

    expect(provider.scope, ReportScope.mine);
    expect(provider.query, isEmpty);
    expect(provider.categoryFilter, isNull);
    expect(provider.statusFilter, IncidentStatus.resolved);
  });

  test('openAt lists unresolved reports at a location', () {
    final provider = IncidentProvider();
    final open = provider.openAt('Student Residence');
    expect(open, isNotEmpty);
    expect(open.every((i) => i.status != IncidentStatus.resolved), isTrue);
    expect(provider.openAt('Cafeteria'), isEmpty); // only one, resolved
  });

  test('delete removes the report', () async {
    final provider = IncidentProvider();
    final id = provider.scoped(student).first.id;

    await provider.delete(id);

    expect(provider.byId(id), isNull);
  });
}
