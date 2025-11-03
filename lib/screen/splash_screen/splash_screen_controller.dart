import 'dart:async';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:bubbly/common/controller/base_controller.dart';
import 'package:bubbly/common/controller/firebase_firestore_controller.dart';
import 'package:bubbly/common/extensions/string_extension.dart';
import 'package:bubbly/common/manager/logger.dart';
import 'package:bubbly/common/manager/session_manager.dart';
import 'package:bubbly/common/service/api/common_service.dart';
import 'package:bubbly/common/service/api/user_service.dart';
import 'package:bubbly/common/widget/restart_widget.dart';
import 'package:bubbly/languages/dynamic_translations.dart';
import 'package:bubbly/model/general/settings_model.dart';
import 'package:bubbly/screen/auth_screen/login_screen.dart';
import 'package:bubbly/screen/dashboard_screen/dashboard_screen.dart';
import 'package:bubbly/screen/gif_sheet/gif_sheet_controller.dart';
import 'package:bubbly/screen/select_language_screen/select_language_screen.dart';

class SplashScreenController extends BaseController {
  @override
  void onReady() async {
    super.onReady();
    if (!Get.isRegistered<GifSheetController>()) {
      Get.put(GifSheetController());
    }
    if (!Get.isRegistered<FirebaseFirestoreController>()) {
      Get.put(FirebaseFirestoreController());
    }
    await fetchSettings();
  }

  Future<void> fetchSettings() async {
    bool showNavigate = await CommonService.instance.fetchGlobalSettings();
    if (showNavigate) {
      final translations = Get.find<DynamicTranslations>();

      // Load JSON translations (already loaded in DynamicTranslations constructor)
      // Now load and merge CSV translations
      var languages = SessionManager.instance.getSettings()?.languages ?? [];
      List<Language> downloadLanguages =
      languages.where((element) => element.status == 1).toList();
      await downloadAndParseLanguages(downloadLanguages);

      var defaultLang =
      languages.firstWhereOrNull((element) => element.isDefault == 1);

      if (defaultLang != null) {
        SessionManager.instance.setFallbackLang(defaultLang.code ?? 'en');
      }

      RestartWidget.restartApp(Get.context!);
      if (SessionManager.instance.isLogin()) {
        UserService.instance
            .fetchUserDetails(userId: SessionManager.instance.getUserID())
            .then((value) {
          if (value != null) {
            Get.off(() => DashboardScreen(myUser: value));
          } else {
            Get.off(() => const LoginScreen());
          }
        });
      } else {
        Get.off(() => const SelectLanguageScreen(
            languageNavigationType: LanguageNavigationType.fromStart));
      }
    }
  }

  Future<void> downloadAndParseLanguages(List<Language> languages) async {
    const int maxConcurrentDownloads = 3;
    final Set<Future<void>> activeDownloads = {};

    for (var language in languages) {
      if (language.code != null && language.csvFile != null) {
        final downloadTask = downloadAndProcessLanguage(language);
        activeDownloads.add(downloadTask);

        if (activeDownloads.length >= maxConcurrentDownloads) {
          await Future.any(activeDownloads);
          activeDownloads
              .removeWhere((task) => task == Future.any(activeDownloads));
        }
      }
    }

    await Future.wait(activeDownloads);
  }

  Future<void> downloadAndProcessLanguage(Language language) async {
    try {
      final response =
      await http.get(Uri.parse(language.csvFile?.addBaseURL() ?? ''));
      if (response.statusCode == 200) {
        final csvContent = utf8.decode(response.bodyBytes);
        Get.find<DynamicTranslations>()
            .addCsvTranslations(language.code!, csvContent);
        Loggers.info('Downloaded and parsed: ${language.code}');
      } else {
        Loggers.error(
            'Failed to download ${language.code}: ${response.statusCode}');
      }
    } catch (e) {
      Loggers.error('Error downloading ${language.code}: $e');
    }
  }
}