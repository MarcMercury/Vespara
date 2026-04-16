import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/env.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// EMAIL VALIDATION SERVICE - Abstract API Integration
/// ════════════════════════════════════════════════════════════════════════════
///
/// Validates emails during signup to:
/// - Catch typos (gmial.com → gmail.com)
/// - Block disposable/temporary email addresses
/// - Verify deliverability before sending Resend emails
/// - Reduce fake accounts

class EmailValidationService {
  EmailValidationService._();

  /// Validate an email address using Abstract API
  /// Returns null if the API is not configured (graceful degradation)
  static Future<EmailValidationResult?> validate(String email) async {
    final apiKey = Env.abstractApiKey;
    if (apiKey.isEmpty) return null;

    try {
      final uri = Uri.https(
        'emailvalidation.abstractapi.com',
        '/v1/',
        {'api_key': apiKey, 'email': email},
      );

      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);

      return EmailValidationResult(
        email: data['email'] as String? ?? email,
        isValid: data['is_valid_format']?['value'] == true,
        isDeliverable: data['deliverability'] == 'DELIVERABLE',
        isDisposable: data['is_disposable_email']?['value'] == true,
        isFreeProvider: data['is_free_email']?['value'] == true,
        autocorrect: data['autocorrect'] as String? ?? '',
        qualityScore: (data['quality_score'] as num?)?.toDouble() ?? 0.0,
      );
    } catch (e) {
      debugPrint('Email validation error: $e');
      return null;
    }
  }

  /// Quick check: is this email safe to use for signup?
  /// Returns an error message if problematic, null if OK
  static Future<String?> checkForSignup(String email) async {
    final result = await validate(email);
    if (result == null) return null; // API unavailable, let it through

    if (!result.isValid) {
      return 'Please enter a valid email address.';
    }

    if (result.isDisposable) {
      return 'Disposable email addresses are not allowed.';
    }

    if (!result.isDeliverable) {
      return 'This email address doesn\'t appear to be deliverable.';
    }

    // Offer autocorrect suggestion
    if (result.autocorrect.isNotEmpty && result.autocorrect != email) {
      return 'Did you mean ${result.autocorrect}?';
    }

    return null;
  }
}

class EmailValidationResult {
  const EmailValidationResult({
    required this.email,
    required this.isValid,
    required this.isDeliverable,
    required this.isDisposable,
    required this.isFreeProvider,
    required this.autocorrect,
    required this.qualityScore,
  });

  final String email;
  final bool isValid;
  final bool isDeliverable;
  final bool isDisposable;
  final bool isFreeProvider;
  final String autocorrect;
  final double qualityScore;

  bool get isHighQuality => qualityScore >= 0.7 && isDeliverable && !isDisposable;
}
