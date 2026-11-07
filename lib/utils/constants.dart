import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF6C47FF);
  static const primaryDark = Color(0xFF5530E6);
  static const primarySoft = Color(0xFFEEE9FF);
  static const background = Color(0xFFF8F7FC);
  static const ink = Color(0xFF1B1A2E);
  static const muted = Color(0xFF7A7891);
  static const border = Color(0xFFE8E6F2);
  static const danger = Color(0xFFE5484D);
  static const dangerSoft = Color(0xFFFFE6E6);
  static const info = Color(0xFF2F80ED);
  static const infoSoft = Color(0xFFE6F0FF);
  static const success = Color(0xFF1F9D55);
  static const successSoft = Color(0xFFDDF5E6);
}

const appFontFamily = 'PlusJakartaSans';

/// Shortest title/description we accept; also used by validators and tests.
const minTitleLength = 5;
const maxTitleLength = 60;
const minDescriptionLength = 15;
const maxDescriptionLength = 500;

enum UserRole { student, staff }

enum IncidentStatus {
  submitted('Submitted', Color(0xFFB7791F), Color(0xFFFFF1CC),
      Icons.outbox_rounded, 'Waiting for the facilities team to review.'),
  inProgress('In Progress', Color(0xFF6C47FF), Color(0xFFEAE4FF),
      Icons.engineering_outlined, 'Staff are working on this issue.'),
  resolved('Resolved', Color(0xFF1F9D55), Color(0xFFDDF5E6),
      Icons.check_circle_outline, 'The issue has been fixed.');

  const IncidentStatus(
      this.label, this.color, this.background, this.icon, this.meaning);
  final String label;
  final Color color;
  final Color background;
  final IconData icon;

  /// Plain-language explanation shown to students.
  final String meaning;
}

/// Students can look at their own reports or everything on campus
/// (to check for duplicates before filing a new one).
enum ReportScope { mine, campus }

enum IncidentCategory {
  facilities('Facilities', Icons.apartment_rounded, Color(0xFF6C47FF)),
  water('Water', Icons.water_drop_outlined, Color(0xFF2F80ED)),
  electricity('Electricity', Icons.bolt_rounded, Color(0xFFE0A100)),
  safety('Safety', Icons.shield_outlined, Color(0xFFE5484D)),
  sanitation('Sanitation', Icons.delete_outline_rounded, Color(0xFF1F9D55)),
  furniture('Furniture', Icons.chair_alt_outlined, Color(0xFF8E5A3C));

  const IncidentCategory(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

/// Replace with the domains your school actually uses.
const allowedEmailDomains = ['alustudent.com', 'alueducation.com'];

/// Campus areas. The exact room/spot goes in the optional detail field.
const campusLocations = [
  'Block A',
  'Block B',
  'Block C',
  'Cafeteria',
  'Library',
  'Student Residence',
  'Sports Field',
  'Main Gate',
  'Parking Lot',
  'Other',
];

const departments = [
  'Computer Science',
  'Business',
  'Engineering',
  'Entrepreneurial Leadership',
  'Other',
];
