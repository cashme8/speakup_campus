import 'package:flutter/material.dart';
import '../utils/constants.dart';

enum NoticeType { error, info, warning }

/// Inline message box for errors, hints and warnings.
class NoticeBanner extends StatelessWidget {
  final String message;
  final NoticeType type;
  final Widget? action;

  const NoticeBanner(
    this.message, {
    super.key,
    this.type = NoticeType.error,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final (Color fg, Color bg, IconData icon) = switch (type) {
      NoticeType.error => (
          AppColors.danger,
          AppColors.dangerSoft,
          Icons.error_outline
        ),
      NoticeType.info => (
          AppColors.primary,
          AppColors.primarySoft,
          Icons.info_outline
        ),
      NoticeType.warning => (
          const Color(0xFFB7791F),
          const Color(0xFFFFF1CC),
          Icons.lightbulb_outline
        ),
    };
    return Semantics(
      liveRegion: type == NoticeType.error,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: fg, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message,
                      style: TextStyle(
                          color: AppColors.ink, fontSize: 13, height: 1.4)),
                  ?action,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
