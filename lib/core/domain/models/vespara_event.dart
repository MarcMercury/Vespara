import 'package:equatable/equatable.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// KULT EVENT MODEL - Enhanced Partiful-Style Events
/// Comprehensive event model with all the bells and whistles
/// ════════════════════════════════════════════════════════════════════════════

/// Event theme/style for titles
enum EventTitleStyle {
  classic,
  eclectic,
  fancy,
  literary,
  digital,
  elegant;

  String get label {
    switch (this) {
      case EventTitleStyle.classic:
        return 'Classic';
      case EventTitleStyle.eclectic:
        return 'Eclectic';
      case EventTitleStyle.fancy:
        return 'Fancy';
      case EventTitleStyle.literary:
        return 'Literary';
      case EventTitleStyle.digital:
        return 'Digital';
      case EventTitleStyle.elegant:
        return 'Elegant';
    }
  }

  String get fontFamily {
    switch (this) {
      case EventTitleStyle.classic:
        return 'Inter';
      case EventTitleStyle.eclectic:
        return 'Courier New';
      case EventTitleStyle.fancy:
        return 'Georgia';
      case EventTitleStyle.literary:
        return 'Times New Roman';
      case EventTitleStyle.digital:
        return 'Roboto Mono';
      case EventTitleStyle.elegant:
        return 'Playfair Display';
    }
  }
}

/// RSVP response options with custom emojis
class RsvpOption extends Equatable {
  const RsvpOption({
    required this.id,
    required this.label,
    required this.emoji,
    required this.order,
  });
  final String id;
  final String label;
  final String emoji;
  final int order;

  static const defaultGoing = RsvpOption(
    id: 'going',
    label: 'Going',
    emoji: '👍',
    order: 0,
  );

  static const defaultMaybe = RsvpOption(
    id: 'maybe',
    label: 'Maybe',
    emoji: '🥺',
    order: 1,
  );

  static const defaultCantGo = RsvpOption(
    id: 'cant_go',
    label: "Can't Go",
    emoji: '😢',
    order: 2,
  );

  static List<RsvpOption> get defaults => [
        defaultGoing,
        defaultMaybe,
        defaultCantGo,
      ];

  @override
  List<Object?> get props => [id, label, emoji, order];
}

/// Event link types (playlist, registry, dress code, etc.)
class EventLink extends Equatable {
  const EventLink({
    required this.id,
    required this.type,
    this.label,
    required this.url,
  });
  final String id;
  final EventLinkType type;
  final String? label;
  final String url;

  @override
  List<Object?> get props => [id, type, url];
}

enum EventLinkType {
  link,
  playlist,
  registry,
  dressCode,
  custom;

  String get label {
    switch (this) {
      case EventLinkType.link:
        return 'Link';
      case EventLinkType.playlist:
        return 'Playlist';
      case EventLinkType.registry:
        return 'Registry';
      case EventLinkType.dressCode:
        return 'Dress Code';
      case EventLinkType.custom:
        return 'Custom';
    }
  }

  String get icon {
    switch (this) {
      case EventLinkType.link:
        return '🔗';
      case EventLinkType.playlist:
        return '🎵';
      case EventLinkType.registry:
        return '🎁';
      case EventLinkType.dressCode:
        return '👔';
      case EventLinkType.custom:
        return '📎';
    }
  }
}

/// Co-host information
class EventCoHost extends Equatable {
  const EventCoHost({
    required this.id,
    required this.userId,
    required this.name,
    this.avatarUrl,
    this.nickname,
    this.role,
    this.canEdit = true,
    this.canInvite = true,
    this.canManageRsvps = true,
  });
  final String id;
  final String userId;
  final String name;
  final String? avatarUrl;
  final String? nickname;
  final String? role; // 'pending', 'accepted', 'declined'
  final bool canEdit;
  final bool canInvite;
  final bool canManageRsvps;

  bool get isAccepted => role == 'accepted';
  bool get isPending => role == 'pending' || role == null;

  @override
  List<Object?> get props => [id, userId, name];
}

/// User's relationship to an event
enum UserEventStatus {
  invited,
  going,
  maybe,
  cantGo,
  hosting,
  cohosting,
  none;

  String get label {
    switch (this) {
      case UserEventStatus.invited:
        return 'INVITED';
      case UserEventStatus.going:
        return 'GOING';
      case UserEventStatus.maybe:
        return 'MAYBE';
      case UserEventStatus.cantGo:
        return "CAN'T GO";
      case UserEventStatus.hosting:
        return 'HOSTING';
      case UserEventStatus.cohosting:
        return 'CO-HOSTING';
      case UserEventStatus.none:
        return '';
    }
  }

  String get emoji {
    switch (this) {
      case UserEventStatus.invited:
        return '💌';
      case UserEventStatus.going:
        return '👍';
      case UserEventStatus.maybe:
        return '🤔';
      case UserEventStatus.cantGo:
        return '😢';
      case UserEventStatus.hosting:
        return '👑';
      case UserEventStatus.cohosting:
        return '🎭';
      case UserEventStatus.none:
        return '';
    }
  }
}

