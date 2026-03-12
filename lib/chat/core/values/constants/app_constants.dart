import 'package:flutter/cupertino.dart';

class AppConstants {
  static final navigatorKey = GlobalKey<NavigatorState>();

  static const int paginationLimit = 20;
  static const int messagePageSize = 50;
  static const int searchDebounceMillis = 300;
  static const int reconnectDelaySeconds = 5;
  static const int maxReconnectAttempts = 10;
  static const int tokenRefreshBufferSeconds = 60;
  static const int maxFileUploadSizeMB = 25;
  static const int maxImageUploadSizeMB = 10;
  static const int maxAudioRecordingSeconds = 120;
}

class AppConfig {
  static const bool testMode = false;
}
