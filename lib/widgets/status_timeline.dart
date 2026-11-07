import 'package:flutter/material.dart';
import '../models/incident.dart';
import '../utils/constants.dart';
import '../utils/format.dart';

/// Horizontal Submitted -> In Progress -> Resolved stepper (as in the mockup).
class StatusTimeline extends StatelessWidget {
  final Incident incident;
  const StatusTimeline(this.incident, {super.key});

  @override
  Widget build(BuildContext context) {
    const steps = IncidentStatus.values;
    final currentIdx = steps.indexOf(incident.status);

    return Semantics(
      label: 'Status: ${incident.status.label}. ${incident.status.meaning}',
      excludeSemantics: true,
      child: Column(
        children: [
          Row(
            children: [
              for (var i = 0; i < steps.length; i++) ...[
                _Dot(
                  status: steps[i],
                  done: i < currentIdx ||
                      (i == currentIdx &&
                          steps[i] == IncidentStatus.resolved),
                  current: i == currentIdx,
                ),
                if (i < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: i < currentIdx
                            ? AppColors.primary
                            : AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < steps.length; i++)
                Expanded(
                  child: _Label(
                    status: steps[i],
                    // Only show a time for steps reached on the current path,
                    // so a reopened report doesn't show an old "Resolved" time.
                    time: i <= currentIdx ? incident.timeFor(steps[i]) : null,
                    align: i == 0
                        ? CrossAxisAlignment.start
                        : i == steps.length - 1
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.center,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final IncidentStatus status;
  final bool done, current;
  const _Dot({required this.status, required this.done, required this.current});

  @override
  Widget build(BuildContext context) {
    final filled = done || current;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? AppColors.primary : Colors.white,
        border: Border.all(
            color: filled ? AppColors.primary : AppColors.border, width: 2),
        boxShadow: current && !done
            ? [
                BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 0,
                    spreadRadius: 4)
              ]
            : null,
      ),
      child: Icon(
        done ? Icons.check_rounded : status.icon,
        size: 15,
        color: filled ? Colors.white : AppColors.muted,
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final IncidentStatus status;
  final DateTime? time;
  final CrossAxisAlignment align;
  const _Label({required this.status, this.time, required this.align});

  @override
  Widget build(BuildContext context) {
    final textAlign = switch (align) {
      CrossAxisAlignment.start => TextAlign.start,
      CrossAxisAlignment.end => TextAlign.end,
      _ => TextAlign.center,
    };
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(status.label,
            textAlign: textAlign,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(time == null ? '—' : stamp(time!),
            textAlign: textAlign,
            style: const TextStyle(fontSize: 10.5, color: AppColors.muted)),
      ],
    );
  }
}

/// Vertical list of every status change, newest first, with staff notes.
class ActivityLog extends StatelessWidget {
  final Incident incident;
  const ActivityLog(this.incident, {super.key});

  @override
  Widget build(BuildContext context) {
    final entries = incident.history.reversed.toList();
    return Column(
      children: [
        for (var i = 0; i < entries.length; i++)
          _ActivityRow(entry: entries[i], isLast: i == entries.length - 1),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final StatusEntry entry;
  final bool isLast;
  const _ActivityRow({required this.entry, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final s = entry.status;
    final who = entry.byName == null ? '' : ' by ${entry.byName}';
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration:
                    BoxDecoration(color: s.background, shape: BoxShape.circle),
                child: Icon(s.icon, size: 14, color: s.color),
              ),
              if (!isLast)
                Expanded(
                    child: Container(width: 2, color: AppColors.border)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Marked ${s.label}$who',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(stamp(entry.at),
                      style: const TextStyle(
                          fontSize: 11.5, color: AppColors.muted)),
                  if (entry.note != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('“${entry.note}”',
                          style: const TextStyle(fontSize: 13, height: 1.4)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
