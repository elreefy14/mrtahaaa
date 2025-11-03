import 'dart:io';

import 'package:bubbly/languages/languages_keys.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:proste_indexed_stack/proste_indexed_stack.dart';
import 'package:bubbly/common/widget/banner_ads_custom.dart';
import 'package:bubbly/common/widget/gradient_border.dart';
import 'package:bubbly/common/widget/gradient_icon.dart';
import 'package:bubbly/model/user_model/user_model.dart';
import 'package:bubbly/screen/dashboard_screen/dashboard_screen_controller.dart';
import 'package:bubbly/screen/explore_screen/explore_screen.dart';
import 'package:bubbly/screen/feed_screen/feed_screen.dart';
import 'package:bubbly/screen/home_screen/home_screen.dart';
import 'package:bubbly/screen/message_screen/message_screen.dart';
import 'package:bubbly/screen/profile_screen/profile_screen.dart';
import 'package:bubbly/screen/profile_screen/widget/post_options_sheet.dart';
import 'package:bubbly/utilities/style_res.dart';
import 'package:bubbly/utilities/text_style_custom.dart';
import 'package:bubbly/utilities/theme_res.dart';
import 'package:bubbly/utilities/asset_res.dart';

class DashboardScreen extends StatelessWidget {
  final User? myUser;

  const DashboardScreen({super.key, this.myUser});

