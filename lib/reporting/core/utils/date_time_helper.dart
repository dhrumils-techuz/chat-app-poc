import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';

import 'logs_helper.dart';

class DateTimeHelper {
  static const String serverDateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
  static const String formatMMMDD = 'MMM dd';
  static const String formatDDMMMYYYY = 'dd MMM, yyyy';
  static const String formatDMMMYYYY = 'd MMM yyyy';
  static const String formatMMMDDYYYY = 'MMM dd, yyyy';
  static const String formatYYYYMMDD = "YYYY-MM-DD";
  static const String formatEEEEMMMMdyyyy = "EEEE, MMMM d, yyyy";
  static const EEEEdMMMMyyyy = 'EEEE, d MMMM, yyyy';
  static const String MMMMdAtHHmm = 'MMMM d \'At\' HH:mm';
  static const String displayDateFormat = formatEEEEMMMMdyyyy;

  /*static final DateFormat serverFormatter = DateFormat(serverDateFormat);
  static final DateFormat displayFormatter = DateFormat(displayDateFormat);
  static final DateFormat mmmDDFormatter = DateFormat(formatMMMDD);
  static final DateFormat ddMMMyyyyFormatter = DateFormat(formatDDMMMYYYY);
  static final DateFormat mmmDDyyyyFormatter = DateFormat(formatMMMDDYYYY);*/

  // created by: Techuz Team
  // Modified By: Techuz Team - 18/04/2025, added a new param for xyz reason
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
    if (dateTime == null || dateTime.isEmpty) {
      return null;
    }
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
    if (dateTime == null) {
      return null;
    }
    final DateFormat formatter = DateFormat(displayFormat);
    final String formatted = formatter.format(dateTime.toLocal());
    return formatted;
  }

  static String? getDateMMMDD(
    String? dateTime, {
    String sourceFormat = serverDateFormat,
    bool convertFromUtc = false,
  }) {
    if (dateTime == null || dateTime.isEmpty) {
      return null;
    }
    return getDisplayDateFormat(
      dateTime,
      sourceFormat: sourceFormat,
      displayFormat: formatMMMDD,
      convertFromUtc: convertFromUtc,
    );
  }

  static String? getDateMMMDDYYYY(
    String? dateTime, {
    String sourceFormat = serverDateFormat,
    bool convertFromUtc = false,
  }) {
    if (dateTime == null || dateTime.isEmpty) {
      return null;
    }
    return getDisplayDateFormat(
      dateTime,
      sourceFormat: sourceFormat,
      displayFormat: formatMMMDDYYYY,
      convertFromUtc: convertFromUtc,
    );
  }

  static String? getDateDDMMMYYYY(
    String? dateTime, {
    String sourceFormat = serverDateFormat,
    bool convertFromUtc = false,
  }) {
    if (dateTime == null || dateTime.isEmpty) {
      return null;
    }
    return getDisplayDateFormat(
      dateTime,
      sourceFormat: sourceFormat,
      displayFormat: formatDDMMMYYYY,
      convertFromUtc: convertFromUtc,
    );
  }

  static String? getDateEEEEMMMMdyyyy(
    DateTime? utcDateTime, {
    bool convertToGmtNegative = false,
  }) {
    if (utcDateTime == null) {
      return null;
    }
    DateTime? gmt530DateTime;
    if (convertToGmtNegative) {
      // Offset for GMT-5:30
      Duration offset = const Duration(hours: -5, minutes: -30);

      // Convert UTC to GMT-5:30
      gmt530DateTime = utcDateTime.add(offset);
    }

    // Format the DateTime as "Wednesday, July 3, 2024"
    String formattedDate =
        DateFormat(displayDateFormat).format(gmt530DateTime ?? utcDateTime);

    return formattedDate;
  }

  static String? getSuffixedDDMMM(
    String? dateTime, {
    String sourceFormat = serverDateFormat,
    bool convertFromUtc = false,
  }) {
    if (dateTime == null || dateTime.isEmpty) {
      return null;
    }
    final DateFormat displayFormatter = DateFormat(sourceFormat);
    DateTime date = displayFormatter.parse(dateTime, convertFromUtc);
    final day = DateFormat.d().format(date);
    final month = DateFormat.MMM().format(date);
    return '$day${getOrdinalSuffix(day)} $month';
  }

  static String getOrdinalSuffix(String day) {
    final lastDigit = int.parse(day) % 10;
    final secondLastDigit = int.parse(day) % 100 ~/ 10;

    if (secondLastDigit == 1) {
      return 'th';
    } else if (lastDigit == 1) {
      return 'st';
    } else if (lastDigit == 2) {
      return 'nd';
    } else if (lastDigit == 3) {
      return 'rd';
    } else {
      return 'th';
    }
  }

  static Future<String> getDeviceTimezone() async {
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      return timezone;
    } catch (e) {
      LogsHelper.debugLog("Failed to get timezone: $e");
      return "Unknown Timezone"; // Fallback value
    }
  }

  /*static String? getTimeAgo(
    String? dateTime, {
    String sourceFormat = serverDateFormat,
    bool convertFromUtc = false,
    bool showDate = true,
    String displayFormat = displayDateFormat,
  }) {
    if (dateTime == null || dateTime.isEmpty) {
      return null;
    }
    final clock = DateTime.now();
    DateTime date =
        DateFormat(sourceFormat).parse(dateTime, convertFromUtc).toLocal();
    var elapsed = clock.millisecondsSinceEpoch - date.millisecondsSinceEpoch;
    final num seconds = elapsed / 1000;
    final num minutes = seconds / 60;
    final num hours = minutes / 60;
    final num days = hours / 24;
    final num months = days / 30;
    final num years = days / 365;

    String result;
    if (seconds < 60) {
      result = AppString.a_moment;
    } else if (seconds < 120) {
      result = "1 ${AppString.minute}";
    } else if (minutes < 60) {
      result = "${minutes.round()} ${AppString.minutes}";
    } else if (minutes < 120) {
      result = "1 ${AppString.hour}";
    } else if (hours < 24) {
      result = "${hours.round()} ${AppString.hours}";
    } else if (hours < 48) {
      result = "1 ${AppString.day}";
    } else {
      if (!showDate) {
        if (days < 30) {
          result = "${days.round()} ${AppString.days}";
        } else if (days < 60) {
          result = "1 ${AppString.month}";
        } else if (days < 365) {
          result = "${months.round()} ${AppString.months}";
        } else if (years < 2) {
          result = "1 ${AppString.year}";
        } else {
          result = "${years.round()} ${AppString.years}";
        }
      } else {
        final DateFormat formatter = DateFormat(displayFormat);
        return formatter.format(date);
      }
    }

    return [result, AppString.ago]
        .where((str) => str.isNotEmpty)
        .join(AppString.wordSeparator);
  }*/
}
