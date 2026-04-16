import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../config/env.dart';

/// Location Service for Tonight Mode
/// Uses device GPS when available, falls back to IPInfo geolocation
class LocationService {
  /// Check whether we have location permission (without requesting)
  static Future<bool> hasPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Request location permission (call from UI layer only)
  static Future<bool> requestPermission() async {
    final permission = await Geolocator.requestPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Get current position — tries GPS first, falls back to IP geolocation
  static Future<Position?> getCurrentPosition() async {
    // Try GPS first
    final gpsPosition = await _getGpsPosition();
    if (gpsPosition != null) return gpsPosition;

    // Fall back to IPInfo for approximate location
    return _getIpPosition();
  }

  /// GPS-based position (requires permission)
  static Future<Position?> _getGpsPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 15));
    } catch (e) {
      debugPrint('GPS position error: $e');
      return null;
    }
  }

  /// IP-based approximate position via IPInfo API
  static Future<Position?> _getIpPosition() async {
    final apiKey = Env.ipinfoApiKey;
    if (apiKey.isEmpty) return null;

    try {
      final response = await http
          .get(Uri.parse('https://ipinfo.io/json?token=$apiKey'))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      final loc = data['loc'] as String?; // "lat,lng" format
      if (loc == null || !loc.contains(',')) return null;

      final parts = loc.split(',');
      final lat = double.tryParse(parts[0]);
      final lng = double.tryParse(parts[1]);
      if (lat == null || lng == null) return null;

      debugPrint('LocationService: Using IP-based location (${data['city']}, ${data['region']})');

      return Position(
        latitude: lat,
        longitude: lng,
        timestamp: DateTime.now(),
        accuracy: 5000, // ~5km accuracy for IP geolocation
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
    } catch (e) {
      debugPrint('IPInfo error: $e');
      return null;
    }
  }

  /// Get city name from IP (useful for onboarding auto-fill)
  static Future<IpLocationInfo?> getCityFromIp() async {
    final apiKey = Env.ipinfoApiKey;
    if (apiKey.isEmpty) return null;

    try {
      final response = await http
          .get(Uri.parse('https://ipinfo.io/json?token=$apiKey'))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      return IpLocationInfo(
        city: data['city'] as String? ?? '',
        region: data['region'] as String? ?? '',
        country: data['country'] as String? ?? '',
        postal: data['postal'] as String? ?? '',
        timezone: data['timezone'] as String? ?? '',
      );
    } catch (e) {
      debugPrint('IPInfo city error: $e');
      return null;
    }
  }

  /// Calculate distance between two points in kilometers
  static double calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(
          startLat,
          startLng,
          endLat,
          endLng,
        ) /
        1000;
  }

  /// Stream position updates
  static Stream<Position> getPositionStream() => Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 100,
        ),
      );
}

/// Structured location info from IPInfo
class IpLocationInfo {
  const IpLocationInfo({
    required this.city,
    required this.region,
    required this.country,
    required this.postal,
    required this.timezone,
  });
  final String city;
  final String region;
  final String country;
  final String postal;
  final String timezone;

  String get displayName => [city, region].where((s) => s.isNotEmpty).join(', ');
}
