import 'package:flutter/foundation.dart';

class LogsHelper {
  static void debugLog(Object? log, {String? tag}) {
    if (kDebugMode) {
      if (tag?.isNotEmpty ?? false) {
        print("$tag: $log");
        return;
      }
      print(log);
    }
  }
}
