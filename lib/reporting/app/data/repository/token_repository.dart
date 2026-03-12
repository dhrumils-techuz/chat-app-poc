import 'package:get/get.dart';

import '../../../core/utils/logs_helper.dart';
import '../../../core/utils/shared_preference_helper.dart';
import '../auth/ms_azure_ad_auth.dart';

class TokenRepository extends GetxService {
  final MsAzureAdAuth _msAzureAdAuth = MsAzureAdAuth();
  var isNewIdToken = false;

  void saveIdToken(String token) async {
    await SharedPreferenceHelper.setString(PreferenceKeys.addIdToken, token);
  }

  Future<String?> getIdToken() async {
    LogsHelper.debugLog(tag: "DebugToken", 'Request to get ID token');
    try {
      if (!_msAzureAdAuth.getIdTokenExpTime().isAfter(DateTime.now())) {
        LogsHelper.debugLog(tag: "DebugToken", 'ID token was expired');
        LogsHelper.debugLog(
            tag: "DebugToken",
            'old = ${SharedPreferenceHelper.getString(PreferenceKeys.addIdToken)}');
        LogsHelper.debugLog(
            'getIdToken() --------------------- New token --------------------------');
        //if (MsAzureAdAuth.tokenGenerateInProgress) {
        isNewIdToken = true;
        var idToken = await _msAzureAdAuth.getNewIdToken();
        return idToken;
        /*} else {
        return SharedPreferenceHelper.getString(PreferenceKeys.addIdToken);
      }*/
      } else {
        LogsHelper.debugLog(tag: "DebugToken", 'ID token was valid');
        LogsHelper.debugLog(
            'getIdToken() --------------------- old token --------------------------');
        isNewIdToken = false;
        return SharedPreferenceHelper.getString(PreferenceKeys.addIdToken);
      }
    } catch (e) {
      LogsHelper.debugLog('Get token failed: $e');
      await deleteRefreshToken();
      return null;
    }
  }

  void deleteIdToken() async {
    await SharedPreferenceHelper.remove(PreferenceKeys.addIdToken);
  }

  void saveRefreshToken(String token) async {
    await SharedPreferenceHelper.setString(
        PreferenceKeys.addRefreshToken, token);
  }

  String? getRefreshToken() {
    return SharedPreferenceHelper.getString(PreferenceKeys.addRefreshToken);
  }

  Future<void> deleteRefreshToken() async {
    await SharedPreferenceHelper.remove(PreferenceKeys.addRefreshToken);
  }

  void saveAccessToken(String token) async {
    await SharedPreferenceHelper.setString(
        PreferenceKeys.addAccessToken, token);
  }

  String? getAccessToken() {
    return SharedPreferenceHelper.getString(PreferenceKeys.addAccessToken);
  }

  void deleteAccessToken() async {
    await SharedPreferenceHelper.remove(PreferenceKeys.addAccessToken);
  }

  void saveDeviceId(String deviceId) async {
    await SharedPreferenceHelper.setString(PreferenceKeys.deviceId, deviceId);
  }

  String? getDeviceId() {
    return SharedPreferenceHelper.getString(PreferenceKeys.deviceId);
  }

  void deleteDeviceId() async {
    await SharedPreferenceHelper.remove(PreferenceKeys.deviceId);
  }
}
