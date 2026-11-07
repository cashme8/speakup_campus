import 'package:flutter/material.dart';
import '../models/incident.dart';
import '../utils/constants.dart';
import '../utils/format.dart';
import 'app_card.dart';
import 'incident_image.dart';
import 'status_chip.dart';

class IncidentCard extends StatelessWidget {
  final Incident incident;
  final VoidCallback onTap;
  const IncidentCard({super.key, required this.incident, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final meta = const TextStyle(color: AppColors.muted, fontSize: 12);
    return Semantics(
      button: true,
      label: '${incident.title}, ${incident.fullLocation}, '
          'status ${incident.status.label}',
      excludeSemantics: true,
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            IncidentImage(incident, width: 60, height: 60),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    incident.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14.5),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    incident.fullLocation,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.muted, fontSize: 12.5),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 12, color: AppColors.muted),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(timeAgo(incident.createdAt),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: meta),
                      ),
                      if (incident.affectedBy.isNotEmpty) ...[
                        const SizedBox(width: 10),
                        const Icon(Icons.people_outline,
                            size: 13, color: AppColors.muted),
                        const SizedBox(width: 3),
                        Text('+${incident.affectedBy.length}', style: meta),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            StatusChip(incident.status),
            const Icon(Icons.chevron_right, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}
