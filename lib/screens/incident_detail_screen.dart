import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_user.dart';
import '../models/incident.dart';
import '../providers/auth_provider.dart';
import '../providers/incident_provider.dart';
import '../utils/constants.dart';
import '../utils/format.dart';
import '../widgets/app_card.dart';
import '../widgets/incident_image.dart';
import '../widgets/notice_banner.dart';
import '../widgets/primary_button.dart';
import '../widgets/section_header.dart';
import '../widgets/status_chip.dart';
import '../widgets/status_timeline.dart';
import '../widgets/status_update_sheet.dart';

class IncidentDetailScreen extends StatelessWidget {
  final String incidentId;
  const IncidentDetailScreen({super.key, required this.incidentId});

  static Future<void> open(BuildContext context, String id) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => IncidentDetailScreen(incidentId: id)),
      );

  Future<void> _confirmDelete(BuildContext context) async {
    final provider = context.read<IncidentProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Withdraw this report?'),
        content: const Text(
            'Staff have not started on it yet. Withdrawing deletes it '
            'permanently.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(d, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              child: const Text('Withdraw')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await provider.delete(incidentId);
      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Report withdrawn')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
          content: Text(errorMessage(e, 'Could not withdraw the report.'))));
    }
  }

  Future<void> _updateStatus(
      BuildContext context, Incident incident, AppUser staff) async {
    final provider = context.read<IncidentProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final result = await StatusUpdateSheet.show(context, incident.status);
    if (result == null) return;
    try {
      await provider.updateStatus(incident.id, result.status,
          by: staff, note: result.note);
      messenger.showSnackBar(SnackBar(
          content: Text('Status updated to ${result.status.label}')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
          content: Text(
              errorMessage(e, 'Could not update the status. Try again.'))));
    }
  }

  Future<void> _toggleAffected(
      BuildContext context, Incident incident, AppUser user) async {
    final messenger = ScaffoldMessenger.of(context);
    final wasConfirmed = incident.isConfirmedBy(user);
    try {
      await context.read<IncidentProvider>().toggleAffected(incident.id, user);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(
          content: Text(wasConfirmed
              ? 'Removed your confirmation'
              : 'Thanks! Staff can see more students are affected.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
          content:
              Text(errorMessage(e, 'Something went wrong. Try again.'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Null for one frame while signing out, before AuthGate swaps to login.
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const SizedBox.shrink();
    final incident = context.watch<IncidentProvider>().byId(incidentId);

    if (incident == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Incident Details')),
        body: const Center(child: Text('This report is no longer available.')),
      );
    }

    final isOwner = incident.isOwnedBy(user);
    final canDelete = isOwner && incident.status == IncidentStatus.submitted;
    final canConfirm = !isOwner && !user.isStaff;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident Details'),
        actions: [
          if (canDelete)
            PopupMenuButton<String>(
              tooltip: 'More options',
              onSelected: (_) => _confirmDelete(context),
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.delete_outline, color: AppColors.danger),
                    title: Text('Withdraw report'),
                  ),
                ),
              ],
            ),
        ],
      ),
      bottomNavigationBar: user.isStaff
          ? _BottomAction(
              child: PrimaryButton(
                label: 'Update status',
                icon: Icons.sync_alt_rounded,
                onPressed: () => _updateStatus(context, incident, user),
              ),
            )
          : canConfirm
              ? _BottomAction(
                  child: _MeTooButton(
                    confirmed: incident.isConfirmedBy(user),
                    count: incident.affectedBy.length,
                    enabled: incident.status != IncidentStatus.resolved,
                    onPressed: () => _toggleAffected(context, incident, user),
                  ),
                )
              : null,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            _SummaryCard(incident: incident, viewer: user),
            if (isOwner) ...[
              const SizedBox(height: 12),
              NoticeBanner(incident.status.meaning, type: NoticeType.info),
            ],
            const SizedBox(height: 22),
            const SectionHeader(title: 'Status Timeline', fontSize: 16),
            const SizedBox(height: 10),
            AppCard(child: StatusTimeline(incident)),
            const SizedBox(height: 22),
            const SectionHeader(title: 'Description', fontSize: 16),
            const SizedBox(height: 8),
            Text(incident.description,
                style: const TextStyle(height: 1.55, fontSize: 14)),
            if (incident.hasImage) ...[
              const SizedBox(height: 22),
              const SectionHeader(title: 'Attached Photo', fontSize: 16),
              const SizedBox(height: 10),
              Semantics(
                button: true,
                label: 'View photo full screen',
                child: GestureDetector(
                  onTap: () => _PhotoViewer.open(context, incident),
                  child: IncidentImage(incident,
                      width: double.infinity, height: 210, radius: 16),
                ),
              ),
            ],
            const SizedBox(height: 22),
            const SectionHeader(title: 'Activity', fontSize: 16),
            const SizedBox(height: 10),
            AppCard(child: ActivityLog(incident)),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final Incident incident;
  final AppUser viewer;
  const _SummaryCard({required this.incident, required this.viewer});

  @override
  Widget build(BuildContext context) {
    const meta = TextStyle(color: AppColors.muted, fontSize: 12);
    final cat = incident.category;
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IncidentImage(incident, width: 76, height: 76),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(incident.title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(incident.fullLocation,
                    style:
                        const TextStyle(color: AppColors.muted, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StatusChip(incident.status),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: cat.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(cat.icon, size: 13, color: cat.color),
                          const SizedBox(width: 4),
                          Text(cat.label,
                              style: TextStyle(
                                  color: cat.color,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _MetaRow(Icons.calendar_today_outlined,
                    'Submitted on ${stamp(incident.createdAt)}', meta),
                _MetaRow(Icons.person_outline,
                    'Reported by ${incident.reporterLabelFor(viewer)}', meta),
                if (incident.affectedBy.isNotEmpty)
                  _MetaRow(
                      Icons.people_outline,
                      '${incident.affectedBy.length} other student'
                      '${incident.affectedBy.length == 1 ? '' : 's'} affected',
                      meta),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final TextStyle style;
  const _MetaRow(this.icon, this.text, this.style);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Icon(icon, size: 13, color: AppColors.muted),
          const SizedBox(width: 5),
          Expanded(child: Text(text, style: style)),
        ],
      ),
    );
  }
}

class _BottomAction extends StatelessWidget {
  final Widget child;
  const _BottomAction({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: child,
        ),
      ),
    );
  }
}

