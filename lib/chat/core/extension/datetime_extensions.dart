extension DateTimeExtensions on DateTime {
  /// Returns true if this DateTime is today.
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Returns true if this DateTime is yesterday.
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Returns true if this DateTime is within the last 7 days.
  bool get isThisWeek {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeekDate =
        DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    return isAfter(startOfWeekDate) || isAtSameMomentAs(startOfWeekDate);
  }

  /// Returns true if this DateTime is within the current year.
  bool get isThisYear {
    return year == DateTime.now().year;
  }

  /// Returns true if this DateTime is on the same day as another DateTime.
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  /// Returns a DateTime with only the date component (midnight).
  DateTime get dateOnly {
    return DateTime(year, month, day);
  }

  /// Returns the number of minutes since this DateTime.
  int get minutesAgo {
    return DateTime.now().difference(this).inMinutes;
  }

  /// Returns the number of hours since this DateTime.
  int get hoursAgo {
    return DateTime.now().difference(this).inHours;
  }

  /// Returns the number of days since this DateTime.
  int get daysAgo {
    return DateTime.now().difference(this).inDays;
  }

  /// Returns a human-readable relative time string.
  String get timeAgo {
    final difference = DateTime.now().difference(this);
    if (difference.inSeconds < 60) return 'just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    if (difference.inDays < 30) return '${difference.inDays ~/ 7}w ago';
    if (difference.inDays < 365) return '${difference.inDays ~/ 30}mo ago';
    return '${difference.inDays ~/ 365}y ago';
  }

  /// Returns the start of the day (midnight).
  DateTime get startOfDay => DateTime(year, month, day);

  /// Returns the end of the day (23:59:59.999).
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);
}
