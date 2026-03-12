import 'dart:convert';

import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:get/get.dart';

import '../../../core/data/api_response_model.dart';
import '../../../core/utils/dialog_helper.dart';
import '../../../core/utils/logs_helper.dart';
import '../../../core/utils/network_helper.dart';
import '../../../core/utils/shared_preference_helper.dart';
import '../../../core/values/app_strings.dart';
import '../../../core/values/constants/server_endpoints.dart';
import '../../data/model/login_model.dart';
import '../../data/repository/sign_in_repository.dart';
import '../../data/repository/user_repository.dart';
import '../../data/types/device_type.dart';
import '../../routes/app_pages.dart';

class SignInController extends GetxController {
  final SignInRepository signInRepository;
  final UserRepository userRepository;

  var isProgressState = false.obs;

  FlutterAppAuth appAuth = FlutterAppAuth();

  SignInController(
      {required this.signInRepository, required this.userRepository});

  @override
  void onInit() {
    super.onInit();
  }

  login() async {
    ApiResponseModel apiResponseModel = await signInRepository.login(
      true,
      deviceType: DeviceType.getPlatformDeviceType(),
      fcmToken: '' /*await NotificationService.getFCMToken()*/,
    );

    isProgressState.value = false;

    if (apiResponseModel.isSuccessful) {
      LoginModel loginModel = LoginModel.fromJson(apiResponseModel.data);
      final loginModelData = loginModel.data;
      if (loginModelData != null) {
        storeData(loginModel);
        userRepository.setUserEmploymentType(loginModelData.role);
        await SharedPreferenceHelper.setString(
            PreferenceKeys.deviceId, loginModelData.deviceId!);
        Get.offAndToNamed(AppRoutes.REPORTING_HOME);
      } else {
        SharedPreferenceHelper.remove(PreferenceKeys.authToken);
        DialogHelper.showSimpleMessage(Keys.Error.tr, apiResponseModel.error);
      }
    }
  }

  microSoftAuth() async {
    var hasNetwork = await NetworkHelper.hasNetworkConnection();

    LogsHelper.debugLog('microSoftAuth() : ${hasNetwork} ${MsAdd.redirectUri}');

    if (!hasNetwork) {
      DialogHelper.showSimpleMessage(
        Keys.Message.tr,
        Keys.Please_connect_to_Internet.tr,
        onTap: () {
          Get.back();
        },
      );

      return;
    }

    isProgressState.value = true;
    try {
      AuthorizationTokenResponse result =
          await appAuth.authorizeAndExchangeCode(
              AuthorizationTokenRequest(MsAdd.clientId, MsAdd.redirectUri,
                  discoveryUrl: MsAdd.discoveryUrl,
                  scopes: MsAdd.scopes,
                  issuer: MsAdd.issuer,
                  serviceConfiguration: AuthorizationServiceConfiguration(
                    authorizationEndpoint: MsAdd.authorizationEndpoint,
                    tokenEndpoint: MsAdd.tokenEndpoint,
                  ),
                  promptValues: ['select_account']));

      LogsHelper.debugLog('microSoftAuth :: ${result}');

      final idToken = result.idToken;
      var accessToken = result.accessToken;
      var refreshToken = result.refreshToken ?? '';

      await SharedPreferenceHelper.setString(
          PreferenceKeys.addAccessToken, result.accessToken!);
      await SharedPreferenceHelper.setString(
          PreferenceKeys.addIdToken, result.idToken!);
      await SharedPreferenceHelper.setString(
          PreferenceKeys.addRefreshToken, result.refreshToken!);

      if (idToken != null) {
        decodeIdToken(idToken);
      }

      LogsHelper.debugLog('AddAuth :: idToken : $idToken ');

      LogsHelper.debugLog('AddAuth :: accessToken :: $accessToken');

      LogsHelper.debugLog('AddAuth :: refresh Token :: $refreshToken');

      login();
    } catch (e) {
      isProgressState.value = false;
      print('ERROR Hello : $e');
    }
  }

  void decodeIdToken(String idToken) async {
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

      await SharedPreferenceHelper.setInt(
          PreferenceKeys.addIdTokenExp, payload['exp']);
    } catch (e) {
      print('Error decoding ID Token: $e');
    }
  }

  storeData(LoginModel loginModel) async {
    /*await SharedPreferenceHelper.setString(
        PreferenceKeys.authToken, loginModel.data!.accessToken!);*/
    if ((loginModel.data!.hasAutoscheduleStarted ?? 0) == 1) {
      await SharedPreferenceHelper.setBool(
          PreferenceKeys.autoScheduleStart, true);
    } else {
      await SharedPreferenceHelper.setBool(
          PreferenceKeys.autoScheduleStart, false);
    }
    await SharedPreferenceHelper.setInt(
        PreferenceKeys.organizationId, loginModel.data!.orgId!);
    /*await SharedPreferenceHelper.setInt(
        PreferenceKeys.parentBranch, loginModel.data!.parentBranch!);*/
    await SharedPreferenceHelper.setString(
        PreferenceKeys.userName, loginModel.data!.name!);
    await SharedPreferenceHelper.setString(
        PreferenceKeys.userEmail, loginModel.data!.email!);
    await SharedPreferenceHelper.setString(
        PreferenceKeys.userPhoneNumber, loginModel.data!.phoneNumber!);
    await SharedPreferenceHelper.setInt(
        PreferenceKeys.userRole, loginModel.data!.role!);
    await SharedPreferenceHelper.setInt(
        PreferenceKeys.userStatus, loginModel.data!.status!);
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
  }
}
