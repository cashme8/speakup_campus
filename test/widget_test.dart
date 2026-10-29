import 'package:flutter_test/flutter_test.dart';
import 'package:speakup_campus/main.dart';
import 'package:speakup_campus/utils/validators.dart';

void main() {
  testWidgets('app starts on the login screen', (tester) async {
    await tester.pumpWidget(const CampusIncidentApp());

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });

  test('ALU email validator accepts only allowed domains', () {
    expect(Validators.aluEmail('amina@alustudent.com'), isNull);
    expect(Validators.aluEmail('staff@alueducation.com'), isNull);
    expect(Validators.aluEmail('someone@gmail.com'), isNotNull);
    expect(Validators.aluEmail('not-an-email'), isNotNull);
  });
}
