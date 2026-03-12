import 'package:bluebird_p2_project/reporting/app/modules/sign_in/sign_in_controller.dart';
import 'package:bluebird_p2_project/reporting/app/modules/sign_in/widget/sign_in_view.dart';
import 'package:bluebird_p2_project/reporting/app/widgets/progress_bar_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../../../core/theme/color.dart';
import '../../data/repository/sign_in_repository.dart';
import '../../data/repository/user_repository.dart';
import '../../data/service/auth/dio_auth_service.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final SignInController controller = Get.put(
      SignInController(
          signInRepository: SignInRepository(
              authService: DioAuthService(dioRemoteApiClient: Get.find())),
          userRepository: UserRepository(
              authService: DioAuthService(dioRemoteApiClient: Get.find()))),
    );
    AppColors myColors = AppColors.getInstance(context);
    return Scaffold(
      backgroundColor: myColors.primaryColor,
      body: SafeArea(
        child: Stack(
          children: [
            SignInView(controller: controller),
            Obx(
              () => ProgressBarWidget(
                isProgress: controller.isProgressState.value,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