class _MeTooButton extends StatelessWidget {
  final bool confirmed;
  final bool enabled;
  final int count;
  final VoidCallback onPressed;

  const _MeTooButton({
    required this.confirmed,
    required this.enabled,
    required this.count,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final label = confirmed ? 'You are affected too' : 'This affects me too';
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: Icon(confirmed ? Icons.check_circle : Icons.front_hand_outlined),
        label: Text(count > 0 ? '$label  ·  $count' : label),
        style: OutlinedButton.styleFrom(
          backgroundColor: confirmed ? AppColors.primarySoft : Colors.white,
          side: BorderSide(
              color: confirmed ? AppColors.primary : AppColors.border),
        ),
      ),
    );
  }
}

class _PhotoViewer extends StatelessWidget {
  final Incident incident;
  const _PhotoViewer(this.incident);

  static void open(BuildContext context, Incident incident) {
    Navigator.push(
      context,
      MaterialPageRoute(
          fullscreenDialog: true, builder: (_) => _PhotoViewer(incident)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(incident.title,
            style: const TextStyle(color: Colors.white, fontSize: 16)),
      ),
      body: Center(
        child: InteractiveViewer(
          maxScale: 4,
          child: IncidentImage(incident,
              width: double.infinity,
              height: MediaQuery.sizeOf(context).height * 0.7,
              radius: 0,
              fit: BoxFit.contain),
        ),
      ),
    );
  }
}