  @override
  Widget build(BuildContext context) {
    // تأكد من إنشاء Controller واحد فقط
    final controller = Get.isRegistered<DashboardScreenController>()
        ? Get.find<DashboardScreenController>()
        : Get.put(DashboardScreenController());

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor(context),
      resizeToAvoidBottomInset: true,
      body: GetBuilder<DashboardScreenController>(
        id: 'main_content',
        builder: (controller) {
          return Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    ProsteIndexedStack(
                      index: controller.selectedPageIndex.value,
                      children: [
                        IndexedStackChild(child: const HomeScreen(), preload: true),
                        IndexedStackChild(child: const ExploreScreen(), preload: true),
                        IndexedStackChild(
                            child: FeedScreen(myUser: myUser),
                            preload: true
                        ),
                        IndexedStackChild(
                            child: ProfileScreen(
                                isDashBoard: true,
                                user: myUser,
                                isTopBarVisible: false
                            ),
                            preload: true
                        ),
                        IndexedStackChild(child: const MessageScreen(), preload: true),
                      ],
                    ),

                    // Floating Chat Button - positioned below Live indicator
                    // Positioned(
                    //   top: 150,
                    //   left: 20,
                    //   child: _buildFloatingChatButton(context, controller),
                    // ),

                    // Floating Action Button for MessageScreen
                    GetBuilder<DashboardScreenController>(
                      id  : 'floating_message_btn',
                      builder: (controller) {
                        if (controller.selectedPageIndex.value == 4) {
                          return Positioned(
                            bottom: 100,
                            right: 20,
                            child: FloatingActionButton(
                              onPressed: () {
                                // Add your message action here
                              },
                              backgroundColor: themeAccentSolid(context),
                              child: Icon(
                                Icons.edit,
                                color: whitePure(context),
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context, controller),
    );
  }

  Widget _buildFloatingChatButton(BuildContext context, DashboardScreenController controller) {
    return GetBuilder<DashboardScreenController>(
      id: 'floating_chat',
      builder: (controller) {
        return AnimatedOpacity(
          opacity: controller.selectedPageIndex.value == 0 ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: GestureDetector(
            onTap: () {
              controller.onChanged(4);
            },
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: blackPure(context).withOpacity(0.7),
                border: Border.all(
                  color: themeAccentSolid(context).withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    color: whitePure(context),
                    size: 22,
                  ),
                  // Unread count badge
                  GetBuilder<DashboardScreenController>(
                    id: 'unread_count',
                    builder: (controller) {
                      if (controller.unReadCount.value > 0) {
                        return Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              controller.unReadCount.value > 9
                                  ? '9+'
                                  : '${controller.unReadCount.value}',
                              style: TextStyleCustom.outFitRegular400(
                                  color: whitePure(context), fontSize: 8),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomNavigationBar(
      BuildContext context, DashboardScreenController controller) {
    return GetBuilder<DashboardScreenController>(
      id: 'bottom_nav',
      builder: (controller) {
        PostUploadingProgress postUpload = controller.postProgress.value;
        bool isPostUploading = postUpload.uploadType == UploadType.none ? false : true;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          color: blackPure(context),
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Home
                  _buildBottomNavItem(
                    context,
                    controller,
                    0,
                    AssetRes.icReel,
                    isPostUploading,
                    label: LKey.home.tr,
                  ),
                  // Explore
                  _buildBottomNavItem(
                    context,
                    controller,
                    1,
                    AssetRes.icSearch,
                    isPostUploading,
                    label: LKey.search.tr,
                  ),
                  // Center Add Button
                  _buildCenterAddButton(context, controller, isPostUploading),
                  // Feed
                  _buildBottomNavItem(
                    context,
                    controller,
                    2,
                    AssetRes.icPost,
                    isPostUploading,
                    label: LKey.content.tr,
                  ),
                  // Profile
                  _buildBottomNavItem(
                    context,
                    controller,
                    3,
                    AssetRes.icProfile,
                    isPostUploading,
                    label: LKey.profile.tr,
                  ),
                ],
              ),
              _buildUploadProgress(context, controller, postUpload, isPostUploading),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUploadProgress(BuildContext context, DashboardScreenController controller,
      PostUploadingProgress postUpload, bool isPostUploading) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      height: isPostUploading ? 30 : 0,
      margin: Platform.isAndroid || !isPostUploading
          ? EdgeInsets.zero
          : const EdgeInsets.only(bottom: 20, top: 5),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
              height: 30,
              decoration: BoxDecoration(gradient: StyleRes.themeGradient)
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: LayoutBuilder(builder: (context, constraints) {
              double progress = (constraints.maxWidth * postUpload.progress) / 100;
              return AnimatedContainer(
                height: 30,
                width: constraints.maxWidth - progress,
                duration: const Duration(milliseconds: 250),
                decoration: BoxDecoration(color: textDarkGrey(context)),
              );
            }),
          ),
          Align(
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (postUpload.uploadType != UploadType.error)
                  Text('${postUpload.progress.toInt()}%',
                      style: TextStyleCustom.outFitMedium500(
                        color: whitePure(context),
                        fontSize: 16,
                      )),
                Text(' ${postUpload.uploadType.title(postUpload.type)}',
                    style: TextStyleCustom.outFitLight300(
                        color: whitePure(context), fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterAddButton(
      BuildContext context, DashboardScreenController controller, bool isPostUploading) {
    return SafeArea(
      bottom: isPostUploading ? false : true,
      child: GestureDetector(
        onTap: () {
          // Show the publish options sheet
          Get.bottomSheet(
            PostOptionsSheet(controller: controller),
            isScrollControlled: true,
          );
        },
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: StyleRes.themeGradient,
            boxShadow: [
              BoxShadow(
                color: themeAccentSolid(context).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.add,
            color: whitePure(context),
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(
      BuildContext context,
      DashboardScreenController controller,
      int index,
      String iconPath,
      bool isPostUploading, {
        bool showUnreadCount = false,
        required String label,
      }) {
    return GetBuilder<DashboardScreenController>(
      id: 'nav_item_$index',
      builder: (controller) {
        final isSelected = controller.selectedPageIndex.value == index;
        final scaleValue = isSelected ? controller.scaleValue.value : 1.0;

        return SafeArea(
          bottom: isPostUploading ? false : true,
          child: GestureDetector(
            onTap: () => controller.onChanged(index),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: AnimatedScale(
                scale: scaleValue,
                duration: const Duration(milliseconds: 300),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: isSelected
                              ? BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: StyleRes.themeGradient.withOpacity(0.2),
                          )
                              : null,
                          child: Icon(
                            _getIconData(iconPath),
                            size: 24,
                            color: isSelected
                                ? themeAccentSolid(context)
                                : textLightGrey(context),
                          ),
                        ),
                        if (showUnreadCount) _buildUnreadCount(controller, context),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyleCustom.outFitRegular400(
                        color: isSelected
                            ? themeAccentSolid(context)
                            : textLightGrey(context),
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getIconData(String iconPath) {
    switch (iconPath) {
      case AssetRes.icReel:
        return Icons.home;
      case AssetRes.icSearch:
        return Icons.search;
      case AssetRes.icPost:
        return Icons.dynamic_feed;
      case AssetRes.icProfile:
        return Icons.person;
      case AssetRes.icChat:
        return Icons.chat_bubble_outline;
      default:
        return Icons.home;
    }
  }

  Widget _buildUnreadCount(
      DashboardScreenController controller, BuildContext context) {
    return GetBuilder<DashboardScreenController>(
      id: 'unread_count',
      builder: (controller) {
        final count = controller.unReadCount.value;
        return count > 0
            ? Positioned(
          top: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            constraints: const BoxConstraints(
              minWidth: 16,
              minHeight: 16,
            ),
            child: Text(
              count > 9 ? '9+' : '$count',
              style: TextStyleCustom.outFitRegular400(
                  color: whitePure(context), fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ),
        )
            : const SizedBox();
      },
    );
  }
}