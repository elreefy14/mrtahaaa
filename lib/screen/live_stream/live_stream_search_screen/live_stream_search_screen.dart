import 'dart:ui';

import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bubbly/common/extensions/common_extension.dart';
import 'package:bubbly/common/extensions/string_extension.dart';
import 'package:bubbly/common/widget/custom_image.dart';
import 'package:bubbly/common/widget/custom_search_text_field.dart';
import 'package:bubbly/common/widget/full_name_with_blue_tick.dart';
import 'package:bubbly/common/widget/loader_widget.dart';
import 'package:bubbly/common/widget/no_data_widget.dart';
import 'package:bubbly/languages/languages_keys.dart';
import 'package:bubbly/model/livestream/app_user.dart';
import 'package:bubbly/model/livestream/livestream.dart';
import 'package:bubbly/screen/live_stream/create_live_stream_screen/create_live_stream_screen.dart';
import 'package:bubbly/screen/live_stream/live_stream_search_screen/live_stream_search_screen_controller.dart';
import 'package:bubbly/screen/live_stream/livestream_screen/widget/live_stream_background_blur_image.dart';
import 'package:bubbly/utilities/asset_res.dart';
import 'package:bubbly/utilities/color_res.dart';
import 'package:bubbly/utilities/text_style_custom.dart';
import 'package:bubbly/utilities/theme_res.dart';

class LiveStreamSearchScreen extends StatelessWidget {
  const LiveStreamSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LiveStreamSearchScreenController());
    return Scaffold(
      body: Stack(
        children: [
          const LiveStreamBlurBackgroundImage(),
          Column(
            children: [
              const LiveStreamSearchTopView(),
              CustomSearchTextField(
                onChanged: controller.onSearchChange,
                backgroundColor: whitePure(context).withValues(alpha: .15),
                borderSide:
                BorderSide(color: whitePure(context).withValues(alpha: .18)),
              ),
              LiveStreamListView(controller: controller),
            ],
          ),
        ],
      ),
    );
  }
}

