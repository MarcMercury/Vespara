import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/travel_plan.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// TRAVEL SERVICE
/// Manages travel plans, companions, overlap detection, and calendar export
/// ════════════════════════════════════════════════════════════════════════════

class TravelService {
  TravelService._();
  static TravelService? _instance;
  static TravelService get instance => _instance ??= TravelService._();

  SupabaseClient get _client => Supabase.instance.client;
  String? get _userId => _client.auth.currentUser?.id;

  // ═══════════════════════════════════════════════════════════════════════════
  // TRAVEL PLANS CRUD
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get all trips for the current user
  Future<List<TravelPlan>> getMyTrips({bool includePast = false}) async {
    try {
      var query = _client
          .from('travel_plans')
          .select('*, travel_companions(*)')
          .eq('user_id', _userId!)
          .eq('is_cancelled', false)
          .order('start_date');

      if (!includePast) {
        query = query.gte('end_date', DateTime.now().toIso8601String().split('T').first);
      }

      final data = await query;
      return (data as List)
          .map((json) => TravelPlan.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('TravelService.getMyTrips error: $e');
      return [];
    }
  }

  /// Get a single trip by ID
  Future<TravelPlan?> getTrip(String tripId) async {
    try {
      final data = await _client
          .from('travel_plans')
          .select('*, travel_companions(*)')
          .eq('id', tripId)
          .single();
      return TravelPlan.fromJson(data);
    } catch (e) {
      debugPrint('TravelService.getTrip error: $e');
      return null;
    }
  }

  /// Create a new trip
  Future<TravelPlan?> createTrip(TravelPlan plan) async {
    try {
      final data = await _client
          .from('travel_plans')
          .insert(plan.toJson())
          .select('*, travel_companions(*)')
          .single();
      return TravelPlan.fromJson(data);
    } catch (e) {
      debugPrint('TravelService.createTrip error: $e');
      return null;
    }
  }

  /// Update a trip
  Future<TravelPlan?> updateTrip(String tripId, Map<String, dynamic> updates) async {
    try {
      final data = await _client
          .from('travel_plans')
          .update(updates)
          .eq('id', tripId)
          .eq('user_id', _userId!)
          .select('*, travel_companions(*)')
          .single();
      return TravelPlan.fromJson(data);
    } catch (e) {
      debugPrint('TravelService.updateTrip error: $e');
      return null;
    }
  }

  /// Cancel a trip (soft delete)
  Future<bool> cancelTrip(String tripId) async {
    try {
      await _client
          .from('travel_plans')
          .update({'is_cancelled': true})
          .eq('id', tripId)
          .eq('user_id', _userId!);
      return true;
    } catch (e) {
      debugPrint('TravelService.cancelTrip error: $e');
      return false;
    }
  }

  /// Mark trip as completed
  Future<bool> completeTrip(String tripId) async {
    try {
      await _client
          .from('travel_plans')
          .update({'is_completed': true})
          .eq('id', tripId)
          .eq('user_id', _userId!);
      return true;
    } catch (e) {
      debugPrint('TravelService.completeTrip error: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COMPANIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Invite a companion to a trip
  Future<bool> inviteCompanion(String tripId, String userId) async {
    try {
      await _client.from('travel_companions').insert({
        'travel_plan_id': tripId,
        'user_id': userId,
        'invited_by': _userId,
        'status': 'invited',
      });
      return true;
    } catch (e) {
      debugPrint('TravelService.inviteCompanion error: $e');
      return false;
    }
  }

  /// Respond to a trip invite
  Future<bool> respondToInvite(String tripId, String status) async {
    try {
      await _client
          .from('travel_companions')
          .update({'status': status})
          .eq('travel_plan_id', tripId)
          .eq('user_id', _userId!);
      return true;
    } catch (e) {
      debugPrint('TravelService.respondToInvite error: $e');
      return false;
    }
  }

  /// Get trips I'm invited to
  Future<List<TravelPlan>> getInvitedTrips() async {
    try {
      final companions = await _client
          .from('travel_companions')
          .select('travel_plan_id')
          .eq('user_id', _userId!)
          .eq('status', 'invited');

      if ((companions as List).isEmpty) return [];

      final planIds =
          companions.map((c) => c['travel_plan_id'] as String).toList();

      final data = await _client
          .from('travel_plans')
          .select('*, travel_companions(*)')
          .inFilter('id', planIds)
          .eq('is_cancelled', false)
          .gte('end_date', DateTime.now().toIso8601String().split('T').first)
          .order('start_date');

      return (data as List)
          .map((json) => TravelPlan.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('TravelService.getInvitedTrips error: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // OVERLAP DETECTION & CONNECTION TRIPS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Find travel overlaps with connections
  Future<List<TravelOverlap>> findOverlaps() async {
    try {
      final data = await _client.rpc('find_travel_overlaps', params: {
        'p_user_id': _userId,
      });
      return (data as List)
          .map((json) => TravelOverlap.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('TravelService.findOverlaps error: $e');
      return [];
    }
  }

  /// Get upcoming trips from connections
  Future<List<TravelPlan>> getConnectionTrips({int limit = 20}) async {
    try {
      final data = await _client.rpc('get_connection_trips', params: {
        'p_user_id': _userId,
        'p_limit': limit,
      });
      return (data as List).map((json) {
        final map = json as Map<String, dynamic>;
        // Map RPC response fields to TravelPlan format
        return TravelPlan(
          id: map['plan_id'] as String,
          userId: map['user_id'] as String,
          title: map['title'] as String,
          destinationCity: map['destination_city'] as String,
          destinationCountry: map['destination_country'] as String?,
          destinationLat: (map['destination_lat'] as num?)?.toDouble(),
          destinationLng: (map['destination_lng'] as num?)?.toDouble(),
          startDate: DateTime.parse(map['start_date'] as String),
          endDate: DateTime.parse(map['end_date'] as String),
          certainty: TripCertainty.fromString(map['certainty'] as String?),
          travelType: TravelType.fromString(map['travel_type'] as String?),
          coverImageUrl: map['cover_image_url'] as String?,
          userName: map['user_name'] as String?,
          userAvatar: map['user_avatar'] as String?,
          createdAt: DateTime.now(),
        );
      }).toList();
    } catch (e) {
      debugPrint('TravelService.getConnectionTrips error: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CALENDAR EXPORT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Generate Google Calendar URL for a trip
  String getGoogleCalendarUrl(TravelPlan plan) {
    final start = _formatCalendarDate(plan.startDate);
    final end = _formatCalendarDate(plan.endDate.add(const Duration(days: 1)));
    final title = Uri.encodeComponent(plan.title);
    final location = Uri.encodeComponent(plan.destinationDisplay);
    final details = Uri.encodeComponent(
      plan.description ?? 'Trip to ${plan.destinationCity}',
    );

    return 'https://calendar.google.com/calendar/render'
        '?action=TEMPLATE'
        '&text=$title'
        '&dates=$start/$end'
        '&details=$details'
        '&location=$location';
  }

  /// Generate .ics file content for Apple/Outlook calendar export
  String generateIcsContent(TravelPlan plan) {
    final start = _formatIcsDate(plan.startDate);
    final end = _formatIcsDate(plan.endDate.add(const Duration(days: 1)));
    final now = _formatIcsDateTime(DateTime.now());

    return 'BEGIN:VCALENDAR\r\n'
        'VERSION:2.0\r\n'
        'PRODID:-//Vespara//Travel//EN\r\n'
        'BEGIN:VEVENT\r\n'
        'UID:${plan.id}@vespara.co\r\n'
        'DTSTAMP:$now\r\n'
        'DTSTART;VALUE=DATE:$start\r\n'
        'DTEND;VALUE=DATE:$end\r\n'
        'SUMMARY:${_escapeIcs(plan.title)}\r\n'
        'LOCATION:${_escapeIcs(plan.destinationDisplay)}\r\n'
        'DESCRIPTION:${_escapeIcs(plan.description ?? 'Trip to ${plan.destinationCity}')}\r\n'
        'END:VEVENT\r\n'
        'END:VCALENDAR\r\n';
  }

  String _formatCalendarDate(DateTime date) {
    return '${date.year}'
        '${date.month.toString().padLeft(2, '0')}'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String _formatIcsDate(DateTime date) {
    return '${date.year}'
        '${date.month.toString().padLeft(2, '0')}'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String _formatIcsDateTime(DateTime date) {
    return '${date.year}'
        '${date.month.toString().padLeft(2, '0')}'
        '${date.day.toString().padLeft(2, '0')}T'
        '${date.hour.toString().padLeft(2, '0')}'
        '${date.minute.toString().padLeft(2, '0')}'
        '${date.second.toString().padLeft(2, '0')}Z';
  }

  String _escapeIcs(String text) {
    return text
        .replaceAll('\\', '\\\\')
        .replaceAll(';', '\\;')
        .replaceAll(',', '\\,')
        .replaceAll('\n', '\\n');
  }
}
