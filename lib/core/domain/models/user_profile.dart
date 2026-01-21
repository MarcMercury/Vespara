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
      photos: List<String>.from(json['photos'] ?? []),
      relationshipTypes: List<String>.from(json['relationship_types'] ?? []),
      loveLanguages: List<String>.from(json['love_languages'] ?? []),
      kinks: List<String>.from(json['kinks'] ?? []),
      boundaries: List<String>.from(json['boundaries'] ?? []),
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
