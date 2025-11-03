import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bubbly/common/widget/custom_shimmer_fill_text.dart';
import 'package:bubbly/common/widget/theme_blur_bg.dart';
import 'package:bubbly/screen/splash_screen/splash_screen_controller.dart';
import 'package:bubbly/utilities/app_res.dart';
import 'package:bubbly/utilities/text_style_custom.dart';
import 'package:bubbly/utilities/theme_res.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(SplashScreenController());
    return Scaffold(
      body: Stack(
        children: [
          const ThemeBlurBg(),
          Align(
            alignment: Alignment.center,
            child: CustomShimmerFillText(
              text: AppRes.appName.toUpperCase(),
              baseColor: whitePure(context),
              textStyle: TextStyleCustom.unboundedBlack900(
                  color: whitePure(context), fontSize: 30),
              finalColor: whitePure(context),
              shimmerColor: themeAccentSolid(context),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Text(
                'Powered by All Safe',
                style: TextStyle(
                  color: whitePure(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
