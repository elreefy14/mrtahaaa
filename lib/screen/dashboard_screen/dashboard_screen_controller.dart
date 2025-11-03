import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:bubbly/common/controller/ads_controller.dart';
import 'package:bubbly/common/controller/base_controller.dart';
import 'package:bubbly/common/manager/logger.dart';
import 'package:bubbly/common/manager/session_manager.dart';
import 'package:bubbly/common/service/subscription/subscription_manager.dart';
import 'package:bubbly/common/widget/restart_widget.dart';
import 'package:bubbly/languages/languages_keys.dart';
import 'package:bubbly/model/chat/chat_thread.dart';
import 'package:bubbly/model/general/settings_model.dart';
import 'package:bubbly/model/user_model/user_model.dart';
import 'package:bubbly/model/post_story/post_model.dart';
import 'package:bubbly/model/post_story/story/story_model.dart';
import 'package:bubbly/screen/camera_screen/camera_screen.dart';
import 'package:bubbly/screen/feed_screen/feed_screen_controller.dart';
import 'package:bubbly/screen/create_feed_screen/create_feed_screen.dart';
import 'package:bubbly/screen/live_stream/create_live_stream_screen/create_live_stream_screen.dart';
import 'package:bubbly/utilities/asset_res.dart';
import 'package:bubbly/utilities/firebase_const.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

class DashboardScreenController extends GetxController
    with GetSingleTickerProviderStateMixin {

  // Updated navigation order: Home, Explore, Feed, Profile, Messages
  List<String> bottomIconList = [
    AssetRes.icReel,     // Home
    AssetRes.icSearch,   // Explore
    AssetRes.icPost,     // Feed
    AssetRes.icProfile,  // Profile
    AssetRes.icChat      // Messages
  ];

  RxInt selectedPageIndex = 0.obs;
  RxDouble scaleValue = 1.0.obs;
  Function(int index)? onBottomIndexChanged;
  Rx<PostUploadingProgress> postProgress = Rx(PostUploadingProgress());
  Function(PostUploadingProgress progress) onProgress = (_) {};

  late AnimationController animationController;

  FirebaseFirestore db = FirebaseFirestore.instance;
  RxInt unReadCount = 0.obs;

  late StreamSubscription _unReadCountSubscription;
  late Animation<double> scaleAnimation;
  User? user = SessionManager.instance.getUser();

  @override
  void onInit() {
    super.onInit();

    animationController = AnimationController(
        duration: const Duration(milliseconds: 200), vsync: this);
    scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeInOut),
    )..addListener(() {
      scaleValue.value = scaleAnimation.value;
      // تحديث UI للتأثيرات البصرية
      update(['nav_item_${selectedPageIndex.value}']);
    });
    onProgress = (progress) {
      postProgress.value = progress;
      // تحديث UI لشريط التقدم
      update(['bottom_nav']);
    };
  }

  @override
  void onReady() async {
    super.onReady();
    createZegoEngine();
    _fetchLanguageFromUser();
    _fetchUnReadCount();
  }

  @override
  void onClose() {
    animationController.dispose();
    _unReadCountSubscription.cancel();
    super.onClose();
  }

  onChanged(int index) {
    // Handle Feed tab specifically (index 2)
    if (index == 2) {
      onFeedPostScrollDown(index);
    }
    if (selectedPageIndex.value == index) return;
    HapticFeedback.lightImpact();
    onBottomIndexChanged?.call(index);
    selectedPageIndex.value = index;

    // تحديث UI
    update(['main_content', 'floating_chat', 'floating_message_btn', 'bottom_nav']);

    animationController
      ..reset()
      ..forward();
  }

  onFeedPostScrollDown(int index) {
    if (selectedPageIndex.value != index) return;
    if (Get.isRegistered<FeedScreenController>()) {
      final controller = Get.find<FeedScreenController>();
      if (controller.posts.isNotEmpty && !controller.isLoading.value) {
        controller.postScrollController.animateTo(0.0,
            duration: const Duration(milliseconds: 150), curve: Curves.linear);
        controller.refreshKey.currentState?.show();
      }
    }
  }

  void _fetchUnReadCount() {
    _unReadCountSubscription = db
        .collection(FirebaseConst.users)
        .doc(user?.id.toString())
        .collection(FirebaseConst.usersList)
        .where(FirebaseConst.isDeleted, isEqualTo: false)
        .withConverter(
        fromFirestore: (snapshot, options) =>
            ChatThread.fromJson(snapshot.data()!),
        toFirestore: (ChatThread value, options) => value.toJson())
        .snapshots()
        .listen((event) {
      final count =
          event.docs.where((doc) => (doc.data().msgCount ?? 0) > 0).length;
      unReadCount.value = count;
      // تحديث UI لعدد الرسائل غير المقروءة
      update(['unread_count', 'floating_chat']);
    });
  }

  Future<void> createZegoEngine() async {
    Setting? appSetting = SessionManager.instance.getSettings();
    int appId = int.parse(appSetting?.zegoAppId ?? '0');
    try {
      await ZegoExpressEngine.createEngineWithProfile(ZegoEngineProfile(
          appId, ZegoScenario.Default,
          appSign: appSetting?.zegoAppSign));
    } on MissingPluginException catch (e) {
      Loggers.error('Create Zego Engine : ${e.message}');
    }
  }

  Future<void> _fetchLanguageFromUser() async {
    String savedLanguage = SessionManager.instance.getLang();
    String userLanguage = user?.appLanguage ?? 'en';
    if (userLanguage != savedLanguage) {
      SessionManager.instance.setLang(userLanguage);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        RestartWidget.restartApp(Get.context!);
      });
    }
  }

  // Add methods to handle publish options from the center add button
  void onAddPost({Post? post, CreateFeedType? type}) {
    if (post == null) return;
    // Handle post addition logic here
  }

  void onAddStory(Story? story) {
    if (story == null) return;
    // Handle story addition logic here
  }

  // Publish option handlers
  void onCreateFeed() {
    Get.to(() => CreateFeedScreen(
        createType: CreateFeedType.feed,
        onAddPost: onAddPost));
  }

  void onCreateStory() {
    Get.to(() => const CameraScreen(cameraType: CameraScreenType.story));
  }

  void onCreateReel() {
    Get.to(() => const CameraScreen(cameraType: CameraScreenType.post));
  }

  void onGoLive() {
    Get.to(() => const CreateLiveStreamScreen());
  }
}

class PostUploadingProgress {
  final CameraScreenType type;
  final UploadType uploadType;
  final double progress;

  PostUploadingProgress(
      {this.type = CameraScreenType.post,
        this.progress = 0,
        this.uploadType = UploadType.none});
}

enum UploadType {
  none,
  finish,
  error,
  uploading;

  String title(CameraScreenType type) {
    switch (this) {
      case UploadType.none:
        return '';
      case UploadType.finish:
        return type == CameraScreenType.post
            ? LKey.postUploadSuccessfully.tr
            : LKey.storyUploadSuccess.tr;
      case UploadType.error:
        return LKey.uploadingFailed.tr;
      case UploadType.uploading:
        return type == CameraScreenType.post
            ? LKey.postIsBeginUploading.tr
            : LKey.storyIsBeginUploading.tr;
    }
  }
}