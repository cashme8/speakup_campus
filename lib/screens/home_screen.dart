import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/incident_provider.dart';
import '../utils/constants.dart';
import '../widgets/empty_state.dart';
import '../widgets/incident_card.dart';
import '../widgets/section_header.dart';
import '../widgets/summary_tile.dart';
import '../widgets/user_avatar.dart';
import 'incident_detail_screen.dart';
import 'report_form_screen.dart';

class HomeScreen extends StatelessWidget {
  /// Switches to the Reports tab, optionally pre-filtered by status.
  final void Function(IncidentStatus? status) onOpenReports;
  final VoidCallback onOpenProfile;

  const HomeScreen({
    super.key,
    required this.onOpenReports,
    required this.onOpenProfile,
  });

  @override
  Widget build(BuildContext context) {
    // Null for one frame while signing out, before AuthGate swaps to login.
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const SizedBox.shrink();
    final incidents = context.watch<IncidentProvider>();
    final stats = incidents.stats(user);
    final recent = incidents.recent(user);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          _Greeting(
            name: user.name,
            firstName: user.firstName,
            isStaff: user.isStaff,
            onAvatarTap: onOpenProfile,
          ),
          const SizedBox(height: 20),
          _HeroCard(
            isStaff: user.isStaff,
            waiting: stats.submitted,
            onPrimary: user.isStaff
                ? () => onOpenReports(IncidentStatus.submitted)
                : () => ReportFormScreen.open(context),
          ),
          if (!user.isStaff) ...[
            const SizedBox(height: 24),
            const SectionHeader(title: 'Quick report'),
            const SizedBox(height: 10),
            const _QuickReportRow(),
          ],
          const SizedBox(height: 24),
          SectionHeader(
            title: user.isStaff ? 'Campus Overview' : 'Report Summary',
            actionLabel: 'See all',
            onAction: () => onOpenReports(null),
          ),
          const SizedBox(height: 10),
          StatsRow(
            stats: stats,
            totalLabel: user.isStaff ? 'Total' : 'My Reports',
            onTap: onOpenReports,
          ),
          const SizedBox(height: 24),
          SectionHeader(
            title: 'Recent Reports',
            actionLabel: recent.isEmpty ? null : 'See all',
            onAction: () => onOpenReports(null),
          ),
          const SizedBox(height: 10),
          if (recent.isEmpty)
            EmptyState(
              icon: Icons.inbox_outlined,
              title: 'No reports yet',
              message: user.isStaff
                  ? 'New reports from students will appear here.'
                  : 'See something broken? Report it and track the fix here.',
              actionLabel: user.isStaff ? null : 'Report an issue',
              onAction: () => ReportFormScreen.open(context),
            )
          else
            for (final i in recent)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: IncidentCard(
                  incident: i,
                  onTap: () => IncidentDetailScreen.open(context, i.id),
                ),
              ),
        ],
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  final String name, firstName;
  final bool isStaff;
  final VoidCallback onAvatarTap;

  const _Greeting({
    required this.name,
    required this.firstName,
    required this.isStaff,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hello, $firstName 👋',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                isStaff
                    ? 'Review new reports and keep students informed.'
                    : 'Help make our campus safer.\nReport issues and track their resolution.',
                style: const TextStyle(
                    color: AppColors.muted, height: 1.45, fontSize: 13.5),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Semantics(
          button: true,
          label: 'Open profile',
          child: GestureDetector(
            onTap: onAvatarTap,
            child: UserAvatar(name: name),
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  final bool isStaff;
  final int waiting;
  final VoidCallback onPrimary;

  const _HeroCard({
    required this.isStaff,
    required this.waiting,
    required this.onPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final title = isStaff
        ? (waiting == 0
            ? 'All caught up!'
            : '$waiting report${waiting == 1 ? '' : 's'}\nwaiting for review')
        : 'See an issue\non campus?';
    final subtitle = isStaff
        ? 'Open a report to update its status and leave a note.'
        : 'Report it and help improve our learning environment.';

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF6C47FF), Color(0xFFA48BFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Campus photo, faded in from the right under a purple gradient
          // so the white text on the left stays readable.
          Positioned.fill(
            child: Image.asset(
              'assets/images/campus_aerial.jpg',
              fit: BoxFit.cover,
              excludeFromSemantics: true,
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xFA5530E6),
                    Color(0xE66C47FF),
                    Color(0x806C47FF),
                  ],
                  stops: [0, 0.55, 1],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.2),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 220,
                  child: Text(subtitle,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 13, height: 1.4)),
                ),
                const SizedBox(height: 16),
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: onPrimary,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 13),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle),
                            child: Icon(
                                isStaff ? Icons.checklist_rounded : Icons.add,
                                size: 18,
                                color: Colors.white),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                                isStaff ? 'Review reports' : 'Report an Issue',
                                style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800)),
                          ),
                          const Icon(Icons.chevron_right,
                              color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One-tap shortcuts that open the form with the category pre-selected.
class _QuickReportRow extends StatelessWidget {
  const _QuickReportRow();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: IncidentCategory.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final c = IncidentCategory.values[i];
          return Semantics(
            button: true,
            label: 'Report a ${c.label} issue',
            excludeSemantics: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => ReportFormScreen.open(context, category: c),
              child: SizedBox(
                width: 64,
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: c.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(c.icon, color: c.color, size: 26),
                    ),
                    const SizedBox(height: 6),
                    Text(c.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11.5, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
