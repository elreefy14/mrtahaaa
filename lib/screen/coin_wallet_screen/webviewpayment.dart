// lib/screen/coin_wallet_screen/webviewpayment.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:bubbly/common/widget/custom_back_button.dart';
import 'package:bubbly/languages/languages_keys.dart';
import 'package:bubbly/utilities/text_style_custom.dart';
import 'package:bubbly/utilities/theme_res.dart';

class PayTabsPaymentScreen extends StatefulWidget {
  final String paymentUrl;
  final String cartId;
  final Function(bool success, String? message) onPaymentComplete;

  const PayTabsPaymentScreen({
    super.key,
    required this.paymentUrl,
    required this.cartId,
    required this.onPaymentComplete,
  });

  @override
  State<PayTabsPaymentScreen> createState() => _PayTabsPaymentScreenState();
}

class _PayTabsPaymentScreenState extends State<PayTabsPaymentScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasProcessedResult = false;
  int _checkCount = 0;
  static const int _maxChecks = 30; // Limit checks to prevent infinite loop

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..enableZoom(false)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) {
              setState(() {
                _isLoading = progress < 100;
              });
            }
          },
          onPageStarted: (String url) {
            print('🌐 Page started loading: $url');
            if (mounted) {
              setState(() {
                _isLoading = true;
              });
            }
          },
          onPageFinished: (String url) {
            print('✅ Page finished loading: $url');
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }

            // Only check for payment result on specific URLs
            if (_shouldCheckForResult(url)) {
              _checkPageContent();
            }
          },
          onWebResourceError: (WebResourceError error) {
            print('❌ WebView Error: ${error.description}');
            if (!_hasProcessedResult) {
              _processPaymentResult(false, 'Network error: ${error.description}');
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            print('🔗 Navigation request: ${request.url}');

            // Check if URL indicates completion
            if (_shouldCheckForResult(request.url)) {
              Future.delayed(Duration(milliseconds: 1000), () {
                if (!_hasProcessedResult) {
                  _checkPageContent();
                }
              });
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..addJavaScriptChannel(
        'PaymentResult',
        onMessageReceived: (JavaScriptMessage message) {
          print('🔔 Received payment result: ${message.message}');
          _handleJavaScriptMessage(message.message);
        },
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  bool _shouldCheckForResult(String url) {
    return url.contains('/payment/return') ||
        url.contains('/callback') ||
        url.contains('payment-success') ||
        url.contains('payment-failed') ||
        url.contains('payment-complete');
  }

  void _checkPageContent() {
    if (_hasProcessedResult || _checkCount >= _maxChecks) {
      return;
    }

    _checkCount++;

    String jsCode = '''
      (function() {
        try {
          var bodyText = document.body.innerText || document.body.textContent || '';
          var bodyHTML = document.body.innerHTML || '';
          
          // Look for JSON response
          var jsonMatch = bodyText.match(/\\{[^}]*"status"[^}]*\\}/);
          if (jsonMatch) {
            try {
              var jsonData = JSON.parse(jsonMatch[0]);
              PaymentResult.postMessage(JSON.stringify({
                type: 'paymentResult',
                success: jsonData.status === true || jsonData.status === "true",
                message: jsonData.message || 'Payment completed',
                data: jsonData
              }));
              return;
            } catch(e) {
              console.log("JSON parse error:", e);
            }
          }
          
          // Check for complete JSON response
          var trimmedText = bodyText.trim();
          if (trimmedText.startsWith('{') && trimmedText.endsWith('}')) {
            try {
              var jsonData = JSON.parse(trimmedText);
              PaymentResult.postMessage(JSON.stringify({
                type: 'paymentResult',
                success: jsonData.status === true || jsonData.status === "true",
                message: jsonData.message || 'Payment completed',
                data: jsonData
              }));
              return;
            } catch(e) {
              console.log("JSON parse error:", e);
            }
          }
          
          // Check for keyword indicators
          var lowerText = bodyText.toLowerCase();
          
          var successWords = [
            'payment successful',
            'payment completed',
            'transaction approved',
            'payment approved',
            'success',
            'completed successfully',
            'coins purchased successfully'
          ];
          
          var failureWords = [
            'payment failed',
            'payment declined',
            'transaction failed',
            'payment error',
            'declined',
            'failed',
            'error'
          ];
          
          var foundSuccess = successWords.some(word => lowerText.includes(word));
          var foundFailure = failureWords.some(word => lowerText.includes(word));
          
          if (foundSuccess && !foundFailure) {
            PaymentResult.postMessage(JSON.stringify({
              type: 'paymentResult',
              success: true,
              message: 'Payment successful'
            }));
          } else if (foundFailure) {
            PaymentResult.postMessage(JSON.stringify({
              type: 'paymentResult',
              success: false,
              message: 'Payment failed'
            }));
          }
          
        } catch (e) {
          console.log("Error checking page content:", e);
        }
      })();
    ''';

    _controller.runJavaScript(jsCode);

    // Limited retry mechanism
    if (!_hasProcessedResult && _checkCount < _maxChecks) {
      Future.delayed(Duration(seconds: 3), () {
        if (!_hasProcessedResult && mounted) {
          _checkPageContent();
        }
      });
    }
  }

  void _handleJavaScriptMessage(String message) {
    if (_hasProcessedResult) return;

    print('🔔 Processing JavaScript message: $message');

    try {
      final Map<String, dynamic> data = jsonDecode(message);

      if (data['type'] == 'paymentResult') {
        bool isSuccess = data['success'] == true;
        String resultMessage = data['message'] ?? 'Payment completed';

        print('📊 Payment result: Success=$isSuccess, Message=$resultMessage');
        _processPaymentResult(isSuccess, resultMessage);
      }
    } catch (e) {
      print('⚠️ Error parsing JavaScript message: $e');

      // Fallback text analysis
      if (message.contains('success') || message.contains('completed')) {
        _processPaymentResult(true, 'Payment successful');
      } else if (message.contains('failed') || message.contains('error')) {
        _processPaymentResult(false, 'Payment failed');
      }
    }
  }

  void _processPaymentResult(bool success, String message) {
    if (_hasProcessedResult) return;

    _hasProcessedResult = true;
    print('📊 Processing payment result: Success=$success, Message=$message');

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    // Close WebView and return result
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.of(context).pop();
        widget.onPaymentComplete(success, message);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (!_hasProcessedResult) {
          _processPaymentResult(false, 'Payment cancelled by user');
        }
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: CustomBackButton(
            onTap: () {
              if (!_hasProcessedResult) {
                _processPaymentResult(false, 'Payment cancelled by user');
              }
            },
          ),
          title: Text(
            LKey.payment.tr,
            style: TextStyleCustom.unboundedMedium500(
              color: textDarkGrey(context),
              fontSize: 18,
            ),
          ),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              Container(
                color: Colors.white.withValues(alpha: 0.9),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        _hasProcessedResult
                            ? 'Processing payment...'
                            : 'Loading payment page...',
                        style: TextStyleCustom.outFitRegular400(
                          color: textDarkGrey(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    print('🗑️ PayTabs WebView disposed');
    super.dispose();
  }
}