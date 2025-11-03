import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:bubbly/common/extensions/common_extension.dart';
import 'package:bubbly/common/extensions/string_extension.dart';
import 'package:bubbly/common/widget/bottom_sheet_top_view.dart';
import 'package:bubbly/common/widget/custom_image.dart';
import 'package:bubbly/common/widget/full_name_with_blue_tick.dart';
import 'package:bubbly/common/widget/gradient_text.dart';
import 'package:bubbly/languages/languages_keys.dart';
import 'package:bubbly/model/general/settings_model.dart';
import 'package:bubbly/model/livestream/app_user.dart';
import 'package:bubbly/screen/gift_sheet/send_gift_sheet_controller.dart';
import 'package:bubbly/screen/coin_wallet_screen/coin_wallet_screen.dart';
import 'package:bubbly/utilities/asset_res.dart';
import 'package:bubbly/utilities/color_res.dart';
import 'package:bubbly/utilities/style_res.dart';
import 'package:bubbly/utilities/text_style_custom.dart';
import 'package:bubbly/utilities/theme_res.dart';

class SendGiftSheet extends StatelessWidget {
  final GiftType giftType;
  final BattleView battleViewType;
  final int? userId;
  final List<AppUser> streamUsers;

  const SendGiftSheet(
      {super.key,
        this.giftType = GiftType.none,
        this.battleViewType = BattleView.red,
        required this.userId,
        this.streamUsers = const []});

