import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:speakup_campus/data/repositories.dart';
import 'package:speakup_campus/models/app_user.dart';
import 'package:speakup_campus/providers/incident_provider.dart';
import 'package:speakup_campus/utils/constants.dart';
import 'support/fakes.dart';
import 'support/seed_data.dart';

AppUser _user(String email, UserRole role,
        {String name = 'Test User', bool verified = true}) =>
    AppUser(
      uid: email,
      name: name,
      email: email,
      department: 'Business',
      role: role,
      emailVerified: verified,
    );

final student = _user(demoStudentEmail, UserRole.student);
final other = _user('other@alustudent.com', UserRole.student);
final staff = _user(demoStaffEmail, UserRole.staff, name: 'Facilities Team');

late FakeIncidentRepository repo;
late FakePhotoStorage storage;

/// A provider bound to [user] with the seed data delivered by the stream.
Future<IncidentProvider> make([AppUser? user]) async {
  repo = FakeIncidentRepository();
  storage = FakePhotoStorage();
  final p = IncidentProvider(repository: repo, storage: storage)
    ..bindUser(user ?? student);
  await pumpEventQueue();
  return p;
}

void main() {
  group('session binding', () {
    test('does not listen until a verified user is bound', () async {
      final p = IncidentProvider(
          repository: FakeIncidentRepository(), storage: FakePhotoStorage())
        ..bindUser(_user('x@alustudent.com', UserRole.student,
            verified: false));
      await pumpEventQueue();
      expect(p.scoped(staff), isEmpty);
      expect(p.loading, isFalse);
    });

    test('logout clears data and filters', () async {
      final p = await make();
      p.setQuery('water');
      p.bindUser(null);
      expect(p.scoped(staff), isEmpty);
      expect(p.query, isEmpty);
    });
  });

  group('views', () {
    test('students only see their own reports, staff see all', () async {
      final p = await make();
      final mine = p.scoped(student);
      expect(mine, isNotEmpty);
      expect(mine.every((i) => i.reporterId == student.uid), isTrue);
      expect(p.scoped(staff).length, greaterThan(mine.length));
    });

    test('campus scope lets students browse every report', () async {
      final p = await make();
      final mineCount = p.browsable(student).length;
      p.setScope(ReportScope.campus);
      expect(p.browsable(student).length, p.scoped(staff).length);
      expect(p.stats(student).total, mineCount); // stats stay personal
    });

    test('filters narrow results and clearFilters resets them', () async {
      final p = await make();
      final all = p.filtered(staff).length;
      p.setStatusFilter(IncidentStatus.resolved);
      expect(p.filtered(staff).every((i) => i.status == IncidentStatus.resolved),
          isTrue);
      p.setQuery('zzz-no-match');
      expect(p.filtered(staff), isEmpty);
      p.clearFilters();
      expect(p.filtered(staff).length, all);
    });

    test('showOwnReports resets filters and applies one status', () async {
      final p = await make();
      p
        ..setScope(ReportScope.campus)
        ..setQuery('water')
        ..setCategoryFilter(IncidentCategory.water)
        ..showOwnReports(status: IncidentStatus.resolved);
      expect(p.scope, ReportScope.mine);
      expect(p.query, isEmpty);
      expect(p.categoryFilter, isNull);
      expect(p.statusFilter, IncidentStatus.resolved);
    });

    test('openAt lists unresolved reports at a location', () async {
      final p = await make();
      expect(p.openAt('Student Residence'), isNotEmpty);
      expect(p.openAt('Cafeteria'), isEmpty); // only one, resolved
    });
  });

  group('submit', () {
    test('writes a Submitted report that arrives via the stream', () async {
      final p = await make();
      final before = p.scoped(student).length;
      await p.submit(
        user: student,
        title: '  Broken window  ',
        description: 'The window in Room 204 will not close.',
        category: IncidentCategory.facilities,
        location: 'Block B',
        locationDetail: '  Room 204 ',
        isAnonymous: true,
      );
      await pumpEventQueue();

      final created = p.scoped(student).first;
      expect(p.scoped(student).length, before + 1);
      expect(created.title, 'Broken window');
      expect(created.fullLocation, 'Block B · Room 204');
      expect(created.status, IncidentStatus.submitted);
      expect(created.isAnonymous, isTrue);
      expect(p.submitting, isFalse);
    });

    test('uploads the photo first and stores its URL', () async {
      final p = await make();
      await p.submit(
        user: student,
        title: 'Leaking pipe',
        description: 'Water is leaking under the sink.',
        category: IncidentCategory.water,
        location: 'Cafeteria',
        photo: File('fake.jpg'),
      );
      await pumpEventQueue();

      expect(storage.uploaded, hasLength(1));
      expect(p.scoped(student).first.imageUrl, contains(storage.uploaded.first));
    });

    test('a failed write deletes the uploaded photo and rethrows', () async {
      final p = await make();
      repo.failNextWrite = true;
      await expectLater(
        p.submit(
          user: student,
          title: 'Leaking pipe',
          description: 'Water is leaking under the sink.',
          category: IncidentCategory.water,
          location: 'Cafeteria',
          photo: File('fake.jpg'),
        ),
        throwsA(isA<AppException>()),
      );
      expect(storage.deleted, storage.uploaded);
      expect(p.submitting, isFalse);
    });
  });

  group('status updates', () {
    test('staff change status, append history and note', () async {
      final p = await make(staff);
      final id = p
          .scoped(staff)
          .firstWhere((i) => i.status == IncidentStatus.submitted)
          .id;
      final before = p.byId(id)!.history.length;

      await p.updateStatus(id, IncidentStatus.inProgress,
          by: staff, note: 'Electrician on the way');
      await pumpEventQueue();

      final updated = p.byId(id)!;
      expect(updated.status, IncidentStatus.inProgress);
      expect(updated.history.length, before + 1);
      expect(updated.history.last.note, 'Electrician on the way');
      expect(updated.history.last.byName, 'Facilities Team');
    });

    test('students cannot update status', () async {
      final p = await make();
      final id = p.scoped(student).first.id;
      expect(
        () => p.updateStatus(id, IncidentStatus.resolved, by: student),
        throwsStateError,
      );
    });
  });

  group('me too, privacy and delete', () {
    test('"Me too" toggles on and off and ignores the owner', () async {
      final p = await make(other);
      final id = p.byId('i2')!.id; // Amina's report

      await p.toggleAffected(id, other);
      await pumpEventQueue();
      expect(p.byId(id)!.isConfirmedBy(other), isTrue);

      await p.toggleAffected(id, other);
      await pumpEventQueue();
      expect(p.byId(id)!.isConfirmedBy(other), isFalse);

      final before = p.byId(id)!.affectedBy.length;
      await p.toggleAffected(id, student); // owner
      await pumpEventQueue();
      expect(p.byId(id)!.affectedBy.length, before);
    });

    test('reporter name is hidden according to role and anonymity', () async {
      final p = await make();
      final anon = p.byId('i5')!; // anonymous seed report
      expect(anon.reporterLabelFor(staff), 'Anonymous student');
      expect(anon.reporterLabelFor(other), 'Anonymous student');

      final named = p.byId('i4')!;
      expect(named.reporterLabelFor(staff), named.reporterName);
      expect(named.reporterLabelFor(other), 'A student');
      expect(p.byId('i1')!.reporterLabelFor(student), 'You');
    });

    test('delete removes the report and its photo', () async {
      final p = await make();
      await p.submit(
        user: student,
        title: 'Broken lamp',
        description: 'The lamp by the gate is broken.',
        category: IncidentCategory.electricity,
        location: 'Main Gate',
        photo: File('fake.jpg'),
      );
      await pumpEventQueue();
      final id = p.scoped(student).first.id;

      await p.delete(id);
      await pumpEventQueue();

      expect(p.byId(id), isNull);
      expect(storage.deleted, hasLength(1));
    });
  });
}
