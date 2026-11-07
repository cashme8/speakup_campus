import 'package:flutter/material.dart';
import '../models/incident.dart';

/// Shows the attached photo, or a tinted category icon when there is none.
class IncidentImage extends StatelessWidget {
  final Incident incident;
  final double? width;
  final double height;
  final double radius;
  final BoxFit fit;

  const IncidentImage(
    this.incident, {
    super.key,
    this.width,
    required this.height,
    this.radius = 12,
    this.fit = BoxFit.cover,
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
    if (incident.imageUrl != null) {
      child = Image.network(
        incident.imageUrl!,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (_, img, progress) => progress == null
            ? img
            : Container(
                width: width,
                height: height,
                color: cat.color.withValues(alpha: 0.08),
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
        errorBuilder: (_, _, _) => placeholder,
      );
    }
    return ClipRRect(borderRadius: BorderRadius.circular(radius), child: child);
  }
}