  @override
  Widget build(BuildContext context) {
    final controller =
    Get.put(SendGiftSheetController(giftType, userId, streamUsers));

    return Container(
      height: Get.height / 1.5,
      margin: EdgeInsets.only(top: AppBar().preferredSize.height * 2.5),
      decoration: ShapeDecoration(
        shape: const SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius.vertical(
            top: SmoothRadius(cornerRadius: 40, cornerSmoothing: 1),
          ),
        ),
        color: scaffoldBackgroundColor(context),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            BottomSheetTopView(
              title: LKey.sendGifts.tr,
              margin: const EdgeInsets.only(top: 15),
            ),
            switch (giftType) {
              GiftType.none => const SizedBox(),
              GiftType.livestream => GiftForLiveStream(
                  controller: controller, streamUsers: streamUsers),
              GiftType.battle => Container(
                width: double.infinity,
                color: battleViewType.color,
                padding: const EdgeInsets.symmetric(vertical: 7),
                margin: const EdgeInsets.only(bottom: 10),
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomImage(
                            size: const Size(30, 30),
                            image: streamUsers.first.profile?.addBaseURL(),
                            fullName: streamUsers.first.fullname,
                            strokeColor: whitePure(context),
                            strokeWidth: 1.2),
                        const SizedBox(width: 5),
                        Flexible(
                            child: FullNameWithBlueTick(
                                username: streamUsers.first.username,
                                fontColor: whitePure(context),
                                isVerify: streamUsers.first.isVerify))
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      LKey.youAreSendingCoinsTo
                          .trParams({'color': battleViewType.value}),
                      style: TextStyleCustom.outFitLight300(
                          color: whitePure(context), fontSize: 12),
                    )
                  ],
                ),
              ),
            },
            const SizedBox(height: 10),
            // Coin Balance Section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Obx(() => GradientText(
                          (controller.myUser.value?.coinWallet ?? '0')
                              .toString(),
                          gradient: StyleRes.themeGradient,
                          style: TextStyleCustom.unboundedSemiBold600(
                              fontSize: 21))),
                      const SizedBox(width: 15),
                      // Recharge Button
                      InkWell(
                        onTap: () {
                          // Navigate to Coin Wallet Screen
                          Get.to(() => const CoinWalletScreen());
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: ShapeDecoration(
                            shape: SmoothRectangleBorder(
                              borderRadius: SmoothBorderRadius(
                                  cornerRadius: 20, cornerSmoothing: 1),
                            ),
                            gradient: StyleRes.themeGradient,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add_circle_outline,
                                color: whitePure(context),
                                size: 16,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'شحن رصيد',
                                style: TextStyleCustom.outFitMedium500(
                                    color: whitePure(context), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(LKey.coinsYouHave.tr,
                      style: TextStyleCustom.outFitRegular400(
                          fontSize: 15, color: textLightGrey(context))),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(child: Obx(
                  () {
                List<Gift> gifts = controller.settings.value?.gifts ?? [];
                return GridView.builder(
                  itemCount: gifts.length,
                  padding: const EdgeInsets.symmetric(horizontal: 11),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisExtent: 126,
                      crossAxisSpacing: 5,
                      mainAxisSpacing: 5),
                  itemBuilder: (context, index) {
                    Gift gift = gifts[index];
                    return InkWell(
                      onTap: () => controller.onGiftTap(gift, context),
                      child: Container(
                        decoration: ShapeDecoration(
                          shape: SmoothRectangleBorder(
                            borderRadius: SmoothBorderRadius(
                                cornerRadius: 5, cornerSmoothing: 1),
                          ),
                          color: bgLightGrey(context),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // استخدام GiftMediaWidget بدلاً من CustomImage
                            GiftMediaWidget(
                              gift: gift,
                              size: const Size(65, 65),
                            ),
                            Text(
                                '${(gift.coinPrice ?? 0).numberFormat} ${LKey.coins.tr}',
                                style: TextStyleCustom.outFitMedium500(
                                    fontSize: 13,
                                    color: textLightGrey(context))),
                            GradientText(LKey.send.tr,
                                gradient: StyleRes.themeGradient,
                                style: TextStyleCustom.unboundedMedium500(
                                    fontSize: 13))
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ))
          ],
        ),
      ),
    );
  }
}

// Widget جديد للتعامل مع الصور والفيديوهات
class GiftMediaWidget extends StatefulWidget {
  final Gift gift;
  final Size size;

  const GiftMediaWidget({
    super.key,
    required this.gift,
    required this.size,
  });

  @override
  State<GiftMediaWidget> createState() => _GiftMediaWidgetState();
}

class _GiftMediaWidgetState extends State<GiftMediaWidget> {
  VideoPlayerController? _videoController;
  bool _isVideo = false;

  @override
  void initState() {
    super.initState();
    _checkMediaType();
  }

  void _checkMediaType() {
    final imageUrl = widget.gift.image?.addBaseURL() ?? '';
    _isVideo = imageUrl.toLowerCase().endsWith('.mp4') ||
        imageUrl.toLowerCase().endsWith('.mov') ||
        imageUrl.toLowerCase().endsWith('.avi');

    if (_isVideo && imageUrl.isNotEmpty) {
      _initializeVideo(imageUrl);
    }
  }

  void _initializeVideo(String url) {
    _videoController = VideoPlayerController.network(url);
    _videoController!.initialize().then((_) {
      if (mounted) {
        setState(() {});
        _videoController!.setLooping(true);
        _videoController!.play();
      }
    });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isVideo && _videoController != null) {
      return Container(
        width: widget.size.width,
        height: widget.size.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.black12,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _videoController!.value.isInitialized
              ? AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!),
          )
              : const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    } else {
      // للصور العادية والـ GIF
      return CustomImage(
        image: widget.gift.image?.addBaseURL(),
        size: widget.size,
        radius: 8,
      );
    }
  }
}

class GiftForLiveStream extends StatelessWidget {
  final SendGiftSheetController controller;
  final List<AppUser> streamUsers;

  const GiftForLiveStream(
      {super.key, required this.controller, required this.streamUsers});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Obx(() {
          return PopupMenuButton<AppUser>(
            initialValue:
            controller.livestreamController.selectedGiftUser.value,
            onSelected: (AppUser value) {
              controller.livestreamController.selectedGiftUser.value = value;
            },
            shape: const RoundedRectangleBorder(
              borderRadius: SmoothBorderRadius.vertical(
                  bottom: SmoothRadius(cornerRadius: 15, cornerSmoothing: 1)),
            ),
            position: PopupMenuPosition.under,
            constraints: const BoxConstraints(
                maxWidth: double.infinity, minWidth: double.infinity),
            itemBuilder: (BuildContext context) {
              return List.generate(
                streamUsers.length,
                    (index) => PopupMenuItem(
                    value: streamUsers[index],
                    padding: EdgeInsets.zero,
                    child:
                    _PopupMenuItemCustom(streamUser: streamUsers[index])),
              );
            },
            child: _PopupMenuItemCustom(
                isPopupChild: true,
                streamUser:
                controller.livestreamController.selectedGiftUser.value!),
          );
        }),
        const SizedBox(height: 3),
        Text(
          LKey.sendingCoinsMessage.tr,
          style: TextStyleCustom.outFitLight300(
              color: textLightGrey(context), fontSize: 13),
        )
      ],
    );
  }
}

class _PopupMenuItemCustom extends StatelessWidget {
  final bool isPopupChild;
  final AppUser streamUser;

  const _PopupMenuItemCustom(
      {this.isPopupChild = false, required this.streamUser});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isPopupChild ? bgLightGrey(context) : null,
      height: 45,
      width: MediaQuery.of(context).size.width - 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomImage(
            size: const Size(30, 30),
            image: streamUser.profile?.addBaseURL(),
            fullName: streamUser.fullname ?? '',
            strokeColor: whitePure(context),
            strokeWidth: 1,
          ),
          const SizedBox(width: 5),
          FullNameWithBlueTick(
            username: streamUser.username,
            isVerify: streamUser.isVerify,
            iconSize: 14,
          ),
          if (isPopupChild)
            Image.asset(AssetRes.icDownArrow_1, width: 26, height: 26),
        ],
      ),
    );
  }
}

enum GiftType {
  none,
  livestream,
  battle;
}

enum BattleView {
  red('red'),
  blue('blue');

  final String value;

  const BattleView(this.value);

  Color get color {
    switch (this) {
      case BattleView.red:
        return ColorRes.likeRed;
      case BattleView.blue:
        return ColorRes.battleProgressColor;
    }
  }
}