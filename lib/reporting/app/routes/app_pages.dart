import 'package:bluebird_p2_project/reporting/app/modules/sign_in/sign_in_screen.dart';
import 'package:get/get.dart';

import 'package:bluebird_p2_project/reporting/app/modules/reporting_home/reporting_home_screen.dart';

class AppPages {
  AppPages._();

  static const INITIAL = AppRoutes.SIGN_IN;

  static final routes = [
    GetPage(
      name: _AppPaths.SIGN_IN,
      page: () => const SignInScreen(),
    ),
    GetPage(
      name: _AppPaths.REPORTING_HOME,
      page: () => const ReportingHomeScreen(),
    ),
  ];
}

abstract class AppRoutes {
  AppRoutes._();
  static const SIGN_IN = _AppPaths.SIGN_IN;
  static const REPORTING_HOME = _AppPaths.REPORTING_HOME;
}

abstract class _AppPaths {
  _AppPaths._();
  static const SIGN_IN = '/sign-in';
  static const REPORTING_HOME = '/reporting-home';
}
