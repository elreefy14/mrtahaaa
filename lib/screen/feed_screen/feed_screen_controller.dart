import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:bubbly/common/controller/base_controller.dart';
import 'package:bubbly/common/manager/session_manager.dart';
import 'package:bubbly/common/service/api/post_service.dart';
import 'package:bubbly/common/service/api/user_service.dart';
import 'package:bubbly/common/service/location/location_service.dart';
import 'package:bubbly/languages/languages_keys.dart';
import 'package:bubbly/model/post_story/post_model.dart';
import 'package:bubbly/model/post_story/story/story_model.dart';
import 'package:bubbly/model/user_model/user_model.dart';
import 'package:bubbly/screen/camera_screen/camera_screen.dart';
import 'package:bubbly/screen/profile_screen/profile_screen_controller.dart';
import 'package:bubbly/screen/story_view_screen/story_view_screen.dart';

class FeedScreenController extends GetxController {
  // استخدم List عادي بدلاً من RxList
  List<Post> posts = [];
  List<User> stories = [];

  // احتفظ بـ Rx للمتغيرات التي تحتاج reactive behavior فقط
  Rx<PostCategory> selectedPostCategory = PostCategory.discover.obs;
  RxBool isLoading = false.obs;
  RxBool isStoriesLoading = false.obs;
  Rx<User?> myUser;

  ScrollController postScrollController = ScrollController();

  FeedScreenController(this.myUser);

  final GlobalKey<RefreshIndicatorState> refreshKey =
  GlobalKey<RefreshIndicatorState>();

  @override
  void onInit() {
    super.onInit();
    initData();
    postScrollController.addListener(_loadMoreData);
  }

  initData() {
    Future.wait([fetchDiscoverPost(), _fetchStory()]);
  }

  Future<void> _fetchMyUser() async {
    try {
      User? user = await UserService.instance.fetchUserDetails();
      if (user != null) {
        myUser.value = user;
        // تحديث UI للمعلومات الشخصية
        update(['user_info']);
      }
    } catch (e) {
      print('Error fetching user: $e');
    }
  }

  Future<void> _fetchStory({bool isEmpty = false}) async {
    try {
      isStoriesLoading.value = true;
      update(['stories_loading']);

      List<User> items = await PostService.instance.fetchStory();
      if (isEmpty) {
        stories.clear();
      }
      stories.addAll(items);

      isStoriesLoading.value = false;
      // تحديث UI للقصص
      update(['stories_list', 'stories_loading']);
    } catch (e) {
      isStoriesLoading.value = false;
      update(['stories_loading']);
      print('Error fetching stories: $e');
    }
  }

  Future<void> fetchDiscoverPost({bool isEmpty = false}) async {
    if (isLoading.value) return;

    try {
      isLoading.value = true;
      update(['loading_state']);

      List<Post> _post = await PostService.instance.fetchPostsDiscover(type: PostType.posts);
      _addDataInPostList(_post, isEmpty);
    } catch (e) {
      isLoading.value = false;
      update(['loading_state']);
      print('Error fetching posts: $e');
    }
  }

  Future<void> _fetchPostsFollowing({bool isEmpty = false}) async {
    if (isLoading.value) return;

    try {
      isLoading.value = true;
      update(['loading_state']);

      List<Post> _post = await PostService.instance.fetchPostsFollowing(type: PostType.posts);
      _addDataInPostList(_post, isEmpty);
    } catch (e) {
      isLoading.value = false;
      update(['loading_state']);
      print('Error fetching following posts: $e');
    }
  }

  Future<void> _fetchPostsNearBy({bool isEmpty = false}) async {
    if (isLoading.value) return;

    try {
      isLoading.value = true;
      update(['loading_state']);

      Position position = await LocationService.instance
          .getCurrentLocation(isPermissionDialogShow: true);

      List<Post> _post = await PostService.instance.fetchPostsNearBy(
          type: PostType.posts,
          placeLat: position.latitude,
          placeLon: position.longitude);

      _addDataInPostList(_post, isEmpty);
    } catch (e) {
      isLoading.value = false;
      update(['loading_state']);
      print('Error fetching nearby posts: $e');
    }
  }

