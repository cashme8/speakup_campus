import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speakup_campus/data/mock_data.dart';
import 'package:speakup_campus/main.dart';

/// End-to-end UI flows on the mock backend. They catch layout overflows and
/// navigation crashes that unit tests on the providers would miss.
Future<void> _login(WidgetTester tester, String email) async {
  tester.view.physicalSize = const Size(1080, 2340); // typical phone
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(const CampusIncidentApp());
  await tester.enterText(find.byType(TextFormField).at(0), email);
  await tester.enterText(find.byType(TextFormField).at(1), 'password123');
  await tester.tap(find.text('Sign in'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('student: home, form validation, reports, detail',
      (tester) async {
    await _login(tester, demoStudentEmail);
    expect(find.text('Hello, Amina 👋'), findsOneWidget);
    expect(find.text('Report an Issue'), findsOneWidget);

    // Submitting an empty form shows validation errors, not a crash.
    await tester.tap(find.text('Report an Issue'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Submit Report'));
    await tester.tap(find.text('Submit Report'));
    await tester.pumpAndSettle();
    expect(find.text('Select a category'), findsWidgets);
    expect(find.text('Title is required'), findsOneWidget);

    // Back with an untouched form leaves without a discard prompt.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Discard this report?'), findsNothing);

    // Reports tab -> campus scope -> open someone else's report.
    await tester.tap(find.text('Reports').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Campus'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Loose stair railing'));
    await tester.pumpAndSettle();
    expect(find.text('Reported by Anonymous student'), findsOneWidget);
    expect(find.text('This affects me too'), findsOneWidget);
    expect(find.text('Update status'), findsNothing);
  });

  testWidgets('signing out returns to login without a crash', (tester) async {
    await _login(tester, demoStudentEmail);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Sign out'), 200,
        scrollable: find.byType(Scrollable).last);
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out').last); // dialog confirm
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Welcome back 👋'), findsOneWidget);
  });

  testWidgets('staff: update a status with a note', (tester) async {
    await _login(tester, demoStaffEmail);
    expect(find.textContaining('waiting for review'), findsOneWidget);

    await tester.tap(find.text('Review reports'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Power outage in the library'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Update status'));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
        of: find.byType(BottomSheet), matching: find.text('In Progress')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Electrician booked');
    await tester.tap(find.text('Save update'));
    await tester.pumpAndSettle();

    expect(find.text('Status updated to In Progress'), findsOneWidget);
    expect(find.text('“Electrician booked”'), findsOneWidget);
  });
}
