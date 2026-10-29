import 'package:flutter_test/flutter_test.dart';
import 'package:speakup_campus/data/mock_data.dart';
import 'package:speakup_campus/models/app_user.dart';
import 'package:speakup_campus/providers/incident_provider.dart';
import 'package:speakup_campus/utils/constants.dart';

AppUser _user(String email, UserRole role) => AppUser(
      uid: email,
      name: 'Test User',
      email: email,
      department: 'Business',
      location: 'Kigali, Rwanda',
      role: role,
      emailVerified: true,
    );

void main() {
  final student = _user(demoStudentEmail, UserRole.student);
  final staff = _user(demoStaffEmail, UserRole.staff);

  test('students only see their own reports, staff see all', () {
    final provider = IncidentProvider();

    final mine = provider.scoped(student);
    expect(mine, isNotEmpty);
    expect(mine.every((i) => i.reporterId == student.uid), isTrue);
    expect(provider.scoped(staff).length, greaterThan(mine.length));
  });

  test('submit adds a Submitted report at the top', () async {
    final provider = IncidentProvider();
    final before = provider.scoped(student).length;

    await provider.submit(
      user: student,
      title: '  Broken window  ',
      description: 'The window in Room 204 will not close.',
      category: IncidentCategory.facilities,
      location: 'Block B, Room 204',
    );

    final list = provider.scoped(student);
    expect(list.length, before + 1);
    expect(list.first.title, 'Broken window');
    expect(list.first.status, IncidentStatus.submitted);
    expect(provider.submitting, isFalse);
  });

  test('updateStatus changes status and appends history', () {
    final provider = IncidentProvider();
    final id = provider.scoped(staff).firstWhere(
        (i) => i.status == IncidentStatus.submitted).id;
    final historyBefore = provider.byId(id)!.history.length;

    provider.updateStatus(id, IncidentStatus.resolved);

    final updated = provider.byId(id)!;
    expect(updated.status, IncidentStatus.resolved);
    expect(updated.history.length, historyBefore + 1);
    expect(updated.timeFor(IncidentStatus.resolved), isNotNull);
  });

  test('filters narrow results and clearFilters resets them', () {
    final provider = IncidentProvider();
    final all = provider.filtered(staff).length;

    provider.setStatusFilter(IncidentStatus.resolved);
    expect(provider.filtered(staff).every(
        (i) => i.status == IncidentStatus.resolved), isTrue);

    provider.setQuery('zzz-no-match');
    expect(provider.filtered(staff), isEmpty);

    provider.clearFilters();
    expect(provider.filtered(staff).length, all);
  });

  test('delete removes the report', () {
    final provider = IncidentProvider();
    final id = provider.scoped(student).first.id;

    provider.delete(id);

    expect(provider.byId(id), isNull);
  });
}
