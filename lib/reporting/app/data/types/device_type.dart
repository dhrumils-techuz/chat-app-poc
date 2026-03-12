import 'dart:io';

class DeviceType {
  static const android = 1;
  static const ios = 2;

  static int? getPlatformDeviceType() {
    if (Platform.isAndroid) {
      return android;
    } else if (Platform.isIOS) {
      return ios;
    }
    return null;
  }
}
