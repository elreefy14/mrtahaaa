import 'dart:async';
import 'dart:io';

import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bubbly/common/controller/base_controller.dart';
import 'package:bubbly/common/extensions/string_extension.dart';
import 'package:bubbly/common/functions/debounce_action.dart';
import 'package:bubbly/common/manager/logger.dart';
import 'package:bubbly/common/service/api/post_service.dart';
import 'package:bubbly/model/post_story/comment/fetch_comment_model.dart';
import 'package:bubbly/model/post_story/post_model.dart';
import 'package:bubbly/screen/comment_sheet/helper/comment_helper.dart';
import 'package:bubbly/screen/dashboard_screen/dashboard_screen_controller.dart';
import 'package:bubbly/screen/home_screen/home_screen_controller.dart';
import 'package:bubbly/screen/reels_screen/reel/reel_page_controller.dart';
import 'package:bubbly/screen/report_sheet/report_sheet.dart';
import 'package:bubbly/utilities/app_res.dart';

class ReelsScreenController extends BaseController {
  static const tag = 'REEL';
  RxBool isVideoDisposing = false.obs;

  DashboardScreenController dashboardController =
  Get.find<DashboardScreenController>();

  HomeScreenController homeScreenController = Get.find<HomeScreenController>();
  final RxDouble previousPosition = 0.0.obs;

  RxMap<int, CachedVideoPlayerPlus> videoControllers =
      <int, CachedVideoPlayerPlus>{}.obs;

  RxList<Post> reels = <Post>[].obs;
  RxInt position = 0.obs;
  Rx<TabType> selectedReelCategory = TabType.values.first.obs;
  PageController pageController = PageController();
  CommentHelper commentHelper = CommentHelper();
  Future<void> Function()? onFetchMoreData;
  Future<void> Function()? onRefresh;
  bool isHomePage;

  // Add this flag to track disposal state
  bool _isDisposed = false;

  ReelsScreenController(
      {required this.reels,
        required this.position,
        required this.onFetchMoreData,
        this.onRefresh,
        required this.isHomePage});

  @override
  void onInit() {
    super.onInit();
    pageController = PageController(initialPage: position.value);
    if (isHomePage) {
      _setupDashboardController();
    }
    if (!isHomePage) {
      initVideoPlayer();
    }
  }

  @override
  void onClose() {
    _isDisposed = true;
    super.onClose();
    disposeAllController();
  }

  void _setupDashboardController() {
    dashboardController.onBottomIndexChanged = (index) {
      if (_isDisposed) return;

      if (index == 0) {
        videoControllers[position.value]?.controller.play();
      } else {
        videoControllers[position.value]?.controller.pause();
      }
    };
  }

  Future<void> _fetchMoreData() async {
    if (_isDisposed) return;

    if (position >= reels.length - 3) {
      await onFetchMoreData?.call().then((value) {
        if (!_isDisposed) {
          _initializeControllerAtIndex(position.value + 1);
        }
      });
    }
  }

  void onReportTap() {
    if (_isDisposed) return;

    Get.bottomSheet(
        ReportSheet(
            reportType: ReportType.post, id: reels[position.value].id?.toInt()),
        isScrollControlled: true);
  }

  Future<void> initVideoPlayer() async {
    if (_isDisposed) return;

    /// Initialize 1st video
    await _initializeControllerAtIndex(position.value);

    if (_isDisposed) return;

    /// Play 1st video
    _playControllerAtIndex(position.value);

    /// Initialize 2nd video
    if (position >= 0 && !_isDisposed) {
      await _initializeControllerAtIndex(position.value - 1);
    }
    if (!_isDisposed) {
      await _initializeControllerAtIndex(position.value + 1);
    }
  }

  void _playNextReel(int index) {
    if (_isDisposed) return;

    _stopControllerAtIndex(index - 1); // Ensure previous reel is stopped
    _disposeControllerAtIndex(index - 2); // Dispose the older controller
    _playControllerAtIndex(index); // Play the new reel
    _initializeControllerAtIndex(index + 1); // Preload the next reel
  }

  void _playPreviousReel(int index) {
    if (_isDisposed) return;

    _stopControllerAtIndex(index + 1); // Ensure next reel is stopped
    _disposeControllerAtIndex(index + 2); // Dispose the older controller
    _playControllerAtIndex(index); // Play the previous reel
    _initializeControllerAtIndex(index - 1); // Preload the previous reel
  }

  RxBool isLoadingVideo = false.obs;

  Future _initializeControllerAtIndex(int index) async {
    if (_isDisposed || reels.length <= index || index < 0) return;

    try {
      /// Create new controller
      final CachedVideoPlayerPlus controller = reels.first.id == -1
          ? CachedVideoPlayerPlus.file(File(reels.first.video ?? ''))
          : CachedVideoPlayerPlus.networkUrl(
          Uri.parse((reels[index].video?.addBaseURL() ?? '')),
          invalidateCacheIfOlderThan: const Duration(seconds: 7));

      /// Add to [controllers] list
      videoControllers[index] = controller;

      if (!_isDisposed) {
        isLoadingVideo.value = true;
      }

      /// Initialize
      await controller.initialize();

      if (_isDisposed) {
        // If disposed during initialization, clean up the controller
        controller.dispose();
        videoControllers.remove(index);
        return;
      }

      isLoadingVideo.value = false;

      Loggers.info('🚀🚀🚀 INITIALIZED $index');
      Loggers.info(
          '############################################################');
    } catch (e) {
      if (!_isDisposed) {
        isLoadingVideo.value = false;
      }
      Loggers.error('Error initializing controller at index $index: $e');
    }
  }

