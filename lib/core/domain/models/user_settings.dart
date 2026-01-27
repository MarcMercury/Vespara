/// User settings model for app preferences and configuration
class UserSettings {
  final String id;
  final String userId;
  
  // Notifications
  final bool notifyNewMessages;
  final bool notifyNewMatches;
  final bool notifyDateReminders;
  final bool notifyAiInsights;
  
  // Privacy
  final bool showOnlineStatus;
  final bool readReceipts;
  final bool profileVisible;
  final bool profileHidden;
  final String locationSharing;
  
  // Discovery
  final int minAge;
  final int maxAge;
  final int maxDistance;
  final String showMe;
  final List<String> relationshipTypes;
  
  // Account
  final bool isPaused;
  final DateTime? pausedAt;
  final String? pauseReason;
  final String? phone;
  final String subscriptionTier;
  final DateTime? subscriptionExpiresAt;
  
  // Calendar
  final bool googleCalendarConnected;
  final bool appleCalendarConnected;
  
  final DateTime createdAt;
  final DateTime updatedAt;

  UserSettings({
    required this.id,
    required this.userId,
    this.notifyNewMessages = true,
    this.notifyNewMatches = true,
    this.notifyDateReminders = true,
    this.notifyAiInsights = false,
    this.showOnlineStatus = true,
    this.readReceipts = false,
    this.profileVisible = true,
    this.profileHidden = false,
    this.locationSharing = 'while_using',
    this.minAge = 21,
    this.maxAge = 55,
    this.maxDistance = 50,
    this.showMe = 'Everyone',
    this.relationshipTypes = const ['Long-term', 'Casual', 'Friendship'],
    this.isPaused = false,
    this.pausedAt,
    this.pauseReason,
    this.phone,
    this.subscriptionTier = 'free',
    this.subscriptionExpiresAt,
    this.googleCalendarConnected = false,
    this.appleCalendarConnected = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      notifyNewMessages: json['notify_new_messages'] as bool? ?? true,
      notifyNewMatches: json['notify_new_matches'] as bool? ?? true,
      notifyDateReminders: json['notify_date_reminders'] as bool? ?? true,
      notifyAiInsights: json['notify_ai_insights'] as bool? ?? false,
      showOnlineStatus: json['show_online_status'] as bool? ?? true,
      readReceipts: json['read_receipts'] as bool? ?? false,
      profileVisible: json['profile_visible'] as bool? ?? true,
      profileHidden: json['profile_hidden'] as bool? ?? false,
      locationSharing: json['location_sharing'] as String? ?? 'while_using',
      minAge: json['min_age'] as int? ?? 21,
      maxAge: json['max_age'] as int? ?? 55,
      maxDistance: json['max_distance'] as int? ?? 50,
      showMe: json['show_me'] as String? ?? 'Everyone',
      relationshipTypes: (json['relationship_types'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          ['Long-term', 'Casual', 'Friendship'],
      isPaused: json['is_paused'] as bool? ?? false,
      pausedAt: json['paused_at'] != null
          ? DateTime.parse(json['paused_at'] as String)
          : null,
      pauseReason: json['pause_reason'] as String?,
      phone: json['phone'] as String?,
      subscriptionTier: json['subscription_tier'] as String? ?? 'free',
      subscriptionExpiresAt: json['subscription_expires_at'] != null
          ? DateTime.parse(json['subscription_expires_at'] as String)
          : null,
      googleCalendarConnected:
          json['google_calendar_connected'] as bool? ?? false,
      appleCalendarConnected:
          json['apple_calendar_connected'] as bool? ?? false,
      createdAt: DateTime.parse(
          json['created_at'] as String? ?? DateTime.now().toIso8601String(),),
      updatedAt: DateTime.parse(
          json['updated_at'] as String? ?? DateTime.now().toIso8601String(),),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'notify_new_messages': notifyNewMessages,
      'notify_new_matches': notifyNewMatches,
      'notify_date_reminders': notifyDateReminders,
      'notify_ai_insights': notifyAiInsights,
      'show_online_status': showOnlineStatus,
      'read_receipts': readReceipts,
      'profile_visible': profileVisible,
      'profile_hidden': profileHidden,
      'location_sharing': locationSharing,
      'min_age': minAge,
      'max_age': maxAge,
      'max_distance': maxDistance,
      'show_me': showMe,
      'relationship_types': relationshipTypes,
      'is_paused': isPaused,
      'paused_at': pausedAt?.toIso8601String(),
      'pause_reason': pauseReason,
      'phone': phone,
      'subscription_tier': subscriptionTier,
      'subscription_expires_at': subscriptionExpiresAt?.toIso8601String(),
      'google_calendar_connected': googleCalendarConnected,
      'apple_calendar_connected': appleCalendarConnected,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  UserSettings copyWith({
    String? id,
    String? userId,
    bool? notifyNewMessages,
    bool? notifyNewMatches,
    bool? notifyDateReminders,
    bool? notifyAiInsights,
    bool? showOnlineStatus,
    bool? readReceipts,
    bool? profileVisible,
    bool? profileHidden,
    String? locationSharing,
    int? minAge,
    int? maxAge,
    int? maxDistance,
    String? showMe,
    List<String>? relationshipTypes,
    bool? isPaused,
    DateTime? pausedAt,
    String? pauseReason,
    String? phone,
    String? subscriptionTier,
    DateTime? subscriptionExpiresAt,
    bool? googleCalendarConnected,
    bool? appleCalendarConnected,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserSettings(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      notifyNewMessages: notifyNewMessages ?? this.notifyNewMessages,
      notifyNewMatches: notifyNewMatches ?? this.notifyNewMatches,
      notifyDateReminders: notifyDateReminders ?? this.notifyDateReminders,
      notifyAiInsights: notifyAiInsights ?? this.notifyAiInsights,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
      readReceipts: readReceipts ?? this.readReceipts,
      profileVisible: profileVisible ?? this.profileVisible,
      profileHidden: profileHidden ?? this.profileHidden,
      locationSharing: locationSharing ?? this.locationSharing,
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      maxDistance: maxDistance ?? this.maxDistance,
      showMe: showMe ?? this.showMe,
      relationshipTypes: relationshipTypes ?? this.relationshipTypes,
      isPaused: isPaused ?? this.isPaused,
      pausedAt: pausedAt ?? this.pausedAt,
      pauseReason: pauseReason ?? this.pauseReason,
      phone: phone ?? this.phone,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      subscriptionExpiresAt:
          subscriptionExpiresAt ?? this.subscriptionExpiresAt,
      googleCalendarConnected:
          googleCalendarConnected ?? this.googleCalendarConnected,
      appleCalendarConnected:
          appleCalendarConnected ?? this.appleCalendarConnected,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Default settings for new users
  factory UserSettings.defaults(String userId) {
    final now = DateTime.now();
    return UserSettings(
      id: '', // Will be set by database
      userId: userId,
      createdAt: now,
      updatedAt: now,
    );
  }
}
