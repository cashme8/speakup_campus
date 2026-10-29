import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/incident_provider.dart';
import '../utils/constants.dart';
import '../utils/format.dart';
import '../widgets/incident_image.dart';
import '../widgets/status_chip.dart';
import '../widgets/status_timeline.dart';

class IncidentDetailScreen extends StatelessWidget {
  final String incidentId;
  const IncidentDetailScreen({super.key, required this.incidentId});

  Future<void> _confirmDelete(BuildContext context) async {
    final provider = context.read<IncidentProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Delete this report?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(d, true),
              child: Text('Delete',
                  style: TextStyle(color: Colors.red.shade600))),
        ],
      ),
    );
    if (ok == true) {
      navigator.pop();
      provider.delete(incidentId);
      messenger.showSnackBar(const SnackBar(content: Text('Report deleted')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final incident = context.watch<IncidentProvider>().byId(incidentId);

    if (incident == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Incident Details')),
        body: const Center(child: Text('This report is no longer available.')),
      );
    }

    final canDelete =
        incident.reporterId == user.uid && incident.status == IncidentStatus.submitted;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident Details'),
        actions: [
          if (canDelete)
            PopupMenuButton<String>(
              onSelected: (_) => _confirmDelete(context),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'delete', child: Text('Delete report')),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            // Summary card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IncidentImage(incident, width: 64, height: 64),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(incident.title,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(incident.location,
                            style: const TextStyle(
                                color: AppColors.muted, fontSize: 13)),
                        const SizedBox(height: 8),
                        StatusChip(incident.status),
                        const SizedBox(height: 8),
                        Text('Submitted on ${stamp(incident.createdAt)}',
                            style: const TextStyle(
                                color: AppColors.muted, fontSize: 12)),
                        Text('Reported by ${incident.reporterName}',
                            style: const TextStyle(
                                color: AppColors.muted, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Timeline
            const Text('Status Timeline',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: StatusTimeline(incident),
            ),

            // Staff controls
            if (user.isStaff) ...[
              const SizedBox(height: 22),
              const Text('Update status',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<IncidentStatus>(
                  showSelectedIcon: false,
                  segments: [
                    for (final s in IncidentStatus.values)
                      ButtonSegment(
                        value: s,
                        label: Text(s.label,
                            style: const TextStyle(fontSize: 12)),
                      ),
                  ],
                  selected: {incident.status},
                  onSelectionChanged: (sel) {
                    context
                        .read<IncidentProvider>()
                        .updateStatus(incident.id, sel.first);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content:
                            Text('Status updated to ${sel.first.label}')));
                  },
                ),
              ),
            ],

            const SizedBox(height: 22),
            const Text('Description',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(incident.description,
                style: const TextStyle(height: 1.5, color: AppColors.ink)),

            if (incident.hasImage) ...[
              const SizedBox(height: 22),
              const Text('Attached Photo',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              IncidentImage(incident,
                  width: double.infinity, height: 200, radius: 16),
            ],
          ],
        ),
      ),
    );
  }
}
