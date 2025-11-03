// lib/common/helper/apple_pay_validator.dart
import 'dart:io';
import 'package:bubbly/common/manager/logger.dart';
import 'package:bubbly/common/service/email_service.dart';

class ApplePayValidator {
  static const String kExpectedMerchantId = "merchant.com.all.safe";
  static const String kMerchantCountryCode = "SA";
  static const String kDefaultCurrency = "SAR";

  /// Validate Apple Pay configuration and send detailed report
  static Future<ApplePayValidationResult> validateConfiguration({
    String? userId,
    String? userEmail,
  }) async {
    final result = ApplePayValidationResult();
    final issues = <String>[];
    final warnings = <String>[];

    try {
      // 1. Platform Check
      if (!Platform.isIOS) {
        issues.add("Apple Pay is only available on iOS devices");
        result.isValid = false;
      }

      // 2. Merchant ID Format Check
      if (!kExpectedMerchantId.startsWith('merchant.')) {
        issues.add("Merchant ID must start with 'merchant.' prefix");
        result.isValid = false;
      }

      // 3. Country Code Check
      if (kMerchantCountryCode.length != 2) {
        issues.add("Invalid country code format. Must be 2 characters (e.g., 'SA', 'US')");
        result.isValid = false;
      }

      // 4. Currency Check
      final validCurrencies = ['SAR', 'USD', 'EUR', 'GBP', 'AED'];
      if (!validCurrencies.contains(kDefaultCurrency)) {
        warnings.add("Currency '$kDefaultCurrency' may not be supported by Apple Pay in all regions");
      }

      // 5. Merchant ID Domain Check
      final merchantDomain = kExpectedMerchantId.replaceFirst('merchant.', '');
      if (!merchantDomain.contains('.')) {
        warnings.add("Merchant ID domain should follow reverse domain format (e.g., com.company.app)");
      }

      result.issues = issues;
      result.warnings = warnings;
      result.merchantId = kExpectedMerchantId;
      result.countryCode = kMerchantCountryCode;
      result.currency = kDefaultCurrency;

      // Send validation report via email
      await _sendValidationReport(result, userId, userEmail);

      return result;

    } catch (e, st) {
      Loggers.error('Apple Pay validation failed: $e');
      result.isValid = false;
      result.issues.add('Validation process failed: ${e.toString()}');
      return result;
    }
  }

  /// Send validation report via email
  static Future<void> _sendValidationReport(
      ApplePayValidationResult result,
      String? userId,
      String? userEmail,
      ) async {
    try {
      final emailService = EmailService();

      final errorDetails = {
        'validationResult': {
          'isValid': result.isValid,
          'merchantId': result.merchantId,
          'countryCode': result.countryCode,
          'currency': result.currency,
          'issues': result.issues,
          'warnings': result.warnings,
        },
        'deviceInfo': {
          'platform': Platform.operatingSystem,
          'version': Platform.operatingSystemVersion,
          'isIOS': Platform.isIOS,
        },
        'timestamp': DateTime.now().toIso8601String(),
        'recommendations': _getRecommendations(result),
      };

      if (result.issues.isNotEmpty) {
        await emailService.sendApplePayErrorReport(
          errorCode: 'VALIDATION_FAILED',
          errorMessage: 'Apple Pay configuration validation failed',
          errorDetails: errorDetails,
          userEmail: userEmail,
          userId: userId,
        );
      } else if (result.warnings.isNotEmpty) {
        await emailService.sendApplePayErrorReport(
          errorCode: 'VALIDATION_WARNINGS',
          errorMessage: 'Apple Pay configuration has warnings',
          errorDetails: errorDetails,
          userEmail: userEmail,
          userId: userId,
        );
      }
    } catch (e) {
      Loggers.error('Failed to send validation report: $e');
    }
  }

  /// Get recommendations based on validation results
  static List<String> _getRecommendations(ApplePayValidationResult result) {
    final recommendations = <String>[];

    if (result.issues.any((issue) => issue.contains('Merchant ID'))) {
      recommendations.addAll([
        'Check Apple Developer Console → Certificates, Identifiers & Profiles → Merchant IDs',
        'Ensure Merchant ID is properly configured and verified',
        'Update kExpectedMerchantId constant to match Apple Developer Console',
      ]);
    }

    if (result.issues.any((issue) => issue.contains('iOS'))) {
      recommendations.add('Test Apple Pay functionality on a physical iOS device');
    }

    if (result.warnings.any((warning) => warning.contains('currency'))) {
      recommendations.addAll([
        'Verify currency is supported in target markets',
        'Check Apple Pay supported currencies documentation',
      ]);
    }

    if (result.warnings.any((warning) => warning.contains('domain'))) {
      recommendations.addAll([
        'Use reverse domain notation for Merchant ID (e.g., merchant.com.yourcompany.appname)',
        'Ensure domain matches your app bundle identifier',
      ]);
    }

    // General recommendations
    recommendations.addAll([
      'Test Apple Pay with different card types (Visa, Mastercard, etc.)',
      'Verify iOS app entitlements include correct Merchant ID',
      'Check PayTabs integration configuration',
      'Test in both sandbox and production environments',
    ]);

    return recommendations;
  }

  /// Quick validation check (without email reporting)
  static bool isConfigurationValid() {
    return Platform.isIOS &&
        kExpectedMerchantId.startsWith('merchant.') &&
        kMerchantCountryCode.length == 2 &&
        kDefaultCurrency.isNotEmpty;
  }

  /// Get configuration summary
  static Map<String, dynamic> getConfigurationSummary() {
    return {
      'merchantId': kExpectedMerchantId,
      'countryCode': kMerchantCountryCode,
      'currency': kDefaultCurrency,
      'platform': Platform.operatingSystem,
      'isIOS': Platform.isIOS,
      'isValid': isConfigurationValid(),
    };
  }
}

class ApplePayValidationResult {
  bool isValid = true;
  List<String> issues = [];
  List<String> warnings = [];
  String merchantId = '';
  String countryCode = '';
  String currency = '';

  Map<String, dynamic> toJson() => {
    'isValid': isValid,
    'issues': issues,
    'warnings': warnings,
    'merchantId': merchantId,
    'countryCode': countryCode,
    'currency': currency,
  };

  @override
  String toString() => 'ApplePayValidationResult(isValid: $isValid, issues: ${issues.length}, warnings: ${warnings.length})';
}
