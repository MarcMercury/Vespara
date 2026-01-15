import 'package:equatable/equatable.dart';

/// Pipeline stage for Roster CRM
enum PipelineStage {
  incoming,
  bench,
  activeRotation,
  legacy,
}

extension PipelineStageExtension on PipelineStage {
  String get displayName {
    switch (this) {
      case PipelineStage.incoming:
        return 'Incoming';
      case PipelineStage.bench:
        return 'The Bench';
      case PipelineStage.activeRotation:
        return 'Active Rotation';
      case PipelineStage.legacy:
        return 'Legacy';
    }
  }
  
  String get shortName {
    switch (this) {
      case PipelineStage.incoming:
        return 'IN';
      case PipelineStage.bench:
        return 'BN';
      case PipelineStage.activeRotation:
        return 'AR';
      case PipelineStage.legacy:
        return 'LG';
    }
  }
}

/// Match/Contact model for Roster CRM
class RosterMatch extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String? nickname;
  final String? avatarUrl;
  final String? source;
  final String? sourceUsername;
  final PipelineStage stage;
  final double momentumScore;
  final String? notes;
  final List<String> interests;
  final DateTime? lastContactDate;
  final String? nextAction;
  final bool isArchived;
  final DateTime? archivedAt;
  final String? archiveReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  const RosterMatch({
    required this.id,
    required this.userId,
    required this.name,
    this.nickname,
    this.avatarUrl,
    this.source,
    this.sourceUsername,
    required this.stage,
    this.momentumScore = 0.5,
    this.notes,
    this.interests = const [],
    this.lastContactDate,
    this.nextAction,
    this.isArchived = false,
    this.archivedAt,
    this.archiveReason,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory RosterMatch.fromJson(Map<String, dynamic> json) {
    return RosterMatch(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      nickname: json['nickname'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      source: json['source'] as String?,
      sourceUsername: json['source_username'] as String?,
      stage: _parsePipeline(json['pipeline'] as String?),
      momentumScore: (json['momentum_score'] as num?)?.toDouble() ?? 0.5,
      notes: json['notes'] as String?,
      interests: List<String>.from(json['interests'] ?? []),
      lastContactDate: json['last_contact_date'] != null
          ? DateTime.parse(json['last_contact_date'] as String)
          : null,
      nextAction: json['next_action'] as String?,
      isArchived: json['is_archived'] as bool? ?? false,
      archivedAt: json['archived_at'] != null
          ? DateTime.parse(json['archived_at'] as String)
          : null,
      archiveReason: json['archive_reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
  
  static PipelineStage _parsePipeline(String? value) {
    switch (value) {
      case 'incoming':
        return PipelineStage.incoming;
      case 'bench':
        return PipelineStage.bench;
      case 'active':
        return PipelineStage.activeRotation;
      case 'legacy':
        return PipelineStage.legacy;
      default:
        return PipelineStage.incoming;
    }
  }
  
  String get pipelineValue {
    switch (stage) {
      case PipelineStage.incoming:
        return 'incoming';
      case PipelineStage.bench:
        return 'bench';
      case PipelineStage.activeRotation:
        return 'active';
      case PipelineStage.legacy:
        return 'legacy';
    }
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'nickname': nickname,
      'avatar_url': avatarUrl,
      'source': source,
      'source_username': sourceUsername,
      'pipeline': pipelineValue,
      'momentum_score': momentumScore,
      'notes': notes,
      'interests': interests,
      'last_contact_date': lastContactDate?.toIso8601String(),
      'next_action': nextAction,
      'is_archived': isArchived,
      'archived_at': archivedAt?.toIso8601String(),
      'archive_reason': archiveReason,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
  
  RosterMatch copyWith({
    String? id,
    String? userId,
    String? name,
    String? nickname,
    String? avatarUrl,
    String? source,
    String? sourceUsername,
    PipelineStage? stage,
    double? momentumScore,
    String? notes,
    List<String>? interests,
    DateTime? lastContactDate,
    String? nextAction,
    bool? isArchived,
    DateTime? archivedAt,
    String? archiveReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RosterMatch(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      nickname: nickname ?? this.nickname,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      source: source ?? this.source,
      sourceUsername: sourceUsername ?? this.sourceUsername,
      stage: stage ?? this.stage,
      momentumScore: momentumScore ?? this.momentumScore,
      notes: notes ?? this.notes,
      interests: interests ?? this.interests,
      lastContactDate: lastContactDate ?? this.lastContactDate,
      nextAction: nextAction ?? this.nextAction,
      isArchived: isArchived ?? this.isArchived,
      archivedAt: archivedAt ?? this.archivedAt,
      archiveReason: archiveReason ?? this.archiveReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  @override
  List<Object?> get props => [
    id,
    userId,
    name,
    nickname,
    avatarUrl,
    source,
    sourceUsername,
    stage,
    momentumScore,
    notes,
    interests,
    lastContactDate,
    nextAction,
    isArchived,
    archivedAt,
    archiveReason,
    createdAt,
    updatedAt,
  ];
}
