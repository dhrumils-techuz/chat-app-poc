import 'package:get/get_navigation/src/root/internacionalization.dart';

class Keys {
  static const String BlueBird = "BlueBird";
  static const String BlueBirdReporting = "BlueBirdReporting";
  static const String Hello_Again = 'Hello_Again';
  static const String Welcome_back_You_have = 'Welcome_back_You_have';
  static const String been_missed = 'been_missed';
  static const String Login_to_BlueBird = 'Login_to_BlueBird';
  static const String Login_with_User_name = 'Login_with_User_name';
  static const String Continue_with_Microsoft = 'Continue_with_Microsoft';
  static const String Continue_with_Google = 'Continue_with_Google';
  static const String Log_out = 'Log_out';
  static const String Some_error_occurred = 'Some_error_occurred';
  static const String Yes = 'Yes';
  static const String No = 'No';
  static const String OK = 'OK';
  static const String Copy = 'Copy';
  static const String You_are_Offline = 'You_are_Offline';
  static const String Please_connect_to_Internet = 'Please_connect_to_Internet';
  static const String Session_Expired = 'Session_Expired';
  static const String
      Unable_to_process_your_request_due_to_poor_internet_connection =
      'Unable_to_process_your_request_due_to_poor_internet_connection';
  static const String Message = 'Message';
  static const String Please_connect_to_internet = 'Please_connect_to_internet';
  static const String Error = "Error";
  static const String Spend_Analysis = 'Spend_Analysis';
  static const String Call_Analysis = 'Call_Analysis';
  static const String Details = 'Details';
  static const String Last_Months = 'Last_Months';
  static const String Select_Sale_Rep = 'Select_Sale_Rep';
  static const String Last_3_Months = 'Last 3 Months';

  // Call Analysis
  static const String Call_Activity = 'Call_Activity';
  static const String Metrics = 'Metrics';
  static const String Trend = 'Trend';
}

class AppStringEnUS {
  static const engMap = {
    Keys.BlueBirdReporting: 'BlueBird Reporting',
    Keys.Hello_Again: 'Hello Again',
    Keys.Welcome_back_You_have: 'Welcome back! You have',
    Keys.been_missed: 'been missed',
    Keys.Login_to_BlueBird: 'Login to BlueBird',
    Keys.Login_with_User_name: 'Login with User name',
    Keys.Continue_with_Microsoft: 'Continue with Microsoft',
    Keys.Continue_with_Google: 'Continue with Google',
    Keys.BlueBird: 'BlueBird',
    Keys.Log_out: 'Log out',
    Keys.Some_error_occurred: 'Some error occurred',
    Keys.Yes: 'Yes',
    Keys.No: 'No',
    Keys.OK: "OK",
    Keys.Copy: 'Copy',
    Keys.You_are_Offline: 'You\'re Offline',
    Keys.Please_connect_to_Internet: "Please connect to Internet",
    Keys.Session_Expired: 'Session Expired',
    Keys.Unable_to_process_your_request_due_to_poor_internet_connection:
        'Unable to process your request due to poor internet connection',
    Keys.Message: 'Message',
    Keys.Please_connect_to_internet: 'Please connect to internet',
    Keys.Error: 'Error',
    Keys.Spend_Analysis: 'Spend Analysis',
    Keys.Call_Analysis: 'Call Analysis',
    Keys.Details: 'Details',
    Keys.Last_Months: 'Last Months',
    Keys.Call_Activity: 'Call Activity',
    Keys.Metrics: 'Metrics',
    Keys.Trend: 'Trend',
    Keys.Last_3_Months: 'Last 3 Months',
  };
}

class ReportingMessages extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': AppStringEnUS.engMap,
      };
}
