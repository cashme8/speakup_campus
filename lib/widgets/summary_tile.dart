import 'package:flutter/material.dart';
import '../providers/incident_provider.dart';
import '../utils/constants.dart';

class SummaryTile extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;
  final Color color;
  final Color background;
  final VoidCallback? onTap;

  const SummaryTile({
    super.key,
    required this.icon,
    required this.count,
    required this.label,
    required this.color,
    required this.background,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: '$count $label',
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
                const SizedBox(height: 8),
                Text('$count',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The row of count tiles used on Home and Profile.
/// Tapping a status tile jumps to the Reports tab filtered by that status.
class StatsRow extends StatelessWidget {
  final IncidentStats stats;
  final String totalLabel;
  final bool showSubmitted;
  final void Function(IncidentStatus? status)? onTap;

  const StatsRow({
    super.key,
    required this.stats,
    required this.totalLabel,
    this.showSubmitted = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    VoidCallback? tap(IncidentStatus? s) =>
        onTap == null ? null : () => onTap!(s);

    final tiles = <Widget>[
      SummaryTile(
        icon: Icons.description_outlined,
        count: stats.total,
        label: totalLabel,
        color: AppColors.primary,
        background: AppColors.primarySoft,
        onTap: tap(null),
      ),
      SummaryTile(
        icon: Icons.schedule,
        count: stats.inProgress,
        label: IncidentStatus.inProgress.label,
        color: AppColors.info,
        background: AppColors.infoSoft,
        onTap: tap(IncidentStatus.inProgress),
      ),
      SummaryTile(
        icon: Icons.check_circle_outline,
        count: stats.resolved,
        label: IncidentStatus.resolved.label,
        color: AppColors.success,
        background: AppColors.successSoft,
        onTap: tap(IncidentStatus.resolved),
      ),
      if (showSubmitted)
        SummaryTile(
          icon: Icons.error_outline,
          count: stats.submitted,
          label: IncidentStatus.submitted.label,
          color: AppColors.danger,
          background: AppColors.dangerSoft,
          onTap: tap(IncidentStatus.submitted),
        ),
    ];

    return Row(
      children: [
        for (var i = 0; i < tiles.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: tiles[i]),
        ],
      ],
    );
  }
}
