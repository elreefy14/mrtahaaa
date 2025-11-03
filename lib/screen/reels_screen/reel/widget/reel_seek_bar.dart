import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bubbly/common/extensions/duration_extension.dart';
import 'package:bubbly/screen/dashboard_screen/dashboard_screen_controller.dart';
import 'package:bubbly/screen/reels_screen/reel/reel_page_controller.dart';
import 'package:bubbly/utilities/text_style_custom.dart';
import 'package:bubbly/utilities/theme_res.dart';

class ReelSeekBar extends StatefulWidget {
  final CachedVideoPlayerPlus? videoController;
  final ReelController controller;

  const ReelSeekBar(
      {super.key, required this.videoController, required this.controller});

  @override
  State<ReelSeekBar> createState() => _ReelSeekBarState();
}

class _ReelSeekBarState extends State<ReelSeekBar> {
  late final GlobalKey sliderKey = GlobalKey();
  late final CachedVideoPlayerPlus? _mainController =
      widget.videoController;
  CachedVideoPlayerPlus? _overlayController;

  OverlayEntry? _overlayEntry;
  Offset? _dragPosition;
  Duration _currentPosition = Duration.zero;
  bool _isOverlayInitialized = false;
  final dashboardController = Get.find<DashboardScreenController>();

  // Add this flag to track if widget is disposed
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _mainController?.controller.addListener(_updateMainPosition);
  }

  void _updateMainPosition() async {
    // Check if widget is disposed or controller is not initialized
    if (_isDisposed || !mounted || _mainController == null || !_mainController!.controller.value.isInitialized) {
      return;
    }

    try {
      final pos = await _mainController?.controller.position;
      if (pos != null && mounted && !_isDisposed) {
        setState(() => _currentPosition = pos);
      }
    } catch (e) {
      // Handle the error gracefully - controller might be disposed
      print('Error getting video position: $e');
    }
  }

  Future<void> _removeOverlay() async {
    if (_isDisposed) return;

    _overlayEntry?.remove();
    _overlayEntry?.dispose();
    _overlayEntry = null;

    if (_isOverlayInitialized && _overlayController != null) {
      _overlayController!.controller.removeListener(_updateOverlayPosition);
      await _overlayController!.dispose();
      _overlayController = null;
      _isOverlayInitialized = false;
    }

    _dragPosition = null;
  }

  void _updateOverlayPosition() async {
    // Check if widget is disposed or controller is not initialized
    if (_isDisposed || !mounted || _overlayController == null || !_overlayController!.controller.value.isInitialized) {
      return;
    }

    try {
      final pos = await _overlayController?.controller.position;
      if (pos != null && mounted && !_isDisposed) {
        setState(() => _currentPosition = pos);
      }
    } catch (e) {
      // Handle the error gracefully
      print('Error getting overlay video position: $e');
    }
  }

  void _updateOverlayLocation(Offset globalOffset) {
    if (_isDisposed) return;
    _dragPosition = globalOffset;
    _overlayEntry?.markNeedsBuild();
  }

  Future<void> _createOverlay() async {
    if (_isDisposed || _mainController == null) return;

    _removeOverlay();

    final url = _mainController?.dataSource;
    if (url == null || _isDisposed) return;

    try {
      final newController =
      CachedVideoPlayerPlus.networkUrl(Uri.parse(url));
      await newController.initialize();

      if (_isDisposed) {
        // If widget was disposed during initialization, clean up
        await newController.dispose();
        return;
      }

      _overlayController = newController;
      _overlayController!.controller.addListener(_updateOverlayPosition);
      _isOverlayInitialized = true;

      _overlayEntry = OverlayEntry(
        builder: (context) {
          if (_dragPosition == null || !_isOverlayInitialized || _isDisposed) {
            return const SizedBox();
          }

          final screenWidth = MediaQuery.of(context).size.width;
          final double dx = (_dragPosition!.dx - 30).clamp(0, screenWidth - 100);
          bool isPostUploading =
              dashboardController.postProgress.value.uploadType !=
                  UploadType.none;
          final top = MediaQuery.of(context).size.height * 0.75 -
              (!isPostUploading ? 60 : 80);

          return Positioned(
            left: dx,
            top: top,
            child: Material(
              color: Colors.transparent,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  SizedBox(
                    width: 100,
                    height: 170,
                    child: ClipRRect(
                        borderRadius: SmoothBorderRadius(
                            cornerRadius: 10, cornerSmoothing: 1),
                        child: VideoPlayer(_overlayController!.controller)),
                  ),
                  Container(
                    width: 100,
                    height: 170,
                    decoration: ShapeDecoration(
                      shape: SmoothRectangleBorder(
                        borderRadius: SmoothBorderRadius(
                            cornerRadius: 10, cornerSmoothing: 1),
                        side: BorderSide(
                          color: whitePure(context).withAlpha(50),
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _currentPosition.printDuration,
                      style: TextStyleCustom.outFitMedium500(
                        color: whitePure(context),
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      if (!_isDisposed && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          if (!_isDisposed && mounted) {
            Overlay.of(context).insert(_overlayEntry!);
          }
        });
      }
    } catch (e) {
      print('Error creating overlay: $e');
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _mainController?.controller.removeListener(_updateMainPosition);
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller =
    _isOverlayInitialized ? _overlayController : _mainController;

    if (controller == null || _isDisposed) return const SizedBox(height: 15);

    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller.controller,
      builder: (context, value, _) {
        // Add safety check for controller state
        if (!value.isInitialized || _isDisposed) {
          return const SizedBox(height: 15);
        }

        final duration = value.duration.inMicroseconds.toDouble();
        final position = value.position.inMicroseconds.toDouble();

        return SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2,
            padding: EdgeInsets.zero,
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 0),
            thumbShape: _InvisibleThumbShape(),
            trackShape: const RectangularSliderTrackShape(),
          ),
          child: Listener(
            onPointerMove: (event) => _updateOverlayLocation(event.position),
            child: Slider(
              key: sliderKey,
              value: position.clamp(0, duration),
              min: 0,
              max: duration,
              activeColor: textLightGrey(context),
              inactiveColor: textDarkGrey(context),
              onChangeStart: (value) {
                if (duration <= 0 || _isDisposed) {
                  return;
                }
                _createOverlay();
                _mainController?.controller.pause();
              },
              onChangeEnd: (value) async {
                if (duration <= 0 || _isDisposed) {
                  return;
                }
                await _removeOverlay();
                if (!_isDisposed && _mainController != null) {
                  _mainController?.controller.play();
                  _mainController?.controller.seekTo(Duration(microseconds: value.toInt()));
                }
              },
              onChanged: (value) {
                if (duration <= 0 || _isDisposed) {
                  return;
                }
                _overlayController
                    ?.controller.seekTo(Duration(microseconds: value.toInt()));
              },
            ),
          ),
        );
      },
    );
  }
}

class _InvisibleThumbShape extends SliderComponentShape {
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(15, 15);

  @override
  void paint(
      PaintingContext context,
      Offset center, {
        required Animation<double> activationAnimation,
        required Animation<double> enableAnimation,
        required bool isDiscrete,
        required TextPainter? labelPainter,
        required RenderBox parentBox,
        required SliderThemeData sliderTheme,
        required TextDirection textDirection,
        required double value,
        required double textScaleFactor,
        required Size sizeWithOverflow,
      }) {
    // No thumb to paint
  }

  bool hitTest(
      Offset thumbCenter,
      Offset touchPosition, {
        required Size sizeWithOverflow,
        required SliderThemeData sliderTheme,
        required TextDirection textDirection,
      }) {
    // Expand interactive area (e.g., 24x24)
    return (touchPosition - thumbCenter).distance <= 12;
  }
}