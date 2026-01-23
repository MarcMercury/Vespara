import 'package:equatable/equatable.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// Profile Photo Model
/// Represents a user's profile photo with ranking metadata
/// ═══════════════════════════════════════════════════════════════════════════

class ProfilePhoto extends Equatable {
  final String id;
  final String userId;
  final String photoUrl;
  final String storagePath;
  final int position;
  final bool isPrimary;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Score data (optional, loaded separately)
  final PhotoScore? score;
  
  ProfilePhoto({
    required this.id,
    required this.userId,
    required this.photoUrl,
    this.storagePath = '',
    required this.position,
    this.isPrimary = false,
    this.version = 1,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.score,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();
  
  /// Create a simplified photo from a URL (for display purposes only)
  factory ProfilePhoto.fromUrl({
    required String id,
    required String userId,
    required String photoUrl,
    required int position,
    bool isPrimary = false,
  }) {
    final now = DateTime.now();
    return ProfilePhoto(
      id: id,
      userId: userId,
      photoUrl: photoUrl,
      storagePath: '',
      position: position,
      isPrimary: isPrimary,
      version: 1,
      createdAt: now,
      updatedAt: now,
    );
  }
  
  factory ProfilePhoto.fromJson(Map<String, dynamic> json) {
    return ProfilePhoto(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      photoUrl: json['photo_url'] as String,
      storagePath: json['storage_path'] as String,
      position: json['position'] as int,
      isPrimary: json['is_primary'] as bool? ?? false,
      version: json['version'] as int? ?? 1,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      score: json['photo_scores'] != null && (json['photo_scores'] as List).isNotEmpty
          ? PhotoScore.fromJson((json['photo_scores'] as List).first)
          : null,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'photo_url': photoUrl,
    'storage_path': storagePath,
    'position': position,
    'is_primary': isPrimary,
    'version': version,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
  
  ProfilePhoto copyWith({
    String? id,
    String? userId,
    String? photoUrl,
    String? storagePath,
    int? position,
    bool? isPrimary,
    int? version,
    DateTime? createdAt,
    DateTime? updatedAt,
    PhotoScore? score,
  }) {
    return ProfilePhoto(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      photoUrl: photoUrl ?? this.photoUrl,
      storagePath: storagePath ?? this.storagePath,
      position: position ?? this.position,
      isPrimary: isPrimary ?? this.isPrimary,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      score: score ?? this.score,
    );
  }
  
  @override
  List<Object?> get props => [id, userId, photoUrl, position, isPrimary, version];
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Photo Score Model
/// Aggregated ranking scores for a photo
/// ═══════════════════════════════════════════════════════════════════════════

class PhotoScore extends Equatable {
  final String id;
  final String photoId;
  final String userId;
  final int photoVersion;
  final double averageRank;
  final int totalRankings;
  final Map<String, int> rankDistribution;
  final int? aiRecommendedPosition;
  final double confidenceScore;
  final bool hasEnoughData;
  final DateTime updatedAt;
  
  const PhotoScore({
    required this.id,
    required this.photoId,
    required this.userId,
    this.photoVersion = 1,
    this.averageRank = 3.0,
    this.totalRankings = 0,
    this.rankDistribution = const {'1': 0, '2': 0, '3': 0, '4': 0, '5': 0},
    this.aiRecommendedPosition,
    this.confidenceScore = 0,
    this.hasEnoughData = false,
    required this.updatedAt,
  });
  
  factory PhotoScore.fromJson(Map<String, dynamic> json) {
    return PhotoScore(
      id: json['id'] as String,
      photoId: json['photo_id'] as String,
      userId: json['user_id'] as String,
      photoVersion: json['photo_version'] as int? ?? 1,
      averageRank: (json['average_rank'] as num?)?.toDouble() ?? 3.0,
      totalRankings: json['total_rankings'] as int? ?? 0,
      rankDistribution: json['rank_distribution'] != null
          ? Map<String, int>.from(
              (json['rank_distribution'] as Map).map(
                (k, v) => MapEntry(k.toString(), (v as num).toInt()),
              ),
            )
          : const {'1': 0, '2': 0, '3': 0, '4': 0, '5': 0},
      aiRecommendedPosition: json['ai_recommended_position'] as int?,
      confidenceScore: (json['confidence_score'] as num?)?.toDouble() ?? 0,
      hasEnoughData: json['has_enough_data'] as bool? ?? false,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }
  
  /// Confidence as a percentage string
  String get confidencePercentage => '${(confidenceScore * 100).toInt()}%';
  
  /// Human readable rank
  String get rankDisplay {
    if (totalRankings == 0) return 'No rankings yet';
    return '${averageRank.toStringAsFixed(1)} avg';
  }
  
  @override
  List<Object?> get props => [id, photoId, averageRank, totalRankings];
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Photo Ranking Model
/// A user's ranking of another user's photos
/// ═══════════════════════════════════════════════════════════════════════════

class PhotoRanking extends Equatable {
  final String id;
  final String rankerId;
  final String rankedUserId;
  final List<String> rankedPhotoIds;
  final Map<String, int> photoVersions;
  final bool isValid;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  const PhotoRanking({
    required this.id,
    required this.rankerId,
    required this.rankedUserId,
    required this.rankedPhotoIds,
    this.photoVersions = const {},
    this.isValid = true,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory PhotoRanking.fromJson(Map<String, dynamic> json) {
    return PhotoRanking(
      id: json['id'] as String,
      rankerId: json['ranker_id'] as String,
      rankedUserId: json['ranked_user_id'] as String,
      rankedPhotoIds: (json['ranked_photo_ids'] as List?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      photoVersions: json['photo_versions'] != null
          ? Map<String, int>.from(
              (json['photo_versions'] as Map).map(
                (k, v) => MapEntry(k.toString(), (v as num).toInt()),
              ),
            )
          : const {},
      isValid: json['is_valid'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'ranker_id': rankerId,
    'ranked_user_id': rankedUserId,
    'ranked_photo_ids': rankedPhotoIds,
    'photo_versions': photoVersions,
    'is_valid': isValid,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
  
  /// Get rankings as a map: photoId -> rank (1-based)
  Map<String, int> get rankings {
    final result = <String, int>{};
    for (var i = 0; i < rankedPhotoIds.length; i++) {
      result[rankedPhotoIds[i]] = i + 1;
    }
    return result;
  }
  
  @override
  List<Object?> get props => [id, rankerId, rankedUserId, rankedPhotoIds];
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Photo Recommendation Model
/// AI-generated recommendation for photo ordering
/// ═══════════════════════════════════════════════════════════════════════════

class PhotoRecommendation {
  final String? recommendedPrimaryId;
  final List<String> recommendedOrder;
  final double confidence;
  final int totalRankings;
  final List<String> insights;
  
  const PhotoRecommendation({
    this.recommendedPrimaryId,
    this.recommendedOrder = const [],
    this.confidence = 0,
    this.totalRankings = 0,
    this.insights = const [],
  });
  
  bool get hasRecommendation => recommendedPrimaryId != null && confidence > 0.2;
  
  String get confidenceLabel {
    if (confidence >= 0.8) return 'High confidence';
    if (confidence >= 0.5) return 'Moderate confidence';
    if (confidence >= 0.2) return 'Low confidence';
    return 'Needs more data';
  }
}
