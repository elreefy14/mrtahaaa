import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bubbly/common/widget/black_gradient_shadow.dart';
import 'package:bubbly/common/widget/double_tap_detector.dart';
import 'package:bubbly/common/widget/loader_widget.dart';
import 'package:bubbly/model/post_story/post_by_id.dart';
import 'package:bubbly/model/post_story/post_model.dart';
import 'package:bubbly/screen/reels_screen/reel/reel_page_controller.dart';
import 'package:bubbly/screen/reels_screen/reel/widget/reel_animation_like.dart';
import 'package:bubbly/screen/reels_screen/reel/widget/reel_seek_bar.dart';
import 'package:bubbly/screen/reels_screen/reel/widget/side_bar_list.dart';
import 'package:bubbly/screen/reels_screen/reel/widget/user_information.dart';
import 'package:bubbly/utilities/asset_res.dart';
import 'package:bubbly/utilities/theme_res.dart';
import 'package:visibility_detector/visibility_detector.dart';

class ReelPage extends StatelessWidget {
  final Post reelData;
  final CachedVideoPlayerPlus? videoPlayerController;
  final GlobalKey likeKey;
  final PostByIdData? postByIdData;

  const ReelPage(
      {super.key,
      required this.reelData,
      this.videoPlayerController,
      required this.likeKey,
      this.postByIdData});

  @override
  Widget build(BuildContext context) {
    ReelController controller;
    if (Get.isRegistered<ReelController>(tag: '${reelData.id}')) {
      controller = Get.find<ReelController>(tag: '${reelData.id}');
      // Delay update until after current frame to ensure proper UI update without conflicts
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.updateReelData(reel: reelData);
        controller.notifyCommentSheet(postByIdData);
      });
    } else {
      controller = Get.put(ReelController(reelData.obs), tag: '${reelData.id}');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.notifyCommentSheet(postByIdData);
      });
    }

    Widget _buildVideoContent() {
      final size = videoPlayerController?.controller.value.size;

      bool hasVideoInitialize = videoPlayerController != null && videoPlayerController!.controller.value.isInitialized;
      return hasVideoInitialize
          ? ClipRRect(
              child: SizedBox.expand(
                child: FittedBox(
                  fit: (size?.width ?? 0) < (size?.height ?? 0)
                      ? BoxFit.cover
                      : BoxFit.fitWidth,
                  child: SizedBox(
                    width: size?.width ?? 0,
                    height: size?.height ?? 0,
                    child: VideoPlayer(videoPlayerController!.controller),
                  ),
                ),
              ),
            )
          : const LoaderWidget();
    }

    Widget _buildPlayPauseOverlay(CachedVideoPlayerPlus? controller) {
      if (controller == null) return const SizedBox.shrink();
      return ValueListenableBuilder(
        valueListenable: controller.controller,
        builder: (context, value, child) {
          return AnimatedOpacity(
            duration: const Duration(milliseconds: 10),
            opacity: value.isPlaying ? 0.0 : 1.0,
            child: Align(
              alignment: Alignment.center,
              child: ClipRRect(
                borderRadius: SmoothBorderRadius(
                  cornerRadius: 30,
                  cornerSmoothing: 1,
                ),
                child: Container(
                    height: 60,
                    width: 60,
                    decoration: BoxDecoration(
                        color: blackPure(context).withValues(alpha: 0.5),
                        shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Image.asset(
                        value.isPlaying ? AssetRes.icPause : AssetRes.icPlay,
                        width: 35,
                        height: 35,
                        color: bgGrey(context))),
              ),
            ),
          );
        },
      );
    }

    void _togglePlayPause() {
      if (videoPlayerController == null) {
        return;
      }
      final controllerValue = videoPlayerController!.controller.value;
      if (!controllerValue.isInitialized) {
        return;
      }

      if (controllerValue.isPlaying) {
        videoPlayerController!.controller.pause();
      } else {
        videoPlayerController!.controller.play();
      }
    }

    void _handleVisibilityChanged(VisibilityInfo info) {
      if (videoPlayerController == null) {
        return;
      }
      final controllerValue = videoPlayerController!.controller.value;
      if (!controllerValue.isInitialized) {
        return;
      }

      if ((info.visibleFraction * 100) > 90) {
        videoPlayerController!.controller.play();
      } else {
        videoPlayerController!.controller.pause();
      }
    }

    Rx<TapDownDetails?> details = Rx(null);

    return Scaffold(
      backgroundColor: blackPure(context),
      resizeToAvoidBottomInset: false,
      body: VisibilityDetector(
        key: Key('ke1${reelData.video ?? ''}'),
        onVisibilityChanged: _handleVisibilityChanged,
        child: DoubleTapDetector(
          onDoubleTap: (value) {
            if (details.value != null) return;
            details.value = value;
          },
          child: InkWell(
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
              _togglePlayPause();
            },
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                _buildVideoContent(),
                const BlackGradientShadow(),
                ReelInfoSection(
                    controller: controller,
                    likeKey: likeKey,
                    videoPlayerPlusController: videoPlayerController),
                if (videoPlayerController != null)
                  _buildPlayPauseOverlay(videoPlayerController),
                Obx(() {
                  if (details.value == null) {
                    return const SizedBox();
                  }
                  return ReelAnimationLike(
                    likeKey: likeKey,
                    position: details.value!.globalPosition,
                    size: const Size(50, 50),
                    leftRightPosition: 8,
                    onLikeCall: () {
                      if (controller.reelData.value.isLiked == true) return;
                      controller.onLikeTap();
                    },
                    onCompleteAnimation: () {
                      details.value = null;
                    },
                  );
                })
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ReelInfoSection extends StatelessWidget {
  final ReelController controller;
  final GlobalKey likeKey;
  final CachedVideoPlayerPlus? videoPlayerPlusController;

  const ReelInfoSection(
      {super.key,
      required this.controller,
      required this.likeKey,
      required this.videoPlayerPlusController});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ReelInfoRow(controller: controller, likeKey: likeKey),
        ReelSeekBar(
            videoController: videoPlayerPlusController,
                controller: controller),
      ],
    );
  }
}

class ReelInfoRow extends StatelessWidget {
  final ReelController controller;
  final GlobalKey likeKey;

  const ReelInfoRow(
      {super.key, required this.controller, required this.likeKey});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: UserInformation(controller: controller)),
        SideBarList(controller: controller, likeKey: likeKey),
      ],
    );
  }
}
