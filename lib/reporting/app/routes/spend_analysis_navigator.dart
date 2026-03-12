import 'package:bluebird_p2_project/reporting/app/data/types/module_navigation_key.dart';
import 'package:bluebird_p2_project/reporting/app/modules/spend_analysis/spend_analysis/spend_analysis_screen.dart';
import 'package:bluebird_p2_project/reporting/app/modules/spend_analysis/spend_analysis_detail/spend_analysis_detail_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

class SpendAnalysisNavigator extends StatelessWidget {
  const SpendAnalysisNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: Get.nestedKey(ModuleNavigationKey.SPEND_ANALYSIS),
      initialRoute: SpendAnalysisRoutes.SPEND_ANALYSIS,
      onGenerateInitialRoutes: (_, __) {
        return [
          GetPageRoute(
            settings: RouteSettings(name: SpendAnalysisRoutes.SPEND_ANALYSIS),
            page: () => const SpendAnalysisScreen(),
          )
        ];
      },
      onGenerateRoute: (settings) {
        return GetPageRoute(
            settings: settings,
            page: () {
              switch (settings.name) {
                case SpendAnalysisRoutes.SPEND_ANALYSIS:
                  return const SpendAnalysisScreen();
                case SpendAnalysisRoutes.SPEND_ANALYSIS_DETAIL:
                  return const SpendAnalysisDetailScreen();
                default:
                  return const SpendAnalysisScreen();
              }
            });
      },
    );
  }
}

abstract class SpendAnalysisRoutes {
  SpendAnalysisRoutes._();
  static const SPEND_ANALYSIS = _SpendAnalysisPaths.SPEND_ANALYSIS;
  static const SPEND_ANALYSIS_DETAIL =
      '${_SpendAnalysisPaths.SPEND_ANALYSIS_DETAIL}';
}

abstract class _SpendAnalysisPaths {
  _SpendAnalysisPaths._();
  static const SPEND_ANALYSIS = '/spend-analysis';
  static const SPEND_ANALYSIS_DETAIL = '/spend-analysis-detail';
}
