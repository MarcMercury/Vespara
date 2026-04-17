import 'package:equatable/equatable.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// CALENDAR EVENT MODEL
/// Maps to the `calendar_events` Supabase table (migration 009)
/// ════════════════════════════════════════════════════════════════════════════

class CalendarEvent extends Equatable {
  const CalendarEvent({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.location,
    this.locationLat,
    this.locationLng,
    required this.startTime,
    required this.endTime,
    this.isAllDay = false,
    this.status = 'confirmed',
    this.matchId,
    this.matchName,
    required this.createdAt,
    this.updatedAt,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) => CalendarEvent(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        location: json['location'] as String?,
        locationLat: (json['location_lat'] as num?)?.toDouble(),
        locationLng: (json['location_lng'] as num?)?.toDouble(),
        startTime: DateTime.parse(json['start_time'] as String),
        endTime: DateTime.parse(json['end_time'] as String),
        isAllDay: json['is_all_day'] as bool? ?? false,
        status: json['status'] as String? ?? 'confirmed',
        matchId: json['match_id'] as String?,
        matchName: json['match_name'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : null,
      );

  final String id;
  final String userId;
  final String title;
  final String? description;
  final String? location;
  final double? locationLat;
  final double? locationLng;
  final DateTime startTime;
  final DateTime endTime;
  final bool isAllDay;
  final String status;
  final String? matchId;
  final String? matchName;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toInsertJson() => {
        'user_id': userId,
        'title': title,
        'description': description,
        'location': location,
        'location_lat': locationLat,
        'location_lng': locationLng,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'is_all_day': isAllDay,
        'status': status,
        'match_id': matchId,
        'match_name': matchName,
      };

  @override
  List<Object?> get props => [id, userId, title, startTime, endTime, status];
}
