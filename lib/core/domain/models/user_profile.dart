import 'package:equatable/equatable.dart';

/// User profile model for Vespara
class UserProfile extends Equatable {
  final String id;
  final String email;
  final String? displayName;
  final String? avatarUrl;
  final String? bio;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double trustScore;
  final List<String> verifications;
  final Map<String, dynamic>? preferences;
  
  const UserProfile({
    required this.id,
    required this.email,
    this.displayName,
    this.avatarUrl,
    this.bio,
    required this.createdAt,
    required this.updatedAt,
    this.trustScore = 0.0,
    this.verifications = const [],
    this.preferences,
  });
  
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      trustScore: (json['trust_score'] as num?)?.toDouble() ?? 0.0,
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
      'updated_at': updatedAt.toIso8601String(),
      'trust_score': trustScore,
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