  _addDataInPostList(List<Post> newList, bool isEmpty) async {
    try {
      if (isEmpty) {
        posts.clear();
      }
      posts.addAll(newList);

      await Future.delayed(const Duration(milliseconds: 200));
      isLoading.value = false;

      // تحديث UI للمنشورات والحالة
      update(['posts_list', 'loading_state', 'pagination_loader']);
    } catch (e) {
      isLoading.value = false;
      update(['loading_state']);
      print('Error adding posts: $e');
    }
  }

  void _removeAndDisposeListener() {
    try {
      postScrollController.removeListener(_loadMoreData);
      postScrollController.dispose();
    } catch (e) {
      print('Error disposing controller: $e');
    }
  }

  Future<void> onChangeCategory(PostCategory value) async {
    try {
      selectedPostCategory.value = value;
      isLoading.value = false;
      update(['category_change']);

      switch (value) {
        case PostCategory.discover:
          await fetchDiscoverPost(isEmpty: true);
        case PostCategory.nearby:
          try {
            await _fetchPostsNearBy(isEmpty: true);
          } catch (e) {
            selectedPostCategory.value = PostCategory.discover;
            await fetchDiscoverPost(isEmpty: true);
          }
        case PostCategory.following:
          await _fetchPostsFollowing(isEmpty: true);
      }
    } catch (e) {
      print('Error changing category: $e');
    }
  }

  Future<void> onRefresh() async {
    try {
      await Future.wait([
        onChangeCategory(selectedPostCategory.value),
        _fetchStory(isEmpty: true),
        _fetchMyUser(),
      ]);
    } catch (e) {
      print('Error refreshing: $e');
    }
  }

  void onCreateStory() {
    Get.to(() => const CameraScreen(cameraType: CameraScreenType.story));
  }

  void onAddStory(Story? story) {
    if (story == null) return;

    try {
      myUser.update((val) {
        val?.stories?.add(story);
      });
      // تحديث UI للمعلومات الشخصية والقصص
      update(['user_info', 'stories_list']);
    } catch (e) {
      print('Error adding story: $e');
    }
  }

  void onWatchStory(List<User> users, int index, String watchType) {
    Get.bottomSheet(
      StoryViewSheet(
        stories: users,
        userIndex: index,
        onUpdateDeleteStory: (story) {
          try {
            final userId = story?.userId;
            final storyId = story?.id;

            if (userId == SessionManager.instance.getUserID()) {
              // Update profile screen controller if registered
              if (Get.isRegistered<ProfileScreenController>(
                  tag: ProfileScreenController.tag)) {
                final controller = Get.find<ProfileScreenController>(
                    tag: ProfileScreenController.tag);
                controller.userData.update((val) {
                  val?.stories?.removeWhere((s) => s.id == storyId);
                });
              }

              // Update current user stories
              myUser.update((val) {
                val?.stories?.removeWhere((s) => s.id == storyId);
              });
              update(['user_info']);
            } else {
              // Remove story from other user's list
              final userIndex = stories.indexWhere((u) => u.id == userId);
              if (userIndex != -1) {
                (stories[userIndex].stories ?? [])
                    .removeWhere((s) => s.id == storyId);
                update(['stories_list']);
              }
            }
          } catch (e) {
            print('Error updating story: $e');
          }
        },
      ),
      isScrollControlled: true,
      ignoreSafeArea: false,
      useRootNavigator: true,
    ).then((value) {
      switch (watchType) {
        case 'my_story':
          _fetchMyUser();
          break;
        case 'other_story':
          _fetchStory(isEmpty: true);
      }
    });
  }

  Future<void> _loadMoreData() async {
    try {
      if (postScrollController.position.pixels >=
          (postScrollController.position.maxScrollExtent - 300) &&
          !isLoading.value) {
        switch (selectedPostCategory.value) {
          case PostCategory.discover:
            await fetchDiscoverPost();
          case PostCategory.nearby:
            await _fetchPostsNearBy();
          case PostCategory.following:
            await _fetchPostsFollowing();
        }
      }
    } catch (e) {
      print('Error loading more data: $e');
    }
  }

  @override
  void onClose() {
    super.onClose();
    _removeAndDisposeListener();
  }
}

enum PostCategory {
  discover,
  nearby,
  following;

  String get title {
    switch (this) {
      case PostCategory.discover:
        return LKey.discover.tr;
      case PostCategory.nearby:
        return LKey.nearby.tr;
      case PostCategory.following:
        return LKey.following.tr;
    }
  }
}