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
  final List<String> photos;
  final List<String> relationshipTypes;
  final List<String> loveLanguages;
  final List<String> kinks;
  final List<String> boundaries;
  
  // Onboarding fields
  final String? city;
  final String? state;
  final String? zipCode;
  final String? pronouns;
  final List<String> gender;
  final List<String> orientation;
  final List<String> relationshipStatus;
  final List<String> seeking;
  final String? partnerInvolvement;
  final List<String> availabilityGeneral;
  final String? schedulingStyle;
  final String? hostingStatus;
  final String? discretionLevel;
  final int? travelRadius;
  final List<String> partyAvailability;
  final List<String> lookingFor; // traits
  final DateTime? birthDate;
  final bool ageVerified;
  final bool onboardingComplete;
  
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
    this.photos = const [],
    this.relationshipTypes = const [],
    this.loveLanguages = const [],
    this.kinks = const [],
    this.boundaries = const [],
    // Onboarding fields
    this.city,
    this.state,
    this.zipCode,
    this.pronouns,
    this.gender = const [],
    this.orientation = const [],
    this.relationshipStatus = const [],
    this.seeking = const [],
    this.partnerInvolvement,
    this.availabilityGeneral = const [],
    this.schedulingStyle,
    this.hostingStatus,
    this.discretionLevel,
    this.travelRadius,
    this.partyAvailability = const [],
    this.lookingFor = const [],
    this.birthDate,
    this.ageVerified = false,
    this.onboardingComplete = false,
  });
  
  /// Computed location string from city/state
  String get displayLocation {
    if (city != null && state != null) {
      return '$city, $state';
    }
    return location ?? city ?? state ?? '';
  }
  
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
      location: json['location_city'] as String?, // legacy field
      photos: List<String>.from(json['photos'] ?? []),
      relationshipTypes: List<String>.from(json['relationship_type'] ?? []),
      loveLanguages: List<String>.from(json['love_languages'] ?? []),
      kinks: List<String>.from(json['kinks'] ?? []),
      boundaries: List<String>.from(json['boundaries'] ?? []),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      trustScore: (json['vouch_score'] as num?)?.toDouble() ?? 0.0,
      vouchCount: json['vouch_count'] as int? ?? 0,
      isVerified: json['is_verified'] as bool? ?? false,
      verifications: List<String>.from(json['verifications'] ?? []),
      preferences: json['tags_preferences'] as Map<String, dynamic>?,
      // Onboarding fields
      city: json['city'] as String?,
      state: json['state'] as String?,
      zipCode: json['zip_code'] as String?,
      pronouns: json['pronouns'] as String?,
      gender: List<String>.from(json['gender'] ?? []),
      orientation: List<String>.from(json['orientation'] ?? []),
      relationshipStatus: List<String>.from(json['relationship_status'] ?? []),
      seeking: List<String>.from(json['seeking'] ?? []),
      partnerInvolvement: json['partner_involvement'] as String?,
      availabilityGeneral: List<String>.from(json['availability_general'] ?? []),
      schedulingStyle: json['scheduling_style'] as String?,
      hostingStatus: json['hosting_status'] as String?,
      discretionLevel: json['discretion_level'] as String?,
      travelRadius: json['travel_radius'] as int?,
      partyAvailability: List<String>.from(json['party_availability'] ?? []),
      lookingFor: List<String>.from(json['looking_for'] ?? []),
      birthDate: json['birth_date'] != null 
          ? DateTime.tryParse(json['birth_date'] as String)
          : null,
      ageVerified: json['age_verified'] as bool? ?? false,
      onboardingComplete: json['onboarding_complete'] as bool? ?? false,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'bio': bio,
      'headline': headline,
      'age': age,
      'occupation': occupation,
      'location_city': location,
      'photos': photos,
      'relationship_type': relationshipTypes,
      'love_languages': loveLanguages,
      'kinks': kinks,
      'boundaries': boundaries,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'vouch_score': trustScore,
      'vouch_count': vouchCount,
      'is_verified': isVerified,
      'verifications': verifications,
      'tags_preferences': preferences,
      // Onboarding fields
      'city': city,
      'state': state,
      'zip_code': zipCode,
      'pronouns': pronouns,
      'gender': gender,
      'orientation': orientation,
      'relationship_status': relationshipStatus,
      'seeking': seeking,
      'partner_involvement': partnerInvolvement,
      'availability_general': availabilityGeneral,
      'scheduling_style': schedulingStyle,
      'hosting_status': hostingStatus,
      'discretion_level': discretionLevel,
      'travel_radius': travelRadius,
      'party_availability': partyAvailability,
      'looking_for': lookingFor,
      'birth_date': birthDate?.toIso8601String().split('T').first,
      'age_verified': ageVerified,
      'onboarding_complete': onboardingComplete,
    };
  }
  
  UserProfile copyWith({
    String? id,
    String? email,
    String? displayName,
    String? avatarUrl,
    String? bio,
    String? headline,
    int? age,
    String? occupation,
    String? location,
    List<String>? photos,
    List<String>? relationshipTypes,
    List<String>? loveLanguages,
    List<String>? kinks,
    List<String>? boundaries,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? trustScore,
    int? vouchCount,
    bool? isVerified,
    List<String>? verifications,
    Map<String, dynamic>? preferences,
    // Onboarding fields
    String? city,
    String? state,
    String? zipCode,
    String? pronouns,
    List<String>? gender,
    List<String>? orientation,
    List<String>? relationshipStatus,
    List<String>? seeking,
    String? partnerInvolvement,
    List<String>? availabilityGeneral,
    String? schedulingStyle,
    String? hostingStatus,
    String? discretionLevel,
    int? travelRadius,
    List<String>? partyAvailability,
    List<String>? lookingFor,
    DateTime? birthDate,
    bool? ageVerified,
    bool? onboardingComplete,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      headline: headline ?? this.headline,
      age: age ?? this.age,
      occupation: occupation ?? this.occupation,
      location: location ?? this.location,
      photos: photos ?? this.photos,
      relationshipTypes: relationshipTypes ?? this.relationshipTypes,
      loveLanguages: loveLanguages ?? this.loveLanguages,
      kinks: kinks ?? this.kinks,
      boundaries: boundaries ?? this.boundaries,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      trustScore: trustScore ?? this.trustScore,
      vouchCount: vouchCount ?? this.vouchCount,
      isVerified: isVerified ?? this.isVerified,
      verifications: verifications ?? this.verifications,
      preferences: preferences ?? this.preferences,
      // Onboarding fields
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      pronouns: pronouns ?? this.pronouns,
      gender: gender ?? this.gender,
      orientation: orientation ?? this.orientation,
      relationshipStatus: relationshipStatus ?? this.relationshipStatus,
      seeking: seeking ?? this.seeking,
      partnerInvolvement: partnerInvolvement ?? this.partnerInvolvement,
      availabilityGeneral: availabilityGeneral ?? this.availabilityGeneral,
      schedulingStyle: schedulingStyle ?? this.schedulingStyle,
      hostingStatus: hostingStatus ?? this.hostingStatus,
      discretionLevel: discretionLevel ?? this.discretionLevel,
      travelRadius: travelRadius ?? this.travelRadius,
      partyAvailability: partyAvailability ?? this.partyAvailability,
      lookingFor: lookingFor ?? this.lookingFor,
      birthDate: birthDate ?? this.birthDate,
      ageVerified: ageVerified ?? this.ageVerified,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    );
  }
  
  @override
  List<Object?> get props => [
    id,
    email,
    displayName,
    avatarUrl,
    bio,
    headline,
    age,
    occupation,
    location,
    photos,
    relationshipTypes,
    loveLanguages,
    kinks,
    boundaries,
    createdAt,
    updatedAt,
    trustScore,
    vouchCount,
    isVerified,
    verifications,
    preferences,
    city,
    state,
    zipCode,
    pronouns,
    gender,
    orientation,
    relationshipStatus,
    seeking,
    partnerInvolvement,
    availabilityGeneral,
    schedulingStyle,
    hostingStatus,
    discretionLevel,
    travelRadius,
    partyAvailability,
    lookingFor,
    birthDate,
    ageVerified,
    onboardingComplete,
  ];
}
