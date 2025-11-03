import 'package:bubbly/languages/languages_keys.dart';
import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bubbly/screen/home_screen/home_screen_controller.dart';
import 'package:bubbly/screen/reels_screen/reels_screen.dart';
import 'package:bubbly/screen/live_stream/live_stream_search_screen/live_stream_search_screen.dart';
import 'package:bubbly/utilities/app_res.dart';
import 'package:bubbly/utilities/text_style_custom.dart';
import 'package:bubbly/utilities/theme_res.dart';

import '../dashboard_screen/dashboard_screen_controller.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeScreenController());
    return Scaffold(
      backgroundColor: themeColor(context),
      body: Stack(
        children: [
          ReelsScreen(
            isHomePage: true,
            reels: controller.reels,
            position: 0,
            isLoading: controller.isLoading,
            onFetchMoreData: () => controller.onRefreshPage(reset: false),
            widget: HomeTopTabsWidget(controller: controller),
            onRefresh: controller.onRefreshPage,
          ),
          // Live Button positioned at top right
          Positioned(
            top: 90,
            right: 20,
            child: SafeArea(
              child: Column(
                children: [
                  LiveButton(),
                  const SizedBox(height: 10),
                  ChatButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LiveButton extends StatelessWidget {
  const LiveButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Get.to(() => const LiveStreamSearchScreen());
      },
      child: Container(
        width: 60,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: ShapeDecoration(
          color: Colors.red.withOpacity(0.9),
          shape: SmoothRectangleBorder(
            borderRadius: SmoothBorderRadius(
                cornerRadius: 20,
                cornerSmoothing: 1
            ),
          ),
          shadows: [
            BoxShadow(
              color: Colors.red.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                  child: const Icon(
                    Icons.videocam,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                // Live indicator dot
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    height: 8,
                    width: 8,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              LKey.live,
              style: TextStyleCustom.unboundedBold700(
                fontSize: 9,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatButton extends StatelessWidget {
  const ChatButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to messages - assuming you have a dashboard controller
        // You can modify this to match your navigation logic
        if (Get.isRegistered<DashboardScreenController>()) {
          final dashboardController = Get.find<DashboardScreenController>();
          dashboardController.onChanged(4); // Messages tab index
        }
      },
      child: Container(
        height: 44,
        width: 44,
        decoration: ShapeDecoration(
          color: Colors.black.withOpacity(0.7),
          shape: SmoothRectangleBorder(
            borderRadius: SmoothBorderRadius(
                cornerRadius: 22,
                cornerSmoothing: 1
            ),
          ),
          // border: Border.all(
          //   color: themeAccentSolid(context).withOpacity(0.3),
          //   width: 1,
          // ),
          shadows: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(
                Icons.chat_bubble_outline,
                color: Colors.white,
                size: 20,
              ),
            ),
            // Unread messages indicator (optional)
            // You can connect this to your unread count logic
            // Positioned(
            //   top: 8,
            //   right: 8,
            //   child: Container(
            //     height: 8,
            //     width: 8,
            //     decoration: const BoxDecoration(
            //       color: Colors.red,
            //       shape: BoxShape.circle,
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}

class HomeTopTabsWidget extends StatelessWidget {
  final HomeScreenController controller;

  const HomeTopTabsWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        height: 44,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: ShapeDecoration(
          color: Colors.black.withOpacity(0.3),
          shape: SmoothRectangleBorder(
            borderRadius: SmoothBorderRadius(
                cornerRadius: 22,
                cornerSmoothing: 1
            ),
          ),
        ),
        child: Obx(() => Row(
          children: TabType.values.map((tabType) {
            bool isSelected = controller.selectedReelCategory.value == tabType;
            return Expanded(
              child: GestureDetector(
                onTap: () => controller.onTabTypeChanged(tabType),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 42,
                  margin: const EdgeInsets.all(4),
                  decoration: isSelected
                      ? ShapeDecoration(
                    color: whitePure(context),
                    shape: SmoothRectangleBorder(
                      borderRadius: SmoothBorderRadius(
                          cornerRadius: 18,
                          cornerSmoothing: 1
                      ),
                    ),
                  )
                      : null,
                  child: Center(
                    child: Text(
                      tabType.title.toUpperCase(),
                      style: TextStyleCustom.unboundedBold700(
                        fontSize: 9,
                        color: isSelected
                            ? textDarkGrey(context)
                            : whitePure(context).withOpacity(0.8),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        )),
      ),
    );
  }
}