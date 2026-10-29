import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF6C47FF);
  static const primaryDark = Color(0xFF5530E6);
  static const background = Color(0xFFF8F7FC);
  static const ink = Color(0xFF1B1A2E);
  static const muted = Color(0xFF7A7891);
  static const border = Color(0xFFE8E6F2);
}

enum UserRole { student, staff }

enum IncidentStatus {
  submitted('Submitted', Color(0xFFB7791F), Color(0xFFFFF1CC)),
  inProgress('In Progress', Color(0xFF6C47FF), Color(0xFFEAE4FF)),
  resolved('Resolved', Color(0xFF1F9D55), Color(0xFFDDF5E6));

  const IncidentStatus(this.label, this.color, this.background);
  final String label;
  final Color color;
  final Color background;
}

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

const campusLocations = [
  'Student Residence',
  'Cafeteria',
  'Library',
  'Block A, Lecture Hall',
  'Block B, Room 204',
  'Block C, Computer Lab',
  'Sports Field',
  'Main Gate',
  'Parking Lot',
];

const departments = [
  'Computer Science',
  'Business',
  'Engineering',
  'Entrepreneurial Leadership',
  'Other',
];
