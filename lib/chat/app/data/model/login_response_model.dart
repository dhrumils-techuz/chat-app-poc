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

  factory LoginResponseData.fromJson(Map<String, dynamic> json) {
    return LoginResponseData(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresIn: json['expiresIn'] as int,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      deviceId: json['deviceId'] as String?,
      encryptionKey: json['encryptionKey'] as String?,
    );
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
