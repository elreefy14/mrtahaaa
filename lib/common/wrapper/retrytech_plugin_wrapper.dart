import 'package:flutter/material.dart';
import 'package:retrytech_plugin/retrytech_plugin.dart';
import 'package:bubbly/common/manager/logger.dart';

class RetrytechPluginWrapper {
  static final RetrytechPluginWrapper _instance = RetrytechPluginWrapper._internal();
  static RetrytechPluginWrapper get shared => _instance;

  RetrytechPluginWrapper._internal();

  bool _isInitialized = false;
  bool _isInitializing = false;
  bool get isInitialized => _isInitialized;

  // ✅ تهيئة الكاميرا مع معالجة الأخطاء
  Future<bool> initCamera() async {
    if (_isInitializing) {
      Loggers.warning('Camera initialization already in progress');
      return false;
    }

    if (_isInitialized) {
      Loggers.warning('Camera already initialized, disposing first...');
      dispose();
      await Future.delayed(const Duration(milliseconds: 500));
    }

    _isInitializing = true;

    try {
      Loggers.info('Initializing RetryTech camera...');

      // إضافة تأخير قصير للتأكد من استعداد النظام
      await Future.delayed(const Duration(milliseconds: 200));

      RetrytechPlugin.shared.initCamera();

      // إضافة تأخير للتأكد من اكتمال التهيئة
      await Future.delayed(const Duration(milliseconds: 500));

      _isInitialized = true;
      Loggers.success('RetryTech camera initialized successfully');
      return true;
    } catch (e) {
      Loggers.error('Failed to initialize RetryTech camera: $e');
      _isInitialized = false;
      return false;
    } finally {
      _isInitializing = false;
    }
  }

  // ✅ تسجيل الفيديو مع معالجة الأخطاء
  Future<bool> startRecording() async {
    if (!_isInitialized) {
      Loggers.error('Cannot start recording: Camera not initialized');
      return false;
    }

    try {
      RetrytechPlugin.shared.startRecording;
      Loggers.info('Video recording started');
      return true;
    } catch (e) {
      Loggers.error('Failed to start recording: $e');
      return false;
    }
  }

  // ✅ إيقاف التسجيل مع معالجة الأخطاء
  Future<String?> stopRecording() async {
    if (!_isInitialized) {
      Loggers.error('Cannot stop recording: Camera not initialized');
      return null;
    }

    try {
      final String? videoPath = await RetrytechPlugin.shared.stopRecording;
      if (videoPath == null || videoPath.isEmpty) {
        Loggers.error('No video file generated');
        return null;
      }
      Loggers.success('Video recording stopped: $videoPath');
      return videoPath;
    } catch (e) {
      Loggers.error('Failed to stop recording: $e');
      return null;
    }
  }

  // ✅ التقاط صورة مع معالجة الأخطاء
  Future<String?> captureImage() async {
    if (!_isInitialized) {
      Loggers.error('Cannot capture image: Camera not initialized');
      return null;
    }

    try {
      final String? imagePath = await RetrytechPlugin.shared.captureImage();
      if (imagePath == null || imagePath.isEmpty) {
        Loggers.error('No image file generated');
        return null;
      }
      Loggers.success('Image captured: $imagePath');
      return imagePath;
    } catch (e) {
      Loggers.error('Failed to capture image: $e');
      return null;
    }
  }

  // ✅ إيقاف مؤقت للتسجيل
  bool pauseRecording() {
    if (!_isInitialized) {
      Loggers.error('Cannot pause recording: Camera not initialized');
      return false;
    }

    try {
      RetrytechPlugin.shared.pauseRecording;
      Loggers.info('Recording paused');
      return true;
    } catch (e) {
      Loggers.error('Failed to pause recording: $e');
      return false;
    }
  }

  // ✅ استئناف التسجيل
  bool resumeRecording() {
    if (!_isInitialized) {
      Loggers.error('Cannot resume recording: Camera not initialized');
      return false;
    }

    try {
      RetrytechPlugin.shared.resumeRecording;
      Loggers.info('Recording resumed');
      return true;
    } catch (e) {
      Loggers.error('Failed to resume recording: $e');
      return false;
    }
  }

  // ✅ تبديل الكاميرا
  bool toggleCamera() {
    if (!_isInitialized) {
      Loggers.error('Cannot toggle camera: Camera not initialized');
      return false;
    }

    try {
      RetrytechPlugin.shared.toggleCamera;
      Loggers.info('Camera toggled');
      return true;
    } catch (e) {
      Loggers.error('Failed to toggle camera: $e');
      return false;
    }
  }

  // ✅ تبديل الفلاش
  bool toggleFlash() {
    if (!_isInitialized) {
      Loggers.error('Cannot toggle flash: Camera not initialized');
      return false;
    }

    try {
      RetrytechPlugin.shared.flashOnOff;
      Loggers.info('Flash toggled');
      return true;
    } catch (e) {
      Loggers.error('Failed to toggle flash: $e');
      return false;
    }
  }

  // ✅ الحصول على عرض الكاميرا مع التحقق من الحالة
  Widget get cameraView {
    if (!_isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Text(
            'Camera not initialized',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    try {
      // إنشاء key فريد لكل instance من الكاميرا
      return Container(
        key: UniqueKey(),
        child: RetrytechPlugin.shared.cameraView,
      );
    } catch (e) {
      Loggers.error('Error creating camera view: $e');
      return Container(
        color: Colors.black,
        child: Center(
          child: Text(
            'Error loading camera: $e',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  // ✅ تنظيف الموارد بشكل آمن
  void dispose() {
    try {
      if (_isInitialized) {
        RetrytechPlugin.shared.disposeCamera;
        _isInitialized = false;
        _isInitializing = false;
        Loggers.info('RetryTech camera disposed');
      }
    } catch (e) {
      Loggers.error('Error disposing camera: $e');
      _isInitialized = false;
      _isInitializing = false;
    }
  }

  // ✅ إعادة تهيئة الكاميرا مع تنظيف كامل
  Future<bool> reinitialize() async {
    Loggers.info('Reinitializing RetryTech camera...');

    // التخلص من الكاميرا الحالية
    dispose();

    // انتظار للتأكد من التنظيف الكامل
    await Future.delayed(const Duration(milliseconds: 700));

    // إعادة التهيئة
    return await initCamera();
  }
}