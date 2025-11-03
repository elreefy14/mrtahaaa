// lib/screen/coin_wallet_screen/coin_wallet_screen_controller.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:bubbly/common/controller/base_controller.dart';
import 'package:bubbly/common/manager/logger.dart';
import 'package:bubbly/common/helper/apple_pay_troubleshooter.dart';
import 'package:bubbly/common/service/api/gift_wallet_service.dart';
import 'package:bubbly/common/service/api/user_service.dart';
import 'package:bubbly/languages/languages_keys.dart';
import 'package:bubbly/model/general/settings_model.dart';
import 'package:bubbly/model/user_model/user_model.dart';
import 'package:bubbly/screen/coin_wallet_screen/webviewpayment.dart';
import 'package:bubbly/common/service/email_service.dart';
import 'package:bubbly/model/payment/paytabs_payment_model.dart';

// PayTabs
import 'package:flutter_paytabs_bridge/PaymentSdkConfigurationDetails.dart';
import 'package:flutter_paytabs_bridge/flutter_paytabs_bridge.dart';
import 'package:flutter_paytabs_bridge/PaymentSDKNetworks.dart';

import '../../common/manager/session_manager.dart';

/// ثابتات مرتبطة ببيانات التاجر
const String kExpectedMerchantId =
    "merchant.com.all.safe"; // Apple Dev Merchant Identifier
const String kMerchantDisplayName =
    "مؤسسة حمود بن عيد بن جلال البقمي لتقنية المعلومات";
const String kMerchantCountryCode = "SA";
const String kDefaultCurrency = "SAR";

class PaymentContext {
  final String flow; // applePay | cardWebview | general
  final String step; // AP-001, WV-001, etc.
  final Map<String, dynamic> data;
  PaymentContext(this.flow, this.step, [this.data = const {}]);

  PaymentContext copy({String? step, Map<String, dynamic>? append}) =>
      PaymentContext(
        flow,
        step ?? this.step,
        {
          ...data,
          if (append != null) ...append,
        },
      );

  @override
  String toString() =>
      "[$flow][$step] ${data.map((k, v) => MapEntry(k, "$v"))}";
}

class PaymentCheckpoint {
  bool isIOS = Platform.isIOS;
  bool walletAssumed = Platform.isIOS;
  String merchantId = kExpectedMerchantId;
  String merchantCountry = kMerchantCountryCode;
  String currency = kDefaultCurrency;
  double amount = 0;
  Map<String, dynamic> ptKeys = {};
  Map<String, dynamic> meta = {};
  Map<String, dynamic> toJson() => {
        "isIOS": isIOS,
        "walletAssumed": walletAssumed,
        "merchantId": merchantId,
        "merchantCountry": merchantCountry,
        "currency": currency,
        "amount": amount,
        "ptKeys": ptKeys,
        "meta": meta,
      };
}

class CoinWalletScreenController extends BaseController {
  // ========= State =========
  Rx<User?> myUser = Rx<User?>(null);
  Setting? get settings => SessionManager.instance.getSettings();
  RxList<CoinPackage> coinPlans = <CoinPackage>[].obs;
  RxBool isApplePayAvailable = false.obs;

  // ========= Lifecycle =========
  @override
  void onInit() {
    super.onInit();
    fetchData();
    loadCoinPackages();
    _checkApplePayAvailability();
  }

  // ========= Data =========
  void fetchData() {
    myUser.value = SessionManager.instance.getUser();
  }

  void loadCoinPackages() {
    if (settings?.coinPackages == null) return;
    coinPlans
      ..clear()
      ..addAll(settings!.coinPackages!.where((p) => p.status == 1));
    coinPlans.sort((a, b) => (a.coinAmount ?? 0).compareTo(b.coinAmount ?? 0));
  }

  // ========= Availability =========
  Future<void> _checkApplePayAvailability() async {
    final ctx =
        PaymentContext("applePay", "AP-000", {"action": "checkAvailability"});
    try {
      if (!Platform.isIOS) {
        isApplePayAvailable.value = false;
        _log(ctx.copy(append: {"reason": "not iOS"}));
        return;
      }
      isApplePayAvailable.value = true;
      _log(ctx.copy(append: {"walletAssumed": true}));
    } catch (e, st) {
      isApplePayAvailable.value = false;
      _err(ctx, "availability_exception", e, st);
    }
  }

  // ========= UI =========
  void onPurchase(CoinPackage coinPackage) {
    if (coinPackage.id == null) {
      showSnackBar(LKey.somethingWentWrong.tr);
      return;
    }
    _showPaymentOptions(coinPackage);
  }