class LiveStreamSearchTopView extends StatelessWidget {
  const LiveStreamSearchTopView({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          const SizedBox(height: 40), // إضافة مسافة فوق الأزرار
          // Header with back button and celebrity challenge button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back button - تم تغيير الأيقونة من icClose إلى back arrow
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Get.back(),
                    borderRadius: BorderRadius.circular(17.5),
                    child: Container(
                      height: 35,
                      width: 35,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: whitePure(context).withValues(alpha: .5),
                              width: 1.5
                          )
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        color: whitePure(context),
                        size: 18,
                      ),
                    ),
                  ),
                ),

                // Celebrity Challenge Button - تم نقله إلى المنتصف
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      // Show "Soon" message
                      Get.snackbar(
                        'تحدي المشاهير', // Celebrity Challenge in Arabic
                        'قريباً', // Soon in Arabic
                        backgroundColor: whitePure(context).withValues(alpha: 0.9),
                        colorText: blackPure(context),
                        snackPosition: SnackPosition.TOP,
                        duration: const Duration(seconds: 2),
                        margin: const EdgeInsets.all(20),
                        borderRadius: 12,
                        icon: Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 24,
                        ),
                      );
                    },
                    borderRadius: SmoothBorderRadius(
                        cornerRadius: 30,
                        cornerSmoothing: 1
                    ).resolve(Directionality.of(context)),
                    child: Container(
                      height: 35,
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      decoration: ShapeDecoration(
                        color: Colors.amber.withValues(alpha: 0.9),
                        shape: SmoothRectangleBorder(
                            borderRadius: SmoothBorderRadius(
                                cornerRadius: 30,
                                cornerSmoothing: 1
                            )
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star,
                            color: whitePure(context),
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'تحدي المشاهير',
                            style: TextStyleCustom.unboundedRegular400(
                              color: whitePure(context),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Go Live button - تم نقله إلى اليمين
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Get.to(() => const CreateLiveStreamScreen());
                    },
                    borderRadius: SmoothBorderRadius(
                        cornerRadius: 30,
                        cornerSmoothing: 1
                    ).resolve(Directionality.of(context)),
                    child: Container(
                      height: 35,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: ShapeDecoration(
                          color: Colors.white,
                          shape: SmoothRectangleBorder(
                              borderRadius: SmoothBorderRadius(
                                  cornerRadius: 30,
                                  cornerSmoothing: 1
                              )
                          )
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            AssetRes.icLive_1,
                            color: blackPure(context),
                            width: 22,
                            height: 22,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            LKey.goLive.tr,
                            style: TextStyleCustom.unboundedRegular400(
                                color: blackPure(context),
                                fontSize: 12
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// باقي الكود (LiveStreamListView) يبقى كما هو بدون تغيير...
class LiveStreamListView extends StatelessWidget {
  final LiveStreamSearchScreenController controller;

  const LiveStreamListView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    Widget _buildBlurredBackground(AppUser? hostUser) {
      return Stack(
        children: [
          CustomImage(
            size: Size(Get.width, Get.height),
            radius: 0,
            image: hostUser?.profile?.addBaseURL(),
            fullName: hostUser?.fullname,
          ),
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: Container(color: blackPure(context).withValues(alpha: .5)),
            ),
          )
        ],
      );
    }

    Widget _buildImageContain(
        {List<AppUser> allUsers = const [],
          int userCount = 0,
          bool isBattleOn = false}) {
      if (allUsers.isEmpty) return const SizedBox();
      return Container(
          height: 310 / 2.4,
          alignment: Alignment.center,
          child: switch (userCount) {
            2 => SizedBox(
              width: double.infinity,
              child: LayoutBuilder(builder: (context, constraints) {
                double imageSize = constraints.maxWidth / 2;
                return Stack(
                  children: [
                    Positioned(
                      left: 10,
                      top: 0,
                      bottom: 0,
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: CustomImage(
                            size: Size(imageSize, imageSize),
                            image: allUsers.first.profile?.addBaseURL(),
                            fullName: allUsers.first.fullname,
                            strokeWidth: 2,
                            strokeColor:
                            whitePure(context).withValues(alpha: .55)),
                      ),
                    ),
                    Positioned(
                      right: 10,
                      top: 0,
                      bottom: 0,
                      child: Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: CustomImage(
                          size: Size(imageSize, imageSize),
                          image: allUsers[1].profile?.addBaseURL(),
                          fullName: allUsers[1].fullname,
                          strokeWidth: 2,
                          strokeColor:
                          whitePure(context).withValues(alpha: .55),
                        ),
                      ),
                    ),
                    if (isBattleOn)
                      Align(
                        alignment: Alignment.center,
                        child: Image.asset(AssetRes.icBattleVs,
                            height: 60, width: 60),
                      )
                  ],
                );
              }),
            ),
            3 => SizedBox(
              width: double.infinity,
              child: LayoutBuilder(builder: (context, constraints) {
                double maxWidth = constraints.maxWidth;
                double imageSize = maxWidth / 1.7;
                double smallImageSize = maxWidth / 2.7;
                return Stack(
                  children: [
                    Align(
                      alignment: AlignmentDirectional.topCenter,
                      child: CustomImage(
                        size: Size(imageSize, imageSize),
                        image: allUsers.first.profile?.addBaseURL(),
                        fullName: allUsers.first.fullname,
                        strokeWidth: 2,
                        strokeColor:
                        whitePure(context).withValues(alpha: .55),
                      ),
                    ),
                    Positioned(
                      left: 30,
                      top: 0,
                      bottom: 0,
                      child: Align(
                        alignment: AlignmentDirectional.bottomStart,
                        child: CustomImage(
                          size: Size(smallImageSize, smallImageSize),
                          image: allUsers[1].profile?.addBaseURL(),
                          fullName: allUsers[1].fullname,
                          strokeWidth: 2,
                          strokeColor:
                          whitePure(context).withValues(alpha: .55),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 30,
                      top: 0,
                      bottom: 0,
                      child: Align(
                        alignment: AlignmentDirectional.bottomEnd,
                        child: CustomImage(
                          size: Size(smallImageSize, smallImageSize),
                          image: allUsers[2].profile?.addBaseURL(),
                          fullName: allUsers[2].fullname,
                          strokeWidth: 2,
                          strokeColor:
                          whitePure(context).withValues(alpha: .55),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
            4 => SizedBox(
              width: double.infinity,
              child: LayoutBuilder(builder: (context, constraints) {
                double maxWidth = constraints.maxWidth;
                double imageSize = maxWidth / 1.7;
                double smallImageSize = maxWidth / 2.7;
                return Stack(
                  children: [
                    Align(
                      alignment: AlignmentDirectional.topCenter,
                      child: CustomImage(
                        size: Size(imageSize, imageSize),
                        image: allUsers.first.profile?.addBaseURL(),
                        fullName: allUsers.first.fullname,
                        strokeWidth: 2,
                        strokeColor:
                        whitePure(context).withValues(alpha: .55),
                      ),
                    ),
                    Positioned(
                      left: 5,
                      top: 0,
                      bottom: 0,
                      child: Align(
                        alignment: AlignmentDirectional.bottomStart,
                        child: CustomImage(
                          size: Size(smallImageSize, smallImageSize),
                          image: allUsers[1].profile?.addBaseURL(),
                          fullName: allUsers[1].fullname,
                          strokeWidth: 2,
                          strokeColor:
                          whitePure(context).withValues(alpha: .55),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: Align(
                        alignment: AlignmentDirectional.bottomCenter,
                        child: CustomImage(
                          size: Size(smallImageSize, smallImageSize),
                          image: allUsers[2].profile?.addBaseURL(),
                          fullName: allUsers[2].fullname,
                          strokeWidth: 2,
                          strokeColor:
                          whitePure(context).withValues(alpha: .55),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 5,
                      top: 0,
                      bottom: 0,
                      child: Align(
                        alignment: AlignmentDirectional.bottomEnd,
                        child: CustomImage(
                          size: Size(smallImageSize, smallImageSize),
                          image: allUsers[3].profile?.addBaseURL(),
                          fullName: allUsers[3].fullname,
                          strokeWidth: 2,
                          strokeColor:
                          whitePure(context).withValues(alpha: .55),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
            1 => CustomImage(
              size: Size(Get.width / 3, Get.width / 3),
              image: allUsers.first.profile?.addBaseURL(),
              fullName: allUsers.first.fullname,
              strokeWidth: 2,
              strokeColor: whitePure(context).withValues(alpha: .55),
            ),
            _ => const SizedBox()
          });
    }

    Widget _buildUserInfo(AppUser? hostUser, int watchingCount) {
      return Column(
        spacing: 5,
        children: [
          if (hostUser != null)
            Container(
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                  color: whitePure(context).withValues(alpha: .15),
                  borderRadius: SmoothBorderRadius(cornerRadius: 30),
                  border: Border.all(
                      color: whitePure(context).withValues(alpha: .15))),
              child: FullNameWithBlueTick(
                  username: hostUser.username,
                  isVerify: hostUser.isVerify,
                  iconSize: 16,
                  icon: AssetRes.icVerifiedWhite,
                  style: TextStyleCustom.outFitMedium500(
                      color: whitePure(context), fontSize: 15)),
            ),
          Text(
            '${watchingCount.numberFormat} ${LKey.viewers.tr}',
            style: TextStyleCustom.outFitLight300(color: whitePure(context)),
          ),
        ],
      );
    }

    Widget _buildDescription(Livestream stream) {
      return Flexible(
          child: Text(stream.description ?? '',
              style: TextStyleCustom.outFitSemiBold600(
                  color: whitePure(context), fontSize: 19),
              maxLines: 3,
              overflow: TextOverflow.ellipsis));
    }

    Widget _buildGridItem(Livestream stream) {
      return Obx(() {
        AppUser? hostUser =
        stream.getHostUser(controller.firebaseFirestoreController.users);

        List<AppUser> allUsers =
        stream.getAllUsers(controller.firebaseFirestoreController.users);
        bool isBattleOn = stream.type == LivestreamType.battle;
        int userCount = allUsers.length;
        int count = stream.watchingCount ?? 0;
        int watchingCount = count >= 0 ? count : 0;

        return Stack(
          children: [
            _buildBlurredBackground(hostUser),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildImageContain(
                      allUsers: allUsers,
                      isBattleOn: isBattleOn,
                      userCount: userCount),
                  _buildUserInfo(hostUser, watchingCount),
                  _buildDescription(stream),
                ],
              ),
            ),
          ],
        );
      });
    }

    return Expanded(
      child: Obx(
            () {
          return controller.isLoading.value &&
              controller.livestreamFilterList.isEmpty
              ? const LoaderWidget()
              : NoDataView(
            showShow: !controller.isLoading.value &&
                controller.livestreamFilterList.isEmpty,
            title: LKey.noLivestreamsTitle,
            description: LKey.noLivestreamsDescription.tr,
            child: GridView.builder(
              itemCount: controller.livestreamFilterList.length,
              padding:
              EdgeInsets.only(bottom: AppBar().preferredSize.height),
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 1,
                  mainAxisSpacing: 1,
                  mainAxisExtent: 310),
              itemBuilder: (context, index) {
                Livestream stream =
                controller.livestreamFilterList[index];
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                      onTap: () => controller.onLiveUserTap(stream),
                      child: _buildGridItem(stream)),
                );
              },
            ),
          );
        },
      ),
    );
  }
}