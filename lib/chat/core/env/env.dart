import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: 'assets/.env.chat')
abstract class Env {
  @EnviedField(varName: 'DEV_URL')
  static const String devUrl = _Env.devUrl;

  @EnviedField(varName: 'STAGING_URL')
  static const String stagingUrl = _Env.stagingUrl;

  @EnviedField(varName: 'PROD_URL')
  static const String prodUrl = _Env.prodUrl;

  @EnviedField(varName: 'SOCKET_URL')
  static const String socketUrl = _Env.socketUrl;

  @EnviedField(varName: 'S3_BUCKET_URL')
  static const String s3BucketUrl = _Env.s3BucketUrl;

  @EnviedField(varName: 'FIREBASE_API_KEY')
  static const String firebaseApiKey = _Env.firebaseApiKey;

  @EnviedField(varName: 'FIREBASE_PROJECT_ID')
  static const String firebaseProjectId = _Env.firebaseProjectId;

  @EnviedField(varName: 'DB_ENCRYPTION_KEY')
  static const String dbEncryptionKey = _Env.dbEncryptionKey;
}
