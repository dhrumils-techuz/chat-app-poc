import 'package:flutter/material.dart';

import '../../core/theme/color.dart';

class ProgressBarWidget extends StatelessWidget {
  const ProgressBarWidget({super.key, required this.isProgress});

  final bool isProgress;

  @override
  Widget build(BuildContext context) {
    AppColors myColors = AppColors.getInstance(context);
    return Visibility(
      visible: isProgress,
      child: Center(
        child: Container(
          height: double.infinity,
          width: double.infinity,
          color: AppColor.trBlack0x22000000,
          child: Center(
            child: CircularProgressIndicator(
              color: myColors.primaryColor,
            ),
          ),
        ),
      ),
    );
  }
}
