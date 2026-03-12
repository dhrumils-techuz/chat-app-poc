import 'package:bluebird_p2_project/reporting/app/data/types/module_navigation_key.dart';
import 'package:bluebird_p2_project/reporting/app/modules/call_analysis/call_activity/call_activity_screen.dart';
import 'package:bluebird_p2_project/reporting/app/modules/call_analysis/completed_calls/completed_calls_screen.dart';
import 'package:bluebird_p2_project/reporting/app/modules/call_analysis/incompleted_calls/incompleted_calls_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

class CallAnalysisNavigator extends StatelessWidget {
  const CallAnalysisNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: Get.nestedKey(ModuleNavigationKey.CALL_ANALYSIS),
      initialRoute: CallAnalysisRoutes.CALL_ANALYSIS,
      onGenerateInitialRoutes: (_, __) {
        return [
          GetPageRoute(
            settings: RouteSettings(name: CallAnalysisRoutes.CALL_ANALYSIS),
            page: () => const CallActivityScreen(),
          )
        ];
      },
      onGenerateRoute: (settings) {
        return GetPageRoute(
            settings: settings,
            page: () {
              switch (settings.name) {
                case CallAnalysisRoutes.CALL_ANALYSIS:
                  return const CallActivityScreen();
                case CallAnalysisRoutes.COMPLETED_CALL:
                  return const CompletedCallsScreen();
                case CallAnalysisRoutes.INCOMPLETED_CALL:
                  return const InCompletedCallsScreen();
                default:
                  return const CallActivityScreen();
              }
            });
      },
    );
  }
}

abstract class CallAnalysisRoutes {
  CallAnalysisRoutes._();
  static const CALL_ANALYSIS = _CallAnalysisPaths.CALL_ANALYSIS;
  static const COMPLETED_CALL = _CallAnalysisPaths.COMPLETED_CALL;
  static const INCOMPLETED_CALL = _CallAnalysisPaths.INCOMPLETED_CALL;
}

abstract class _CallAnalysisPaths {
  _CallAnalysisPaths._();
  static const CALL_ANALYSIS = '/call-analysis';
  static const COMPLETED_CALL = '/completed-call';
  static const INCOMPLETED_CALL = '/incompleted-call';
}
