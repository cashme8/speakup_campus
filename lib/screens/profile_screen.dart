import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/incident_provider.dart';
import '../utils/constants.dart';
import '../widgets/app_card.dart';
import '../widgets/section_header.dart';
import '../widgets/summary_tile.dart';
import '../widgets/user_avatar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmSignOut(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You can sign back in with your ALU email.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(d, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              child: const Text('Sign out')),
        ],
      ),
    );
    if (ok == true) await auth.logout();
  }

  @override
  Widget build(BuildContext context) {
    // Null for one frame while signing out, before AuthGate swaps to login.
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const SizedBox.shrink();
    final stats = context.watch<IncidentProvider>().stats(user);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          const Text('Profile',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),
          AppCard(
            radius: 18,
            child: Row(
              children: [
                UserAvatar(name: user.name, radius: 30),
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
                          _RoleBadge(isStaff: user.isStaff),
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
          const SizedBox(height: 16),
          StatsRow(
            stats: stats,
            totalLabel: user.isStaff ? 'Total Reports' : 'My Reports',
            showSubmitted: false,
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Privacy & fair use', fontSize: 16),
          const SizedBox(height: 10),
          AppCard(
            child: Column(
              children: [
                _PolicyRow(
                  Icons.visibility_off_outlined,
                  user.isStaff
                      ? 'Students can report anonymously. Respect that choice '
                          'and only contact reporters through official channels.'
                      : 'Other students never see your name. Choose '
                          '“Report anonymously” to hide it from staff too.',
                ),
                const Divider(height: 24, color: AppColors.border),
                const _PolicyRow(
                  Icons.verified_user_outlined,
                  'Only verified ALU accounts can use the app, and only '
                      'authorised staff can change a report’s status.',
                ),
                const Divider(height: 24, color: AppColors.border),
                const _PolicyRow(
                  Icons.gavel_outlined,
                  'False or abusive reports can be traced to the account '
                      'that filed them, even when anonymous.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          OutlinedButton.icon(
            onPressed: () => _confirmSignOut(context),
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              foregroundColor: AppColors.danger,
              side: BorderSide(color: AppColors.danger.withValues(alpha: 0.4)),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final bool isStaff;
  const _RoleBadge({required this.isStaff});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isStaff ? AppColors.successSoft : AppColors.primarySoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(isStaff ? 'Staff' : 'Student',
          style: TextStyle(
              color: isStaff ? AppColors.success : AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w700)),
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

class _PolicyRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _PolicyRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text,
              style: const TextStyle(fontSize: 13, height: 1.45)),
        ),
      ],
    );
  }
}
