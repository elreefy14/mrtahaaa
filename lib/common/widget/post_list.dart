import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bubbly/common/widget/load_more_widget.dart';
import 'package:bubbly/common/widget/loader_widget.dart';
import 'package:bubbly/common/widget/no_data_widget.dart';
import 'package:bubbly/languages/languages_keys.dart';
import 'package:bubbly/model/post_story/post_model.dart';
import 'package:bubbly/screen/post_screen/post_card.dart';

class PostList extends StatelessWidget {
  // تغيير النوع ليقبل List عادي أو RxList
  final dynamic posts; // يمكن أن يكون List<Post> أو RxList<Post>
  final dynamic isLoading; // يمكن أن يكون bool أو RxBool
  final Future<void> Function()? onFetchMoreData;
  final bool shrinkWrap;
  final bool shouldShowPinOption;
  final bool isMe;
  final bool showNoData;
  final ScrollPhysics? physics;

  const PostList({
    super.key,
    required this.posts,
    required this.isLoading,
    this.onFetchMoreData,
    this.shrinkWrap = false,
    this.shouldShowPinOption = false,
    this.isMe = false,
    this.showNoData = true,
    this.physics,
  });

  // Helper methods للحصول على القيم الصحيحة
  List<Post> get _posts {
    if (posts is RxList<Post>) {
      return (posts as RxList<Post>).value;
    }
    return posts as List<Post>;
  }

  bool get _isLoading {
    if (isLoading is RxBool) {
      return (isLoading as RxBool).value;
    }
    return isLoading as bool;
  }

  @override
  Widget build(BuildContext context) {
    // إذا كانت المتغيرات Reactive، استخدم Obx
    if (posts is RxList<Post> || isLoading is RxBool) {
      return Obx(() => _buildContent());
    }

    // إذا لم تكن Reactive، ابني المحتوى مباشرة
    return _buildContent();
  }

  Widget _buildContent() {
    // Show loader when loading and no posts
    if (_isLoading && _posts.isEmpty) {
      return const LoaderWidget();
    }

    // Show no data view when not loading and no posts
    if (!_isLoading && _posts.isEmpty) {
      return showNoData ? _buildNoDataView() : const SizedBox();
    }

    // Show posts list with load more functionality
    return LoadMoreWidget(
      loadMore: onFetchMoreData ?? () async {},
      child: ListView.builder(
        itemCount: _posts.length,
        primary: !shrinkWrap,
        shrinkWrap: shrinkWrap,
        physics: physics,
        padding: EdgeInsets.only(bottom: AppBar().preferredSize.height / 2),
        itemBuilder: (context, index) {
          final post = _posts[index];
          return _buildPostCard(post);
        },
      ),
    );
  }

  /// Builds the no data view with proper scrollable area
  Widget _buildNoDataView() {
    return Stack(
      children: [
        NoDataView(
          title: isMe ? LKey.noMyPostsTitle.tr : LKey.noUserPostsTitle.tr,
          description: isMe
              ? LKey.noMyPostsDescription.tr
              : LKey.noUserPostsDescription.tr,
          showShow: !_isLoading && _posts.isEmpty,
        ),
        // Maintains scrollable area for pull-to-refresh
        SingleChildScrollView(
          child: Container(
            height: MediaQuery.of(Get.context!).size.height,
            width: MediaQuery.of(Get.context!).size.width,
            color: Colors.transparent,
          ),
        ),
      ],
    );
  }

  /// Builds individual post card
  Widget _buildPostCard(Post post) {
    return PostCard(
      post: post,
      shouldShowPinOption: shouldShowPinOption,
      likeKey: GlobalKey(),
    );
  }
}