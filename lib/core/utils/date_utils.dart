import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._();

  static final DateFormat _displayFormat = DateFormat('MMM d, yyyy • h:mm a');
  static final DateFormat _shortDateFormat = DateFormat('MMM d, yyyy');

  static String formatDateTime(DateTime dateTime) {
    return _displayFormat.format(dateTime);
  }

  static String formatShortDate(DateTime dateTime) {
    return _shortDateFormat.format(dateTime);
  }

  static String formatIso(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return formatDateTime(date);
    } catch (_) {
      return isoString;
    }
  }

  /// Returns friendly relative time (e.g. 'Just now', '5m ago', '2h ago', 'Yesterday', 'Oct 12')
  static String formatRelative(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return _shortDateFormat.format(dateTime);
    }
  }
}

