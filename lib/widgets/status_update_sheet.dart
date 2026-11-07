import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'primary_button.dart';

class StatusUpdate {
  final IncidentStatus status;
  final String? note;
  const StatusUpdate(this.status, this.note);
}

/// Staff-only sheet: pick the new status and optionally leave a note that
/// the reporter will see. Replaces one-tap changes so a mis-tap cannot
/// silently change a report.
class StatusUpdateSheet extends StatefulWidget {
  final IncidentStatus current;
  const StatusUpdateSheet({super.key, required this.current});

  static Future<StatusUpdate?> show(
      BuildContext context, IncidentStatus current) {
    return showModalBottomSheet<StatusUpdate>(
      context: context,
      isScrollControlled: true,
      builder: (_) => StatusUpdateSheet(current: current),
    );
  }

  @override
  State<StatusUpdateSheet> createState() => _StatusUpdateSheetState();
}

class _StatusUpdateSheetState extends State<StatusUpdateSheet> {
  late IncidentStatus _selected = widget.current;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  bool get _hasChange =>
      _selected != widget.current || _note.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Update status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('The reporter sees the new status and your note.',
              style: TextStyle(color: AppColors.muted)),
          const SizedBox(height: 16),
          for (final s in IncidentStatus.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _StatusOption(
                status: s,
                selected: _selected == s,
                isCurrent: widget.current == s,
                onTap: () => setState(() => _selected = s),
              ),
            ),
          const SizedBox(height: 8),
          TextField(
            controller: _note,
            maxLines: 3,
            maxLength: 200,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Add a note for the student (optional)\n'
                  'e.g. Technician booked for Thursday morning',
            ),
          ),
          const SizedBox(height: 8),
          PrimaryButton(
            label: 'Save update',
            onPressed: _hasChange
                ? () => Navigator.pop(
                    context, StatusUpdate(_selected, _note.text.trim()))
                : null,
          ),
        ],
      ),
    );
  }
}

class _StatusOption extends StatelessWidget {
  final IncidentStatus status;
  final bool selected;
  final bool isCurrent;
  final VoidCallback onTap;

  const _StatusOption({
    required this.status,
    required this.selected,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? status.background : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: selected ? status.color : AppColors.border,
                width: selected ? 1.5 : 1),
          ),
          child: Row(
            children: [
              Icon(status.icon, color: status.color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCurrent ? '${status.label} (current)' : status.label,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(status.meaning,
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 12)),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected ? status.color : AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