/// Event visibility
enum EventVisibility {
  private,
  public,
  friends,
  openInvite;

  String get label {
    switch (this) {
      case EventVisibility.private:
        return 'Private';
      case EventVisibility.public:
        return 'Public';
      case EventVisibility.friends:
        return 'Friends Only';
      case EventVisibility.openInvite:
        return 'Open Invite';
    }
  }

  String get description {
    switch (this) {
      case EventVisibility.private:
        return 'Only people you invite can see this';
      case EventVisibility.public:
        return 'Anyone on Kult can discover this';
      case EventVisibility.friends:
        return 'Only your friends/matches can see this';
      case EventVisibility.openInvite:
        return 'Guests can invite their friends';
    }
  }
}

/// Enhanced event model - Partiful-style
class VesparaEvent extends Equatable {
  const VesparaEvent({
    required this.id,
    required this.hostId,
    required this.hostName,
    this.hostAvatarUrl,
    this.hostNickname,
    this.coHosts = const [],
    required this.title,
    this.titleStyle = EventTitleStyle.classic,
    this.description,
    this.coverImageUrl,
    this.coverTheme,
    this.coverEffect,
    required this.startTime,
    this.endTime,
    this.hasDatePoll = false,
    this.pollOptions,
    this.venueName,
    this.venueAddress,
    this.venueLat,
    this.venueLng,
    this.isVirtual = false,
    this.virtualLink,
    this.maxSpots,
    this.currentAttendees = 0,
    this.costPerPerson,
    this.costCurrency = 'USD',
    this.links = const [],
    this.rsvpOptions = const [],
    this.requiresApproval = false,
    this.collectGuestInfo = false,
    this.sendReminders = true,
    this.reminderHoursBefore = 24,
    this.visibility = EventVisibility.private,
    this.contentRating = 'PG',
    this.ageRestriction = 18,
    this.sections = const [],
    this.rsvps = const [],
    required this.createdAt,
    this.updatedAt,
    this.isDraft = false,
  });
  final String id;
  final String hostId;
  final String hostName;
  final String? hostAvatarUrl;
  final String? hostNickname;
  final List<EventCoHost> coHosts;

  // Title & styling
  final String title;
  final EventTitleStyle titleStyle;
  final String? description;

  // Cover image
  final String? coverImageUrl;
  final String? coverTheme;
  final String? coverEffect;

  // Date & time
  final DateTime startTime;
  final DateTime? endTime;
  final bool hasDatePoll;
  final List<DateTime>? pollOptions;

  // Location
  final String? venueName;
  final String? venueAddress;
  final double? venueLat;
  final double? venueLng;
  final bool isVirtual;
  final String? virtualLink;

  // Capacity & cost
  final int? maxSpots;
  final int currentAttendees;
  final double? costPerPerson;
  final String? costCurrency;

  // Links
  final List<EventLink> links;

  // RSVP settings
  final List<RsvpOption> rsvpOptions;
  final bool requiresApproval;
  final bool collectGuestInfo;
  final bool sendReminders;
  final int? reminderHoursBefore;

  // Visibility
  final EventVisibility visibility;

  // Content rating
  final String contentRating; // PG, flirty, spicy, explicit
  final int ageRestriction;

  // Sections (additional content blocks)
  final List<EventSection> sections;

  // Guest responses
  final List<EventRsvp> rsvps;

  // Metadata
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isDraft;

  /// Spots remaining
  int? get spotsRemaining {
    if (maxSpots == null) return null;
    return maxSpots! - currentAttendees;
  }

  /// Is event full
  bool get isFull {
    if (maxSpots == null) return false;
    return currentAttendees >= maxSpots!;
  }

  /// Count of guests going
  int get goingCount => rsvps.where((r) => r.status == 'going').length;

  /// Count of guests maybe
  int get maybeCount => rsvps.where((r) => r.status == 'maybe').length;

  /// Count of invites pending
  int get pendingCount => rsvps.where((r) => r.status == 'invited').length;

  /// Is event in the past
  bool get isPast => startTime.isBefore(DateTime.now());

  /// Is event today
  bool get isToday {
    final now = DateTime.now();
    return startTime.year == now.year &&
        startTime.month == now.month &&
        startTime.day == now.day;
  }

