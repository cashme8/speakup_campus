import 'dart:io';
import 'package:flutter/material.dart';
import '../models/incident.dart';

/// Shows the attached photo, or a tinted category icon when there is none.
class IncidentImage extends StatelessWidget {
  final Incident incident;
  final double? width;
  final double height;
  final double radius;

  const IncidentImage(
    this.incident, {
    super.key,
    this.width,
    required this.height,
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final cat = incident.category;
    final placeholder = Container(
      width: width,
      height: height,
      color: cat.color.withValues(alpha: 0.12),
      child: Icon(cat.icon, color: cat.color, size: height * 0.45),
    );

    Widget child = placeholder;
    if (incident.localImagePath != null) {
      child = Image.file(
        File(incident.localImagePath!),
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
      );
    } else if (incident.imageUrl != null) {
      child = Image.network(
        incident.imageUrl!,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
      );
    }
    return ClipRRect(borderRadius: BorderRadius.circular(radius), child: child);
  }
}
