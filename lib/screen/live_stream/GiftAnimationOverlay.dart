// gift_animation_overlay.dart
import 'dart:async';
import 'dart:math';
import 'package:bubbly/common/extensions/common_extension.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bubbly/common/extensions/string_extension.dart';
import 'package:bubbly/common/widget/custom_image.dart';
import 'package:bubbly/model/livestream/livestream_comment.dart';
import 'package:bubbly/screen/live_stream/livestream_screen/livestream_screen_controller.dart';
import 'package:bubbly/utilities/asset_res.dart';
import 'package:bubbly/utilities/text_style_custom.dart';
import 'package:bubbly/utilities/theme_res.dart';

class GiftAnimationOverlay extends StatefulWidget {
  final LivestreamScreenController controller;

  const GiftAnimationOverlay({super.key, required this.controller});

  @override
  State<GiftAnimationOverlay> createState() => _GiftAnimationOverlayState();
}

class _GiftAnimationOverlayState extends State<GiftAnimationOverlay> {
  final List<AnimatedGiftItem> _activeGifts = [];
  // Keep track of all gift comment IDs already animated in current live session
  final Set<dynamic> _processedGiftIds = {}; // dynamic to accept int or String IDs
  StreamSubscription? _giftSubscription;
  int _initialMaxGiftId = 0;

  @override
  void initState() {
    super.initState();
    _listenToGifts();
  }

  void _listenToGifts() {
    // Determine highest gift comment ID already present at join time
    final giftsAtJoin = widget.controller.comments.where((c) =>
        c.commentType == LivestreamCommentType.gift && c.gift != null);
    if (giftsAtJoin.isNotEmpty) {
      _initialMaxGiftId = giftsAtJoin.map((e) => e.id ?? 0).reduce(max);
    }
    // Mark existing gifts as already processed to avoid replaying when overlay is rebuilt
    final existingGifts = widget.controller.comments.where((c) =>
        c.commentType == LivestreamCommentType.gift && c.gift != null);
    _processedGiftIds.addAll(existingGifts.map((e) => e.id));
    _giftSubscription = widget.controller.comments.listen((comments) {
      for (var comment in comments) {
        if (comment.commentType == LivestreamCommentType.gift &&
            comment.gift != null &&
            (comment.id ?? 0) > _initialMaxGiftId &&
            !_isGiftAlreadyAnimated(comment)) {
          _addGiftAnimation(comment);
        }
      }
    });
  }

  bool _isGiftAlreadyAnimated(LivestreamComment comment) {
    return _processedGiftIds.contains(comment.id) ||
        _activeGifts.any((item) => item.comment.id == comment.id);
  }

  void _addGiftAnimation(LivestreamComment comment) {
    final animatedGift = AnimatedGiftItem(
      comment: comment,
      onComplete: () {
        setState(() {
          _activeGifts.removeWhere((item) => item.comment.id == comment.id);
        });
      },
    );

    setState(() {
      _activeGifts.add(animatedGift);
    });
    // Record that this gift animation has been processed
    _processedGiftIds.add(comment.id);

    // Remove gift after animation duration
    Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _activeGifts.removeWhere((item) => item.comment.id == comment.id);
        });
      }
    });
  }

  @override
  void dispose() {
    _giftSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: _activeGifts.map((gift) {
        return AnimatedGiftWidget(
          key: ValueKey(gift.comment.id),
          giftItem: gift,
        );
      }).toList(),
    );
  }
}

class AnimatedGiftItem {
  final LivestreamComment comment;
  final VoidCallback onComplete;

  AnimatedGiftItem({
    required this.comment,
    required this.onComplete,
  });
}

class AnimatedGiftWidget extends StatefulWidget {
  final AnimatedGiftItem giftItem;

  const AnimatedGiftWidget({super.key, required this.giftItem});

  @override
  State<AnimatedGiftWidget> createState() => _AnimatedGiftWidgetState();
}

