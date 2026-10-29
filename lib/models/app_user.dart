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
    required this.location,
    required this.role,
    required this.emailVerified,
  });

  bool get isStaff => role == UserRole.staff;
  String get firstName => name.trim().split(' ').first;

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
