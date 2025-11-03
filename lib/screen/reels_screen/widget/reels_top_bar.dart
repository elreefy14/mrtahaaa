import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bubbly/common/manager/session_manager.dart';
import 'package:bubbly/common/widget/custom_back_button.dart';
import 'package:bubbly/screen/reels_screen/reels_screen_controller.dart';
import 'package:bubbly/utilities/asset_res.dart';
import 'package:bubbly/utilities/theme_res.dart';

class ReelsTopBar extends StatelessWidget {
  final ReelsScreenController controller;
  final Widget? widget;

  const ReelsTopBar({super.key, required this.controller, this.widget});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Visibility(
                  visible: !controller.isHomePage,
                  replacement: const SizedBox(width: 30),
                  child: CustomBackButton(
                      color: whitePure(context),
                      height: 30,
                      width: 30,
                      padding: EdgeInsets.zero,
                      image: AssetRes.icBackArrow_1),
                ),
                if (widget != null) Flexible(child: widget!),
                Obx(() {
                  if (controller.reels.isEmpty) {
                    return const SizedBox(width: 30, height: 30);
                  }

                  bool isVisible = controller.reels[controller.position.value].userId !=
                          SessionManager.instance.getUserID();

                  return Visibility(
                    visible: isVisible,
                    replacement: const SizedBox(width: 30, height: 30),
                    child: InkWell(
                      onTap: controller.onReportTap,
                      child: Image.asset(AssetRes.icAlert, width: 30, height: 30),
                    ),
                  );
                })
              ],
            ),
          ),
        ),
      ],
    );
  }
}
