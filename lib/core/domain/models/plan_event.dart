import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// PLAN EVENT MODEL
/// Enhanced event model for THE PLAN section with:
/// - Certainty levels (color-coded)
/// - Connection references (who the event is with)
/// - AI suggestion metadata
/// ════════════════════════════════════════════════════════════════════════════

/// Certainty level for an event (how likely it is to happen)
enum EventCertainty {
  locked,      // 100% happening - green
  likely,      // Very likely (75%+) - blue
  tentative,   // Maybe (50%) - yellow
  exploring,   // Still figuring it out (25%) - orange
  wishful,     // Just an idea - pink/red
}

extension EventCertaintyExtension on EventCertainty {
  String get label {
    switch (this) {
      case EventCertainty.locked:
        return 'Locked In';
      case EventCertainty.likely:
        return 'Very Likely';
      case EventCertainty.tentative:
        return 'Tentative';
      case EventCertainty.exploring:
        return 'Exploring';
      case EventCertainty.wishful:
        return 'Wishful';
    }
  }
  
  String get description {
    switch (this) {
      case EventCertainty.locked:
        return 'This is definitely happening';
      case EventCertainty.likely:
        return 'Almost confirmed, just details to finalize';
      case EventCertainty.tentative:
        return 'On the calendar but could change';
      case EventCertainty.exploring:
        return 'Still working out timing/logistics';
      case EventCertainty.wishful:
        return 'An idea I\'d love to make happen';
    }
  }
  
  Color get color {
    switch (this) {
      case EventCertainty.locked:
        return const Color(0xFF00D9A5); // Green - success
      case EventCertainty.likely:
        return const Color(0xFF6366F1); // Indigo - primary
      case EventCertainty.tentative:
        return const Color(0xFFFBBF24); // Yellow - caution
      case EventCertainty.exploring:
        return const Color(0xFFF97316); // Orange - exploring
      case EventCertainty.wishful:
        return const Color(0xFFEC4899); // Pink - dream
    }
  }
  
  double get percentage {
    switch (this) {
      case EventCertainty.locked:
        return 1.0;
      case EventCertainty.likely:
        return 0.75;
      case EventCertainty.tentative:
        return 0.5;
      case EventCertainty.exploring:
        return 0.25;
      case EventCertainty.wishful:
        return 0.1;
    }
  }
  
  static EventCertainty fromString(String? value) {
    switch (value) {
      case 'locked':
        return EventCertainty.locked;
      case 'likely':
        return EventCertainty.likely;
      case 'tentative':
        return EventCertainty.tentative;
      case 'exploring':
        return EventCertainty.exploring;
      case 'wishful':
        return EventCertainty.wishful;
      default:
        return EventCertainty.tentative;
    }
  }
}

/// Connection reference for an event
class EventConnection {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? pipeline; // incoming, bench, active, legacy
  
  const EventConnection({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.pipeline,
  });
  