  /// Is event tomorrow
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return startTime.year == tomorrow.year &&
        startTime.month == tomorrow.month &&
        startTime.day == tomorrow.day;
  }

  /// Formatted date label (Today, Tomorrow, Thu, Next Fri, etc.)
  String get dateLabel {
    final now = DateTime.now();
    final diff = startTime.difference(now);

    if (isToday) return 'Today';
    if (isTomorrow) return 'Tomorrow';
    if (diff.inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[startTime.weekday - 1];
    }
    if (diff.inDays < 14) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return 'Next ${days[startTime.weekday - 1]}';
    }
    // Format as "Sat 1/24"
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[startTime.weekday - 1]} ${startTime.month}/${startTime.day}';
  }

  /// Formatted time
  String get timeLabel {
    final hour = startTime.hour > 12
        ? startTime.hour - 12
        : (startTime.hour == 0 ? 12 : startTime.hour);
    final period = startTime.hour >= 12 ? 'pm' : 'am';
    final minutes = startTime.minute > 0
        ? ':${startTime.minute.toString().padLeft(2, '0')}'
        : '';
    return '$hour$minutes$period';
  }

  /// Combined date + time label for card display
  String get dateTimeLabel => '$dateLabel · $timeLabel';

  /// Copy with
  VesparaEvent copyWith({
    String? id,
    String? hostId,
    String? hostName,
    String? hostAvatarUrl,
    String? hostNickname,
    List<EventCoHost>? coHosts,
    String? title,
    EventTitleStyle? titleStyle,
    String? description,
    String? coverImageUrl,
    String? coverTheme,
    String? coverEffect,
    DateTime? startTime,
    DateTime? endTime,
    bool? hasDatePoll,
    List<DateTime>? pollOptions,
    String? venueName,
    String? venueAddress,
    double? venueLat,
    double? venueLng,
    bool? isVirtual,
    String? virtualLink,
    int? maxSpots,
    int? currentAttendees,
    double? costPerPerson,
    String? costCurrency,
    List<EventLink>? links,
    List<RsvpOption>? rsvpOptions,
    bool? requiresApproval,
    bool? collectGuestInfo,
    bool? sendReminders,
    int? reminderHoursBefore,
    EventVisibility? visibility,
    String? contentRating,
    int? ageRestriction,
    List<EventSection>? sections,
    List<EventRsvp>? rsvps,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDraft,
  }) =>
      VesparaEvent(
        id: id ?? this.id,
        hostId: hostId ?? this.hostId,
        hostName: hostName ?? this.hostName,
        hostAvatarUrl: hostAvatarUrl ?? this.hostAvatarUrl,
        hostNickname: hostNickname ?? this.hostNickname,
        coHosts: coHosts ?? this.coHosts,
        title: title ?? this.title,
        titleStyle: titleStyle ?? this.titleStyle,
        description: description ?? this.description,
        coverImageUrl: coverImageUrl ?? this.coverImageUrl,
        coverTheme: coverTheme ?? this.coverTheme,
        coverEffect: coverEffect ?? this.coverEffect,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        hasDatePoll: hasDatePoll ?? this.hasDatePoll,
        pollOptions: pollOptions ?? this.pollOptions,
        venueName: venueName ?? this.venueName,
        venueAddress: venueAddress ?? this.venueAddress,
        venueLat: venueLat ?? this.venueLat,
        venueLng: venueLng ?? this.venueLng,
        isVirtual: isVirtual ?? this.isVirtual,
        virtualLink: virtualLink ?? this.virtualLink,
        maxSpots: maxSpots ?? this.maxSpots,
        currentAttendees: currentAttendees ?? this.currentAttendees,
        costPerPerson: costPerPerson ?? this.costPerPerson,
        costCurrency: costCurrency ?? this.costCurrency,
        links: links ?? this.links,
        rsvpOptions: rsvpOptions ?? this.rsvpOptions,
        requiresApproval: requiresApproval ?? this.requiresApproval,
        collectGuestInfo: collectGuestInfo ?? this.collectGuestInfo,
        sendReminders: sendReminders ?? this.sendReminders,
        reminderHoursBefore: reminderHoursBefore ?? this.reminderHoursBefore,
        visibility: visibility ?? this.visibility,
        contentRating: contentRating ?? this.contentRating,
        ageRestriction: ageRestriction ?? this.ageRestriction,
        sections: sections ?? this.sections,
        rsvps: rsvps ?? this.rsvps,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        isDraft: isDraft ?? this.isDraft,
      );

  @override
  List<Object?> get props => [id, title, startTime, hostId];
}

/// Event section - additional content blocks
class EventSection extends Equatable {
  const EventSection({
    required this.id,
    required this.title,
    required this.content,
    required this.order,
  });
  final String id;
  final String title;
  final String content;
  final int order;

  @override
  List<Object?> get props => [id, title, order];
}

/// Event RSVP response
class EventRsvp extends Equatable {
  const EventRsvp({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.status,
    this.message,
    this.guestInfo,
    required this.createdAt,
    this.respondedAt,
  });
  final String id;
  final String eventId;
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final String status; // invited, going, maybe, cant_go
  final String? message;
  final Map<String, dynamic>? guestInfo;
  final DateTime createdAt;
  final DateTime? respondedAt;

  @override
  List<Object?> get props => [id, eventId, userId, status];
}
