import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:figma_squircle_updated/figma_squircle.dart';

import 'package:bubbly/screen/comment_sheet/helper/comment_helper.dart';
import 'package:bubbly/utilities/color_res.dart';
import 'package:bubbly/utilities/asset_res.dart';
import 'package:bubbly/utilities/style_res.dart';
import 'package:bubbly/utilities/theme_res.dart';
import 'package:bubbly/languages/languages_keys.dart';
import 'package:bubbly/utilities/text_style_custom.dart';

import '../../../common/widget/gradient_text.dart';

class CommentAudioRecordContainer extends StatelessWidget {
  final CommentHelper helper;
  final Function() onSend;
  final Function() onDelete;

  const CommentAudioRecordContainer({super.key, required this.helper, required this.onSend, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    if (helper.audioWidthAnimation == null) return const SizedBox();

    return AnimatedBuilder(
      animation: helper.audioWidthAnimation!,
      builder: (context, child) {
        return Align(
          alignment: Alignment.centerLeft,
          child: ClipRect(
            child: Container(
              width: helper.audioWidthAnimation!.value,
              height: 46,
              margin: const EdgeInsets.symmetric(horizontal: 15),
              decoration: ShapeDecoration(
                color: bgLightGrey(context),
                shape: SmoothRectangleBorder(
                  borderRadius: SmoothBorderRadius(cornerRadius: 30),
                ),
              ),
              child: helper.audioWidthAnimation!.value > 120
                  ? Row(
                      children: [
                        InkWell(
                          onTap: onDelete,
                          child: AnimatedContainer(
                            height: 45,
                            width: 45,
                            duration: const Duration(milliseconds: 100),
                            margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: ColorRes.likeRed.withOpacity(.1),
                            ),
                            alignment: Alignment.center,
                            child: Image.asset(
                              AssetRes.icDelete,
                              height: 25,
                              width: 25,
                              color: ColorRes.likeRed,
                            ),
                          ),
                        ),
                        Expanded(
                          child: AudioWaveforms(
                            size: Size(MediaQuery.of(context).size.width, 35),
                            recorderController: helper.recorderController,
                            waveStyle: WaveStyle(
                              middleLineColor: Colors.transparent,
                              extendWaveform: true,
                              waveThickness: 1.5,
                              spacing: 3,
                              waveColor: bgGrey(context),
                              gradient: StyleRes.wavesGradient,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: onSend,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10.0),
                            child: GradientText(
                              LKey.send.tr,
                              gradient: StyleRes.themeGradient,
                              style: TextStyleCustom.unboundedMedium500(fontSize: 15),
                            ),
                          ),
                        ),
                      ],
                    )
                  : null,
            ),
          ),
        );
      },
    );
  }
}