  factory EventConnection.fromJson(Map<String, dynamic> json) {
    return EventConnection(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      pipeline: json['pipeline'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'avatar_url': avatarUrl,
    'pipeline': pipeline,
  };
}

/// Plan Event - Enhanced calendar event for THE PLAN
class PlanEvent extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final String? notes;
  final DateTime startTime;
  final DateTime? endTime;
  final bool isAllDay;
  final String? location;
  
  // Connection tracking
  final List<EventConnection> connections; // Who the event is with
  
  // Certainty system
  final EventCertainty certainty;
  
  // External calendar sync
  final String? externalCalendarId;
  final String? externalCalendarSource; // google, apple, outlook
  final bool isSynced;
  
  // AI features
  final bool isAiSuggested;
  final String? aiSuggestionReason;
  final double? aiMatchScore; // How good this suggestion is
  final bool isConflicted;
  final String? conflictReason;
  
  // Status
  final bool isCancelled;
  final bool isCompleted;
  
  // Experience event fields (auto-synced from Experience page)
  final bool isFromExperience;
  final String? experienceHostName;
  final bool isHosting;
  
  // Metadata
  final DateTime createdAt;
  final DateTime? updatedAt;

  const PlanEvent({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.notes,
    required this.startTime,
    this.endTime,
    this.isAllDay = false,
    this.location,
    this.connections = const [],
    this.certainty = EventCertainty.tentative,
    this.externalCalendarId,
    this.externalCalendarSource,
    this.isSynced = false,
    this.isAiSuggested = false,
    this.aiSuggestionReason,
    this.aiMatchScore,
    this.isConflicted = false,
    this.conflictReason,
    this.isCancelled = false,
    this.isCompleted = false,
    this.isFromExperience = false,
    this.experienceHostName,
    this.isHosting = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory PlanEvent.fromJson(Map<String, dynamic> json) {
    return PlanEvent(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      notes: json['notes'] as String?,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : null,
      isAllDay: json['is_all_day'] as bool? ?? false,
      location: json['location'] as String?,
      connections: (json['connections'] as List?)
              ?.map((c) => EventConnection.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      certainty: EventCertaintyExtension.fromString(json['certainty'] as String?),
      externalCalendarId: json['external_calendar_id'] as String?,
      externalCalendarSource: json['external_calendar_source'] as String?,
      isSynced: json['is_synced'] as bool? ?? false,
      isAiSuggested: json['is_ai_suggested'] as bool? ?? false,
      aiSuggestionReason: json['ai_suggestion_reason'] as String?,
      aiMatchScore: (json['ai_match_score'] as num?)?.toDouble(),
      isConflicted: json['is_conflicted'] as bool? ?? false,
      conflictReason: json['conflict_reason'] as String?,
      isCancelled: json['is_cancelled'] as bool? ?? false,
      isCompleted: json['is_completed'] as bool? ?? false,
      isFromExperience: json['is_from_experience'] as bool? ?? false,
      experienceHostName: json['experience_host_name'] as String?,
      isHosting: json['is_hosting'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'title': title,
    'description': description,
    'notes': notes,
    'start_time': startTime.toIso8601String(),
    'end_time': endTime?.toIso8601String(),
    'is_all_day': isAllDay,
    'location': location,
    'connections': connections.map((c) => c.toJson()).toList(),
    'certainty': certainty.name,
    'external_calendar_id': externalCalendarId,
    'external_calendar_source': externalCalendarSource,
    'is_synced': isSynced,
    'is_ai_suggested': isAiSuggested,
    'ai_suggestion_reason': aiSuggestionReason,
    'ai_match_score': aiMatchScore,
    'is_conflicted': isConflicted,
    'conflict_reason': conflictReason,
    'is_cancelled': isCancelled,
    'is_completed': isCompleted,
    'is_from_experience': isFromExperience,
    'experience_host_name': experienceHostName,
    'is_hosting': isHosting,
  };

  /// Formatted date for display
  String get formattedDate {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[startTime.month - 1]} ${startTime.day}';
  }

  /// Formatted time range
  String get formattedTimeRange {
    if (isAllDay) return 'All Day';
    
    String formatHour(DateTime dt) {
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '$hour:${dt.minute.toString().padLeft(2, '0')} $period';
    }
    
    if (endTime == null) return formatHour(startTime);
    return '${formatHour(startTime)} - ${formatHour(endTime!)}';
  }
  
  /// Connection names for display
  String get connectionNames {
    if (connections.isEmpty) return 'Solo';
    if (connections.length == 1) return 'with ${connections.first.name}';
    if (connections.length == 2) {
      return 'with ${connections[0].name} & ${connections[1].name}';
    }
    return 'with ${connections.first.name} & ${connections.length - 1} others';
  }

  /// Is event today
  bool get isToday {
    final now = DateTime.now();
    return startTime.year == now.year &&
        startTime.month == now.month &&
        startTime.day == now.day;
  }

  /// Is event upcoming (within 7 days)
  bool get isUpcoming {
    final diff = startTime.difference(DateTime.now());
    return diff.inDays >= 0 && diff.inDays <= 7;
  }
  
  /// Is event in the past
  bool get isPast => startTime.isBefore(DateTime.now());
  
  /// Copy with helper
  PlanEvent copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? notes,
    DateTime? startTime,
    DateTime? endTime,
    bool? isAllDay,
    String? location,
    List<EventConnection>? connections,
    EventCertainty? certainty,
    String? externalCalendarId,
    String? externalCalendarSource,
    bool? isSynced,
    bool? isAiSuggested,
    String? aiSuggestionReason,
    double? aiMatchScore,
    bool? isConflicted,
    String? conflictReason,
    bool? isCancelled,
    bool? isCompleted,
    bool? isFromExperience,
    String? experienceHostName,
    bool? isHosting,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PlanEvent(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isAllDay: isAllDay ?? this.isAllDay,
      location: location ?? this.location,
      connections: connections ?? this.connections,
      certainty: certainty ?? this.certainty,
      externalCalendarId: externalCalendarId ?? this.externalCalendarId,
      externalCalendarSource: externalCalendarSource ?? this.externalCalendarSource,
      isSynced: isSynced ?? this.isSynced,
      isAiSuggested: isAiSuggested ?? this.isAiSuggested,
      aiSuggestionReason: aiSuggestionReason ?? this.aiSuggestionReason,
      aiMatchScore: aiMatchScore ?? this.aiMatchScore,
      isConflicted: isConflicted ?? this.isConflicted,
      conflictReason: conflictReason ?? this.conflictReason,
      isCancelled: isCancelled ?? this.isCancelled,
      isCompleted: isCompleted ?? this.isCompleted,
      isFromExperience: isFromExperience ?? this.isFromExperience,
      experienceHostName: experienceHostName ?? this.experienceHostName,
      isHosting: isHosting ?? this.isHosting,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, title, startTime, certainty, connections];
}

/// AI Date Suggestion - when AI recommends a potential date
class AiDateSuggestion extends Equatable {
  final String id;
  final EventConnection connection;
  final List<DateTime> suggestedTimes;
  final String reason;
  final double compatibilityScore;
  final String? sharedInterest;
  final bool isHotMatch; // Both users are very available
  
  const AiDateSuggestion({
    required this.id,
    required this.connection,
    required this.suggestedTimes,
    required this.reason,
    required this.compatibilityScore,
    this.sharedInterest,
    this.isHotMatch = false,
  });
  
  @override
  List<Object?> get props => [id, connection.id, suggestedTimes];
}

/// Time slot for availability display
class TimeSlot extends Equatable {
  final DateTime start;
  final DateTime end;
  final bool isAvailable;
  final bool isBusy;
  final String? busyReason;
  final String? externalSource; // google, apple
  
  const TimeSlot({
    required this.start,
    required this.end,
    this.isAvailable = true,
    this.isBusy = false,
    this.busyReason,
    this.externalSource,
  });
  
  @override
  List<Object?> get props => [start, end, isAvailable];
}
