import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bubbly/common/widget/loader_widget.dart';
import 'package:bubbly/common/widget/my_refresh_indicator.dart';
import 'package:bubbly/common/widget/no_data_widget.dart';
import 'package:bubbly/common/widget/post_list.dart';
import 'package:bubbly/languages/languages_keys.dart';
import 'package:bubbly/model/user_model/user_model.dart';
import 'package:bubbly/screen/feed_screen/feed_screen_controller.dart';
import 'package:bubbly/screen/feed_screen/widget/feed_top_view.dart';
import 'package:bubbly/screen/feed_screen/widget/story_view.dart';

class FeedScreen extends StatelessWidget {
  final User? myUser;

  const FeedScreen({super.key, this.myUser});

  @override
  Widget build(BuildContext context) {
    // استخدم GetBuilder بدلاً من Get.put لتجنب إعادة إنشاء Controller
    return GetBuilder<FeedScreenController>(
      init: FeedScreenController(myUser.obs),
      builder: (controller) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section with user info and actions
            FeedTopView(controller: controller),

            // Main content area
            Expanded(
              child: MyRefreshIndicator(
                refreshKey: controller.refreshKey,
                onRefresh: controller.onRefresh,
                shouldRefresh: true,
                child: _buildMainContent(controller),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMainContent(FeedScreenController controller) {
    return Stack(
      children: [
        // Empty state handling - استخدم GetBuilder بدلاً من Obx
        GetBuilder<FeedScreenController>(
          id: 'loading_state',
          builder: (controller) {
            // Show no data view when not loading and no posts
            if (!controller.isLoading.value && controller.posts.isEmpty) {
              return Stack(
                children: [
                  NoDataView(
                    safeAreaTop: false,
                    title: LKey.noUserPostsTitle.tr,
                    description: LKey.noUserPostsDescription.tr,
                  ),
                  // Maintains scrollable area for pull-to-refresh
                  SingleChildScrollView(
                    child: SizedBox(
                      width: double.infinity,
                      height: Get.height,
                    ),
                  ),
                ],
              );
            }

            // Show loader when loading and no posts
            if (controller.isLoading.value && controller.posts.isEmpty) {
              return const LoaderWidget();
            }

            // Return empty widget for other states
            return const SizedBox();
          },
        ),

        // Main scrollable content
        _buildScrollableContent(controller),
      ],
    );
  }

  Widget _buildScrollableContent(FeedScreenController controller) {
    return SingleChildScrollView(
      controller: controller.postScrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stories section at the top
          GetBuilder<FeedScreenController>(
            id: 'stories_list',
            builder: (controller) {
              return StoryView(controller: controller);
            },
          ),

          // Posts feed section - مرر List عادي بدلاً من RxList
          GetBuilder<FeedScreenController>(
            id: 'posts_list',
            builder: (controller) {
              return PostList(
                posts: controller.posts, // List عادي
                isLoading: controller.isLoading.value, // bool عادي
                shrinkWrap: true,
                showNoData: false,
                physics: const NeverScrollableScrollPhysics(),
              );
            },
          ),

          // Loading indicator for pagination
          GetBuilder<FeedScreenController>(
            id: 'pagination_loader',
            builder: (controller) {
              if (controller.isLoading.value && controller.posts.isNotEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: LoaderWidget(),
                  ),
                );
              }
              return const SizedBox();
            },
          ),

          // Bottom spacing for better scrolling experience
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}