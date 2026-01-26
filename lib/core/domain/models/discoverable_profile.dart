import 'package:equatable/equatable.dart';

/// Profile model for discovery and matching
class DiscoverableProfile extends Equatable {
  const DiscoverableProfile({
    required this.id,
    this.displayName,
    this.headline,
    this.age,
    this.bio,
    this.photos = const [],
    this.location,
    this.distanceKm,
    this.heightCm,
    this.bodyType,
    this.education,
    this.occupation,
    this.company,
    this.drinking,
    this.smoking,
    this.cannabis,
    this.relationshipTypes = const [],
    this.loveLanguages = const [],
    this.communicationStyle,
    this.prompts = const [],
    this.kinks = const [],
    this.boundaries = const [],
    this.heatLevel,
    this.hardLimits = const [],
    this.hook,
    this.compatibilityScore = 0.5,
    this.isStrictMatch = true,
    this.isWildcard = false,
    this.wildcardReason,
    this.vouchCount = 0,
    this.isVerified = false,
    this.verifications = const [],
  });

  factory DiscoverableProfile.fromJson(Map<String, dynamic> json) {
    // Calculate age from date_of_birth if present
    int? age;
    if (json['date_of_birth'] != null) {
      final dob = DateTime.parse(json['date_of_birth']);
      age = DateTime.now().difference(dob).inDays ~/ 365;
    }

    return DiscoverableProfile(
      id: json['id'] as String,
      displayName: json['display_name'] as String?,
      headline: json['headline'] as String?,
      age: age ?? json['age'] as int?,
      bio: json['bio'] as String?,
      photos: List<String>.from(json['photos'] ?? []),
      location: json['location_city'] as String?,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      heightCm: json['height_cm'] as int?,
      bodyType: json['body_type'] as String?,
      education: json['education'] as String?,
      occupation: json['occupation'] as String?,
      company: json['company'] as String?,
      drinking: json['drinking'] as String?,
      smoking: json['smoking'] as String?,
      cannabis: json['cannabis'] as String?,
      relationshipTypes: List<String>.from(json['relationship_type'] ?? []),
      loveLanguages: List<String>.from(json['love_languages'] ?? []),
      communicationStyle: json['communication_style'] as String?,
      prompts: (json['prompts'] as List?)
              ?.map((p) => ProfilePrompt.fromJson(p))
              .toList() ??
          [],
      kinks: List<String>.from(json['kinks'] ?? []),
      boundaries: List<String>.from(json['boundaries'] ?? []),
      heatLevel: json['heat_level'] as String?,
      hardLimits: List<String>.from(json['hard_limits'] ?? []),
      hook: json['hook'] as String?,
      compatibilityScore:
          (json['compatibility_score'] as num?)?.toDouble() ?? 0.5,
      isStrictMatch: json['is_strict_match'] as bool? ?? true,
      isWildcard: json['is_wildcard'] as bool? ?? false,
      wildcardReason: json['wildcard_reason'] as String?,
      vouchCount: json['vouch_count'] as int? ?? 0,
      isVerified: json['is_verified'] as bool? ?? false,
      verifications: List<String>.from(json['verifications'] ?? []),
    );
  }
  final String id;
  final String? displayName;
  final String? headline;
  final int? age;
  final String? bio;
  final List<String> photos;
  final String? location;
  final double? distanceKm;

  // Physical attributes
  final int? heightCm;
  final String? bodyType;

  // Lifestyle
  final String? education;
  final String? occupation;
  final String? company;
  final String? drinking;
  final String? smoking;
  final String? cannabis;

  // Relationship preferences
  final List<String> relationshipTypes;
  final List<String> loveLanguages;
  final String? communicationStyle;

  // Dating prompts (questions & answers)
  final List<ProfilePrompt> prompts;

  // Kinks & boundaries (for adult features)
  final List<String> kinks;
  final List<String> boundaries;
  final String? heatLevel;
  final List<String> hardLimits;
  final String? hook;

  // Match quality
  final double compatibilityScore;
  final bool isStrictMatch;
  final bool isWildcard;
  final String? wildcardReason;

  // Trust & verification
  final int vouchCount;
  final bool isVerified;
  final List<String> verifications;

  String get displayAge => age != null ? '$age' : '';

  String get primaryPhoto => photos.isNotEmpty ? photos.first : '';

  String get matchQuality {
    if (compatibilityScore >= 0.8) return 'Excellent Match';
    if (compatibilityScore >= 0.6) return 'Great Match';
    if (compatibilityScore >= 0.4) return 'Good Match';
    return 'Potential Match';
  }

  @override
  List<Object?> get props => [id, displayName, photos, compatibilityScore];
}

/// Profile prompt (question and answer)
class ProfilePrompt extends Equatable {
  const ProfilePrompt({
    required this.question,
    required this.answer,
  });

  factory ProfilePrompt.fromJson(Map<String, dynamic> json) => ProfilePrompt(
        question: json['question'] as String? ?? '',
        answer: json['answer'] as String? ?? '',
      );
  final String question;
  final String answer;

  Map<String, dynamic> toJson() => {
        'question': question,
        'answer': answer,
      };

  @override
  List<Object?> get props => [question, answer];
}

/// Swipe direction enum
enum SwipeDirection { left, right, superLike }

/// Discovery card in swipe queue
class DiscoveryCard extends Equatable {
  const DiscoveryCard({
    required this.id,
    required this.profile,
    this.isViewed = false,
    this.viewedAt,
    required this.expiresAt,
  });

  factory DiscoveryCard.fromJson(Map<String, dynamic> json) => DiscoveryCard(
        id: json['id'] as String,
        profile: DiscoverableProfile.fromJson(json['profile'] ?? json),
        isViewed: json['is_viewed'] as bool? ?? false,
        viewedAt: json['viewed_at'] != null
            ? DateTime.parse(json['viewed_at'])
            : null,
        expiresAt: json['expires_at'] != null
            ? DateTime.parse(json['expires_at'])
            : DateTime.now().add(const Duration(days: 7)),
      );
  final String id;
  final DiscoverableProfile profile;
  final bool isViewed;
  final DateTime? viewedAt;
  final DateTime expiresAt;

  @override
  List<Object?> get props => [id, profile, isViewed];
}
