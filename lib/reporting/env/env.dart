import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: 'assets/.env')
abstract class Env {
  @EnviedField(varName: 'CLIENT_ID')
  static const String clientId = _Env.clientId;

  @EnviedField(varName: 'TENANT_ID')
  static const String tenantId = _Env.tenantId;

  @EnviedField(varName: 'REDIRECT_URI')
  static const String redirectUri = _Env.redirectUri;

  @EnviedField(varName: 'LOCALHOST')
  static const String localhost = _Env.localhost;

  @EnviedField(varName: 'DEV_URL')
  static const String devUrl = _Env.devUrl;

  @EnviedField(varName: 'STAGING_URL')
  static const String stagingUrl = _Env.stagingUrl;

  @EnviedField(varName: 'PROD_URL')
  static const String prodUrl = _Env.prodUrl;
}
