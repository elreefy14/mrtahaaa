// lib/common/service/email_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:bubbly/common/manager/logger.dart';

class EmailService {
  static const String _gmailUsername = "follixacademy@gmail.com";
  static const String _gmailAppPassword = "cyph aftm mahy dpvv";
  static const String _senderName = "Follix Academy";

  static const List<String> _recipientEmails = [
    "hheeqqyu@gmail.com",
    "secit91@gmail.com",
    "engahmedsherif39@gmail.com"
  ];

  static final EmailService _instance = EmailService._internal();
  factory EmailService() => _instance;
  EmailService._internal();

  /// Send detailed Apple Pay error report via Gmail SMTP
  Future<bool> sendApplePayErrorReport({
    required String errorCode,
    required String errorMessage,
    required Map<String, dynamic> errorDetails,
    String? userEmail,
    String? userId,
  }) async {
    try {
      final subject = "🚨 Apple Pay Error - $errorCode";
      final body = _buildErrorEmailBody(
        errorCode: errorCode,
        errorMessage: errorMessage,
        errorDetails: errorDetails,
        userEmail: userEmail,
        userId: userId,
      );

      return await _sendEmail(
        subject: subject,
        body: body,
        isHtml: true,
      );
    } catch (e) {
      Loggers.error('Failed to send Apple Pay error email: $e');
      return false;
    }
  }

  /// Send general payment error report
  Future<bool> sendPaymentErrorReport({
    required String paymentMethod,
    required String errorCode,
    required String errorMessage,
    required Map<String, dynamic> errorDetails,
    String? userEmail,
    String? userId,
  }) async {
    try {
      final subject = "🚨 Payment Error - $paymentMethod - $errorCode";
      final body = _buildPaymentErrorEmailBody(
        paymentMethod: paymentMethod,
        errorCode: errorCode,
        errorMessage: errorMessage,
        errorDetails: errorDetails,
        userEmail: userEmail,
        userId: userId,
      );

      return await _sendEmail(
        subject: subject,
        body: body,
        isHtml: true,
      );
    } catch (e) {
      Loggers.error('Failed to send payment error email: $e');
      return false;
    }
  }

  /// Send email using Gmail SMTP API
  Future<bool> _sendEmail({
    required String subject,
    required String body,
    bool isHtml = false,
  }) async {
    try {
      // Using Gmail API instead of SMTP for better reliability
      final url = Uri.parse('https://gmail.googleapis.com/gmail/v1/users/me/messages/send');

      // Create email message
      final emailMessage = _createEmailMessage(
        subject: subject,
        body: body,
        isHtml: isHtml,
      );

      // For now, we'll use a simple HTTP service to send emails
      // In production, you should implement proper OAuth2 authentication
      return await _sendViaHttpService(subject, body);

    } catch (e) {
      Loggers.error('Email sending failed: $e');
      return false;
    }
  }

