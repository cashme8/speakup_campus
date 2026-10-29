import 'package:flutter_test/flutter_test.dart';
import 'package:speakup_campus/data/mock_data.dart';
import 'package:speakup_campus/providers/auth_provider.dart';
import 'package:speakup_campus/utils/constants.dart';

void main() {
  test('login rejects short passwords', () async {
    final auth = AuthProvider();
    final ok = await auth.login(demoStudentEmail, '123');

    expect(ok, isFalse);
    expect(auth.isLoggedIn, isFalse);
    expect(auth.error, isNotNull);
  });

  test('student login gives a verified student', () async {
    final auth = AuthProvider();
    await auth.login(demoStudentEmail, 'password123');

    expect(auth.isLoggedIn, isTrue);
    expect(auth.user!.role, UserRole.student);
    expect(auth.user!.emailVerified, isTrue);
  });

  test('staff email logs in as staff', () async {
    final auth = AuthProvider();
    await auth.login(demoStaffEmail, 'password123');

    expect(auth.user!.isStaff, isTrue);
  });

  test('register creates an unverified student until verified', () async {
    final auth = AuthProvider();
    await auth.register(
      name: 'New Student',
      department: 'Business',
      email: 'new@alustudent.com',
      password: 'password123',
    );
    expect(auth.user!.emailVerified, isFalse);
    expect(auth.user!.role, UserRole.student);

    await auth.checkVerified();
    expect(auth.user!.emailVerified, isTrue);
  });

  test('logout clears the user', () async {
    final auth = AuthProvider();
    await auth.login(demoStudentEmail, 'password123');
    auth.logout();

    expect(auth.isLoggedIn, isFalse);
  });
}
