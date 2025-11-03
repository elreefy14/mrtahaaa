// lib/model/payment/paytabs_response_model.dart

import 'package:bubbly/model/user_model/user_model.dart';

class PayTabsResponseModel {
  final bool? status;
  final String? message;
  final PayTabsData? data;

  PayTabsResponseModel({
    this.status,
    this.message,
    this.data,
  });

  factory PayTabsResponseModel.fromJson(Map<String, dynamic> json) {
    return PayTabsResponseModel(
      status: json['status'],
      message: json['message'],
      data: json['data'] != null ? PayTabsData.fromJson(json['data']) : null,
    );
  }
}

// Response model for payment confirmation
class PaymentConfirmationModel {
  final bool? status;
  final String? message;
  final User? data;

  PaymentConfirmationModel({
    this.status,
    this.message,
    this.data,
  });

  factory PaymentConfirmationModel.fromJson(Map<String, dynamic> json) {
    return PaymentConfirmationModel(
      status: json['status'],
      message: json['message'],
      data: json['data'] != null ? User.fromJson(json['data']) : null,
    );
  }
}

class PayTabsData {
  final Map<String, dynamic>? headers;
  final PayTabsOriginal? original;
  final dynamic exception;

  PayTabsData({
    this.headers,
    this.original,
    this.exception,
  });

  factory PayTabsData.fromJson(Map<String, dynamic> json) {
    return PayTabsData(
      headers: json['headers'],
      original: json['original'] != null
          ? PayTabsOriginal.fromJson(json['original'])
          : null,
      exception: json['exception'],
    );
  }
}

class PayTabsOriginal {
  final String? iframeUrl;
  final String? cartId;
  final String? profileId;
  final String? serverKey;
  final String? clientKey;
  final String? merchantId;
  final String? currency;
  final double? amount;

  PayTabsOriginal({
    this.iframeUrl,
    this.cartId,
    this.profileId,
    this.serverKey,
    this.clientKey,
    this.merchantId,
    this.currency,
    this.amount,
  });

  factory PayTabsOriginal.fromJson(Map<String, dynamic> json) {
    return PayTabsOriginal(
      iframeUrl: json['iframeUrl'],
      cartId: json['cartId'],
      profileId: json['profile_id'] ?? json['profileId'],
      serverKey: json['server_key'] ?? json['serverKey'],
      clientKey: json['client_key'] ?? json['clientKey'],
      merchantId: json['merchant_id'] ?? json['merchantId'],
      currency: json['currency'],
      amount: json['amount']?.toDouble(),
    );
  }

  /// Check if all required PayTabs keys are present for Apple Pay
  bool get hasRequiredApplePayKeys =>
      profileId != null &&
      profileId!.isNotEmpty &&
      serverKey != null &&
      serverKey!.isNotEmpty &&
      clientKey != null &&
      clientKey!.isNotEmpty &&
      cartId != null &&
      cartId!.isNotEmpty;

  /// Get missing keys for Apple Pay configuration
  List<String> get missingApplePayKeys {
    final missing = <String>[];
    if (profileId == null || profileId!.isEmpty) missing.add('profile_id');
    if (serverKey == null || serverKey!.isEmpty) missing.add('server_key');
    if (clientKey == null || clientKey!.isEmpty) missing.add('client_key');
    if (cartId == null || cartId!.isEmpty) missing.add('cart_id');
    return missing;
  }
}
