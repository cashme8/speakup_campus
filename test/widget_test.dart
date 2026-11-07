import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speakup_campus/utils/validators.dart';
import 'support/fakes.dart';

void main() {
  testWidgets('app starts on the login screen when signed out',
      (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(find.text('Welcome back 👋'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('register -> verify email -> home', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    final auth = FakeAuthRepository();
    await tester.pumpWidget(buildTestApp(auth: auth));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create a student account'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Grace Uwase');
    await tester.tap(find.text('Select your department'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Business').last);
    await tester.pumpAndSettle();
    await tester.enterText(fields.at(1), 'grace@alustudent.com');
    await tester.enterText(fields.at(2), 'secret123');
    await tester.enterText(fields.at(3), 'secret123');
    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Check your inbox'), findsOneWidget);
    expect(auth.verificationEmailsSent, 1);

    auth.verifyEmail('grace@alustudent.com');
    await tester.tap(find.text('I’ve verified, continue'));
    await tester.pumpAndSettle();
    expect(find.text('Hello, Grace 👋'), findsOneWidget);
  });

  test('ALU email validator accepts only allowed domains', () {
    expect(Validators.aluEmail('amina@alustudent.com'), isNull);
    expect(Validators.aluEmail('staff@alueducation.com'), isNull);
    expect(Validators.aluEmail('g.kabanda+staff@alustudent.com'), isNull);
    expect(Validators.aluEmail('someone@gmail.com'), isNotNull);
    expect(Validators.aluEmail('not-an-email'), isNotNull);
  });
}