class _AnimatedGiftWidgetState extends State<AnimatedGiftWidget>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _sparkleController;
  late AnimationController _bounceController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _sparkleAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
  }

  void _setupAnimations() {
    // Main animation controller
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // Sparkle animation controller
    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Bounce animation controller
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Scale animation - grows and shrinks
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.3, curve: Curves.elasticOut),
    ));

    // Fade animation
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.2, curve: Curves.easeIn),
    ));

    // Rotation animation
    _rotationAnimation = Tween<double>(
      begin: -0.1,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeInOut),
    ));

    // Slide animation - moves up and fades out
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, -2),
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
    ));

    // Sparkle animation
    _sparkleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _sparkleController,
      curve: Curves.easeInOut,
    ));

    // Bounce animation
    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticInOut,
    ));
  }

  void _startAnimations() {
    _mainController.forward();

    // Start sparkle animation with delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _sparkleController.repeat(reverse: true);
      }
    });

    // Start bounce animation with delay
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _bounceController.forward();
      }
    });

    // Complete callback
    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.giftItem.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _sparkleController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gift = widget.giftItem.comment.gift;
    final senderUser = widget.giftItem.comment.senderUser;
    final receiverUser = widget.giftItem.comment.receiverUser;

    return Center(
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _mainController,
          _sparkleController,
          _bounceController,
        ]),
        builder: (context, child) {
          return Transform.translate(
            offset: _slideAnimation.value * 100,
            child: Transform.scale(
              scale: _scaleAnimation.value * _bounceAnimation.value,
              child: Transform.rotate(
                angle: _rotationAnimation.value,
                child: Opacity(
                  opacity: _fadeAnimation.value *
                      (1.0 - (_mainController.value > 0.7 ? (_mainController.value - 0.7) / 0.3 : 0)),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        // Sparkle effects
                        ..._buildSparkleEffects(),

                        // Main gift container
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.purple.withValues(alpha: 0.3),
                                Colors.pink.withValues(alpha: 0.3),
                                Colors.orange.withValues(alpha: 0.3),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.purple.withValues(alpha: 0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Sender info
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CustomImage(
                                    size: const Size(30, 30),
                                    image: senderUser?.profile?.addBaseURL(),
                                    fullName: senderUser?.fullname,
                                    strokeWidth: 2,
                                    strokeColor: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    senderUser?.username ?? '',
                                    style: TextStyleCustom.outFitMedium500(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // Gift image with glow effect
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.yellow.withValues(alpha: 0.6),
                                      blurRadius: 15,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: CustomImage(
                                  size: const Size(80, 80),
                                  image: gift?.image?.addBaseURL() ?? '',
                                  radius: 40,
                                  isShowPlaceHolder: true,
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Gift value
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.asset(
                                      AssetRes.icCoin,
                                      height: 20,
                                      width: 20,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      (gift?.coinPrice ?? 0).numberFormat,
                                      style: TextStyleCustom.outFitBold700(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Receiver info (if not battle)
                              if (receiverUser != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'To: ${receiverUser.username ?? ''}',
                                  style: TextStyleCustom.outFitLight300(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildSparkleEffects() {
    final sparkles = <Widget>[];
    final random = Random();

    for (int i = 0; i < 8; i++) {
      final angle = (i * 45) * (pi / 180);
      final distance = 60 + (random.nextDouble() * 40);
      final size = 4 + (random.nextDouble() * 6);

      sparkles.add(
        Positioned(
          left: cos(angle) * distance * _sparkleAnimation.value,
          top: sin(angle) * distance * _sparkleAnimation.value,
          child: Transform.scale(
            scale: _sparkleAnimation.value,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Colors.yellow.withValues(
                  alpha: _sparkleAnimation.value * 0.8,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.yellow.withValues(
                      alpha: _sparkleAnimation.value * 0.6,
                    ),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return sparkles;
  }
}