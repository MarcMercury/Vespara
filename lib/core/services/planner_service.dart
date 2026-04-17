import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/models/calendar_event.dart';
import '../domain/models/travel_plan.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// PLANNER SERVICE
/// Unified access to calendar_events + travel_plans for the Planner feature
/// ════════════════════════════════════════════════════════════════════════════

class PlannerService {
  PlannerService._();
  static PlannerService? _instance;
  static PlannerService get instance => _instance ??= PlannerService._();

  SupabaseClient get _client => Supabase.instance.client;
  String? get _userId => _client.auth.currentUser?.id;

  // ═══════════════════════════════════════════════════════════════════════════
  // CALENDAR EVENTS CRUD
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get all calendar events for the current user
  Future<List<CalendarEvent>> getMyEvents() async {
    try {
      final data = await _client
          .from('calendar_events')
          .select()
          .eq('user_id', _userId!)
          .neq('status', 'cancelled')
          .order('start_time');
      return (data as List)
          .map((json) => CalendarEvent.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      print('[PlannerService] getMyEvents error: $e\n$st');
      return [];
    }
  }

  /// Create a new calendar event
  Future<CalendarEvent?> createEvent(CalendarEvent event) async {
    try {
      final json = event.toInsertJson();
      print('[PlannerService] createEvent inserting: $json');
      final data = await _client
          .from('calendar_events')
          .insert(json)
          .select()
          .single();
      print('[PlannerService] createEvent success: ${data['id']}');
      return CalendarEvent.fromJson(data);
    } catch (e, st) {
      print('[PlannerService] createEvent error: $e\n$st');
      return null;
    }
  }

  /// Delete a calendar event
  Future<bool> deleteEvent(String eventId) async {
    try {
      await _client
          .from('calendar_events')
          .delete()
          .eq('id', eventId)
          .eq('user_id', _userId!);
      return true;
    } catch (e, st) {
      print('[PlannerService] deleteEvent error: $e\n$st');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TRAVEL PLANS (read-only for unified view)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get current user's travel plans
  Future<List<TravelPlan>> getMyTrips() async {
    try {
      final data = await _client
          .from('travel_plans')
          .select()
          .eq('user_id', _userId!)
          .eq('is_cancelled', false)
          .order('start_date');
      return (data as List)
          .map((json) => TravelPlan.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      print('[PlannerService] getMyTrips error: $e\n$st');
      return [];
    }
  }

  /// Get connection travel plans (visible to current user)
  Future<List<TravelPlan>> getConnectionTrips() async {
    try {
      final data = await _client
          .from('travel_plans')
          .select()
          .neq('user_id', _userId!)
          .eq('is_cancelled', false)
          .inFilter('visibility', ['connections', 'friends', 'public'])
          .order('start_date');
      return (data as List)
          .map((json) => TravelPlan.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      print('[PlannerService] getConnectionTrips error: $e\n$st');
      return [];
    }
  }
}
