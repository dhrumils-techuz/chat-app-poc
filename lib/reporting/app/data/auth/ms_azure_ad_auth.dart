import 'dart:convert';

import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:get/get.dart';

import '../../../core/utils/dialog_helper.dart';
import '../../../core/utils/logs_helper.dart';
import '../../../core/utils/shared_preference_helper.dart';
import '../../../core/values/app_strings.dart';
import '../../../core/values/constants/server_endpoints.dart';

class MsAzureAdAuth {
  FlutterAppAuth appAuth = FlutterAppAuth();

  static bool tokenGenerateInProgress = false;

  Future<AuthorizationTokenResponse?> microSoftAuth() async {
    return await appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(MsAdd.clientId, MsAdd.redirectUri,
            discoveryUrl: MsAdd.discoveryUrl,
            scopes: MsAdd.scopes,
            issuer: MsAdd.issuer,
            serviceConfiguration: AuthorizationServiceConfiguration(
              authorizationEndpoint: MsAdd.authorizationEndpoint,
              tokenEndpoint: MsAdd.tokenEndpoint,
            ),
            promptValues: ['select_account']));
  }

  Future<TokenResponse?> generateIdToken(String refreshToken) async {
    FlutterAppAuth appAuth = FlutterAppAuth();
    return await appAuth.token(TokenRequest(MsAdd.clientId, MsAdd.redirectUri,
        discoveryUrl: MsAdd.discoveryUrl,
        refreshToken: refreshToken,
        scopes: MsAdd.scopes));
  }

  Future<String?> getNewIdToken() async {
    var refreshToken =
        SharedPreferenceHelper.getString(PreferenceKeys.addRefreshToken);
    LogsHelper.debugLog('getNewidToken :: $refreshToken');
    if (refreshToken != null) {
      tokenGenerateInProgress = true;
      TokenResponse? tokenResponse = await generateIdToken(refreshToken);

      if (tokenResponse != null) {
        await SharedPreferenceHelper.setString(
            PreferenceKeys.addAccessToken, tokenResponse.accessToken!);
        await SharedPreferenceHelper.setString(
            PreferenceKeys.addIdToken, tokenResponse.idToken!);
        /*await SharedPreferenceHelper.setString(
            PreferenceKeys.addRefreshToken, tokenResponse.refreshToken!);*/
        var expIdToke = await decodeIdToken(tokenResponse.idToken!);
        await SharedPreferenceHelper.setInt(
            PreferenceKeys.addIdTokenExp, expIdToke);

        return tokenResponse.idToken;
      } else {
        /*DialogHelper.showSimpleMessage(
          Keys.message.tr,
          Keys.your_session_has_expired_please_sign_in_again_to_continue.tr,
          onTap: () {
            try {
              Future.delayed(Duration(seconds: 1), () {
                SharedPreferenceHelper.clear();
                Get.offAllNamed(Routes.SIGN_IN);
              });
            } catch (error) {
              LogsHelper.debugLog('getNewIdToken :: ${error}');
            }
          },
        );*/
      }
    } else {
      /*DialogHelper.showSimpleMessage(
        Keys.message.tr,
        Keys.your_session_has_expired_please_sign_in_again_to_continue.tr,
        onTap: () {
          try {
            Future.delayed(Duration(seconds: 1), () {
              SharedPreferenceHelper.clear();
              Get.offAllNamed(Routes.SIGN_IN);
            });
          } catch (error) {
            LogsHelper.debugLog('getNewIdToken :: ${error}');
          }
        },
      );*/
    }

    tokenGenerateInProgress = false;

    return null;
  }

  logOutAuth() async {
    try {
      var idToken = SharedPreferenceHelper.getString(PreferenceKeys.addIdToken);

      EndSessionResponse endSessionResponse = await appAuth.endSession(
          EndSessionRequest(
              idTokenHint: idToken,
              postLogoutRedirectUrl: MsAdd.logoutUrl,
              serviceConfiguration: AuthorizationServiceConfiguration(
                  authorizationEndpoint: MsAdd.authorizationEndpoint,
                  tokenEndpoint: MsAdd.tokenEndpoint,
                  endSessionEndpoint: MsAdd.endSessionEndpoint)));

      LogsHelper.debugLog('Logout successful ${endSessionResponse.state}');
    } catch (e) {
      LogsHelper.debugLog('Logout failed: $e');
    }
  }

  DateTime getIdTokenExpTime() {
    int timestampInMilliseconds =
        (SharedPreferenceHelper.getInt(PreferenceKeys.addIdTokenExp) ?? 0) *
            1000;
    DateTime idTokenExpTime =
        DateTime.fromMillisecondsSinceEpoch(timestampInMilliseconds)
            .add(Duration(minutes: -5));

    LogsHelper.debugLog('getIdTokenExpTime :: $idTokenExpTime');

    return idTokenExpTime;
  }

  Future<int> decodeIdToken(String idToken) async {
    try {
      // Split the token into its three parts (header, payload, signature)
      final parts = idToken.split('.');
      if (parts.length != 3) {
        throw Exception('Invalid token format');
      }

      // Decode the payload (second part of the token)
      final payloadBase64 = parts[1];
      final normalizedPayload = base64Url.normalize(payloadBase64);
      final decodedPayload = utf8.decode(base64Url.decode(normalizedPayload));

      // Print the decoded payload
      print('Decoded Payload: $decodedPayload');

      // Parse the payload as a JSON object
      final Map<String, dynamic> payload = jsonDecode(decodedPayload);
      print('Decoded ID Token Payload ${payload['exp']} : $payload');

      /*await SharedPreferenceHelper.setInt(
          PreferenceKeys.addIdTokenExp, payload['exp']);*/
      return payload['exp'];
    } catch (e) {
      print('Error decoding ID Token: $e');
      return 0;
    }
  }
}
