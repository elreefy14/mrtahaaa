import 'dart:io';
import 'package:flutter/material.dart';
import 'package:easy_video_editor/easy_video_editor.dart';
import 'package:video_player/video_player.dart';

class VideoTrimmingScreen extends StatefulWidget {
  final File videoFile;
  const VideoTrimmingScreen({Key? key, required this.videoFile}) : super(key: key);

  @override
  State<VideoTrimmingScreen> createState() => _VideoTrimmingScreenState();
}

class _VideoTrimmingScreenState extends State<VideoTrimmingScreen> {
  double _startValue = 0.0;
  double _endValue = 0.0;
  bool _progressVisibility = false;
  double _videoDuration = 0.0;
  double _exportProgress = 0.0;
  
  VideoPlayerController? _videoPlayerController;

  @override
  void initState() {
    super.initState();
    _initVideoDuration();
    _initVideoPlayer();
  }

  Future<void> _initVideoDuration() async {
    final editor = VideoEditorBuilder(videoPath: widget.videoFile.path);
    final metadata = await editor.getVideoMetadata();
    if (!mounted) return;
    setState(() {
      _videoDuration = (metadata.duration ?? 0).toDouble();
      _endValue = _videoDuration;
    });
  }

  Future<void> _initVideoPlayer() async {
    _videoPlayerController = VideoPlayerController.file(widget.videoFile);
    await _videoPlayerController!.initialize();
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    try {
      _videoPlayerController?.pause();
      _videoPlayerController?.dispose();
    } catch (e) {
      debugPrint('Video controller dispose error: $e');
    }
    super.dispose();
  }

  Future<void> _saveTrimmedVideo() async {
    setState(() {
      _progressVisibility = true;
      _exportProgress = 0.0;
    });
    final editor = VideoEditorBuilder(videoPath: widget.videoFile.path)
        .trim(startTimeMs: _startValue.toInt(), endTimeMs: _endValue.toInt());
    try {
      final outputPath = await editor.export(
        onProgress: (progress) {
          if (!mounted) return;
          setState(() {
            _exportProgress = progress;
          });
        },
      );
      if (!mounted) return;
      setState(() {
        _progressVisibility = false;
      });
      if (outputPath != null && mounted) {
        Navigator.of(context).pop(outputPath);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل حفظ الفيديو المقتص')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _progressVisibility = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء القص: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('قص الفيديو'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _progressVisibility ? null : _saveTrimmedVideo,
          ),
        ],
      ),
      body: _progressVisibility
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('جاري تصدير الفيديو...'),
                  if (_exportProgress > 0)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: LinearProgressIndicator(value: _exportProgress),
                    ),
                ],
              ),
            )
          : _videoDuration == 0.0 || _videoPlayerController == null || !_videoPlayerController!.value.isInitialized
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    // الفيديو في Expanded ليأخذ المساحة المتاحة بدون overflow
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: _videoPlayerController!.value.aspectRatio,
                        child: FittedBox(
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                          child: SizedBox(
                            width: _videoPlayerController!.value.size.width,
                            height: _videoPlayerController!.value.size.height,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                VideoPlayer(_videoPlayerController!),
                                if (!_videoPlayerController!.value.isPlaying)
                                  IconButton(
                                    icon: const Icon(Icons.play_arrow, size: 48, color: Colors.white),
                                    onPressed: () => setState(() { _videoPlayerController!.play(); }),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // باقي العناصر في ScrollView لتفادي overflow
                    SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text('حدد نقطة البداية والنهاية:'),
                            Row(
                              children: [
                                const Text('البداية:'),
                                Expanded(
                                  child: Slider(
                                    min: 0.0,
                                    max: _videoDuration,
                                    value: _startValue.clamp(0.0, _endValue),
                                    onChanged: (value) {
                                      setState(() {
                                        _startValue = value;
                                        if (_startValue > _endValue) {
                                          _endValue = _startValue;
                                        }
                                        _videoPlayerController!.seekTo(Duration(milliseconds: _startValue.toInt()));
                                      });
                                    },
                                  ),
                                ),
                                Text(_formatDuration(_startValue)),
                              ],
                            ),
                            Row(
                              children: [
                                const Text('النهاية:'),
                                Expanded(
                                  child: Slider(
                                    min: 0.0,
                                    max: _videoDuration,
                                    value: _endValue.clamp(_startValue, _videoDuration),
                                    onChanged: (value) {
                                      setState(() {
                                        _endValue = value;
                                        if (_endValue < _startValue) {
                                          _startValue = _endValue;
                                        }
                                      });
                                    },
                                  ),
                                ),
                                Text(_formatDuration(_endValue)),
                              ],
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.cut),
                              label: const Text('قص الفيديو'),
                              onPressed: _saveTrimmedVideo,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  String _formatDuration(double ms) {
    final seconds = (ms / 1000).floor();
    final min = (seconds ~/ 60).toString().padLeft(2, '0');
    final sec = (seconds % 60).toString().padLeft(2, '0');
    return '$min:$sec';
  }
}
