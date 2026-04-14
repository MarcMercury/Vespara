import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// TRAVEL PLAN MODEL
/// Trip sharing with certainty levels, companions, and overlap detection
/// ════════════════════════════════════════════════════════════════════════════

enum TravelType {
  leisure,
  business,
  adventure,
  relocation,
  event,
  other;

  String get label {
    switch (this) {
      case TravelType.leisure:
        return 'Leisure';
      case TravelType.business:
        return 'Business';
      case TravelType.adventure:
        return 'Adventure';
      case TravelType.relocation:
        return 'Relocation';
      case TravelType.event:
        return 'Event';
      case TravelType.other:
        return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case TravelType.leisure:
        return '🏖️';
      case TravelType.business:
        return '💼';
      case TravelType.adventure:
        return '🏔️';
      case TravelType.relocation:
        return '🚚';
      case TravelType.event:
        return '🎉';
      case TravelType.other:
        return '✈️';
    }
  }

  static TravelType fromString(String? value) {
    switch (value) {
      case 'leisure':
        return TravelType.leisure;
      case 'business':
        return TravelType.business;
      case 'adventure':
        return TravelType.adventure;
      case 'relocation':
        return TravelType.relocation;
      case 'event':
        return TravelType.event;
      default:
        return TravelType.other;
    }
  }
}

enum TripVisibility {
  private,
  connections,
  friends,
  public;

  String get label {
    switch (this) {
      case TripVisibility.private:
        return 'Only Me';
      case TripVisibility.connections:
        return 'Connections';
      case TripVisibility.friends:
        return 'Friends';
      case TripVisibility.public:
        return 'Everyone';
    }
  }

  String get icon {
    switch (this) {
      case TripVisibility.private:
        return '🔒';
      case TripVisibility.connections:
        return '🤝';
      case TripVisibility.friends:
        return '👥';
      case TripVisibility.public:
        return '🌐';
    }
  }

  static TripVisibility fromString(String? value) {
    switch (value) {
      case 'private':
        return TripVisibility.private;
      case 'connections':
        return TripVisibility.connections;
      case 'friends':
        return TripVisibility.friends;
      case 'public':
        return TripVisibility.public;
      default:
        return TripVisibility.connections;
    }
  }
}

enum TripCertainty {
  locked,
  likely,
  tentative,
  exploring,
  wishful;

  String get label {
    switch (this) {
      case TripCertainty.locked:
        return 'Locked In';
      case TripCertainty.likely:
        return 'Very Likely';
      case TripCertainty.tentative:
        return 'Tentative';
      case TripCertainty.exploring:
        return 'Exploring';
      case TripCertainty.wishful:
        return 'Wishful';
    }
  }

  Color get color {
    switch (this) {
      case TripCertainty.locked:
        return const Color(0xFF00D9A5);
      case TripCertainty.likely:
        return const Color(0xFF6366F1);
      case TripCertainty.tentative:
        return const Color(0xFFFBBF24);
      case TripCertainty.exploring:
        return const Color(0xFFF97316);
      case TripCertainty.wishful:
        return const Color(0xFFEC4899);
    }
  }

  IconData get icon {
    switch (this) {
      case TripCertainty.locked:
        return Icons.lock_rounded;
      case TripCertainty.likely:
        return Icons.thumb_up_rounded;
      case TripCertainty.tentative:
        return Icons.help_outline_rounded;
      case TripCertainty.exploring:
        return Icons.explore_rounded;
      case TripCertainty.wishful:
        return Icons.auto_awesome_rounded;
    }
  }

  static TripCertainty fromString(String? value) {
    switch (value) {
      case 'locked':
        return TripCertainty.locked;
      case 'likely':
        return TripCertainty.likely;
      case 'tentative':
        return TripCertainty.tentative;
      case 'exploring':
        return TripCertainty.exploring;
      case 'wishful':
        return TripCertainty.wishful;
      default:
        return TripCertainty.tentative;
    }
  }
}

