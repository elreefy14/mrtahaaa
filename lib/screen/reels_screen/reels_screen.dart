import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bubbly/common/widget/loader_widget.dart';
import 'package:bubbly/common/widget/my_refresh_indicator.dart';
import 'package:bubbly/common/widget/no_data_widget.dart';
import 'package:bubbly/languages/languages_keys.dart';
import 'package:bubbly/model/post_story/post_by_id.dart';
import 'package:bubbly/model/post_story/post_model.dart';
import 'package:bubbly/screen/comment_sheet/widget/hashtag_and_mention_view.dart';
import 'package:bubbly/screen/reels_screen/reel/reel_page.dart';
import 'package:bubbly/screen/reels_screen/reels_screen_controller.dart';
import 'package:bubbly/screen/reels_screen/widget/reels_text_field.dart';
import 'package:bubbly/screen/reels_screen/widget/reels_top_bar.dart';
import 'package:bubbly/utilities/theme_res.dart';

class ReelsScreen extends StatelessWidget {
  final RxList<Post> reels;
  final int position;
  final Widget? widget;
  final Future<void> Function()? onFetchMoreData;
  final Future<void> Function()? onRefresh;
  final RxBool? isLoading;
  final PostByIdData? postByIdData;
  final bool isHomePage;

  const ReelsScreen(
      {super.key,
      required this.reels,
      required this.position,
      this.onFetchMoreData,
      this.widget,
      this.onRefresh,
      this.isLoading,
      this.postByIdData,
      this.isHomePage = false});

  @override
  Widget build(BuildContext context) {
    final ReelsScreenController controller = Get.put(
        ReelsScreenController(
            reels: reels,
            position: position.obs,
            onFetchMoreData: onFetchMoreData,
            onRefresh: onRefresh,
            isHomePage: isHomePage),
        tag: isHomePage
            ? ReelsScreenController.tag
            : '${DateTime.now().millisecondsSinceEpoch}');

    return Scaffold(
      backgroundColor: blackPure(context),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            children: [
              Expanded(
                child: MyRefreshIndicator(
                  onRefresh: onRefresh ?? () async {},
                  shouldRefresh: onRefresh != null,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Obx(() {
                        final reels = controller.reels;
                        bool _isLoading = isLoading?.value ?? false;
                        return _isLoading && reels.isEmpty
                            ? const LoaderWidget()
                            : !_isLoading && reels.isEmpty
                                ? NoDataWidgetWithScroll(
                                    title: LKey.reelsEmptyTitle.tr,
                                    description: LKey.reelsEmptyDescription.tr)
                                : PageView.builder(
                                    controller: controller.pageController,
                                    itemCount: reels.length,
                                    physics:
                                        const CustomPageViewScrollPhysics(),
                                    onPageChanged: controller.onPageChanged,
                                    scrollDirection: Axis.vertical,
                                    itemBuilder: (context, index) {
                                      final reel = reels[index];
                                      return Obx(() {
                                        CachedVideoPlayerPlus?
                                            videoController =
                                            controller.videoControllers[index];
                                        return ReelPage(
                                            reelData: reel,
                                            videoPlayerController:
                                                videoController,
                                            likeKey: GlobalKey(),
                                            postByIdData: postByIdData);
                                      });
                                    },
                                  );
                      }),
                      HashTagAndMentionUserView(
                          helper: controller.commentHelper),
                    ],
                  ),
                ),
              ),
              ReelsTextField(controller: controller),
            ],
          ),
          ReelsTopBar(controller: controller, widget: widget)
        ],
      ),
    );
  }
}

class CustomPageViewScrollPhysics extends ScrollPhysics {
  const CustomPageViewScrollPhysics({super.parent});

  @override
  CustomPageViewScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return CustomPageViewScrollPhysics(parent: buildParent(ancestor)!);
  }

  @override
  SpringDescription get spring => const SpringDescription(
        mass: 1,
        stiffness: 600,
        damping: 60,
      );
}
