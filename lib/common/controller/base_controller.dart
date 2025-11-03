import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bubbly/common/widget/loader_widget.dart';
import 'package:bubbly/utilities/text_style_custom.dart';
import 'package:bubbly/utilities/theme_res.dart';

class BaseController extends FullLifeCycleController {
  RxBool isLoading = false.obs;
  static final share = BaseController();

  void showLoader({bool barrierDismissible = true}) async {
    if (isLoading.value) return;
    if (Get.isSnackbarOpen) {
      Get.back();
    }
    isLoading.value = true;
    await Get.dialog(const LoaderWidget(),
        barrierDismissible: barrierDismissible);
    isLoading.value = false;
  }

  void stopLoader() {
    if (Get.isDialogOpen == true) {
      Get.back();
    }
  }

  void showSnackBar(String? title) {
    if (Get.isSnackbarOpen) {
      return;
    }

    Get.rawSnackbar(
      backgroundColor: blackPure(Get.context!),
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.all(15),
      borderRadius: 10,
      isDismissible: true,
      duration: const Duration(seconds: 2),
      snackPosition: SnackPosition.TOP,
      messageText: Text(title?.capitalizeFirst?.tr ?? '',
          style: TextStyleCustom.outFitRegular400(
              color: whitePure(Get.context!), fontSize: 17)),
    );
  }

  void stopSnackBar() {
    if (Get.isSnackbarOpen) {
      Get.back();
    }
  }
}
