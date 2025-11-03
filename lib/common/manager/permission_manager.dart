// lib/common/manager/permission_manager.dart

import 'package:permission_handler/permission_handler.dart';
import 'package:bubbly/common/manager/logger.dart';

class PermissionManager {
  static final PermissionManager _instance = PermissionManager._internal();
  static PermissionManager get instance => _instance;

  PermissionManager._internal();

  bool _isRequestingPermissions = false;

  /// طلب أذونات الكاميرا والميكروفون بشكل متتالي لتجنب التضارب
  Future<Map<Permission, PermissionStatus>> requestCameraAndMicrophone() async {
    if (_isRequestingPermissions) {
      Loggers.warning('Permissions request already in progress');
      return {};
    }

    _isRequestingPermissions = true;
    Map<Permission, PermissionStatus> results = {};

    try {
      // طلب أذن الكاميرا أولاً
      Loggers.info('Requesting camera permission...');
      final cameraStatus = await Permission.camera.request();
      results[Permission.camera] = cameraStatus;

      // انتظار قصير بين الطلبات
      await Future.delayed(const Duration(milliseconds: 500));

      // طلب أذن الميكروفون
      Loggers.info('Requesting microphone permission...');
      final microphoneStatus = await Permission.microphone.request();
      results[Permission.microphone] = microphoneStatus;

      Loggers.success('Permissions requested successfully');
      return results;

    } catch (e) {
      Loggers.error('Error requesting permissions: $e');
      return {};
    } finally {
      _isRequestingPermissions = false;
    }
  }

  /// فحص حالة الأذونات دون طلبها
  Future<Map<Permission, PermissionStatus>> checkCameraAndMicrophone() async {
    try {
      final cameraStatus = await Permission.camera.status;
      final microphoneStatus = await Permission.microphone.status;

      return {
        Permission.camera: cameraStatus,
        Permission.microphone: microphoneStatus,
      };
    } catch (e) {
      Loggers.error('Error checking permissions: $e');
      return {};
    }
  }

  /// التحقق من أن الأذونات مُمنوحة
  Future<bool> arePermissionsGranted() async {
    final statuses = await checkCameraAndMicrophone();

    final cameraGranted = statuses[Permission.camera]?.isGranted ?? false;
    final microphoneGranted = statuses[Permission.microphone]?.isGranted ?? false;

    return cameraGranted && microphoneGranted;
  }

  /// طلب أذن واحد فقط
  Future<PermissionStatus> requestSinglePermission(Permission permission) async {
    if (_isRequestingPermissions) {
      Loggers.warning('Another permission request is in progress');
      return PermissionStatus.denied;
    }

    _isRequestingPermissions = true;

    try {
      Loggers.info('Requesting ${permission.toString()} permission...');
      final status = await permission.request();
      Loggers.info('${permission.toString()} permission result: $status');
      return status;
    } catch (e) {
      Loggers.error('Error requesting ${permission.toString()}: $e');
      return PermissionStatus.denied;
    } finally {
      _isRequestingPermissions = false;
    }
  }

  /// فحص وطلب الأذونات إذا لزم الأمر
  Future<bool> ensurePermissions() async {
    final currentStatuses = await checkCameraAndMicrophone();

    final cameraStatus = currentStatuses[Permission.camera] ?? PermissionStatus.denied;
    final microphoneStatus = currentStatuses[Permission.microphone] ?? PermissionStatus.denied;

    // إذا كانت الأذونات ممنوحة بالفعل
    if (cameraStatus.isGranted && microphoneStatus.isGranted) {
      return true;
    }

    // إذا كانت مرفوضة نهائياً
    if (cameraStatus.isPermanentlyDenied || microphoneStatus.isPermanentlyDenied) {
      Loggers.warning('Some permissions are permanently denied');
      return false;
    }

    // طلب الأذونات المطلوبة
    final results = await requestCameraAndMicrophone();

    final finalCameraStatus = results[Permission.camera] ?? PermissionStatus.denied;
    final finalMicrophoneStatus = results[Permission.microphone] ?? PermissionStatus.denied;

    return finalCameraStatus.isGranted && finalMicrophoneStatus.isGranted;
  }

  /// فتح إعدادات التطبيق
  Future<bool> openAppSettings() async {
    try {
      return await openAppSettings();
    } catch (e) {
      Loggers.error('Error opening app settings: $e');
      return false;
    }
  }
}