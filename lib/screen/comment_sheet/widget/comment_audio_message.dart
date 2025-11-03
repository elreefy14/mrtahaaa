import 'dart:io';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:bubbly/common/extensions/string_extension.dart';
import 'package:bubbly/utilities/asset_res.dart';
import 'package:bubbly/utilities/color_res.dart';
import 'package:bubbly/utilities/style_res.dart';
import 'package:bubbly/utilities/theme_res.dart';

/// Simple audio player widget for post comments (voice type).
/// Downloads and caches remote audio files locally before playing.
class CommentAudioMessage extends StatefulWidget {
  const CommentAudioMessage({Key? key, required this.url}) : super(key: key);

  /// Remote URL of the voice comment audio (mp3/aac/etc).
  final String url;

  @override
  State<CommentAudioMessage> createState() => _CommentAudioMessageState();
}

class _CommentAudioMessageState extends State<CommentAudioMessage> {
  final PlayerController _playerController = PlayerController();
  PlayerState _playerState = PlayerState.stopped;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isDownloading = false;
  String? _localFilePath;
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  String _getValidAudioUrl(String url) {
    if (url.isEmpty) return '';

    // If already a complete HTTP URL, return as-is
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    // If it's a relative S3 path, construct the full URL
    if (url.contains('suplleexx/comments/') || url.startsWith('/suplleexx/')) {
      const String s3BaseUrl = 'https://s3.eu-north-1.amazonaws.com';
      String cleanPath = url.startsWith('/') ? url.substring(1) : url;
      return '$s3BaseUrl/$cleanPath';
    }

    // For other cases, use the existing addBaseURL logic
    return url.addBaseURL();
  }