  void _showPaymentOptions(CoinPackage coinPackage) {
    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(maxHeight: Get.height * 0.8),
        decoration: BoxDecoration(
          color: Get.theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 10),
                decoration: BoxDecoration(
                    color: Get.theme.dividerColor,
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 20),
              Text('Choose Payment Method',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Get.theme.textTheme.bodyLarge?.color)),
              const SizedBox(height: 10),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Get.theme.cardColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Get.theme.dividerColor),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.monetization_on,
                        color: Colors.amber, size: 30),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                '${coinPackage.coinAmount ?? 0} ${LKey.coins.tr}',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Get.theme.textTheme.bodyLarge?.color)),
                            Text(_formatPrice(coinPackage.coinPlanPrice),
                                style: TextStyle(
                                    fontSize: 14,
                                    color:
                                        Get.theme.textTheme.bodyMedium?.color)),
                          ]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (Platform.isIOS) ...[
                Obx(() => _buildPaymentOption(
                      icon: Icons.apple,
                      title: 'Apple Pay',
                      subtitle: isApplePayAvailable.value
                          ? 'قم بالدفع ابل باي يا حسن'
                          : 'Apple Pay غير متوفر',
                      isEnabled: isApplePayAvailable.value,
                      onTap: () {
                        if (isApplePayAvailable.value) {
                          Get.back();
                          _initiateApplePayPayment(coinPackage);
                        }
                      },
                    )),
                const SizedBox(height: 10),
              ],
              _buildPaymentOption(
                icon: Icons.credit_card,
                title: 'Credit Card',
                subtitle: 'Pay with credit or debit card',
                onTap: () {
                  Get.back();
                  _initiateWebViewPayment(coinPackage);
                },
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Get.back(),
                child: Text('Cancel',
                    style: TextStyle(
                        color: Get.theme.textTheme.bodyMedium?.color,
                        fontSize: 16)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildPaymentOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isEnabled = true,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                  color: isEnabled
                      ? Get.theme.dividerColor
                      : Get.theme.dividerColor.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(12),
              color: isEnabled ? null : Colors.grey.withOpacity(0.1),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isEnabled
                        ? Get.theme.primaryColor.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Icon(icon,
                      color: isEnabled ? Get.theme.primaryColor : Colors.grey,
                      size: 24),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isEnabled
                                    ? Get.theme.textTheme.bodyLarge?.color
                                    : Colors.grey)),
                        const SizedBox(height: 2),
                        Text(subtitle,
                            style: TextStyle(
                                fontSize: 13,
                                color: isEnabled
                                    ? Get.theme.textTheme.bodyMedium?.color
                                    : Colors.grey)),
                      ]),
                ),
                Icon(Icons.arrow_forward_ios,
                    color: isEnabled
                        ? Get.theme.textTheme.bodyMedium?.color
                        : Colors.grey,
                    size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ========= Apple Pay =========
  void _initiateApplePayPayment(CoinPackage coinPackage) async {
    final baseCtx = PaymentContext("applePay", "AP-001", {
      "packageId": coinPackage.id,
      "coins": coinPackage.coinAmount,
      "price": coinPackage.coinPlanPrice,
      "currency": settings?.currency,
      "expectedMerchantId": kExpectedMerchantId,
      "timestamp": DateTime.now().toIso8601String(),
    });

    // Log start of Apple Pay flow
    await _logApplePayEvent('INITIATE_APPLE_PAY', baseCtx);
    showLoader(barrierDismissible: false);

    try {
      // Step 1: prerequisites
      final pre = await diagnoseApplePayPrereqs(coinPackage);
      await _logApplePayEvent('PREREQS_CHECKED',
          baseCtx.copy(step: "AP-002", append: {"prereqs": pre.toJson()}));

      if (!pre.isIOS) {
        final errorMsg = "Apple Pay is only available on iOS";
        await _logApplePayError(
            'PLATFORM_ERROR', errorMsg, baseCtx.copy(step: "AP-002A"));
        stopLoader();
        _failUI(errorMsg, baseCtx.copy(step: "AP-002A"));
        return;
      }

      if (coinPackage.coinPlanPrice == null ||
          (coinPackage.coinPlanPrice?.toDouble() ?? 0) <= 0) {
        final errorMsg = "Invalid amount: ${coinPackage.coinPlanPrice}";
        await _logApplePayError(
            'INVALID_AMOUNT', errorMsg, baseCtx.copy(step: "AP-002B"));
        stopLoader();
        _failUI("Amount must be greater than 0", baseCtx.copy(step: "AP-002B"));
        return;
      }

      // Step 2: fetch server config
      _log(baseCtx
          .copy(step: "AP-003", append: {"call": "buyCoinsWithPayTabs"}));
      final response = await GiftWalletService.instance
          .buyCoinsWithPayTabs(coinPackageId: coinPackage.id!)
          .timeout(const Duration(seconds: 25));

      _log(baseCtx.copy(step: "AP-004", append: {
        "apiStatus": response.status,
        "apiMessage": response.message,
        "hasOriginal": response.data?.original != null,
      }));

      stopLoader();

      if (response.status != true || response.data?.original == null) {
        _failUI(response.message ?? LKey.somethingWentWrong.tr,
            baseCtx.copy(step: "AP-004F"));
        return;
      }

      final paymentData = response.data!.original!;
      if (!_validatePaymentData(paymentData)) {
        final missingKeys = paymentData.missingApplePayKeys;
        final errorMsg =
            "Payment config invalid (missing PayTabs keys: ${missingKeys.join(', ')})";
        await _logApplePayError(
            'PAYMENT_CONFIG_INVALID',
            errorMsg,
            baseCtx.copy(step: "AP-004V", append: {
              "paymentData": paymentData,
              "missingKeys": missingKeys,
              "hasRequiredKeys": paymentData.hasRequiredApplePayKeys,
            }));

        // إظهار رسالة خطأ مع اقتراح بديل
        _showPaymentConfigErrorAndFallback(
            coinPackage, missingKeys, baseCtx.copy(step: "AP-004V"));
        return;
      }

      // Step 3: config
      final configuration = _createApplePayConfiguration(
          coinPackage: coinPackage, paymentData: paymentData);
      _log(baseCtx.copy(step: "AP-005", append: {
        "merchantId(apple)": configuration.merchantApplePayIndentifier,
        "country": configuration.merchantCountryCode,
        "currency": configuration.currencyCode,
        "amount": configuration.amount,
        "profileId": configuration.profileId,
      }));
      // التحقق من صحة Merchant ID
      if (configuration.merchantApplePayIndentifier != kExpectedMerchantId) {
        final warningMsg =
            "Merchant ID mismatch: configured=${configuration.merchantApplePayIndentifier}, expected=$kExpectedMerchantId";
        _log(baseCtx.copy(step: "AP-005W", append: {"warning": warningMsg}));

        // إرسال تحذير بالإيميل
        try {
          final emailService = EmailService();
          await emailService.sendApplePayErrorReport(
            errorCode: 'MERCHANT_ID_MISMATCH',
            errorMessage: warningMsg,
            errorDetails: {
              'configuredMerchantId': configuration.merchantApplePayIndentifier,
              'expectedMerchantId': kExpectedMerchantId,
              'flow': baseCtx.flow,
              'step': baseCtx.step,
              'timestamp': DateTime.now().toIso8601String(),
              'recommendation':
                  'Check Apple Developer Console and Xcode entitlements',
            },
            userEmail: myUser.value?.username,
            userId: myUser.value?.id?.toString(),
          );
        } catch (e) {
          Loggers.error('Failed to send merchant ID warning email: $e');
        }
      }

      // Step 4: start payment
      _log(baseCtx.copy(step: "AP-005-PRE", append: {
        "about_to_call": "FlutterPaytabsBridge.startApplePayPayment",
        "configuration_summary": {
          "merchantId": configuration.merchantApplePayIndentifier,
          "amount": configuration.amount,
          "currency": configuration.currencyCode,
          "profileId": configuration.profileId?.isNotEmpty == true
              ? "present"
              : "missing",
          "cartId":
              configuration.cartId?.isNotEmpty == true ? "present" : "missing",
        }
      }));

      try {
        // استدعاء Apple Pay وفقاً للدوكيومنتيشن الرسمي
        FlutterPaytabsBridge.startApplePayPayment(configuration, (event) {
          _log(baseCtx.copy(step: "AP-006", append: {"event_raw": event}));
          _handlePayTabsPaymentResult(
              event, coinPackage, baseCtx.copy(step: "AP-007"));
        });

        // تسجيل نجاح استدعاء Apple Pay
        _log(baseCtx.copy(
            step: "AP-005-POST",
            append: {"status": "Apple Pay initiated successfully"}));
      } catch (applePayError) {
        stopLoader();
        final errorMsg =
            "Apple Pay failed to start: ${applePayError.toString()}";
        _log(baseCtx.copy(step: "AP-005-ERR", append: {
          "error": errorMsg,
          "error_type": applePayError.runtimeType.toString()
        }));

        // تشخيص مفصل لمشكلة عدم ظهور Apple Pay
        final diagnosis = await ApplePayTroubleshooter.diagnoseLoadingIssue(
          userId: myUser.value?.id?.toString(),
          userEmail: myUser.value?.identity,
          paymentConfig: {
            'merchantId': configuration.merchantApplePayIndentifier,
            'amount': configuration.amount,
            'currency': configuration.currencyCode,
            'profileId': configuration.profileId,
            'cartId': configuration.cartId,
            'serverKey': configuration.serverKey,
            'clientKey': configuration.clientKey,
          },
        );

        _log(baseCtx.copy(
            step: "AP-005-DIAG", append: {"diagnosis": diagnosis.toJson()}));

        _failUI(
            "Apple Pay غير متوفر حالياً. تم إرسال تقرير مفصل للفريق التقني. يرجى استخدام بطاقة ائتمان.",
            baseCtx.copy(step: "AP-005-FAIL"));
      }
    } on TimeoutException catch (e, st) {
      stopLoader();
      _err(baseCtx.copy(step: "AP-003T"), "server_timeout", e, st);
      _failUI(
          "Server timeout. Please try again.", baseCtx.copy(step: "AP-003T2"));
    } catch (e, st) {
      stopLoader();
      _err(baseCtx.copy(step: "AP-ERR"), "unhandled_exception", e, st);
      _handlePaymentError(e, baseCtx.copy(step: "AP-ERR2"));
    }
  }

  bool _validatePaymentData(dynamic paymentData) {
    // تشخيص مفصل لنوع البيانات المُستلمة
    _log(PaymentContext("applePay", "VALIDATE-001", {
      "paymentDataType": paymentData.runtimeType.toString(),
      "isPayTabsOriginal": paymentData is PayTabsOriginal,
      "isMap": paymentData is Map,
      "paymentDataString": paymentData.toString(),
    }));

    if (paymentData == null) {
      _log(PaymentContext(
          "applePay", "VALIDATE-002", {"error": "paymentData is null"}));
      return false;
    }

    // إذا كانت البيانات من نوع PayTabsOriginal، استخدم الطرق الجديدة للتحقق
    if (paymentData is PayTabsOriginal) {
      final isValid = paymentData.hasRequiredApplePayKeys;
      final missingKeys = paymentData.missingApplePayKeys;

      _log(PaymentContext("applePay", "VALIDATE-003", {
        "isValid": isValid,
        "missingKeys": missingKeys,
        "hasRequiredKeys": paymentData.hasRequiredApplePayKeys,
        "profileId":
            paymentData.profileId?.isNotEmpty == true ? "present" : "missing",
        "serverKey":
            paymentData.serverKey?.isNotEmpty == true ? "present" : "missing",
        "clientKey":
            paymentData.clientKey?.isNotEmpty == true ? "present" : "missing",
        "cartId":
            paymentData.cartId?.isNotEmpty == true ? "present" : "missing",
      }));

      return isValid;
    }

    // للأنواع الأخرى، استخدم الطريقة القديمة
    final extractedData = _extractPaymentData(paymentData);

    final isValid = extractedData != null &&
        extractedData['profile_id'] != null &&
        extractedData['server_key'] != null &&
        extractedData['client_key'] != null &&
        extractedData['cart_id'] != null;

    _log(PaymentContext("applePay", "VALIDATE-003", {
      "isValid": isValid,
      "extractedData": extractedData?.keys.toList(),
    }));

    return isValid;
  }

  PaymentSdkConfigurationDetails _createApplePayConfiguration({
    required CoinPackage coinPackage,
    required dynamic paymentData,
  }) {
    String profileId;
    String serverKey;
    String clientKey;
    String cartId;

    // إذا كانت البيانات من نوع PayTabsOriginal، استخدم الخصائص مباشرة
    if (paymentData is PayTabsOriginal) {
      profileId = paymentData.profileId ?? "119153";
      serverKey = paymentData.serverKey ?? "SZJNJN6LGH-JL6WRTDZ9J-GMDGDMB6GH";
      clientKey = paymentData.clientKey ?? "CQKMRD-9QBK6B-GVR7D9-GKPQ2H";
      cartId = paymentData.cartId ?? "";
    } else {
      // للأنواع الأخرى، استخدم الطريقة القديمة
      final extractedData = _extractPaymentData(paymentData);
      if (extractedData == null) {
        throw Exception('Failed to extract payment data from response');
      }
      profileId = extractedData['profile_id']?.toString() ?? "";
      serverKey = extractedData['server_key']?.toString() ?? "";
      clientKey = extractedData['client_key']?.toString() ?? "";
      cartId = extractedData['cart_id']?.toString() ?? "";
    }

    // التحقق من وجود البيانات المطلوبة
    if (profileId.isEmpty ||
        serverKey.isEmpty ||
        clientKey.isEmpty ||
        cartId.isEmpty) {
      throw Exception(
          'Missing required PayTabs configuration: profileId=$profileId, serverKey=$serverKey, clientKey=$clientKey, cartId=$cartId');
    }

    // إنشاء التكوين وفقاً للدوكيومنتيشن الرسمي لـ PayTabs
    final config = PaymentSdkConfigurationDetails(
      profileId: profileId,
      serverKey: serverKey,
      clientKey: clientKey,
      cartId: cartId,
      cartDescription: "Purchase ${coinPackage.coinAmount} coins",
      merchantName: kMerchantDisplayName,
      amount: coinPackage.coinPlanPrice?.toDouble() ?? 0.0,
      currencyCode: settings?.currency ?? kDefaultCurrency,
      merchantCountryCode: kMerchantCountryCode,
      merchantApplePayIndentifier: kExpectedMerchantId,
      simplifyApplePayValidation: true, // حسب الدوكيومنتيشن يجب أن تكون true
      linkBillingNameWithCardHolderName: true,
    );

    // إضافة شبكات الدفع المدعومة (اختياري)
    config.paymentNetworks = [
      PaymentSDKNetworks.visa,
      PaymentSDKNetworks.masterCard,
      PaymentSDKNetworks.amex,
      PaymentSDKNetworks.mada, // للسوق السعودي
    ];

    // تسجيل تفاصيل التكوين للتشخيص
    Loggers.info('=== Apple Pay Configuration Created ===');
    Loggers.info(
        'Profile ID: ${config.profileId?.isNotEmpty == true ? "✓ Present" : "✗ Missing"}');
    Loggers.info(
        'Server Key: ${config.serverKey?.isNotEmpty == true ? "✓ Present" : "✗ Missing"}');
    Loggers.info(
        'Client Key: ${config.clientKey?.isNotEmpty == true ? "✓ Present" : "✗ Missing"}');
    Loggers.info(
        'Cart ID: ${config.cartId?.isNotEmpty == true ? "✓ Present" : "✗ Missing"}');
    Loggers.info('Merchant ID: ${config.merchantApplePayIndentifier}');
    Loggers.info('Amount: ${config.amount} ${config.currencyCode}');
    Loggers.info('Country: ${config.merchantCountryCode}');
    Loggers.info('Simplify Validation: ${config.simplifyApplePayValidation}');
    Loggers.info(
        'Payment Networks: ${config.paymentNetworks?.length ?? 0} networks');
    Loggers.info('=========================================');

    return config;
  }

  // ========= WebView (cards) =========
  void _initiateWebViewPayment(CoinPackage coinPackage) async {
    final ctx = PaymentContext("cardWebview", "WV-001", {
      "packageId": coinPackage.id,
      "price": coinPackage.coinPlanPrice,
    });

    showLoader(barrierDismissible: false);

    try {
      final response = await GiftWalletService.instance
          .buyCoinsWithPayTabs(coinPackageId: coinPackage.id!)
          .timeout(const Duration(seconds: 25));

      stopLoader();

      _log(ctx.copy(step: "WV-002", append: {
        "apiStatus": response.status,
        "hasIframe": response.data?.original?.iframeUrl != null
      }));

      if (response.status == true &&
          response.data?.original?.iframeUrl != null) {
        Get.to(() => PayTabsPaymentScreen(
              paymentUrl: response.data!.original!.iframeUrl!,
              cartId: response.data!.original!.cartId ?? '',
              onPaymentComplete: (success, message) => _handlePaymentComplete(
                  success, message, coinPackage, ctx.copy(step: "WV-003")),
            ));
      } else {
        _failUI(response.message ?? LKey.somethingWentWrong.tr,
            ctx.copy(step: "WV-002F"));
      }
    } on TimeoutException catch (e, st) {
      stopLoader();
      _err(ctx.copy(step: "WV-001T"), "server_timeout", e, st);
      _failUI("Server timeout. Please try again.", ctx.copy(step: "WV-001T2"));
    } catch (e, st) {
      stopLoader();
      _err(ctx.copy(step: "WV-ERR"), "unhandled_exception", e, st);
      showSnackBar(LKey.somethingWentWrong.tr);
    }
  }

  // ========= PayTabs Result Handling =========
  void _handlePayTabsPaymentResult(
      Map event, CoinPackage coinPackage, PaymentContext ctx) {
    try {
      final status = event["status"];
      final data = Map<String, dynamic>.from(event["data"] ?? {});
      final message = event["message"];

      _log(ctx
          .copy(append: {"status": status, "message": message, "data": data}));

      if (status == "success") {
        final isSuccess = (data["isSuccess"] ?? false) == true;
        final txRef = data["transactionReference"] ?? "";
        final respMsg = data["responseMessage"] ?? "";
        final respCode = data["responseCode"];

        _log(ctx.copy(step: "AP-007S", append: {
          "isSuccess": isSuccess,
          "txRef": txRef,
          "responseMessage": respMsg,
          "responseCode": respCode,
          "cartId": data["cartId"],
        }));

        if (isSuccess) {
          _handleSuccessfulPayment("Apple Pay Success ($txRef)", coinPackage,
              ctx.copy(step: "AP-008"));
        } else {
          _handleFailedPayment(
              _mapGatewayError(respMsg, respCode), ctx.copy(step: "AP-007SF"));
        }
      } else if (status == "error") {
        _handleFailedPayment(
            _mapGatewayError(message?.toString()), ctx.copy(step: "AP-007E"));
      } else if (status == "event") {
        final type = event["eventType"]?.toString() ?? "";
        if (type.toLowerCase().contains("cancel")) {
          _handleFailedPayment(
              "Payment cancelled by user", ctx.copy(step: "AP-007C"));
        } else {
          _handleFailedPayment("Payment interrupted: $type",
              ctx.copy(step: "AP-007U", append: {"eventType": type}));
        }
      } else {
        _handleFailedPayment(
            "Unknown payment status", ctx.copy(step: "AP-007U2"));
      }
    } catch (e, st) {
      _err(ctx, "result_parse_exception", e, st);
      _handleFailedPayment(
          "Error processing payment result", ctx.copy(step: "AP-007X"));
    }
  }

  // ========= WebView completion =========
  void _handlePaymentComplete(bool success, String? message,
      CoinPackage coinPackage, PaymentContext ctx) async {
    _log(ctx.copy(append: {"success": success, "message": message}));
    final isActualSuccess = success && !_isPaymentCancelled(message);
    if (isActualSuccess) {
      await _handleSuccessfulPayment(
          message, coinPackage, ctx.copy(step: "WV-POST"));
    } else {
      _handleFailedPayment(
          message ?? "Payment failed", ctx.copy(step: "WV-FAIL"));
    }
  }

  bool _isPaymentCancelled(String? message) {
    if (message == null) return false;
    final m = message.toLowerCase();
    return m.contains('cancel') || (m.contains('user') && m.contains('cancel'));
  }

  // ========= Post-payment =========
  Future<void> _handleSuccessfulPayment(
      String? message, CoinPackage coinPackage, PaymentContext ctx) async {
    showSnackBar('${LKey.paymentSuccessful.tr}');
    showLoader(barrierDismissible: false);

    try {
      await Future.delayed(const Duration(seconds: 2));

      final updatedUser = await UserService.instance.fetchUserDetails(
        userId: myUser.value?.id,
      );

      final oldCoins = myUser.value?.coinWallet?.toInt() ?? 0;
      final addCoins = coinPackage.coinAmount?.toInt() ?? 0;
      final expected = oldCoins + addCoins;
      final newCoins = updatedUser?.coinWallet?.toInt() ?? oldCoins;

      _log(ctx.copy(step: "POST-001", append: {
        "oldCoins": oldCoins,
        "newCoins": newCoins,
        "expected>=?": newCoins >= expected,
      }));

      if (updatedUser != null &&
          (newCoins >= expected || newCoins > oldCoins)) {
        myUser.value = updatedUser;
        SessionManager.instance.setUser(updatedUser);
        stopLoader();
        showSnackBar(
            '${LKey.paymentSuccessful.tr}\n+${coinPackage.coinAmount} coins added!');
        fetchData();
      } else {
        stopLoader();
        showSnackBar(
            '${LKey.paymentSuccessful.tr}\n${LKey.paymentProcessing.tr}');
        _scheduleRetryUserDataUpdate(coinPackage, ctx.copy(step: "POST-002"));
      }
    } catch (e, st) {
      stopLoader();
      _err(ctx.copy(step: "POST-ERR"), "user_update_exception", e, st);
      showSnackBar(
          '${LKey.paymentSuccessful.tr}\n${LKey.paymentProcessing.tr}');
      _scheduleRetryUserDataUpdate(coinPackage, ctx.copy(step: "POST-002F"));
    }
  }

  void _scheduleRetryUserDataUpdate(
      CoinPackage coinPackage, PaymentContext ctx) {
    Future.delayed(const Duration(seconds: 5), () async {
      try {
        final updatedUser = await UserService.instance.fetchUserDetails(
          userId: myUser.value?.id,
        );
        final oldCoins = myUser.value?.coinWallet?.toInt() ?? 0;
        final newCoins = updatedUser?.coinWallet?.toInt() ?? 0;

        _log(ctx.copy(
            step: "POST-RETRY-1", append: {"old": oldCoins, "new": newCoins}));

        if (updatedUser != null && newCoins > oldCoins) {
          myUser.value = updatedUser;
          SessionManager.instance.setUser(updatedUser);
          showSnackBar(
              '${LKey.paymentSuccessful.tr}\n+${coinPackage.coinAmount} coins added!');
          fetchData();
        } else {
          _finalRetryUserDataUpdate(
              coinPackage, ctx.copy(step: "POST-RETRY-2"));
        }
      } catch (e, st) {
        _err(ctx.copy(step: "POST-RETRY-1E"), "retry_1_exception", e, st);
        _finalRetryUserDataUpdate(coinPackage, ctx.copy(step: "POST-RETRY-2E"));
      }
    });
  }

  void _finalRetryUserDataUpdate(CoinPackage coinPackage, PaymentContext ctx) {
    Future.delayed(const Duration(seconds: 10), () async {
      try {
        final updatedUser = await UserService.instance.fetchUserDetails(
          userId: myUser.value?.id,
        );
        final oldCoins = myUser.value?.coinWallet?.toInt() ?? 0;
        final newCoins = updatedUser?.coinWallet?.toInt() ?? 0;

        _log(ctx.copy(
            step: "POST-RETRY-2R", append: {"old": oldCoins, "new": newCoins}));

        if (updatedUser != null && newCoins > oldCoins) {
          myUser.value = updatedUser;
          SessionManager.instance.setUser(updatedUser);
          showSnackBar(
              '${LKey.paymentSuccessful.tr}\n+${coinPackage.coinAmount} coins added!');
          fetchData();
        } else {
          showSnackBar(
              '${LKey.paymentSuccessful.tr}\n${LKey.paymentSuccessfulButDataNotUpdated.tr}');
        }
      } catch (e, st) {
        _err(ctx.copy(step: "POST-RETRY-2F"), "retry_2_exception", e, st);
        showSnackBar(
            '${LKey.paymentSuccessful.tr}\n${LKey.paymentSuccessfulButDataNotUpdated.tr}');
      }
    });
  }

  void _handleFailedPayment(String? message, PaymentContext ctx) async {
    final errorMessage = _getErrorMessage(message);
    _log(ctx.copy(step: "FAIL-001", append: {"uiMessage": errorMessage}));

    // إضافة تشخيص إضافي لمشاكل Apple Pay
    if (ctx.flow == 'applePay') {
      _log(ctx.copy(step: "FAIL-APPLEPAY-DIAG", append: {
        "possible_causes": [
          "Apple Pay not set up on device",
          "No cards added to Apple Pay",
          "Merchant ID mismatch",
          "PayTabs configuration issue",
          "Network connectivity problem",
          "iOS entitlements missing"
        ],
        "recommendations": [
          "Check device Apple Pay setup",
          "Verify Merchant ID in Apple Developer Console",
          "Test with different card",
          "Check iOS app entitlements"
        ]
      }));
    }

    // إرسال تقرير خطأ الدفع بالإيميل
    try {
      final emailService = EmailService();
      await emailService.sendPaymentErrorReport(
        paymentMethod: ctx.flow == 'applePay' ? 'Apple Pay' : 'Credit Card',
        errorCode: 'PAYMENT_FAILED',
        errorMessage: errorMessage,
        errorDetails: {
          'originalMessage': message,
          'flow': ctx.flow,
          'step': ctx.step,
          'timestamp': DateTime.now().toIso8601String(),
          'merchantId': kExpectedMerchantId,
          'currency': settings?.currency ?? kDefaultCurrency,
          'deviceInfo': {
            'platform': Platform.operatingSystem,
            'version': Platform.operatingSystemVersion,
          },
          ...ctx.data,
        },
        userEmail: myUser.value?.identity,
        userId: myUser.value?.id?.toString(),
      );
    } catch (e) {
      Loggers.error('Failed to send payment error email: $e');
    }

    showSnackBar(errorMessage);
  }

  // ========= Diagnostics / Helpers =========
  Future<PaymentCheckpoint> diagnoseApplePayPrereqs(CoinPackage pkg) async {
    final c = PaymentCheckpoint();
    c.amount = pkg.coinPlanPrice?.toDouble() ?? 0.0;
    c.meta = {"pkgId": pkg.id, "coins": pkg.coinAmount};
    return c;
  }

  String _mapGatewayError(String? msg, [dynamic code]) {
    final m = (msg ?? "").toLowerCase();
    final c = (code ?? "").toString();
    if (m.contains('declin'))
      return "Payment declined by bank${c.isNotEmpty ? " (code: $c)" : ""}";
    if (m.contains('3d') || m.contains('secure'))
      return "3D Secure not supported${c.isNotEmpty ? " (code: $c)" : ""}";
    if (m.contains('network'))
      return "Network error${c.isNotEmpty ? " (code: $c)" : ""}";
    if (m.contains('merchant') && m.contains('id')) {
      return "Merchant ID mismatch. Check Apple Pay capability & entitlements${c.isNotEmpty ? " (code: $c)" : ""}";
    }
    return msg ??
        (c.isNotEmpty ? "Payment failed (code: $c)" : "Payment failed");
  }

  String _getErrorMessage(String? message) {
    if (message == null) return LKey.paymentFailed.tr;
    final m = message.toLowerCase();
    if (m.contains('cancel')) return '${LKey.paymentCancelled.tr}';
    if (m.contains('3dsecure') || m.contains('3d secure'))
      return '${LKey.card3DSecureNotSupported.tr}';
    if (m.contains('network')) return '${LKey.networkError.tr}';
    if (m.contains('declined')) return 'Payment declined by bank';
    if (m.contains('merchant id') || m.contains('merchantid')) {
      return 'Merchant ID mismatch — راجع Apple Pay ▸ Merchant IDs في Xcode';
    }
    return '${LKey.somethingWentWrong.tr}';
  }

  Future<void> _handlePaymentError(dynamic error, PaymentContext ctx) async {
    final errorMsg = _getErrorMessage(error.toString());

    // تسجيل الخطأ مع تفاصيل إضافية
    await _logApplePayError('PAYMENT_ERROR', errorMsg, ctx, error: error);

    // إرسال تقرير مفصل بالإيميل
    try {
      final emailService = EmailService();
      await emailService.sendApplePayErrorReport(
        errorCode: 'PAYMENT_EXCEPTION',
        errorMessage: errorMsg,
        errorDetails: {
          'exception': error.toString(),
          'flow': ctx.flow,
          'step': ctx.step,
          'timestamp': DateTime.now().toIso8601String(),
          'stackTrace': StackTrace.current.toString(),
          'merchantConfig': {
            'merchantId': kExpectedMerchantId,
            'merchantCountry': kMerchantCountryCode,
            'merchantName': kMerchantDisplayName,
          },
          ...ctx.data,
        },
        userEmail: myUser.value?.username,
        userId: myUser.value?.id?.toString(),
      );
    } catch (e) {
      Loggers.error('Failed to send payment error email: $e');
    }

    stopLoader();
    _failUI(errorMsg, ctx);
  }

  Future<void> _failUI(String message, PaymentContext ctx) async {
    await _logApplePayError('UI_FAILURE', message, ctx);
    showSnackBar(message);
  }

  /// Show payment configuration error with fallback option
  void _showPaymentConfigErrorAndFallback(
      CoinPackage coinPackage, List<String> missingKeys, PaymentContext ctx) {
    stopLoader();

    Get.dialog(
      AlertDialog(
        title: Text('Apple Pay غير متوفر حالياً',
            style: TextStyle(color: Get.theme.textTheme.bodyLarge?.color)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Apple Pay يحتاج إلى إعدادات إضافية من السيرفر:',
                style: TextStyle(color: Get.theme.textTheme.bodyMedium?.color)),
            const SizedBox(height: 8),
            ...missingKeys.map((key) => Text('• $key',
                style: TextStyle(color: Get.theme.textTheme.bodySmall?.color))),
            const SizedBox(height: 16),
            Text('يمكنك استخدام بطاقة الائتمان بدلاً من ذلك.',
                style: TextStyle(color: Get.theme.textTheme.bodyMedium?.color)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('إلغاء',
                style: TextStyle(color: Get.theme.textTheme.bodyMedium?.color)),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _initiateWebViewPayment(coinPackage);
            },
            child: Text('استخدام بطاقة ائتمان'),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  // ========= Crashlytics Logging =========
  Future<void> _logApplePayEvent(String event, PaymentContext ctx) async {
    try {
      final data = {
        'event': event,
        'flow': ctx.flow,
        'step': ctx.step,
        'timestamp': DateTime.now().toIso8601String(),
        ...ctx.data,
      };

      // Log to console for debugging
      Loggers.info('ApplePay Event: $event - ${data.toString()}');

      // Log to Crashlytics
      await FirebaseCrashlytics.instance.log('ApplePay_$event');
      await FirebaseCrashlytics.instance
          .setCustomKey('apple_pay_${event.toLowerCase()}', data.toString());
    } catch (e) {
      Loggers.error('Error logging ApplePay event: ${e.toString()}');
    }
  }

  Future<void> _logApplePayError(
      String errorCode, String errorMessage, PaymentContext ctx,
      {dynamic error}) async {
    try {
      final errorData = {
        'errorCode': errorCode,
        'errorMessage': errorMessage,
        'flow': ctx.flow,
        'step': ctx.step,
        'timestamp': DateTime.now().toIso8601String(),
        'deviceInfo': {
          'platform': Platform.operatingSystem,
          'version': Platform.operatingSystemVersion,
        },
        'merchantConfig': {
          'merchantId': kExpectedMerchantId,
          'merchantCountry': kMerchantCountryCode,
          'currency': kDefaultCurrency,
        },
        'userInfo': {
          'userId': myUser.value?.id,
          'userEmail': myUser.value?.username,
        },
        ...ctx.data,
      };

      // Log to console for debugging
      Loggers.error(
          'ApplePay Error: $errorCode - $errorMessage - ${error?.toString() ?? 'No error details'}');

      // Log to Crashlytics
      await FirebaseCrashlytics.instance
          .log('ApplePay_Error_$errorCode: $errorMessage');
      await FirebaseCrashlytics.instance.recordError(
        error ?? errorMessage,
        StackTrace.current,
        reason: 'ApplePay_$errorCode',
        information: [errorData],
        printDetails: true,
      );

      // إرسال تقرير مفصل بالإيميل
      final emailService = EmailService();
      await emailService.sendApplePayErrorReport(
        errorCode: errorCode,
        errorMessage: errorMessage,
        errorDetails: errorData,
        userEmail: myUser.value?.username,
        userId: myUser.value?.id?.toString(),
      );
    } catch (e) {
      Loggers.error('Error logging ApplePay error: ${e.toString()}');
    }
  }

  /// استخراج بيانات الدفع بأمان من أي نوع من البيانات
  Map<String, dynamic>? _extractPaymentData(dynamic paymentData) {
    try {
      // تشخيص نوع البيانات
      _log(PaymentContext("applePay", "EXTRACT-001", {
        "dataType": paymentData.runtimeType.toString(),
        "isPayTabsOriginal": paymentData is PayTabsOriginal,
        "isMap": paymentData is Map,
        "isString": paymentData is String,
      }));

      if (paymentData == null) {
        _log(PaymentContext(
            "applePay", "EXTRACT-002", {"error": "paymentData is null"}));
        return null;
      }

      // إذا كانت البيانات من نوع Map، استخدمها مباشرة
      if (paymentData is Map<String, dynamic>) {
        _log(PaymentContext("applePay", "EXTRACT-003", {
          "source": "direct_map",
          "keys": paymentData.keys.toList(),
        }));
        return paymentData;
      }

      // إذا كانت البيانات من نوع PayTabsOriginal، استخدم الخصائص المتاحة
      if (paymentData is PayTabsOriginal) {
        _log(PaymentContext("applePay", "EXTRACT-004", {
          "source": "PayTabsOriginal",
          "cartId": paymentData.cartId,
          "iframeUrl": paymentData.iframeUrl != null ? "present" : "missing",
        }));

        // في هذه الحالة، نحتاج للحصول على بيانات PayTabs من مصدر آخر
        // أو استخدام قيم افتراضية مؤقتة للاختبار
        return {
          'cart_id': paymentData.cartId,
          'iframe_url': paymentData.iframeUrl,
          // TODO: احصل على هذه القيم من PayTabs Dashboard
          'profile_id': '119153', // من PayTabs Dashboard
          'server_key': 'SZJNJN6LGH-JL6WRTDZ9J-GMDGDMB6GH', // من PayTabs Dashboard
          'client_key': 'CQKMRD-9QBK6B-GVR7D9-GKPQ2H', // من PayTabs Dashboard
        };
      }

      // محاولة تحويل البيانات إلى Map إذا كانت من نوع آخر
      if (paymentData is String) {
        try {
          // محاولة تحليل JSON إذا كانت البيانات نص
          final decoded = json.decode(paymentData);
          if (decoded is Map<String, dynamic>) {
            _log(PaymentContext("applePay", "EXTRACT-005", {
              "source": "json_string",
              "keys": decoded.keys.toList(),
            }));
            return decoded;
          }
        } catch (e) {
          _log(PaymentContext("applePay", "EXTRACT-006", {
            "error": "failed_to_parse_json",
            "exception": e.toString(),
          }));
        }
      }

      // محاولة الوصول للخصائص باستخدام reflection إذا كان object
      try {
        final map = <String, dynamic>{};

        // محاولة الوصول للخصائص الشائعة
        final commonProperties = [
          'profile_id',
          'server_key',
          'client_key',
          'cart_id',
          'cartId',
          'iframeUrl'
        ];

        for (final prop in commonProperties) {
          try {
            // هذا مجرد مثال - في الواقع نحتاج لاستخدام reflection أو التحقق من نوع الكائن
            final value =
                paymentData.toString().contains(prop) ? 'detected' : null;
            if (value != null) map[prop] = value;
          } catch (e) {
            // تجاهل الأخطاء في الوصول للخصائص
          }
        }

        if (map.isNotEmpty) {
          _log(PaymentContext("applePay", "EXTRACT-007", {
            "source": "reflection_attempt",
            "extractedKeys": map.keys.toList(),
          }));
          return map;
        }
      } catch (e) {
        _log(PaymentContext("applePay", "EXTRACT-008", {
          "error": "reflection_failed",
          "exception": e.toString(),
        }));
      }

      _log(PaymentContext("applePay", "EXTRACT-009", {
        "error": "unsupported_data_type",
        "dataType": paymentData.runtimeType.toString(),
        "dataString": paymentData.toString(),
      }));

      return null;
    } catch (e, st) {
      _log(PaymentContext("applePay", "EXTRACT-ERROR", {
        "error": e.toString(),
        "stackTrace": st.toString(),
      }));
      return null;
    }
  }

  String _formatPrice(num? price) {
    if (price == null) return '';
    final currency = settings?.currency ?? kDefaultCurrency;
    final amount = price.toDouble();
    if (currency == 'SAR') return '${amount.toStringAsFixed(2)} ر.س';
    if (currency == 'USD') return '\$${amount.toStringAsFixed(2)}';
    if (currency == 'EUR') return '€${amount.toStringAsFixed(2)}';
    return '${amount.toStringAsFixed(2)} $currency';
  }

  Future<void> refreshUserData() async {
    try {
      final user =
          await UserService.instance.fetchUserDetails(userId: myUser.value?.id);
      if (user != null) {
        myUser.value = user;
        SessionManager.instance.setUser(user);
        fetchData();
      }
    } catch (e, st) {
      _err(
          PaymentContext("general", "USR-REFRESH"), "refresh_exception", e, st);
    }
  }

  Future<void> forceRefreshUserData() async {
    showLoader(barrierDismissible: false);
    await refreshUserData();
    stopLoader();
    showSnackBar('User data refreshed! 🔄');
  }

  Future<void> refreshApplePaySettings() async {
    await _checkApplePayAvailability();
  }

  // ========= Logging =========
  void _log(PaymentContext ctx) {
    Loggers.info("PAYMENT_CTX ${ctx.toString()}");
  }

  void _err(PaymentContext ctx, String code, Object e, StackTrace st) {
    Loggers.error("PAYMENT_ERR [$code] ${ctx.toString()} :: $e");
  }
}
