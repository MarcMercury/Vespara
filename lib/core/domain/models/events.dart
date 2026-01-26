import 'package:equatable/equatable.dart';

/// Calendar event for The Planner
class CalendarEvent extends Equatable {
  const CalendarEvent({
    required this.id,
    required this.userId,
    this.matchId,
    this.matchName,
    required this.title,
    this.description,
    this.location,
    this.locationLat,
    this.locationLng,
    required this.startTime,
    required this.endTime,
    this.isAllDay = false,
    this.externalCalendarId,
    this.externalCalendarSource,
    this.aiConflictDetected = false,
    this.aiConflictReason,
    this.aiSuggestions,
    this.status = EventStatus.tentative,
    this.reminderMinutes = const [60, 1440],
    required this.createdAt,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) => CalendarEvent(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        matchId: json['match_id'] as String?,
        matchName: json['match_name'] as String?,
        title: json['title'] as String,
        description: json['description'] as String?,
        location: json['location'] as String?,
        locationLat: (json['location_lat'] as num?)?.toDouble(),
        locationLng: (json['location_lng'] as num?)?.toDouble(),
        startTime: DateTime.parse(json['start_time'] as String),
        endTime: DateTime.parse(json['end_time'] as String),
        isAllDay: json['is_all_day'] as bool? ?? false,
        externalCalendarId: json['external_calendar_id'] as String?,
        externalCalendarSource: json['external_calendar_source'] as String?,
        aiConflictDetected: json['ai_conflict_detected'] as bool? ?? false,
        aiConflictReason: json['ai_conflict_reason'] as String?,
        aiSuggestions: (json['ai_suggestions'] as List?)?.cast<String>(),
        status: EventStatus.fromString(json['status'] as String?),
        reminderMinutes:
            (json['reminder_minutes'] as List?)?.cast<int>() ?? [60, 1440],
        createdAt: DateTime.parse(json['created_at'] as String),
      );
  final String id;
  final String userId;
  final String? matchId;
  final String? matchName;
  final String title;
  final String? description;
  final String? location;
  final double? locationLat;
  final double? locationLng;
  final DateTime startTime;
  final DateTime endTime;
  final bool isAllDay;
  final String? externalCalendarId;
  final String? externalCalendarSource;
  final bool aiConflictDetected;
  final String? aiConflictReason;
  final List<String>? aiSuggestions;
  final EventStatus status;
  final List<int> reminderMinutes;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'match_id': matchId,
        'title': title,
        'description': description,
        'location': location,
        'location_lat': locationLat,
        'location_lng': locationLng,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'is_all_day': isAllDay,
        'external_calendar_id': externalCalendarId,
        'external_calendar_source': externalCalendarSource,
        'status': status.value,
        'reminder_minutes': reminderMinutes,
      };

  /// Formatted date for display
  String get formattedDate {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
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

    return '${formatHour(startTime)} - ${formatHour(endTime)}';
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

  @override
  List<Object?> get props => [id, title, startTime, matchId];
}

enum EventStatus {
  tentative,
  confirmed,
  cancelled;

  static EventStatus fromString(String? value) {
    switch (value) {
      case 'confirmed':
        return EventStatus.confirmed;
      case 'cancelled':
        return EventStatus.cancelled;
      default:
        return EventStatus.tentative;
    }
  }

  String get value {
    switch (this) {
      case EventStatus.tentative:
        return 'tentative';
      case EventStatus.confirmed:
        return 'confirmed';
      case EventStatus.cancelled:
        return 'cancelled';
    }
  }

  String get label {
    switch (this) {
      case EventStatus.tentative:
        return 'Tentative';
      case EventStatus.confirmed:
        return 'Confirmed';
      case EventStatus.cancelled:
        return 'Cancelled';
    }
  }
}

/// Group event for Group Stuff module
class GroupEvent extends Equatable {
  const GroupEvent({
    required this.id,
    required this.hostId,
    this.hostName,
    this.hostAvatar,
    required this.title,
    this.description,
    this.coverImageUrl,
    this.eventType = 'social',
    this.venueName,
    this.venueAddress,
    this.venueLat,
    this.venueLng,
    this.isVirtual = false,
    this.virtualLink,
    required this.startTime,
    this.endTime,
    this.maxAttendees,
    this.currentAttendees = 0,
    this.isPrivate = true,
    this.inviteCode,
    this.requiresApproval = false,
    this.ageRestriction = 18,
    this.contentRating = 'social',
    this.invites = const [],
    required this.createdAt,
  });

