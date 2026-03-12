import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';

import 'logs_helper.dart';

class DateTimeHelper {
  static const String serverDateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
  static const String formatMMMDD = 'MMM dd';
  static const String formatDDMMMYYYY = 'dd MMM, yyyy';
  static const String formatDMMMYYYY = 'd MMM yyyy';
  static const String formatMMMDDYYYY = 'MMM dd, yyyy';
  static const String formatHHmm = 'HH:mm';
  static const String formathhmma = 'hh:mm a';
  static const String formatEEEE = 'EEEE';
  static const String formatEEEEMMMMdyyyy = 'EEEE, MMMM d, yyyy';
  static const String displayDateFormat = formatEEEEMMMMdyyyy;

  static String? getCurrentUtcTimeServerFormat() {
    DateTime date = DateTime.now().toUtc();
    final DateFormat formatter = DateFormat(serverDateFormat);
    final String formatted = formatter.format(date);
    return formatted;
  }

  static String? getDisplayDateFormat(
    String? dateTime, {
    String? sourceFormat = serverDateFormat,
    String displayFormat = displayDateFormat,
    bool convertFromUtc = false,
  }) {
    if (dateTime == null || dateTime.isEmpty) return null;
    if (sourceFormat != null) {
      DateTime date = DateFormat(sourceFormat).parse(dateTime, convertFromUtc);
      return getDisplayDateFormatFromDateTime(date,
          displayFormat: displayFormat);
    } else {
      DateTime date = DateTime.parse(dateTime);
      return getDisplayDateFormatFromDateTime(date,
          displayFormat: displayFormat);
    }
  }

  static String? getDisplayDateFormatFromDateTime(
    DateTime? dateTime, {
    String displayFormat = displayDateFormat,
  }) {
    if (dateTime == null) return null;
    final DateFormat formatter = DateFormat(displayFormat);
    final String formatted = formatter.format(dateTime.toLocal());
    return formatted;
  }

  /// Formats a timestamp for chat message display.
  /// Shows "HH:mm" for today, "Yesterday" for yesterday,
  /// day name for this week, and "dd MMM yyyy" for older.
  static String formatChatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final local = dateTime.toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(local.year, local.month, local.day);

    final difference = today.difference(messageDay).inDays;

    if (difference == 0) {
      return DateFormat(formathhmma).format(local);
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return DateFormat(formatEEEE).format(local);
    } else {
      return DateFormat(formatDMMMYYYY).format(local);
    }
  }

  /// Formats a timestamp for conversation list display.
  /// Shows time for today, "Yesterday" for yesterday, and date for older.
  static String formatConversationTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final local = dateTime.toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(local.year, local.month, local.day);

    final difference = today.difference(messageDay).inDays;

    if (difference == 0) {
      return DateFormat(formathhmma).format(local);
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return DateFormat(formatEEEE).format(local);
    } else if (local.year == now.year) {
      return DateFormat(formatMMMDD).format(local);
    } else {
      return DateFormat(formatDMMMYYYY).format(local);
    }
  }

  /// Formats last seen timestamp for user presence display.
  static String formatLastSeen(DateTime dateTime) {
    final now = DateTime.now();
    final local = dateTime.toLocal();
    final difference = now.difference(local);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return formatChatTimestamp(dateTime);
    }
  }

  /// Returns a date separator string for grouping messages by date.
  static String getDateSeparator(DateTime dateTime) {
    final now = DateTime.now();
    final local = dateTime.toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(local.year, local.month, local.day);

    final difference = today.difference(messageDay).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (local.year == now.year) {
      return DateFormat(formatDMMMYYYY).format(local);
    } else {
      return DateFormat(formatDMMMYYYY).format(local);
    }
  }

  static Future<String> getDeviceTimezone() async {
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      return timezone;
    } catch (e) {
      LogsHelper.debugLog("Failed to get timezone: $e");
      return "Unknown Timezone";
    }
  }
}
