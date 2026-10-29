import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/incident_provider.dart';
import '../utils/constants.dart';
import '../utils/format.dart';
import '../widgets/summary_tile.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final stats = context.watch<IncidentProvider>().stats(user);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          const Text('Profile',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFFEEE9FF),
                  child: Text(initials(user.name),
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(user.name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800)),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEE9FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(user.isStaff ? 'Staff' : 'Student',
                                style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _InfoRow(Icons.school_outlined, user.department),
                      _InfoRow(Icons.location_on_outlined, user.location),
                      _InfoRow(Icons.mail_outline, user.email),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: SummaryTile(
                  icon: Icons.description_outlined,
                  count: stats.total,
                  label: user.isStaff ? 'Total Reports' : 'My Reports',
                  color: AppColors.primary,
                  background: const Color(0xFFEEE9FF),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SummaryTile(
                  icon: Icons.schedule,
                  count: stats.inProgress,
                  label: 'In Progress',
                  color: const Color(0xFF2F80ED),
                  background: const Color(0xFFE6F0FF),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SummaryTile(
                  icon: Icons.check_circle_outline,
                  count: stats.resolved,
                  label: 'Resolved',
                  color: const Color(0xFF1F9D55),
                  background: const Color(0xFFDDF5E6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          OutlinedButton.icon(
            onPressed: () => context.read<AuthProvider>().logout(),
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              foregroundColor: Colors.red.shade600,
              side: BorderSide(color: Colors.red.shade200),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.muted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(color: AppColors.muted, fontSize: 12.5)),
          ),
        ],
      ),
    );
  }
}