  factory GroupEvent.fromJson(Map<String, dynamic> json) => GroupEvent(
        id: json['id'] as String,
        hostId: json['host_id'] as String,
        hostName: json['host_name'] as String?,
        hostAvatar: json['host_avatar'] as String?,
        title: json['title'] as String,
        description: json['description'] as String?,
        coverImageUrl: json['cover_image_url'] as String?,
        eventType: json['event_type'] as String? ?? 'social',
        venueName: json['venue_name'] as String?,
        venueAddress: json['venue_address'] as String?,
        venueLat: (json['venue_lat'] as num?)?.toDouble(),
        venueLng: (json['venue_lng'] as num?)?.toDouble(),
        isVirtual: json['is_virtual'] as bool? ?? false,
        virtualLink: json['virtual_link'] as String?,
        startTime: DateTime.parse(json['start_time'] as String),
        endTime:
            json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
        maxAttendees: json['max_attendees'] as int?,
        currentAttendees: json['current_attendees'] as int? ?? 0,
        isPrivate: json['is_private'] as bool? ?? true,
        inviteCode: json['invite_code'] as String?,
        requiresApproval: json['requires_approval'] as bool? ?? false,
        ageRestriction: json['age_restriction'] as int? ?? 18,
        contentRating: json['content_rating'] as String? ?? 'social',
        invites: (json['invites'] as List?)
                ?.map((i) => EventInvite.fromJson(i))
                .toList() ??
            [],
        createdAt: DateTime.parse(json['created_at'] as String),
      );
  final String id;
  final String hostId;
  final String? hostName;
  final String? hostAvatar;
  final String title;
  final String? description;
  final String? coverImageUrl;
  final String eventType;
  final String? venueName;
  final String? venueAddress;
  final double? venueLat;
  final double? venueLng;
  final bool isVirtual;
  final String? virtualLink;
  final DateTime startTime;
  final DateTime? endTime;
  final int? maxAttendees;
  final int currentAttendees;
  final bool isPrivate;
  final String? inviteCode;
  final bool requiresApproval;
  final int ageRestriction;
  final String contentRating;
  final List<EventInvite> invites;
  final DateTime createdAt;

  /// Spots remaining
  int? get spotsRemaining {
    if (maxAttendees == null) return null;
    return maxAttendees! - currentAttendees;
  }

  /// Is full
  bool get isFull {
    if (maxAttendees == null) return false;
    return currentAttendees >= maxAttendees!;
  }

  /// Is public (inverse of isPrivate)
  bool get isPublic => !isPrivate;

  @override
  List<Object?> get props => [id, title, startTime, hostId];
}

/// Event invite
class EventInvite extends Equatable {
  const EventInvite({
    required this.id,
    required this.eventId,
    required this.userId,
    this.userName,
    this.userAvatar,
    required this.invitedById,
    this.status = InviteStatus.pending,
    this.responseMessage,
    this.addedToCalendar = false,
    required this.createdAt,
    this.respondedAt,
  });

  factory EventInvite.fromJson(Map<String, dynamic> json) => EventInvite(
        id: json['id'] as String,
        eventId: json['event_id'] as String,
        userId: json['user_id'] as String,
        userName: json['user_name'] as String?,
        userAvatar: json['user_avatar'] as String?,
        invitedById: json['invited_by'] as String,
        status: InviteStatus.fromString(json['status'] as String?),
        responseMessage: json['response_message'] as String?,
        addedToCalendar: json['added_to_calendar'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
        respondedAt: json['responded_at'] != null
            ? DateTime.parse(json['responded_at'])
            : null,
      );
  final String id;
  final String eventId;
  final String userId;
  final String? userName;
  final String? userAvatar;
  final String invitedById;
  final InviteStatus status;
  final String? responseMessage;
  final bool addedToCalendar;
  final DateTime createdAt;
  final DateTime? respondedAt;

  @override
  List<Object?> get props => [id, eventId, userId, status];
}

enum InviteStatus {
  pending,
  accepted,
  declined,
  maybe;

  static InviteStatus fromString(String? value) {
    switch (value) {
      case 'accepted':
        return InviteStatus.accepted;
      case 'declined':
        return InviteStatus.declined;
      case 'maybe':
        return InviteStatus.maybe;
      default:
        return InviteStatus.pending;
    }
  }

  String get value {
    switch (this) {
      case InviteStatus.pending:
        return 'pending';
      case InviteStatus.accepted:
        return 'accepted';
      case InviteStatus.declined:
        return 'declined';
      case InviteStatus.maybe:
        return 'maybe';
    }
  }

  String get emoji {
    switch (this) {
      case InviteStatus.pending:
        return '⏳';
      case InviteStatus.accepted:
        return '✅';
      case InviteStatus.declined:
        return '❌';
      case InviteStatus.maybe:
        return '🤔';
    }
  }
}