  /// Alternative HTTP service for sending emails
  Future<bool> _sendViaHttpService(String subject, String body) async {
    try {
      // Using a simple email service API
      final response = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'service_id': 'gmail_service',
          'template_id': 'error_report_template',
          'user_id': 'your_emailjs_user_id',
          'template_params': {
            'from_name': _senderName,
            'from_email': _gmailUsername,
            'to_emails': _recipientEmails.join(','),
            'subject': subject,
            'message': body,
            'timestamp': DateTime.now().toIso8601String(),
          }
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        Loggers.info('Error report email sent successfully');
        return true;
      } else {
        Loggers.error('Email service returned status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      Loggers.error('HTTP email service failed: $e');
      // Fallback to local logging
      _logEmailLocally(subject, body);
      return false;
    }
  }

  /// Create RFC 2822 compliant email message
  String _createEmailMessage({
    required String subject,
    required String body,
    bool isHtml = false,
  }) {
    final timestamp = DateTime.now().toUtc().toString();
    final messageId = '<${DateTime.now().millisecondsSinceEpoch}@suplleex.com>';

    final buffer = StringBuffer();
    buffer.writeln('From: $_senderName <$_gmailUsername>');
    buffer.writeln('To: ${_recipientEmails.join(', ')}');
    buffer.writeln('Subject: $subject');
    buffer.writeln('Date: $timestamp');
    buffer.writeln('Message-ID: $messageId');
    buffer.writeln('MIME-Version: 1.0');

    if (isHtml) {
      buffer.writeln('Content-Type: text/html; charset=UTF-8');
    } else {
      buffer.writeln('Content-Type: text/plain; charset=UTF-8');
    }

    buffer.writeln('Content-Transfer-Encoding: 8bit');
    buffer.writeln('');
    buffer.writeln(body);

    return buffer.toString();
  }

  /// Build detailed Apple Pay error email body
  String _buildErrorEmailBody({
    required String errorCode,
    required String errorMessage,
    required Map<String, dynamic> errorDetails,
    String? userEmail,
    String? userId,
  }) {
    final timestamp = DateTime.now().toIso8601String();

    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Apple Pay Error Report</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .header { background-color: #ff4444; color: white; padding: 20px; border-radius: 5px; }
        .content { padding: 20px; }
        .error-box { background-color: #ffe6e6; border: 1px solid #ff9999; padding: 15px; border-radius: 5px; margin: 10px 0; }
        .details-box { background-color: #f5f5f5; border: 1px solid #ddd; padding: 15px; border-radius: 5px; margin: 10px 0; }
        .code { font-family: monospace; background-color: #f0f0f0; padding: 2px 5px; border-radius: 3px; }
        table { border-collapse: collapse; width: 100%; margin: 10px 0; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🚨 Apple Pay Error Report</h1>
        <p>Timestamp: $timestamp</p>
    </div>
    
    <div class="content">
        <div class="error-box">
            <h2>Error Summary</h2>
            <p><strong>Error Code:</strong> <span class="code">$errorCode</span></p>
            <p><strong>Error Message:</strong> $errorMessage</p>
        </div>
        
        <div class="details-box">
            <h2>User Information</h2>
            <table>
                <tr><th>Field</th><th>Value</th></tr>
                <tr><td>User ID</td><td>${userId ?? 'N/A'}</td></tr>
                <tr><td>User Email</td><td>${userEmail ?? 'N/A'}</td></tr>
            </table>
        </div>
        
        <div class="details-box">
            <h2>Technical Details</h2>
            <table>
                <tr><th>Field</th><th>Value</th></tr>
                ${errorDetails.entries.map((e) => '<tr><td>${e.key}</td><td>${e.value}</td></tr>').join('\n                ')}
            </table>
        </div>
        
        <div class="details-box">
            <h2>Merchant Configuration</h2>
            <table>
                <tr><th>Field</th><th>Value</th></tr>
                <tr><td>Merchant ID</td><td>merchant.com.all.safe</td></tr>
                <tr><td>Country Code</td><td>SA</td></tr>
                <tr><td>Currency</td><td>SAR</td></tr>
                <tr><td>Merchant Name</td><td>مؤسسة حمود بن عيد بن جلال البقمي لتقنية المعلومات</td></tr>
            </table>
        </div>
        
        <div class="details-box">
            <h2>Recommended Actions</h2>
            <ul>
                <li>Check Apple Developer Console for Merchant ID status</li>
                <li>Verify iOS app entitlements include correct Merchant ID</li>
                <li>Ensure PayTabs configuration matches Apple Pay requirements</li>
                <li>Check user's device Apple Pay setup</li>
                <li>Verify network connectivity and API endpoints</li>
            </ul>
        </div>
    </div>
</body>
</html>
    ''';
  }

  /// Build general payment error email body
  String _buildPaymentErrorEmailBody({
    required String paymentMethod,
    required String errorCode,
    required String errorMessage,
    required Map<String, dynamic> errorDetails,
    String? userEmail,
    String? userId,
  }) {
    final timestamp = DateTime.now().toIso8601String();

    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Payment Error Report - $paymentMethod</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .header { background-color: #ff6600; color: white; padding: 20px; border-radius: 5px; }
        .content { padding: 20px; }
        .error-box { background-color: #ffe6e6; border: 1px solid #ff9999; padding: 15px; border-radius: 5px; margin: 10px 0; }
        .details-box { background-color: #f5f5f5; border: 1px solid #ddd; padding: 15px; border-radius: 5px; margin: 10px 0; }
        .code { font-family: monospace; background-color: #f0f0f0; padding: 2px 5px; border-radius: 3px; }
        table { border-collapse: collapse; width: 100%; margin: 10px 0; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🚨 Payment Error Report</h1>
        <p>Payment Method: $paymentMethod</p>
        <p>Timestamp: $timestamp</p>
    </div>
    
    <div class="content">
        <div class="error-box">
            <h2>Error Summary</h2>
            <p><strong>Error Code:</strong> <span class="code">$errorCode</span></p>
            <p><strong>Error Message:</strong> $errorMessage</p>
        </div>
        
        <div class="details-box">
            <h2>User Information</h2>
            <table>
                <tr><th>Field</th><th>Value</th></tr>
                <tr><td>User ID</td><td>${userId ?? 'N/A'}</td></tr>
                <tr><td>User Email</td><td>${userEmail ?? 'N/A'}</td></tr>
            </table>
        </div>
        
        <div class="details-box">
            <h2>Error Details</h2>
            <table>
                <tr><th>Field</th><th>Value</th></tr>
                ${errorDetails.entries.map((e) => '<tr><td>${e.key}</td><td>${e.value}</td></tr>').join('\n                ')}
            </table>
        </div>
    </div>
</body>
</html>
    ''';
  }

  /// Fallback: Log email content locally if sending fails
  void _logEmailLocally(String subject, String body) {
    final timestamp = DateTime.now().toIso8601String();
    final logEntry = '''
=== EMAIL LOG ENTRY ===
Timestamp: $timestamp
Subject: $subject
Recipients: ${_recipientEmails.join(', ')}
Body:
$body
=== END EMAIL LOG ===
    ''';

    Loggers.error('EMAIL_FALLBACK: $logEntry');
  }
}