  void _playControllerAtIndex(int index) async {
    if (_isDisposed || reels.length <= index || index < 0) return;

    if (dashboardController.selectedPageIndex.value != 0 && isHomePage) {
      return;
    }

    try {
      CachedVideoPlayerPlus? controller = videoControllers[index];
      if (controller != null && controller.controller.value.isInitialized && !_isDisposed) {
        await controller.controller.play();
        controller.controller.setLooping(true);
        videoControllers.refresh();

        if (!_isDisposed) {
          DebounceAction.shared.call(() {
            if (!_isDisposed) {
              _increaseViewsCount(reels[index]);
            }
          }, milliseconds: 3000);
        }

        Loggers.info('🚀🚀🚀 PLAYING $index');
      } else if (!_isDisposed) {
        await _initializeControllerAtIndex(index);
        _playControllerAtIndex(index);
      }
    } catch (e) {
      Loggers.error('Error playing controller at index $index: $e');
    }
  }

  void _increaseViewsCount(Post? post) async {
    if (_isDisposed || post == null || post.id == null) {
      return Loggers.error('Post not found or ID is null');
    }

    final postId = post.id ?? -1;
    if (postId == -1) {
      return Loggers.error('Post ID $postId not found in reels');
    }

    final reelIndex = reels.indexWhere((element) => element.id == postId);
    if (reelIndex == -1 || _isDisposed) {
      return Loggers.error('Post ID $postId not found in reels');
    }

    try {
      final response =
      await PostService.instance.increaseViewsCount(postId: postId);

      if (response.status == true && !_isDisposed) {
        post.increaseViews();
        reels[reelIndex] = post;

        final controllerTag = postId.toString();
        if (Get.isRegistered<ReelController>(tag: controllerTag)) {
          Get.find<ReelController>(tag: controllerTag).updateReelData(reel: post);
        }
      }
    } catch (e) {
      Loggers.error('Error increasing views count: $e');
    }
  }

  void _stopControllerAtIndex(int index) {
    if (_isDisposed || reels.length <= index || index < 0) return;

    try {
      final controller = videoControllers[index];
      if (controller != null && controller.controller.value.isInitialized) {
        controller.controller.pause();
        controller.controller.seekTo(const Duration()); // Reset position
        Loggers.info('🚀🚀🚀 STOPPED $index');
      }
    } catch (e) {
      Loggers.error('Error stopping controller at index $index: $e');
    }
  }

  Future<void> _disposeControllerAtIndex(int index) async {
    if (_isDisposed || reels.length <= index || index < 0) return;

    try {
      final CachedVideoPlayerPlus? controller =
      videoControllers[index];
      if (controller != null) {
        _stopControllerAtIndex(index); // Ensure the video is stopped before disposal
        await controller.dispose();
        videoControllers.remove(index);
        Loggers.info('🚀🚀🚀 DISPOSED $index');
      }
    } catch (e) {
      Loggers.error('Error disposing controller at index $index: $e');
    }
  }

  Future<void> disposeAllController() async {
    isVideoDisposing.value = true;

    final controllersToDispose = Map<int, CachedVideoPlayerPlus>.from(videoControllers);
    videoControllers.clear(); // Clear early to prevent usage during async dispose

    for (var entry in controllersToDispose.entries) {
      try {
        final controller = entry.value;
        if (controller.controller.value.isInitialized) {
          await controller.controller.pause(); // Optional: pause before disposing
        }
        await controller.dispose();
      } catch (e, stack) {
        print('❌ Failed to dispose controller at index ${entry.key}: $e');
        print(stack);
      }
    }

    isVideoDisposing.value = false;
  }

  void onPageChanged(int index) {
    if (_isDisposed) return;

    commentHelper.detectableTextFocusNode.unfocus();
    commentHelper.detectableTextController.clear();

    if (index > position.value) {
      _fetchMoreData();
      _playNextReel(index);
    } else {
      _playPreviousReel(index);
    }
    position.value = index;
  }

  void onUpdateComment(Comment comment, bool isReplyComment) {
    if (_isDisposed) return;

    final post = reels.firstWhereOrNull((e) => e.id == comment.postId);
    if (post == null) {
      return Loggers.error('Post not found');
    }
    final controllerTag = post.id.toString();
    if (Get.isRegistered<ReelController>(tag: controllerTag)) {
      Get.find<ReelController>(tag: controllerTag)
          .reelData
          .update((val) => val?.updateCommentCount(1));
    }
  }

  Future<void> onRefreshPage(List<Post> reels) async {
    if (_isDisposed || onRefresh == null) return;

    try {
      position.value = 0;

      if (pageController.hasClients && !_isDisposed) {
        pageController.jumpToPage(position.value);
      }

      if (_isDisposed) return;

      final CachedVideoPlayerPlus controller =
      CachedVideoPlayerPlus.networkUrl(
          Uri.parse((reels[position.value].video?.addBaseURL() ?? '')));
      await controller.initialize();

      if (_isDisposed) {
        await controller.dispose();
        return;
      }

      // Step 2: Dispose old controllers not needed anymore
      await disposeAllController();

      if (!_isDisposed) {
        videoControllers[position.value] = controller;

        /// Play 1st video
        _playControllerAtIndex(position.value);
        await _initializeControllerAtIndex(position.value + 1);
      }
    } catch (e) {
      Loggers.error('Error refreshing page: $e');
    }
  }
}