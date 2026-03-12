import '../types/device_type.dart';

class DeviceModel {
  final String? deviceId;
  final DeviceType deviceType;
  final String? fcmToken;
  final String? deviceName;
  final String? osVersion;
  final String? appVersion;
  final DateTime? lastActiveAt;

  DeviceModel({
    this.deviceId,
    required this.deviceType,
    this.fcmToken,
    this.deviceName,
    this.osVersion,
    this.appVersion,
    this.lastActiveAt,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      deviceId: json['deviceId'] as String?,
      deviceType: DeviceType.fromValue(json['deviceType'] as int),
      fcmToken: json['fcmToken'] as String?,
      deviceName: json['deviceName'] as String?,
      osVersion: json['osVersion'] as String?,
      appVersion: json['appVersion'] as String?,
      lastActiveAt: json['lastActiveAt'] != null
          ? DateTime.parse(json['lastActiveAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'deviceType': deviceType.value,
      'fcmToken': fcmToken,
      'deviceName': deviceName,
      'osVersion': osVersion,
      'appVersion': appVersion,
      'lastActiveAt': lastActiveAt?.toIso8601String(),
    };
  }

  DeviceModel copyWith({
    String? deviceId,
    DeviceType? deviceType,
    String? fcmToken,
    String? deviceName,
    String? osVersion,
    String? appVersion,
    DateTime? lastActiveAt,
  }) {
    return DeviceModel(
      deviceId: deviceId ?? this.deviceId,
      deviceType: deviceType ?? this.deviceType,
      fcmToken: fcmToken ?? this.fcmToken,
      deviceName: deviceName ?? this.deviceName,
      osVersion: osVersion ?? this.osVersion,
      appVersion: appVersion ?? this.appVersion,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }
}