class TravelPlan extends Equatable {
  const TravelPlan({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.destinationCity,
    this.destinationCountry,
    this.destinationLat,
    this.destinationLng,
    required this.startDate,
    required this.endDate,
    this.isFlexible = false,
    this.flexibleDays = 0,
    this.certainty = TripCertainty.tentative,
    this.visibility = TripVisibility.connections,
    this.travelType = TravelType.leisure,
    this.accommodation,
    this.notes,
    this.coverImageUrl,
    this.aiSuggestions,
    this.aiMatchScore,
    this.isCancelled = false,
    this.isCompleted = false,
    this.companions = const [],
    required this.createdAt,
    this.updatedAt,
    // Joined fields from queries
    this.userName,
    this.userAvatar,
  });

  factory TravelPlan.fromJson(Map<String, dynamic> json) => TravelPlan(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        destinationCity: json['destination_city'] as String,
        destinationCountry: json['destination_country'] as String?,
        destinationLat: (json['destination_lat'] as num?)?.toDouble(),
        destinationLng: (json['destination_lng'] as num?)?.toDouble(),
        startDate: DateTime.parse(json['start_date'] as String),
        endDate: DateTime.parse(json['end_date'] as String),
        isFlexible: json['is_flexible'] as bool? ?? false,
        flexibleDays: json['flexible_days'] as int? ?? 0,
        certainty: TripCertainty.fromString(json['certainty'] as String?),
        visibility: TripVisibility.fromString(json['visibility'] as String?),
        travelType: TravelType.fromString(json['travel_type'] as String?),
        accommodation: json['accommodation'] as String?,
        notes: json['notes'] as String?,
        coverImageUrl: json['cover_image_url'] as String?,
        aiSuggestions: (json['ai_suggestions'] as List?)?.cast<String>(),
        aiMatchScore: (json['ai_match_score'] as num?)?.toDouble(),
        isCancelled: json['is_cancelled'] as bool? ?? false,
        isCompleted: json['is_completed'] as bool? ?? false,
        companions: (json['travel_companions'] as List?)
                ?.map((c) =>
                    TravelCompanion.fromJson(c as Map<String, dynamic>))
                .toList() ??
            [],
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : null,
        userName: json['user_name'] as String?,
        userAvatar: json['user_avatar'] as String?,
      );

  final String id;
  final String userId;
  final String title;
  final String? description;
  final String destinationCity;
  final String? destinationCountry;
  final double? destinationLat;
  final double? destinationLng;
  final DateTime startDate;
  final DateTime endDate;
  final bool isFlexible;
  final int flexibleDays;
  final TripCertainty certainty;
  final TripVisibility visibility;
  final TravelType travelType;
  final String? accommodation;
  final String? notes;
  final String? coverImageUrl;
  final List<String>? aiSuggestions;
  final double? aiMatchScore;
  final bool isCancelled;
  final bool isCompleted;
  final List<TravelCompanion> companions;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? userName;
  final String? userAvatar;

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'title': title,
        'description': description,
        'destination_city': destinationCity,
        'destination_country': destinationCountry,
        'destination_lat': destinationLat,
        'destination_lng': destinationLng,
        'start_date': startDate.toIso8601String().split('T').first,
        'end_date': endDate.toIso8601String().split('T').first,
        'is_flexible': isFlexible,
        'flexible_days': flexibleDays,
        'certainty': certainty.name,
        'visibility': visibility.name,
        'travel_type': travelType.name,
        'accommodation': accommodation,
        'notes': notes,
        'cover_image_url': coverImageUrl,
      };

  /// Duration of the trip in days
  int get durationDays => endDate.difference(startDate).inDays + 1;

  /// Formatted date range
  String get dateRange {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    if (startDate.month == endDate.month && startDate.year == endDate.year) {
      return '${months[startDate.month - 1]} ${startDate.day}–${endDate.day}';
    }
    return '${months[startDate.month - 1]} ${startDate.day} – ${months[endDate.month - 1]} ${endDate.day}';
  }

  /// Whether the trip is currently happening
  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate.subtract(const Duration(days: 1))) &&
        now.isBefore(endDate.add(const Duration(days: 1)));
  }

  /// Whether the trip is upcoming
  bool get isUpcoming => startDate.isAfter(DateTime.now());

  /// Whether the trip is past
  bool get isPast => endDate.isBefore(DateTime.now());

  /// Destination display string
  String get destinationDisplay {
    if (destinationCountry != null && destinationCountry!.isNotEmpty) {
      return '$destinationCity, $destinationCountry';
    }
    return destinationCity;
  }

  @override
  List<Object?> get props => [id, userId, title, startDate, endDate];
}

