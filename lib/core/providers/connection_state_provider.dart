import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// CONNECTION STATE PROVIDER
/// Manages user connections, QR code linking, and event-based connections
/// ════════════════════════════════════════════════════════════════════════════

/// Connection between two users
class UserConnection {
  // For connection requests

  const UserConnection({
    required this.id,
    required this.userId,
    required this.connectedUserId,
    this.connectedUserName,
    this.connectedUserAvatar,
    this.type = ConnectionType.qrCode,
    this.eventId,
    this.eventName,
    required this.connectedAt,
    this.isPending = false,
  });
  final String id;
  final String userId;
  final String connectedUserId;
  final String? connectedUserName;
  final String? connectedUserAvatar;
  final ConnectionType type;
  final String? eventId; // If connected at an event
  final String? eventName;
  final DateTime connectedAt;
  final bool isPending;
}

enum ConnectionType {
  qrCode, // Scanned QR code in person
  event, // Met at an event
  match, // Matched via swiping
  mutual, // Mutual friends introduced
}

/// Event with attendee tracking
class VesparaEvent {
  const VesparaEvent({
    required this.id,
    required this.hostId,
    required this.hostName,
    this.hostAvatar,
    required this.title,
    this.description,
    this.coverImageUrl,
    this.venue,
    this.address,
    required this.startTime,
    this.endTime,
    this.isPublic = true,
    this.maxAttendees,
    this.attendees = const [],
    required this.createdAt,
  });
  final String id;
  final String hostId;
  final String hostName;
  final String? hostAvatar;
  final String title;
  final String? description;
  final String? coverImageUrl;
  final String? venue;
  final String? address;
  final DateTime startTime;
  final DateTime? endTime;
  final bool isPublic;
  final int? maxAttendees;
  final List<EventAttendee> attendees;
  final DateTime createdAt;

  bool get isPast => DateTime.now()
      .isAfter(endTime ?? startTime.add(const Duration(hours: 3)));
  bool get isUpcoming => !isPast;
  int get attendeeCount => attendees.length;
  bool get isFull => maxAttendees != null && attendeeCount >= maxAttendees!;
}

class EventAttendee {
  const EventAttendee({
    required this.userId,
    required this.name,
    this.avatar,
    this.status = AttendeeStatus.going,
    required this.joinedAt,
  });
  final String userId;
  final String name;
  final String? avatar;
  final AttendeeStatus status;
  final DateTime joinedAt;
}

enum AttendeeStatus { going, maybe, invited }

/// Connection state for event attendees and instant connections
class VesparaConnectionState {
  const VesparaConnectionState({
    this.connections = const [],
    this.events = const [],
    this.connectedUserIds = const {},
    this.myQrCode,
    this.isScanning = false,
  });
  final List<UserConnection> connections;
  final List<VesparaEvent> events;
  final Set<String> connectedUserIds;
  final String? myQrCode;
  final bool isScanning;

  VesparaConnectionState copyWith({
    List<UserConnection>? connections,
    List<VesparaEvent>? events,
    Set<String>? connectedUserIds,
    String? myQrCode,
    bool? isScanning,
  }) =>
      VesparaConnectionState(
        connections: connections ?? this.connections,
        events: events ?? this.events,
        connectedUserIds: connectedUserIds ?? this.connectedUserIds,
        myQrCode: myQrCode ?? this.myQrCode,
        isScanning: isScanning ?? this.isScanning,
      );

  /// Get people from past events I'm not connected to
  List<EventAttendee> getUnconnectedEventAttendees(String myUserId) {
    final Set<String> seen = {};
    final List<EventAttendee> result = [];

    for (final event in events.where((e) => e.isPast)) {
      for (final attendee in event.attendees) {
        if (attendee.userId != myUserId &&
            !connectedUserIds.contains(attendee.userId) &&
            !seen.contains(attendee.userId)) {
          seen.add(attendee.userId);
          result.add(attendee);
        }
      }
    }
    return result;
  }

  /// Get public upcoming events
  List<VesparaEvent> get publicUpcomingEvents =>
      events.where((e) => e.isPublic && e.isUpcoming).toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));

  /// Get my events (hosted + attending)
  List<VesparaEvent> getMyEvents(String myUserId) => events
      .where(
        (e) =>
            e.hostId == myUserId ||
            e.attendees.any((a) => a.userId == myUserId),
      )
      .toList()
    ..sort((a, b) => a.startTime.compareTo(b.startTime));
}

