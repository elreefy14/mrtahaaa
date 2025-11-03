import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bubbly/common/controller/base_controller.dart';
import 'package:bubbly/common/functions/debounce_action.dart';
import 'package:bubbly/common/manager/branch_io_manager.dart';
import 'package:bubbly/common/manager/firebase_notification_manager.dart';
import 'package:bubbly/common/manager/haptic_manager.dart';
import 'package:bubbly/common/manager/logger.dart';
import 'package:bubbly/common/manager/session_manager.dart';
import 'package:bubbly/common/service/api/post_service.dart';
import 'package:bubbly/common/service/navigation/navigate_with_controller.dart';
import 'package:bubbly/languages/languages_keys.dart';
import 'package:bubbly/model/general/status_model.dart';
import 'package:bubbly/model/post_story/music/music_model.dart';
import 'package:bubbly/model/post_story/post_by_id.dart';
import 'package:bubbly/model/post_story/post_model.dart';
import 'package:bubbly/model/user_model/user_model.dart';
import 'package:bubbly/screen/audio_details_screen/audio_sheet.dart';
import 'package:bubbly/screen/comment_sheet/comment_sheet.dart';
import 'package:bubbly/screen/gift_sheet/send_gift_sheet_controller.dart';
import 'package:bubbly/screen/post_screen/post_screen_controller.dart';
import 'package:bubbly/screen/saved_post_screen/saved_post_screen_controller.dart';

class ReelController extends BaseController {
  Rx<Post> reelData;
  bool isLikeLoading = false;
  bool isSavedLoading = false;

  User? get myUser => SessionManager.instance.getUser();
  Timer? _debounce;

  ReelController(this.reelData) {
    reelData.listen((p0) {
      if (p0.postType == PostType.video &&
          Get.isRegistered<PostScreenController>(tag: '${p0.id}')) {
        final controller = Get.find<PostScreenController>(tag: '${p0.id}');
        controller.updatePost(p0);
      }
    });
  }

  @override
  void onClose() {
    super.onClose();
    reelData.close();
    _debounce?.cancel();
  }

  updateReelData({Post? reel}) {
    if (reel != null) {
      reelData.value = reel;
    }
  }

  void onLikeTap() {
    if (reelData.value.isLiked == false) {
      HapticManager.shared.light();
    }
    FocusManager.instance.primaryFocus?.unfocus();
    int reelId = reelData.value.id?.toInt() ?? -1;

    if (reelId == -1) {
      return Loggers.error('Invalid Post id : $reelId');
    }

    reelData.update((val) {
      val?.likeToggle(val.isLiked == true ? false : true);
    });
    print('object');
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), () async {
      try {
        await (reelData.value.isLiked == true
            ? _likePostApi(reelId)
            : _disLikePostApi(reelId));
        // if (reelData.value.postType == PostType.video &&
        //     Get.isRegistered<PostScreenController>(tag: '$reelId')) {
        //   final controller = Get.find<PostScreenController>(tag: '$reelId');
        //   controller.updatePost(reelData.value);
        // }
      } catch (e) {
        Loggers.error('ERROR IN LIKE  REEL $e');
      }
    });
  }

  Future<void> _likePostApi(int id) async {
    StatusModel result = await PostService.instance.likePost(postId: id);
    if (result.status == true) {
      Post? reel = reelData.value;
      if (reel.user?.notifyPostLike == 1 && myUser?.id != reel.userId) {
        FirebaseNotificationManager.instance.sendLocalisationNotification(
            LKey.activityLikedPost,
            type: NotificationType.post,
            body: NotificationInfo(id: reel.id),
            deviceType: reel.user?.device ?? 0,
            deviceToken: reel.user?.deviceToken ?? '',
            languageCode: reel.user?.appLanguage);
      }
    }
  }

  Future<void> _disLikePostApi(int id) async {
    await PostService.instance.disLikePost(postId: id);
  }

  Future<void> onCommentTap(
      {PostByIdData? postByIdData, bool isFromNotification = false}) async {
    FocusManager.instance.primaryFocus?.unfocus();

    await Get.bottomSheet(
        CommentSheet(
          replyComment: postByIdData?.reply,
          comment: postByIdData?.comment,
          post: reelData.value,
          isFromNotification: isFromNotification,
        ),
        isScrollControlled: true,
        backgroundColor: Colors.transparent);
  }

  void onSaved() {
    FocusManager.instance.primaryFocus?.unfocus();
    int reelId = reelData.value.id?.toInt() ?? -1;
    if (reelId == -1) {
      return Loggers.error('Invalid Post id : $reelId');
    }

    if (isSavedLoading) {
      return Loggers.error('Is saved loading : $isSavedLoading');
    }
    isSavedLoading = true;
    HapticManager.shared.light();
    reelData.update((val) {
      val?.saveToggle(val.isSaved == true ? false : true);
    });

    DebounceAction.shared.call(() async {
      if (reelData.value.id == null) {
        return Loggers.error('Reel value not found');
      }
      await ((reelData.value.isSaved ?? false)
          ? _savePostApi(reelId)
          : _unSavePostApi(reelId));
      isSavedLoading = false;
    });
  }

  Future<void> _savePostApi(int id) async {
    StatusModel result = await PostService.instance.savePost(postId: id);
    if (result.status == true) {
      if (Get.isRegistered<SavedPostScreenController>()) {
        final controller = Get.find<SavedPostScreenController>();
        controller.unsavedIds.removeWhere((element) => element == id);
      }
    }
  }

  Future<void> _unSavePostApi(int id) async {
    StatusModel result = await PostService.instance.unSavePost(postId: id);
    if (result.status == true) {
      if (Get.isRegistered<SavedPostScreenController>()) {
        final controller = Get.find<SavedPostScreenController>();
        controller.unsavedIds.add(id);
      }
    }
  }

  void onShareTap() {
    FocusManager.instance.primaryFocus?.unfocus();
    BranchIoManager.instance.shareContent(
        type: ShareBranchType.post,
        post: reelData.value,
        onShareSuccess: () {
          reelData.update((val) => val?.increaseShares(1));
        });
  }

  void onGiftTap() {
    FocusManager.instance.primaryFocus?.unfocus();
    GiftManager.openGiftSheet(
      userId: reelData.value.userId ?? -1,
      onCompletion: (giftManager) {
        GiftManager.showAnimationDialog(giftManager.gift);
        GiftManager.sendNotification(reelData.value);
      },
    );
  }

  void onAudioTap(Music? music) async {
    FocusManager.instance.primaryFocus?.unfocus();

    await Get.bottomSheet(AudioSheet(music: music), isScrollControlled: true);
  }

  void onUserTap(User? user) {
    if (reelData.value.id == -1) return;
    NavigationService.shared.openProfileScreen(user);
  }

  void notifyCommentSheet(PostByIdData? data) {
    if (data != null && (data.comment != null || data.reply != null)) {
      DebounceAction.shared.call(() {
        onCommentTap(postByIdData: data, isFromNotification: true);
      }, milliseconds: 1000);
    }
  }
}
