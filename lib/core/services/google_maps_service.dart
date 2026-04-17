import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/env.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// GOOGLE MAPS PLATFORM SERVICE
/// Unified client for Google Maps APIs used across the app:
///   - Places (New) — venue search, autocomplete, place details
///   - Geocoding     — address ↔ coordinates
///   - Directions    — route between two points
///   - Distance Matrix — travel time/distance for multiple pairs
///   - Time Zone     — local timezone from coordinates
///   - Maps Static   — thumbnail map images for cards
/// ════════════════════════════════════════════════════════════════════════════

class GoogleMapsService {
  GoogleMapsService._();
  static GoogleMapsService? _instance;
  static GoogleMapsService get instance =>
      _instance ??= GoogleMapsService._();

  String get _apiKey => Env.googleMapsApiKey;
  bool get isConfigured => _apiKey.isNotEmpty;

  // ═══════════════════════════════════════════════════════════════════════════
  // PLACES (NEW) — Nearby Search & Autocomplete
  // ═══════════════════════════════════════════════════════════════════════════

  /// Search nearby places by type (restaurant, bar, cafe, etc.)
  Future<List<PlaceResult>> nearbySearch({
    required double lat,
    required double lng,
    required double radiusMeters,
    List<String> types = const ['restaurant', 'bar', 'cafe'],
    int maxResults = 10,
  }) async {
    if (!isConfigured) return [];

    try {
      final response = await http.post(
        Uri.parse('https://places.googleapis.com/v1/places:searchNearby'),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _apiKey,
          'X-Goog-FieldMask':
              'places.id,places.displayName,places.formattedAddress,'
              'places.location,places.rating,places.types,'
              'places.primaryType,places.priceLevel,places.photos',
        },
        body: jsonEncode({
          'includedTypes': types,
          'maxResultCount': maxResults,
          'locationRestriction': {
            'circle': {
              'center': {'latitude': lat, 'longitude': lng},
              'radius': radiusMeters,
            },
          },
        }),
      );

      if (response.statusCode != 200) {
        debugPrint('Places nearbySearch error: ${response.statusCode}');
        return [];
      }

      final data = jsonDecode(response.body);
      return (data['places'] as List? ?? [])
          .map((p) => PlaceResult.fromJson(p as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('GoogleMapsService.nearbySearch error: $e');
      return [];
    }
  }

  /// Autocomplete place search (for travel destination, event venue, etc.)
  Future<List<AutocompleteResult>> autocomplete({
    required String query,
    List<String> types = const ['(cities)'],
    String? sessionToken,
  }) async {
    if (!isConfigured || query.length < 2) return [];

    try {
      final response = await http.post(
        Uri.parse('https://places.googleapis.com/v1/places:autocomplete'),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _apiKey,
        },
        body: jsonEncode({
          'input': query,
          'includedPrimaryTypes': types,
          if (sessionToken != null) 'sessionToken': sessionToken,
        }),
      );

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body);
      return (data['suggestions'] as List? ?? [])
          .where((s) => s['placePrediction'] != null)
          .map((s) =>
              AutocompleteResult.fromJson(s['placePrediction'] as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('GoogleMapsService.autocomplete error: $e');
      return [];
    }
  }

  /// Get place details by place ID
  Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    if (!isConfigured) return null;

    try {
      final response = await http.get(
        Uri.parse('https://places.googleapis.com/v1/places/$placeId'),
        headers: {
          'X-Goog-Api-Key': _apiKey,
          'X-Goog-FieldMask':
              'id,displayName,formattedAddress,location,rating,'
              'regularOpeningHours,priceLevel,websiteUri,primaryType,photos',
        },
      );

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      return PlaceDetails.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('GoogleMapsService.getPlaceDetails error: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GEOCODING — Address ↔ Coordinates
  // ═══════════════════════════════════════════════════════════════════════════

  /// Convert address text to coordinates
  Future<GeocodingResult?> geocode(String address) async {
    if (!isConfigured || address.isEmpty) return null;

    try {
      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json'
          '?address=${Uri.encodeComponent(address)}'
          '&key=$_apiKey',
        ),
      );

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      final results = data['results'] as List?;
      if (results == null || results.isEmpty) return null;

      return GeocodingResult.fromJson(results.first as Map<String, dynamic>);
    } catch (e) {
      debugPrint('GoogleMapsService.geocode error: $e');
      return null;
    }
  }

  /// Convert coordinates to address (reverse geocode)
  Future<GeocodingResult?> reverseGeocode(double lat, double lng) async {
    if (!isConfigured) return null;

    try {
      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json'
          '?latlng=$lat,$lng'
          '&key=$_apiKey',
        ),
      );

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      final results = data['results'] as List?;
      if (results == null || results.isEmpty) return null;

      return GeocodingResult.fromJson(results.first as Map<String, dynamic>);
    } catch (e) {
      debugPrint('GoogleMapsService.reverseGeocode error: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DIRECTIONS — Route Between Two Points
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get directions and travel time between two points
  Future<DirectionsResult?> getDirections({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    String mode = 'driving', // driving, walking, transit, bicycling
  }) async {
    if (!isConfigured) return null;

    try {
      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/directions/json'
          '?origin=$originLat,$originLng'
          '&destination=$destLat,$destLng'
          '&mode=$mode'
          '&key=$_apiKey',
        ),
      );

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) return null;

      final leg = (routes.first['legs'] as List).first;
      return DirectionsResult(
        distanceText: leg['distance']['text'] as String,
        distanceMeters: leg['distance']['value'] as int,
        durationText: leg['duration']['text'] as String,
        durationSeconds: leg['duration']['value'] as int,
        startAddress: leg['start_address'] as String? ?? '',
        endAddress: leg['end_address'] as String? ?? '',
        polyline: routes.first['overview_polyline']?['points'] as String? ?? '',
      );
    } catch (e) {
      debugPrint('GoogleMapsService.getDirections error: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DISTANCE MATRIX — Travel Times for Multiple Destinations
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get travel time/distance from one origin to multiple destinations
  Future<List<DistanceEntry>> getDistanceMatrix({
    required double originLat,
    required double originLng,
    required List<({double lat, double lng})> destinations,
    String mode = 'driving',
  }) async {
    if (!isConfigured || destinations.isEmpty) return [];

    try {
      final destStr = destinations
          .map((d) => '${d.lat},${d.lng}')
          .join('|');

      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/distancematrix/json'
          '?origins=$originLat,$originLng'
          '&destinations=$destStr'
          '&mode=$mode'
          '&key=$_apiKey',
        ),
      );

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body);
      final rows = data['rows'] as List?;
      if (rows == null || rows.isEmpty) return [];

      final elements = (rows.first['elements'] as List);
      return elements.asMap().entries.map((entry) {
        final e = entry.value;
        if (e['status'] != 'OK') {
          return DistanceEntry(
            index: entry.key,
            distanceText: 'N/A',
            distanceMeters: 0,
            durationText: 'N/A',
            durationSeconds: 0,
          );
        }
        return DistanceEntry(
          index: entry.key,
          distanceText: e['distance']['text'] as String,
          distanceMeters: e['distance']['value'] as int,
          durationText: e['duration']['text'] as String,
          durationSeconds: e['duration']['value'] as int,
        );
      }).toList();
    } catch (e) {
      debugPrint('GoogleMapsService.getDistanceMatrix error: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TIME ZONE — Local Time From Coordinates
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get timezone info for a location (useful for Travel feature)
  Future<TimezoneResult?> getTimezone({
    required double lat,
    required double lng,
    DateTime? timestamp,
  }) async {
    if (!isConfigured) return null;

    try {
      final ts = (timestamp ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000;
      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/timezone/json'
          '?location=$lat,$lng'
          '&timestamp=$ts'
          '&key=$_apiKey',
        ),
      );

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      if (data['status'] != 'OK') return null;

      return TimezoneResult(
        timeZoneId: data['timeZoneId'] as String,
        timeZoneName: data['timeZoneName'] as String,
        rawOffset: data['rawOffset'] as int,
        dstOffset: data['dstOffset'] as int,
      );
    } catch (e) {
      debugPrint('GoogleMapsService.getTimezone error: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MAPS STATIC — Thumbnail Map Images
  // ═══════════════════════════════════════════════════════════════════════════

  /// Generate a static map image URL for event cards, travel plans, etc.
  String getStaticMapUrl({
    required double lat,
    required double lng,
    int zoom = 14,
    int width = 400,
    int height = 200,
    String mapType = 'roadmap',
    bool addMarker = true,
  }) {
    if (!isConfigured) return '';

    final marker = addMarker ? '&markers=color:red|$lat,$lng' : '';
    return 'https://maps.googleapis.com/maps/api/staticmap'
        '?center=$lat,$lng'
        '&zoom=$zoom'
        '&size=${width}x$height'
        '&maptype=$mapType'
        '&style=feature:all|element:labels|visibility:on'
        '$marker'
        '&key=$_apiKey';
  }

  /// Generate a static map URL showing a route between two points
  String getRouteStaticMapUrl({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    int width = 400,
    int height = 200,
  }) {
    if (!isConfigured) return '';

    return 'https://maps.googleapis.com/maps/api/staticmap'
        '?size=${width}x$height'
        '&markers=color:green|label:A|$originLat,$originLng'
        '&markers=color:red|label:B|$destLat,$destLng'
        '&path=color:0x4285F4ff|weight:4|$originLat,$originLng|$destLat,$destLng'
        '&key=$_apiKey';
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ═════════════════════════════════════════════════════════════════════════════

class PlaceResult {
  const PlaceResult({
    required this.id,
    required this.name,
    required this.address,
    this.lat,
    this.lng,
    this.rating,
    this.primaryType,
    this.priceLevel,
    this.photoReference,
  });

  final String id;
  final String name;
  final String address;
  final double? lat;
  final double? lng;
  final double? rating;
  final String? primaryType;
  final String? priceLevel;
  final String? photoReference;

  factory PlaceResult.fromJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>?;
    final photos = json['photos'] as List?;
    return PlaceResult(
      id: json['id'] as String? ?? '',
      name: (json['displayName'] as Map?)?['text'] as String? ?? '',
      address: json['formattedAddress'] as String? ?? '',
      lat: location?['latitude'] as double?,
      lng: location?['longitude'] as double?,
      rating: (json['rating'] as num?)?.toDouble(),
      primaryType: json['primaryType'] as String?,
      priceLevel: json['priceLevel'] as String?,
      photoReference: photos != null && photos.isNotEmpty
          ? photos.first['name'] as String?
          : null,
    );
  }
}

class AutocompleteResult {
  const AutocompleteResult({
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
  });

  final String placeId;
  final String mainText;
  final String secondaryText;

  factory AutocompleteResult.fromJson(Map<String, dynamic> json) {
    final structured = json['structuredFormat'] as Map<String, dynamic>?;
    return AutocompleteResult(
      placeId: json['placeId'] as String? ?? '',
      mainText: (structured?['mainText'] as Map?)?['text'] as String? ?? '',
      secondaryText:
          (structured?['secondaryText'] as Map?)?['text'] as String? ?? '',
    );
  }

  String get fullText =>
      secondaryText.isNotEmpty ? '$mainText, $secondaryText' : mainText;
}

class PlaceDetails {
  const PlaceDetails({
    required this.id,
    required this.name,
    required this.address,
    this.lat,
    this.lng,
    this.rating,
    this.priceLevel,
    this.websiteUri,
    this.primaryType,
    this.openNow,
  });

  final String id;
  final String name;
  final String address;
  final double? lat;
  final double? lng;
  final double? rating;
  final String? priceLevel;
  final String? websiteUri;
  final String? primaryType;
  final bool? openNow;

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>?;
    final hours = json['regularOpeningHours'] as Map<String, dynamic>?;
    return PlaceDetails(
      id: json['id'] as String? ?? '',
      name: (json['displayName'] as Map?)?['text'] as String? ?? '',
      address: json['formattedAddress'] as String? ?? '',
      lat: location?['latitude'] as double?,
      lng: location?['longitude'] as double?,
      rating: (json['rating'] as num?)?.toDouble(),
      priceLevel: json['priceLevel'] as String?,
      websiteUri: json['websiteUri'] as String?,
      primaryType: json['primaryType'] as String?,
      openNow: hours?['openNow'] as bool?,
    );
  }
}

class GeocodingResult {
  const GeocodingResult({
    required this.formattedAddress,
    required this.lat,
    required this.lng,
    this.city,
    this.state,
    this.country,
    this.postalCode,
  });

  final String formattedAddress;
  final double lat;
  final double lng;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;

  factory GeocodingResult.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry']?['location'] as Map<String, dynamic>?;
    final components = json['address_components'] as List? ?? [];

    String? getComponent(String type) {
      for (final c in components) {
        final types = (c['types'] as List?)?.cast<String>() ?? [];
        if (types.contains(type)) return c['long_name'] as String?;
      }
      return null;
    }

    return GeocodingResult(
      formattedAddress: json['formatted_address'] as String? ?? '',
      lat: (geometry?['lat'] as num?)?.toDouble() ?? 0,
      lng: (geometry?['lng'] as num?)?.toDouble() ?? 0,
      city: getComponent('locality') ?? getComponent('sublocality'),
      state: getComponent('administrative_area_level_1'),
      country: getComponent('country'),
      postalCode: getComponent('postal_code'),
    );
  }
}

class DirectionsResult {
  const DirectionsResult({
    required this.distanceText,
    required this.distanceMeters,
    required this.durationText,
    required this.durationSeconds,
    required this.startAddress,
    required this.endAddress,
    required this.polyline,
  });

  final String distanceText;
  final int distanceMeters;
  final String durationText;
  final int durationSeconds;
  final String startAddress;
  final String endAddress;
  final String polyline;
}

class DistanceEntry {
  const DistanceEntry({
    required this.index,
    required this.distanceText,
    required this.distanceMeters,
    required this.durationText,
    required this.durationSeconds,
  });

  final int index;
  final String distanceText;
  final int distanceMeters;
  final String durationText;
  final int durationSeconds;
}

class TimezoneResult {
  const TimezoneResult({
    required this.timeZoneId,
    required this.timeZoneName,
    required this.rawOffset,
    required this.dstOffset,
  });

  final String timeZoneId;
  final String timeZoneName;
  final int rawOffset; // seconds from UTC
  final int dstOffset; // DST offset in seconds

  /// Total UTC offset in hours
  double get utcOffsetHours => (rawOffset + dstOffset) / 3600;

  /// Formatted offset string like "UTC-5" or "UTC+9"
  String get formattedOffset {
    final hours = utcOffsetHours;
    final sign = hours >= 0 ? '+' : '';
    return 'UTC$sign${hours.toStringAsFixed(hours == hours.roundToDouble() ? 0 : 1)}';
  }
}
