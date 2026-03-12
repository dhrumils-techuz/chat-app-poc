import 'package:flutter/foundation.dart';

import '../../../env/env.dart';

class ServerEndpoints {
  static const String localhost = Env.localhost;
  static const String devUrl = Env.devUrl;
  static const String stagingUrl = Env.stagingUrl;
  static const String prodUrl = Env.prodUrl;
  static const String mockTestUrl = "https://httpstat.us/502";
}

class ApiEndpoints {
  //Base
  static String baseURL = ServerEndpoints.devUrl;

  //Auth
  static String prefixAuth = '$baseURL/auth';
  static String login = '$prefixAuth/login';
  static String logout = '$prefixAuth/logout';

  //Common
  static String prefixCommon = '$baseURL/common';
  static String saveFCMToken = '$prefixCommon/saveFCMToken';

  //Spending Analysis
  static String prefixSpendingAnalysis = '';
  static String spendingAnalysisDetails = '';
}

class MsAdd {
  static String clientId = Env.clientId;
  static String tenantId = Env.tenantId;

  static String redirectUri = Env.redirectUri;
  static List<String> scopes = [
    'openid',
    'profile',
    'email',
    'offline_access',
    'User.Read',
    'Calendars.ReadWrite',
    'Mail.ReadWrite'
  ];
  static String authorizationEndpoint =
      'https://login.microsoftonline.com/$tenantId/oauth2/v2.0/authorize';
  static String tokenEndpoint =
      'https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token';
  static String issuer = "https://login.microsoftonline.com/$tenantId/v2.0";
  static String discoveryUrl =
      'https://login.microsoftonline.com/$tenantId/v2.0/.well-known/openid-configuration';
  static String logoutRedirectUrl = 'https://www.google.com/';
  static String logoutUrl =
      'https://login.microsoftonline.com/$tenantId/oauth2/v2.0/logout?post_logout_redirect_uri=$logoutRedirectUrl';
  static String endSessionEndpoint =
      'https://login.microsoftonline.com/$tenantId/oauth2/v2.0/logout';
}