/// Connection state notifier
class ConnectionStateNotifier extends StateNotifier<VesparaConnectionState> {
  ConnectionStateNotifier() : super(_initialState());

  static const String _primaryConnectScheme = 'kult';

  static VesparaConnectionState _initialState() {
    // Start with empty state - data will be loaded from database
    return const VesparaConnectionState();
  }

  /// Generate QR code data for my profile
  String generateMyQrCode(String userId, String displayName) {
    // In production, this would be encrypted/signed
    final qrData = '$_primaryConnectScheme://connect/$userId/$displayName';
    state = state.copyWith(myQrCode: qrData);
    return qrData;
  }

  /// Connect via QR code scan
  void connectViaQr(String scannedUserId, String? userName, String? avatar) {
    if (state.connectedUserIds.contains(scannedUserId)) {
      return; // Already connected
    }

    final newConnection = UserConnection(
      id: 'conn-${DateTime.now().millisecondsSinceEpoch}',
      userId: 'current-user',
      connectedUserId: scannedUserId,
      connectedUserName: userName,
      connectedUserAvatar: avatar,
      connectedAt: DateTime.now(),
    );

    state = state.copyWith(
      connections: [...state.connections, newConnection],
      connectedUserIds: {...state.connectedUserIds, scannedUserId},
    );
  }

  /// Connect via event (swipe on event attendee)
  void connectViaEvent(String userId, String? userName, String? avatar,
      String eventId, String? eventName,) {
    if (state.connectedUserIds.contains(userId)) return;

    final newConnection = UserConnection(
      id: 'conn-${DateTime.now().millisecondsSinceEpoch}',
      userId: 'current-user',
      connectedUserId: userId,
      connectedUserName: userName,
      connectedUserAvatar: avatar,
      type: ConnectionType.event,
      eventId: eventId,
      eventName: eventName,
      connectedAt: DateTime.now(),
    );

    state = state.copyWith(
      connections: [...state.connections, newConnection],
      connectedUserIds: {...state.connectedUserIds, userId},
    );
  }

  /// RSVP to an event
  void rsvpToEvent(String eventId, String userId, String userName) {
    final updatedEvents = state.events.map((e) {
      if (e.id == eventId) {
        final newAttendee = EventAttendee(
          userId: userId,
          name: userName,
          joinedAt: DateTime.now(),
        );
        return VesparaEvent(
          id: e.id,
          hostId: e.hostId,
          hostName: e.hostName,
          hostAvatar: e.hostAvatar,
          title: e.title,
          description: e.description,
          coverImageUrl: e.coverImageUrl,
          venue: e.venue,
          address: e.address,
          startTime: e.startTime,
          endTime: e.endTime,
          isPublic: e.isPublic,
          maxAttendees: e.maxAttendees,
          attendees: [...e.attendees, newAttendee],
          createdAt: e.createdAt,
        );
      }
      return e;
    }).toList();

    state = state.copyWith(events: updatedEvents);
  }

  /// Create a new event
  void createEvent({
    required String title,
    String? description,
    String? venue,
    String? address,
    required DateTime startTime,
    DateTime? endTime,
    required bool isPublic,
    int? maxAttendees,
  }) {
    final newEvent = VesparaEvent(
      id: 'event-${DateTime.now().millisecondsSinceEpoch}',
      hostId: 'current-user',
      hostName: 'You',
      title: title,
      description: description,
      venue: venue,
      address: address,
      startTime: startTime,
      endTime: endTime,
      isPublic: isPublic,
      maxAttendees: maxAttendees,
      attendees: [],
      createdAt: DateTime.now(),
    );

    state = state.copyWith(events: [...state.events, newEvent]);
  }

  void setScanning(bool scanning) {
    state = state.copyWith(isScanning: scanning);
  }
}

/// Providers
final connectionStateProvider =
    StateNotifierProvider<ConnectionStateNotifier, VesparaConnectionState>(
        (ref) => ConnectionStateNotifier(),);

final publicEventsProvider = Provider<List<VesparaEvent>>((ref) {
  final state = ref.watch(connectionStateProvider);
  return state.publicUpcomingEvents;
});

final metAtEventsProvider = Provider<List<EventAttendee>>((ref) {
  final state = ref.watch(connectionStateProvider);
  return state.getUnconnectedEventAttendees('current-user');
});
