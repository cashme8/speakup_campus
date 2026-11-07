import '../utils/constants.dart';

class AppUser {
  final String uid;
  final String name;
  final String email;
  final String department;
  final String location;
  final UserRole role;
  final bool emailVerified;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.department,
    this.location = 'Kigali, Rwanda',
    required this.role,
    required this.emailVerified,
  });

  bool get isStaff => role == UserRole.staff;
  String get firstName => name.trim().split(' ').first;

  /// Firestore `users/{uid}` document. `emailVerified` lives in Firebase
  /// Auth, not Firestore, so it is passed in separately.
  factory AppUser.fromMap(
    String uid,
    Map<String, dynamic> data, {
    required String email,
    required bool emailVerified,
  }) {
    return AppUser(
      uid: uid,
      name: (data['name'] as String?) ?? email.split('@').first,
      email: email,
      department: (data['department'] as String?) ?? 'Not set',
      role: data['role'] == 'staff' ? UserRole.staff : UserRole.student,
      emailVerified: emailVerified,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'department': department,
        'role': role.name,
      };

  AppUser copyWith({bool? emailVerified}) => AppUser(
        uid: uid,
        name: name,
        email: email,
        department: department,
        location: location,
        role: role,
        emailVerified: emailVerified ?? this.emailVerified,
      );
}
