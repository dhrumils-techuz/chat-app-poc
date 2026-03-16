import 'user_model.dart';

class LoginResponseModel {
  final int? status;
  final String? message;
  final LoginResponseData? data;

  LoginResponseModel({this.status, this.message, this.data});

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      status: json['status'] as int?,
      message: json['message'] as String?,
      data: json['data'] != null
          ? LoginResponseData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': data?.toJson(),
    };
  }
}

class LoginResponseData {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final UserModel user;
  final String? deviceId;
  final String? encryptionKey;

  LoginResponseData({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.user,
    this.deviceId,
    this.encryptionKey,
  });

  /// Parses the server login response.
  ///
  /// Server returns tokens nested: `{ tokens: { accessToken, refreshToken, expiresIn }, user: {...} }`
  /// `expiresIn` comes as a string like "15m" — we parse it to seconds.
  factory LoginResponseData.fromJson(Map<String, dynamic> json) {
    // Tokens may be nested under 'tokens' key or flat at root level.
    final tokensMap = json['tokens'] as Map<String, dynamic>? ?? json;

    return LoginResponseData(
      accessToken: tokensMap['accessToken'] as String,
      refreshToken: tokensMap['refreshToken'] as String,
      expiresIn: _parseExpiresIn(tokensMap['expiresIn']),
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      deviceId: json['deviceId'] as String?,
      encryptionKey: json['encryptionKey'] as String?,
    );
  }

  /// Parses expiresIn which can be an int (seconds) or a string like "15m", "1h", "30s".
  static int _parseExpiresIn(dynamic value) {
    if (value is int) return value;
    if (value is String) {
      final match = RegExp(r'^(\d+)([smhd]?)$').firstMatch(value.trim());
      if (match != null) {
        final num = int.parse(match.group(1)!);
        final unit = match.group(2) ?? 's';
        switch (unit) {
          case 'm':
            return num * 60;
          case 'h':
            return num * 3600;
          case 'd':
            return num * 86400;
          case 's':
          default:
            return num;
        }
      }
    }
    return 900; // Default 15 minutes
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresIn': expiresIn,
      'user': user.toJson(),
      'deviceId': deviceId,
      'encryptionKey': encryptionKey,
    };
  }
}
