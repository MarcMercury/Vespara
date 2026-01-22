import 'package:equatable/equatable.dart';

/// User profile model for Vespara Dating App
class UserProfile extends Equatable {
  final String id;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final String? bio;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final double trustScore;
  final int vouchCount;
  final bool isVerified;
  final List<String> verifications;
  final Map<String, dynamic>? preferences;
  
  // Dating-specific fields
  final String? headline;
  final int? age;
  final String? occupation;
  final String? location;
  final String? city;
  final String? state;
  final String? zipCode;
  final List<String> photos;
  final List<String> relationshipTypes;
  final List<String> loveLanguages;
  final List<String> kinks;
  final List<String> boundaries;
  
  // Identity fields (from onboarding)
  final String? pronouns;
  final List<String> gender;
  final List<String> orientation;
  final List<String> relationshipStatus;
  final List<String> seeking;
  final List<String> lookingFor;
  final List<String> availabilityGeneral;
  final String? hostingStatus;
  final String? discretionLevel;
  final String? schedulingStyle;
  final String? partnerInvolvement;
  
  // Build Experience fields (vibe/interests/desires)
  final List<String> vibeTags;
  final List<String> interestTags;
  final List<String> desireTags;
  
  // THE INTERVIEW fields (heat, limits, logistics)
  final String? hook;  // 140-char profile teaser
  final String? heatLevel;  // mild, medium, hot, nuclear
  final List<String> hardLimits;  // non-negotiable boundaries
  final double bandwidth;  // 0-1 availability/energy level
  final int travelRadius;  // miles willing to travel
  final List<String> partyAvailability;  // event/party preferences
  
  /// Returns a display-friendly location string
  /// Prioritizes city/state, falls back to location field
  String get displayLocation {
    if (city != null && city!.isNotEmpty && state != null && state!.isNotEmpty) {
      return '$city, $state';
    } else if (city != null && city!.isNotEmpty) {
      return city!;
    } else if (location != null && location!.isNotEmpty) {
      return location!;
    } else if (zipCode != null && zipCode!.isNotEmpty) {
      return zipCode!;
    }
    return '';
  }

  const UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    this.bio,
    required this.createdAt,
    this.updatedAt,
    this.trustScore = 0.0,
    this.vouchCount = 0,
    this.isVerified = false,
    this.verifications = const [],
    this.preferences,
    this.headline,
    this.age,
    this.occupation,
    this.location,
    this.city,
    this.state,
    this.zipCode,
    this.photos = const [],
    this.relationshipTypes = const [],
    this.loveLanguages = const [],
    this.kinks = const [],
    this.boundaries = const [],
    this.pronouns,
    this.gender = const [],
    this.orientation = const [],
    this.relationshipStatus = const [],
    this.seeking = const [],
    this.lookingFor = const [],
    this.availabilityGeneral = const [],
    this.hostingStatus,
    this.discretionLevel,
    this.schedulingStyle,
    this.partnerInvolvement,
    this.vibeTags = const [],
    this.interestTags = const [],
    this.desireTags = const [],
    this.hook,
    this.heatLevel,
    this.hardLimits = const [],
    this.bandwidth = 0.5,
    this.travelRadius = 25,
    this.partyAvailability = const [],
  });
  
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      displayName: json['display_name'] as String? ?? 'Unknown',
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      headline: json['headline'] as String?,
      age: json['age'] as int?,
      occupation: json['occupation'] as String?,
      location: json['location'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      zipCode: json['zip_code'] as String?,
      photos: List<String>.from(json['photos'] ?? []),
      relationshipTypes: List<String>.from(json['relationship_types'] ?? []),
      loveLanguages: List<String>.from(json['love_languages'] ?? []),
      kinks: List<String>.from(json['kinks'] ?? []),
      boundaries: List<String>.from(json['boundaries'] ?? []),
      pronouns: json['pronouns'] as String?,
      gender: List<String>.from(json['gender'] ?? []),
      orientation: List<String>.from(json['orientation'] ?? []),
      relationshipStatus: List<String>.from(json['relationship_status'] ?? []),
      seeking: List<String>.from(json['seeking'] ?? []),
      lookingFor: List<String>.from(json['looking_for'] ?? []),
      availabilityGeneral: List<String>.from(json['availability_general'] ?? []),
      hostingStatus: json['hosting_status'] as String?,
      hook: json['hook'] as String?,
      heatLevel: json['heat_level'] as String?,
      hardLimits: List<String>.from(json['hard_limits'] ?? []),
      bandwidth: (json['bandwidth'] as num?)?.toDouble() ?? 0.5,
      travelRadius: json['travel_radius'] as int? ?? 25,
      partyAvailability: List<String>.from(json['party_availability'] ?? []),
      discretionLevel: json['discretion_level'] as String?,
      schedulingStyle: json['scheduling_style'] as String?,
      partnerInvolvement: json['partner_involvement'] as String?,
      vibeTags: List<String>.from(json['vibe_tags'] ?? []),
      interestTags: List<String>.from(json['interest_tags'] ?? []),
      desireTags: List<String>.from(json['desire_tags'] ?? []),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      trustScore: (json['trust_score'] as num?)?.toDouble() ?? 0.0,
      vouchCount: json['vouch_count'] as int? ?? 0,
      isVerified: json['is_verified'] as bool? ?? false,
      verifications: List<String>.from(json['verifications'] ?? []),
      preferences: json['preferences'] as Map<String, dynamic>?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'bio': bio,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'trust_score': trustScore,
      'vouch_count': vouchCount,
      'is_verified': isVerified,
      'verifications': verifications,
      'preferences': preferences,
    };
  }
  
  UserProfile copyWith({
    String? id,
    String? email,
    String? displayName,
    String? avatarUrl,
    String? bio,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? trustScore,
    List<String>? verifications,
    Map<String, dynamic>? preferences,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      trustScore: trustScore ?? this.trustScore,
      verifications: verifications ?? this.verifications,
      preferences: preferences ?? this.preferences,
    );
  }
  
  @override
  List<Object?> get props => [
    id,
    email,
    displayName,
    avatarUrl,
    bio,
    createdAt,
    updatedAt,
    trustScore,
    verifications,
    preferences,
  ];
}
