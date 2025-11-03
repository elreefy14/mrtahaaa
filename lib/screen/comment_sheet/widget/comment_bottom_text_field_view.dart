import 'package:detectable_text_field/detectable_text_field.dart';
import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bubbly/common/extensions/string_extension.dart';
import 'package:bubbly/common/widget/custom_divider.dart';
import 'package:bubbly/common/widget/custom_image.dart';
import 'package:bubbly/languages/languages_keys.dart';
import 'package:bubbly/model/user_model/user_model.dart';
import 'package:bubbly/screen/comment_sheet/comment_sheet_controller.dart';
import 'package:bubbly/screen/comment_sheet/helper/comment_helper.dart';
import 'package:bubbly/utilities/text_style_custom.dart';
import 'package:bubbly/utilities/theme_res.dart';
import 'package:bubbly/utilities/asset_res.dart';

import 'comment_audio_record_container.dart';

class CommentBottomTextFieldView extends StatefulWidget {
  final CommentHelper helper;
  final bool isFromBottomSheet;

  const CommentBottomTextFieldView({
    super.key,
    required this.helper,
    required this.isFromBottomSheet
  });

  @override
  State<CommentBottomTextFieldView> createState() => _CommentBottomTextFieldViewState();
}

class _CommentBottomTextFieldViewState extends State<CommentBottomTextFieldView>
    with SingleTickerProviderStateMixin {

  late final CommentSheetController controller;
  CommentHelper get helper => widget.helper;
  bool get isFromBottomSheet => widget.isFromBottomSheet;

  @override
  void initState() {
    super.initState();
    controller = Get.find<CommentSheetController>();
    helper.initRecorderAnimation(this);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: whitePure(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CustomDivider(),
          // Recording container overlay
          Obx(() => helper.isRecording.value
              ? CommentAudioRecordContainer(
            helper: helper,
            onDelete: helper.cancelRecording,
            onSend: () => helper.sendRecordedAudio(
              controller.post.value!,
                  (c, isReply) => controller.onAddComment(c, isReply),
            ),
          )
              : const SizedBox()),
          SafeArea(
            top: false,
            maintainBottomViewPadding: true,
            minimum: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 15),
              child: Row(
                children: [
                  Obx(() {
                    User? user = controller.myUser.value;
                    return CustomImage(
                        size: const Size(46, 46),
                        image: user?.profilePhoto?.addBaseURL(),
                        fullName: user?.fullname);
                  }),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Obx(
                          () {
                        return Container(
                          decoration: ShapeDecoration(
                            shape: SmoothRectangleBorder(
                              borderRadius: SmoothBorderRadius(
                                  cornerRadius:
                                  helper.isReplyUser.value ? 20 : 30),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (helper.isReplyUser.value)
                                ReplyingToUserText(helper: helper),
                              Container(
                                decoration: BoxDecoration(
                                    borderRadius: !helper.isReplyUser.value
                                        ? BorderRadius.circular(30)
                                        : const BorderRadius.vertical(
                                        bottom: Radius.circular(19)),
                                    border: Border(
                                      top: !helper.isReplyUser.value
                                          ? BorderSide(color: bgGrey(context))
                                          : BorderSide.none,
                                      bottom:
                                      BorderSide(color: bgGrey(context)),
                                      left: BorderSide(color: bgGrey(context)),
                                      right: BorderSide(color: bgGrey(context)),
                                    )),
                                child: DetectableTextField(
                                  onTap: () async {
                                    if (!isFromBottomSheet) {
                                      await Future.delayed(
                                          const Duration(milliseconds: 350));
                                      final ctx = controller.commentKey.currentContext;
                                      if (ctx != null) {
                                        Scrollable.ensureVisible(ctx,
                                            duration: const Duration(
                                                milliseconds: 500));
                                      }
                                    }
                                  },
                                  controller: helper.detectableTextController,
                                  focusNode: helper.detectableTextFocusNode,
                                  style: TextStyleCustom.outFitRegular400(
                                      color: textDarkGrey(context),
                                      fontSize: 16),
                                  onChanged: helper.onChanged,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 15, vertical: 8),
                                    suffixIconConstraints:
                                    const BoxConstraints(),
                                    suffixIcon: _buildSuffixIcon(),
                                    hintText: '${LKey.writeHere.tr}..',
                                    hintStyle: TextStyle(
                                        color: textLightGrey(context)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSuffixIcon() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Obx(() {
        if (helper.isRecording.value) return const SizedBox();

        final bool isTextComment = helper.isTextComment.value;
        if (!isTextComment) {
          // show GIF & mic options
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: helper.startRecording,
                child: Image.asset(AssetRes.icMicrophone,
                    width: 22, height: 22, color: themeAccentSolid(context)),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: controller.onSendComment,
                child: Text(LKey.gif.tr,
                    style: TextStyleCustom.unboundedMedium500(
                        fontSize: 15, color: themeAccentSolid(context))),
              )
            ],
          );
        }
        // when text present show POST button
        return InkWell(
          onTap: controller.onSendComment,
          child: Text(LKey.post.tr,
              style: TextStyleCustom.unboundedMedium500(
                  fontSize: 15, color: themeAccentSolid(context))),
        );
      }),
    );
  }
}

class ReplyingToUserText extends StatelessWidget {
  const ReplyingToUserText({required this.helper, super.key});

  final CommentHelper helper;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
          color: bgMediumGrey(context),
          borderRadius:
          const BorderRadius.vertical(top: Radius.circular(19)),
          border: Border.all(color: bgGrey(context))),
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
                '${LKey.replyingTo.tr} @${helper.replyComment.value?.user?.username}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: textLightGrey(context))),
          ),
          InkWell(
              onTap: helper.onCloseReply,
              child: Icon(Icons.close_rounded,
                  color: textLightGrey(context), size: 20)),
        ],
      ),
    );
  }
}