import 'package:flutter_test/flutter_test.dart';
import 'package:speakup_campus/providers/auth_provider.dart';
import 'package:speakup_campus/utils/constants.dart';
import 'support/fakes.dart';
import 'support/seed_data.dart';

void main() {
  late FakeAuthRepository repo;
  late AuthProvider auth;

  setUp(() async {
    repo = FakeAuthRepository();
    auth = AuthProvider(repo);
    await pumpEventQueue();
  });

  test('starts initialising, then signed out', () async {
    final fresh = AuthProvider(FakeAuthRepository());
    expect(fresh.initializing, isTrue);
    await pumpEventQueue();
    expect(fresh.initializing, isFalse);
    expect(fresh.isLoggedIn, isFalse);
  });

  test('wrong password shows an error and stays signed out', () async {
    final ok = await auth.login(demoStudentEmail, 'nope-nope');
    await pumpEventQueue();

    expect(ok, isFalse);
    expect(auth.isLoggedIn, isFalse);
    expect(auth.error, 'Incorrect email or password.');
  });

  test('student and staff roles come from the profile', () async {
    await auth.login(demoStudentEmail, 'password123');
    await pumpEventQueue();
    expect(auth.user!.role, UserRole.student);

    await auth.logout();
    await auth.login(demoStaffEmail, 'password123');
    await pumpEventQueue();
    expect(auth.user!.isStaff, isTrue);
  });

  test('register creates an unverified student and sends the email',
      () async {
    await auth.register(
      name: 'New Student',
      department: 'Business',
      email: 'new@alustudent.com',
      password: 'password123',
    );
    await pumpEventQueue();

    expect(auth.user!.emailVerified, isFalse);
    expect(auth.user!.role, UserRole.student);
    expect(repo.verificationEmailsSent, 1);
  });

  test('register rejects non-ALU emails before calling the backend',
      () async {
    final ok = await auth.register(
      name: 'Outsider',
      department: 'Business',
      email: 'someone@gmail.com',
      password: 'password123',
    );
    expect(ok, isFalse);
    expect(auth.error, contains('ALU email'));
    expect(repo.verificationEmailsSent, 0);
  });

  test('checkVerified fails until the link is clicked, then succeeds',
      () async {
    await auth.register(
      name: 'New Student',
      department: 'Business',
      email: 'new@alustudent.com',
      password: 'password123',
    );
    await pumpEventQueue();

    expect(await auth.checkVerified(), isFalse);
    expect(auth.error, contains('isn’t verified'));

    repo.verifyEmail('new@alustudent.com');
    expect(await auth.checkVerified(), isTrue);
    await pumpEventQueue();
    expect(auth.user!.emailVerified, isTrue);
  });

  test('logout clears the user', () async {
    await auth.login(demoStudentEmail, 'password123');
    await pumpEventQueue();
    await auth.logout();
    await pumpEventQueue();

    expect(auth.isLoggedIn, isFalse);
  });
}
