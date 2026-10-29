import 'package:flutter/material.dart';
import '../models/incident.dart';
import '../utils/constants.dart';
import '../utils/format.dart';

class StatusTimeline extends StatelessWidget {
  final Incident incident;
  const StatusTimeline(this.incident, {super.key});

  @override
  Widget build(BuildContext context) {
    const steps = IncidentStatus.values;
    final currentIdx = steps.indexOf(incident.status);

    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < steps.length; i++) ...[
              _Dot(done: i <= currentIdx, current: i == currentIdx),
              if (i < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 3,
                    color: i < currentIdx
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < steps.length; i++)
              _Label(
                status: steps[i],
                time: incident.timeFor(steps[i]),
                align: i == 0
                    ? CrossAxisAlignment.start
                    : i == steps.length - 1
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.center,
              ),
          ],
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final bool done, current;
  const _Dot({required this.done, required this.current});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? AppColors.primary : Colors.white,
        border: Border.all(
            color: done ? AppColors.primary : AppColors.border, width: 2),
      ),
      child: done
          ? Icon(current ? Icons.bolt : Icons.check,
              size: 14, color: Colors.white)
          : null,
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
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(status.label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(time == null ? 'Pending' : stamp(time!),
            style: const TextStyle(fontSize: 10.5, color: AppColors.muted)),
      ],
    );
  }
}
