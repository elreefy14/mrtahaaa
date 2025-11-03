import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:bubbly/common/extensions/string_extension.dart';
import 'package:bubbly/common/widget/custom_image.dart';
import 'package:bubbly/common/widget/gradient_text.dart';
import 'package:bubbly/languages/languages_keys.dart';
import 'package:bubbly/model/general/settings_model.dart';
import 'package:bubbly/utilities/app_res.dart';
import 'package:bubbly/utilities/style_res.dart';
import 'package:bubbly/utilities/text_style_custom.dart';
import 'package:bubbly/utilities/theme_res.dart';

class SendGiftDialog extends StatefulWidget {
  final Gift gift;

  const SendGiftDialog({super.key, required this.gift});

  @override
  State<SendGiftDialog> createState() => _SendGiftDialogState();
}

class _SendGiftDialogState extends State<SendGiftDialog> {
  VideoPlayerController? _videoController;
  bool _isVideo = false;

  @override
  void initState() {
    super.initState();
    _checkMediaType();
    Future.delayed(const Duration(seconds: AppRes.giftDialogDismissTime), () {
      Get.back();
    });
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

  Widget _buildMediaWidget() {
    if (_isVideo && _videoController != null) {
      return Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.black12,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
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
        size: const Size(90, 90),
        radius: 12,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: whitePure(context),
      shape: RoundedRectangleBorder(borderRadius: SmoothBorderRadius(cornerRadius: 20)),
      alignment: const Alignment(0, 0.4),
      child: AspectRatio(
        aspectRatio: 1.8,
        child: Container(
          decoration: ShapeDecoration(
              shape: SmoothRectangleBorder(borderRadius: SmoothBorderRadius(cornerRadius: 20)),
              color: whitePure(context)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMediaWidget(),
              const SizedBox(height: 15),
              Text(LKey.yourGiftHasBeenSent.tr,
                  style: TextStyleCustom.outFitRegular400(
                      fontSize: 15, color: textLightGrey(context))),
              GradientText(LKey.successfully.tr,
                  gradient: StyleRes.themeGradient,
                  style: TextStyleCustom.unboundedSemiBold600(fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }
}