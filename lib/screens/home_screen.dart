import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/incident_provider.dart';
import '../utils/constants.dart';
import '../utils/format.dart';
import '../widgets/empty_state.dart';
import '../widgets/incident_card.dart';
import '../widgets/summary_tile.dart';
import 'incident_detail_screen.dart';
import 'report_form_screen.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onSeeAll;
  const HomeScreen({super.key, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final incidents = context.watch<IncidentProvider>();
    final stats = incidents.stats(user);
    final recent = incidents.recent(user);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          // Greeting
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hello, ${user.firstName} 👋',
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(
                      user.isStaff
                          ? 'Review reports and keep students updated.'
                          : 'Help make our campus safer.\nReport issues and track their resolution.',
                      style: const TextStyle(
                          color: AppColors.muted, height: 1.4, fontSize: 13.5),
                    ),
                  ],
                ),
              ),
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFEEE9FF),
                child: Text(initials(user.name),
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Hero card
          _HeroCard(isStaff: user.isStaff, onSeeAll: onSeeAll),
          const SizedBox(height: 24),

          // Summary
          _SectionHeader(
            title: user.isStaff ? 'All Reports' : 'Report Summary',
            onSeeAll: onSeeAll,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SummaryTile(
                  icon: Icons.description_outlined,
                  count: stats.total,
                  label: user.isStaff ? 'Total' : 'My Reports',
                  color: AppColors.primary,
                  background: const Color(0xFFEEE9FF),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SummaryTile(
                  icon: Icons.schedule,
                  count: stats.inProgress,
                  label: 'In Progress',
                  color: const Color(0xFF2F80ED),
                  background: const Color(0xFFE6F0FF),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SummaryTile(
                  icon: Icons.check_circle_outline,
                  count: stats.resolved,
                  label: 'Resolved',
                  color: const Color(0xFF1F9D55),
                  background: const Color(0xFFDDF5E6),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SummaryTile(
                  icon: Icons.error_outline,
                  count: stats.submitted,
                  label: 'Submitted',
                  color: const Color(0xFFE5484D),
                  background: const Color(0xFFFFE6E6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Recent
          _SectionHeader(title: 'Recent Reports', onSeeAll: onSeeAll),
          const SizedBox(height: 12),
          if (recent.isEmpty)
            EmptyState(
              icon: Icons.inbox_outlined,
              title: 'No reports yet',
              message: user.isStaff
                  ? 'New reports from students will appear here.'
                  : 'See something broken? Report it and we will keep you updated.',
              actionLabel: user.isStaff ? null : 'Report an issue',
              onAction: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportFormScreen()),
              ),
            )
          else
            for (final i in recent)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: IncidentCard(
                  incident: i,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => IncidentDetailScreen(incidentId: i.id)),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final bool isStaff;
  final VoidCallback onSeeAll;
  const _HeroCard({required this.isStaff, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF7B5CFF), Color(0xFF9B7BFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isStaff ? 'Reports waiting\nfor review' : 'See an issue\non campus?',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1.2),
          ),
          const SizedBox(height: 6),
          Text(
            isStaff
                ? 'Open a report to update its status.'
                : 'Report it and help improve our learning environment.',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: isStaff
                  ? onSeeAll
                  : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ReportFormScreen()),
                      ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                          color: AppColors.primary, shape: BoxShape.circle),
                      child: Icon(isStaff ? Icons.checklist : Icons.add,
                          size: 18, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(isStaff ? 'Review reports' : 'Report an Issue',
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800)),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.primary),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;
  const _SectionHeader({required this.title, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title,
              style:
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        ),
        GestureDetector(
          onTap: onSeeAll,
          child: const Text('See all',
              style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13)),
        ),
      ],
    );
  }
}