class TravelCompanion extends Equatable {
  const TravelCompanion({
    required this.id,
    required this.travelPlanId,
    required this.userId,
    this.status = 'invited',
    this.invitedBy,
    required this.createdAt,
    this.userName,
    this.userAvatar,
  });

  factory TravelCompanion.fromJson(Map<String, dynamic> json) =>
      TravelCompanion(
        id: json['id'] as String,
        travelPlanId: json['travel_plan_id'] as String,
        userId: json['user_id'] as String,
        status: json['status'] as String? ?? 'invited',
        invitedBy: json['invited_by'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        userName: json['user_name'] as String?,
        userAvatar: json['user_avatar'] as String?,
      );

  final String id;
  final String travelPlanId;
  final String userId;
  final String status;
  final String? invitedBy;
  final DateTime createdAt;
  final String? userName;
  final String? userAvatar;

  @override
  List<Object?> get props => [id, travelPlanId, userId];
}

class TravelOverlap extends Equatable {
  const TravelOverlap({
    required this.planId,
    required this.planTitle,
    required this.planDestination,
    required this.planStart,
    required this.planEnd,
    required this.overlapUserId,
    required this.overlapUserName,
    this.overlapUserAvatar,
    required this.overlapPlanId,
    required this.overlapPlanTitle,
    required this.overlapPlanDestination,
    required this.overlapPlanStart,
    required this.overlapPlanEnd,
    required this.overlapStart,
    required this.overlapEnd,
    this.distanceKm,
    this.isSameCity = false,
  });

  factory TravelOverlap.fromJson(Map<String, dynamic> json) => TravelOverlap(
        planId: json['plan_id'] as String,
        planTitle: json['plan_title'] as String,
        planDestination: json['plan_destination'] as String,
        planStart: DateTime.parse(json['plan_start'] as String),
        planEnd: DateTime.parse(json['plan_end'] as String),
        overlapUserId: json['overlap_user_id'] as String,
        overlapUserName: json['overlap_user_name'] as String,
        overlapUserAvatar: json['overlap_user_avatar'] as String?,
        overlapPlanId: json['overlap_plan_id'] as String,
        overlapPlanTitle: json['overlap_plan_title'] as String,
        overlapPlanDestination: json['overlap_plan_destination'] as String,
        overlapPlanStart: DateTime.parse(json['overlap_plan_start'] as String),
        overlapPlanEnd: DateTime.parse(json['overlap_plan_end'] as String),
        overlapStart: DateTime.parse(json['overlap_start'] as String),
        overlapEnd: DateTime.parse(json['overlap_end'] as String),
        distanceKm: (json['distance_km'] as num?)?.toDouble(),
        isSameCity: json['is_same_city'] as bool? ?? false,
      );

  final String planId;
  final String planTitle;
  final String planDestination;
  final DateTime planStart;
  final DateTime planEnd;
  final String overlapUserId;
  final String overlapUserName;
  final String? overlapUserAvatar;
  final String overlapPlanId;
  final String overlapPlanTitle;
  final String overlapPlanDestination;
  final DateTime overlapPlanStart;
  final DateTime overlapPlanEnd;
  final DateTime overlapStart;
  final DateTime overlapEnd;
  final double? distanceKm;
  final bool isSameCity;

  int get overlapDays => overlapEnd.difference(overlapStart).inDays + 1;

  @override
  List<Object?> get props => [planId, overlapPlanId];
}