  Future<String?> _downloadAndCacheAudio(String audioUrl) async {
    try {
      setState(() {
        _isDownloading = true;
        _downloadProgress = 0.0;
      });

      // Generate a unique filename based on the URL
      final uri = Uri.parse(audioUrl);
      final filename = path.basename(uri.path);
      final fileExtension = path.extension(filename).isNotEmpty
          ? path.extension(filename)
          : '.m4a';

      // Create a cache filename
      final cacheFilename = '${uri.pathSegments.join('_').replaceAll(RegExp(r'[^\w\-_\.]'), '_')}$fileExtension';

      // Get the app's cache directory
      final directory = await getTemporaryDirectory();
      final cacheDir = Directory('${directory.path}/audio_cache');
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }

      final localFile = File('${cacheDir.path}/$cacheFilename');

      // Check if file already exists
      if (await localFile.exists()) {
        print('CommentAudioMessage: Using cached file: ${localFile.path}');
        return localFile.path;
      }

      print('CommentAudioMessage: Downloading audio from: $audioUrl');

      // Download the file
      final request = http.Request('GET', Uri.parse(audioUrl));
      final response = await http.Client().send(request);

      if (response.statusCode != 200) {
        throw Exception('Failed to download audio: ${response.statusCode}');
      }

      final contentLength = response.contentLength ?? 0;
      var downloadedBytes = 0;

      final sink = localFile.openWrite();

      await response.stream.listen(
            (chunk) {
          sink.add(chunk);
          downloadedBytes += chunk.length;

          if (contentLength > 0) {
            final progress = downloadedBytes / contentLength;
            if (mounted) {
              setState(() {
                _downloadProgress = progress;
              });
            }
          }
        },
        onDone: () async {
          await sink.close();
        },
        onError: (error) async {
          await sink.close();
          throw error;
        },
        cancelOnError: true,
      ).asFuture();

      print('CommentAudioMessage: Audio downloaded to: ${localFile.path}');
      return localFile.path;

    } catch (e) {
      print('CommentAudioMessage: Failed to download audio: $e');
      return null;
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadProgress = 0.0;
        });
      }
    }
  }

  Future<void> _initPlayer() async {
    try {
      String audioUrl = _getValidAudioUrl(widget.url);

      if (audioUrl.isEmpty) {
        print('CommentAudioMessage: Invalid audio URL');
        setState(() {
          _hasError = true;
        });
        return;
      }

      // Download and cache the audio file
      _localFilePath = await _downloadAndCacheAudio(audioUrl);

      if (_localFilePath == null) {
        setState(() {
          _hasError = true;
        });
        return;
      }

      print('CommentAudioMessage: Preparing player with local file: $_localFilePath');

      // Now use the local file path with the player
      await _playerController.preparePlayer(
        path: _localFilePath!,
        shouldExtractWaveform: true, // Now we can extract waveforms from local file
      );

      // Listen to player state changes
      _playerController.onPlayerStateChanged.listen((event) {
        if (mounted) {
          setState(() {
            _playerState = event;
          });
        }
      });

      // Listen to duration changes
      _playerController.onCurrentDurationChanged.listen((duration) {
        print('CommentAudioMessage: Duration changed: $duration ms');
      });

      // Listen to completion events
      _playerController.onCompletion.listen((_) {
        print('CommentAudioMessage: Audio playback completed');
        if (mounted) {
          setState(() {
            _playerState = PlayerState.stopped;
          });
        }
      });

      setState(() {
        _isInitialized = true;
        _hasError = false;
      });

      print('CommentAudioMessage: Player initialized successfully');

    } catch (e) {
      print('CommentAudioMessage: Failed to initialize player: $e');
      setState(() {
        _isInitialized = false;
        _hasError = true;
      });
    }
  }

  void _togglePlayback() {
    if (_hasError) {
      print('CommentAudioMessage: Player has error, attempting to reinitialize');
      _initPlayer();
      return;
    }

    if (!_isInitialized || _isDownloading) {
      print('CommentAudioMessage: Player not ready');
      return;
    }

    try {
      if (_playerState == PlayerState.playing) {
        _playerController.pausePlayer();
      } else {
        _playerController.startPlayer();
        _playerController.setFinishMode(finishMode: FinishMode.pause);
      }
    } catch (e) {
      print('CommentAudioMessage: Error toggling playback: $e');
      setState(() {
        _hasError = true;
      });
    }
  }

  @override
  void dispose() {
    _playerController.dispose();
    super.dispose();
  }

  Widget _buildPlayButton() {
    if (_hasError) {
      return Icon(
        Icons.error_outline,
        size: 22,
        color: Colors.red,
      );
    }

    if (_isDownloading) {
      return Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: _downloadProgress > 0 ? _downloadProgress : null,
              valueColor: AlwaysStoppedAnimation<Color>(textDarkGrey(context)),
            ),
          ),
          if (_downloadProgress > 0)
            Text(
              '${(_downloadProgress * 100).toInt()}%',
              style: TextStyle(fontSize: 8, color: textDarkGrey(context)),
            ),
        ],
      );
    }

    if (!_isInitialized) {
      return SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(textDarkGrey(context)),
        ),
      );
    }

    return Image.asset(
      _playerState == PlayerState.playing ? AssetRes.icPause : AssetRes.icPlay,
      width: 22,
      height: 22,
    );
  }

  Widget _buildWaveform() {
    if (_hasError) {
      return Container(
        height: 50,
        alignment: Alignment.center,
        child: Text(
          'Error loading audio',
          style: TextStyle(
            color: Colors.red,
            fontSize: 12,
          ),
        ),
      );
    }

    if (_isDownloading) {
      return Container(
        height: 50,
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: _downloadProgress > 0 ? _downloadProgress : null,
                valueColor: AlwaysStoppedAnimation<Color>(bgGrey(context)),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Downloading... ${_downloadProgress > 0 ? "${(_downloadProgress * 100).toInt()}%" : ""}',
              style: TextStyle(
                color: bgGrey(context),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    if (!_isInitialized) {
      return Container(
        height: 50,
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(bgGrey(context)),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Loading...',
              style: TextStyle(
                color: bgGrey(context),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    // Use the actual AudioFileWaveforms widget now that we have a local file
    return AudioFileWaveforms(
      size: Size(150, 50),
      playerController: _playerController,
      //enableSeek: true,
      waveformType: WaveformType.fitWidth,
      playerWaveStyle: PlayerWaveStyle(
        fixedWaveColor: bgGrey(context),
        liveWaveColor: StyleRes.themeGradient.colors.first,
        spacing: 6,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      width: 220,
      decoration: ShapeDecoration(
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius(cornerRadius: 15, cornerSmoothing: 1),
        ),
        color: textDarkGrey(context),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: _togglePlayback,
            child: Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: whitePure(context),
              ),
              alignment: Alignment.center,
              child: _buildPlayButton(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: _buildWaveform()),
        ],
      ),
    );
  }
}