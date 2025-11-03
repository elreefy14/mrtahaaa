import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:bubbly/common/manager/firebase_notification_manager.dart';
import 'package:bubbly/common/manager/internet_connection_manager.dart';
import 'package:bubbly/common/manager/logger.dart';
import 'package:bubbly/common/manager/permission_manager.dart';
import 'package:bubbly/common/manager/session_manager.dart';
import 'package:bubbly/common/widget/restart_widget.dart';
import 'package:bubbly/languages/dynamic_translations.dart';
import 'package:bubbly/screen/splash_screen/splash_screen.dart';
import 'package:bubbly/utilities/theme_res.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_branch_sdk/flutter_branch_sdk.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:permission_handler/permission_handler.dart';

import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  Loggers.success("Handling a background message: ${message.data}");
  await Firebase.initializeApp();
  if (Platform.isIOS) {
    FirebaseNotificationManager.instance.showNotification(message);
  }
}

/// إصلاح دالة فحص الأذونات لتجنب التضارب
Future<void> checkPermissions() async {
  try {
    print('=== Checking Permissions ===');

    // استخدام Permission Manager لتجنب التضارب
    final permissionManager = PermissionManager.instance;

    // فحص الحالة الحالية للأذونات
    final currentStatuses = await permissionManager.checkCameraAndMicrophone();

    print('Camera Permission: ${currentStatuses[Permission.camera]}');
    print('Microphone Permission: ${currentStatuses[Permission.microphone]}');

    // طلب الأذونات إذا لزم الأمر
    final success = await permissionManager.ensurePermissions();

    print('=== Permissions Check Complete ===');
    print('Permissions granted: $success');
  } catch (e) {
    print('Error checking permissions: $e');
  }
}

Future<void> _initCrashlytics() async {
  // تفعيل التجميع (يمكنك تعطيله في debug لو حابب)
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

  // Flutter framework errors (غير محاصرة)
  FlutterError.onError = (FlutterErrorDetails details) async {
    // تجاهل أخطاء PlatformException الخاصة بإنشاء views مكررة
    final asText = details.exception.toString();
    if (asText.contains('PlatformException') &&
        asText.contains('already created')) {
      Loggers.warning('Ignoring duplicate view creation error');
      return;
    }

    // أرسل كـ non-fatal
    await FirebaseCrashlytics.instance.recordFlutterError(details);
    // ما زلنا نظهرها في اللوغ المحلي
    FlutterError.presentError(details);
  };

  // Errors خارج Flutter zone (PlatformDispatcher)
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    FirebaseCrashlytics.instance.recordError(
      error,
      stack,
      fatal: true,
      reason: 'Uncaught zone error',
    );
    return true;
  };
}

Future<void> main() async {
  // شغل كل شيء داخل runZonedGuarded عشان أي استثناء يوصل لـ Crashlytics
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // طلب الأذونات قبل تهيئة Firebase
    await checkPermissions();

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Crashlytics
    await _initCrashlytics();

    // اربط userId في Crashlytics (لو متاح)
    try {
      final uid = SessionManager.instance.getUser()?.id?.toString();
      if (uid != null && uid.isNotEmpty) {
        await FirebaseCrashlytics.instance.setUserIdentifier(uid);
      }
    } catch (_) {}

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Initialize GetStorage with default container
    try {
      await GetStorage.init();
      Loggers.success('GetStorage initialized successfully');
    } catch (e, st) {
      Loggers.error('GetStorage initialization failed: $e');
      await FirebaseCrashlytics.instance
          .recordError(e, st, reason: 'GetStorage init error');
    }

    // Init Ads (ignore async wait if needed)
    MobileAds.instance.initialize();

    // Init Branch SDK
    try {
      await FlutterBranchSdk.init();
    } catch (e, st) {
      Loggers.error('Branch SDK init error: $e\n$st');
      // non-fatal في Crashlytics
      await FirebaseCrashlytics.instance
          .recordError(e, st, reason: 'Branch SDK init error');
    }

    // Load Translations
    Get.put(DynamicTranslations());

    // Run the app
    runApp(const RestartWidget(child: MyApp()));
  }, (Object error, StackTrace stack) async {
    // Fatal
    await FirebaseCrashlytics.instance.recordError(
      error,
      stack,
      fatal: true,
      reason: 'runZonedGuarded uncaught',
    );
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      builder: (context, child) =>
          ScrollConfiguration(behavior: MyBehavior(), child: child!),
      onReady: () {
        InternetConnectionManager.instance.listenNoInternetConnection();
      },
      translations: Get.find<DynamicTranslations>(),
      locale: Locale(SessionManager.instance.getLang()),
      fallbackLocale: Locale(SessionManager.instance.getFallbackLang()),
      themeMode: ThemeMode.light,
      darkTheme: ThemeRes.darkTheme(context),
      theme: ThemeRes.lightTheme(context),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}

class MyBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}
