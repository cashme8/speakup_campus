import 'package:intl/intl.dart';

String timeAgo(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'Just now';
  if (d.inMinutes < 60) return '${d.inMinutes} min ago';
  if (d.inHours < 24) {
    return '${d.inHours} hour${d.inHours == 1 ? '' : 's'} ago';
  }
  if (d.inDays < 30) return '${d.inDays} day${d.inDays == 1 ? '' : 's'} ago';
  return DateFormat('MMM d, y').format(t);
}

String stamp(DateTime t) => DateFormat('MMM d, h:mm a').format(t);

String initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts.first[0] + parts.last[0]).toUpperCase();
}
