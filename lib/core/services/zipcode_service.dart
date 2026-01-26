import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service for looking up city and state from ZIP code
class ZipCodeService {
  static const String _baseUrl = 'https://api.zippopotam.us/us';

  /// Looks up city and state for a given US ZIP code
  /// Returns null if ZIP code is invalid or not found
  static Future<ZipCodeResult?> lookup(String zipCode) async {
    // Validate ZIP code format (5 digits)
    final cleanZip = zipCode.trim();
    if (!RegExp(r'^\d{5}$').hasMatch(cleanZip)) {
      return null;
    }

    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/$cleanZip'),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final places = data['places'] as List?;

        if (places != null && places.isNotEmpty) {
          final place = places[0];
          return ZipCodeResult(
            city: place['place name'] ?? '',
            state: place['state abbreviation'] ?? '',
            stateFull: place['state'] ?? '',
            zipCode: cleanZip,
          );
        }
      }
      return null;
    } catch (e) {
      // Network error or timeout
      return null;
    }
  }
}

/// Result from ZIP code lookup
class ZipCodeResult {
  const ZipCodeResult({
    required this.city,
    required this.state,
    required this.stateFull,
    required this.zipCode,
  });
  final String city;
  final String state;
  final String stateFull;
  final String zipCode;
}
