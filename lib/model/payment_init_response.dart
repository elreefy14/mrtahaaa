import 'dart:convert';

class PaymentInitResponse {
  bool status;
  String message;
  Map<String, dynamic> data;

  PaymentInitResponse({required this.status, required this.message, required this.data});

  factory PaymentInitResponse.fromJson(Map<String, dynamic> json) {
    return PaymentInitResponse(
      status: json['status'],
      message: json['message'],
      data: json['data'],
    );
  }
}
