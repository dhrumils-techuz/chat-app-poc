import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';

import 'package:get/get.dart';

import '../../../../core/theme/color.dart';
import '../../../../core/theme/text_style.dart';
import '../../../../core/values/app_images.dart';
import '../../../../core/values/app_sizes.dart';
import '../../../../core/values/app_strings.dart';
import '../../../routes/app_pages.dart';
import '../../../widgets/progress_bar_widget.dart';
import '../sign_in_controller.dart';

class SignInView extends StatelessWidget {
  const SignInView({super.key, required this.controller});

  final SignInController controller;

  @override
  Widget build(BuildContext context) {
    AppColors myColors = AppColors.getInstance(context);

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
          systemNavigationBarColor: myColors.primaryColor,
          statusBarColor: myColors.primaryColor,
          statusBarBrightness:
              GetPlatform.isAndroid ? Brightness.light : Brightness.dark,
          statusBarIconBrightness:
              GetPlatform.isAndroid ? Brightness.light : Brightness.dark,
          systemNavigationBarDividerColor: myColors.primaryColor),
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(
            height: AppSizes.dimenToPx58,
          ),
          Center(
            child: Text(Keys.Hello_Again.tr,
                style: AppTextStyles.primaryTextSemiBoldW600.copyWith(
                  color: myColors.onPrimaryColor,
                  fontSize: AppTextSizes.text32,
                )),
          ),
          const SizedBox(
            height: AppSizes.dimenToPx12,
          ),
          Text(Keys.Welcome_back_You_have.tr,
              textAlign: TextAlign.center,
              style: AppTextStyles.primaryTextMediumW500.copyWith(
                color: myColors.onPrimaryColor,
                fontSize: AppTextSizes.text18,
              )),
          Text(Keys.been_missed.tr,
              textAlign: TextAlign.center,
              style: AppTextStyles.primaryTextMediumW500.copyWith(
                color: myColors.onPrimaryColor,
                fontSize: AppTextSizes.text18,
              )),
          const SizedBox(
            height: AppSizes.dimenToPx80,
          ),
          Image.asset(
            AppImages.imgBlueBirdLogoWithoutBG,
            //width: AppSizes.dimenToPx314,
            //height: AppSizes.dimenToPx314,
            width: AppSizes.dimenToPx200,
            height: AppSizes.dimenToPx200,
          ),
          const SizedBox(
            height: AppSizes.dimenToPx100,
          ),
          Text(Keys.Login_to_BlueBird.tr,
              textAlign: TextAlign.center,
              style: AppTextStyles.primaryTextSemiBoldW600.copyWith(
                color: myColors.onPrimaryColor,
                fontSize: AppTextSizes.text20,
              )),
          const SizedBox(
            height: AppSizes.dimenToPx26,
          ),
          Visibility(
            visible: false,
            child: GestureDetector(
              onTap: () {},
              child: Container(
                height: AppSizes.dimenToPx54,
                width: AppSizes.dimenToPx343,
                decoration: BoxDecoration(
                    color: myColors.onPrimaryColor,
                    borderRadius: const BorderRadius.all(
                        Radius.circular(AppSizes.dimenToPx8))),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      AppImages.icGoogleIcon,
                      height: AppSizes.dimenToPx20,
                      width: AppSizes.dimenToPx20,
                    ),
                    const SizedBox(
                      width: AppSizes.dimenToPx18,
                    ),
                    Text(Keys.Continue_with_Google.tr,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.primaryTextBoldW700.copyWith(
                          color: myColors.colorOnBackground,
                          fontSize: AppTextSizes.text16,
                        ))
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(
            height: AppSizes.dimenToPx16,
          ),
          GestureDetector(
            onTap: () {
              controller.microSoftAuth();
              //controller.tokenGenerate();
            },
            child: Container(
              height: AppSizes.dimenToPx54,
              width: AppSizes.dimenToPx343,
              decoration: BoxDecoration(
                  color: myColors.onPrimaryColor,
                  borderRadius: const BorderRadius.all(
                      Radius.circular(AppSizes.dimenToPx8))),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    AppImages.icMicrosoftIcon,
                    height: AppSizes.dimenToPx20,
                    width: AppSizes.dimenToPx20,
                  ),
                  const SizedBox(
                    width: AppSizes.dimenToPx18,
                  ),
                  Text(Keys.Continue_with_Microsoft.tr,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.primaryTextBoldW700.copyWith(
                        color: myColors.colorOnBackground,
                        fontSize: AppTextSizes.text16,
                      ))
                ],
              ),
            ),
          ),
          const SizedBox(
            height: AppSizes.dimenToPx26,
          ),
          Visibility(
            visible: false,
            child: GestureDetector(
              onTap: () {
                //controller.generateIdToken(controller.refreshToken);
              },
              child: Text(Keys.Login_with_User_name.tr,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.primaryTextSemiBoldW600.copyWith(
                    color: myColors.onPrimaryColor,
                    fontSize: AppTextSizes.text16,
                    decoration: TextDecoration.underline,
                    decorationColor:
                        myColors.onPrimaryColor, // Change underline color
                    decorationThickness: 1.0,
                  )),
            ),
          ),
        ],
      ),
    );
  }
}
