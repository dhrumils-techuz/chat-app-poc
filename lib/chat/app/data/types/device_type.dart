import 'dart:io';

import 'package:flutter/foundation.dart';

enum DeviceType {
  android(1),
  ios(2),
  windows(3),
  web(4);

  final int value;
  const DeviceType(this.value);

  static DeviceType get current {
    if (kIsWeb) return DeviceType.web;
    if (Platform.isAndroid) return DeviceType.android;
    if (Platform.isIOS) return DeviceType.ios;
    if (Platform.isWindows) return DeviceType.windows;
    return DeviceType.web;
  }

  static DeviceType fromValue(int value) {
    return DeviceType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => DeviceType.web,
    );
  }
}
