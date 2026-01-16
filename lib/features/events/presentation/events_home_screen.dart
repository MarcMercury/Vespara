import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/domain/models/vespara_event.dart';
import '../widgets/event_tile_card.dart';
import 'event_creation_screen.dart';
import 'event_detail_screen.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// EVENTS HOME - Partiful-Style Events Dashboard
/// Beautiful tile-based layout with filters and personalized welcome
/// ════════════════════════════════════════════════════════════════════════════

class EventsHomeScreen extends ConsumerStatefulWidget {
  const EventsHomeScreen({super.key});

  @override
  ConsumerState<EventsHomeScreen> createState() => _EventsHomeScreenState();
}

class _EventsHomeScreenState extends ConsumerState<EventsHomeScreen> {
  String _selectedFilter = 'Upcoming';
  final String _userName = 'Marc'; // Would come from auth provider
  
  // Mock data - would come from provider
  late List<VesparaEvent> _allEvents;
  
  @override
  void initState() {
    super.initState();
    _allEvents = _getMockEvents();
  }

  List<VesparaEvent> get _filteredEvents {
    final now = DateTime.now();
    switch (_selectedFilter) {
      case 'Upcoming':
        return _allEvents.where((e) => e.startTime.isAfter(now) && !e.isDraft).toList();
      case 'Invites':
        return _allEvents.where((e) => 
          e.rsvps.any((r) => r.userId == 'current-user' && r.status == 'invited')
        ).toList();
      case 'Hosting':
        return _allEvents.where((e) => e.hostId == 'current-user').toList();
      case 'Open invite':
        return _allEvents.where((e) => e.visibility == EventVisibility.openInvite).toList();
      case 'Attended':
        return _allEvents.where((e) => 
          e.isPast && e.rsvps.any((r) => r.userId == 'current-user' && r.status == 'going')
        ).toList();
      case 'All past events':
        return _allEvents.where((e) => e.isPast).toList();
      default:
        return _allEvents;
    }
  }

  // Get counts for filter badges
  int get _upcomingCount => _allEvents.where((e) => e.startTime.isAfter(DateTime.now()) && !e.isDraft).length;
  int get _invitesCount => _allEvents.where((e) => 
    e.rsvps.any((r) => r.userId == 'current-user' && r.status == 'invited')).length;
  int get _hostingCount => _allEvents.where((e) => e.hostId == 'current-user').length;
  int get _attendedCount => _allEvents.where((e) => 
    e.isPast && e.rsvps.any((r) => r.userId == 'current-user' && r.status == 'going')).length;
  int get _pastCount => _allEvents.where((e) => e.isPast).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VesparaColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Welcome header with gradient
            SliverToBoxAdapter(child: _buildHeader()),
            
            // Filter chips
            SliverToBoxAdapter(child: _buildFilterBar()),
            
            // Event grid
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: _buildEventGrid(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createEvent,
        backgroundColor: VesparaColors.glow,
        icon: Icon(Icons.add, color: VesparaColors.background),
        label: Text(
          'Create Event',
          style: TextStyle(
            color: VesparaColors.background,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF2D1B4E), // Deep purple
            const Color(0xFF1A1523).withOpacity(0.8),
            VesparaColors.background,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button and search
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back, color: VesparaColors.primary),
              ),
              IconButton(
                onPressed: _showSearch,
                icon: Icon(Icons.search, color: VesparaColors.primary),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Welcome message
          Text(
            'Welcome back $_userName!',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w300,
              fontStyle: FontStyle.italic,
              color: VesparaColors.primary,
              letterSpacing: 0.5,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Stats summary
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 16,
                color: VesparaColors.secondary,
              ),
              children: [
                const TextSpan(text: 'You have '),
                TextSpan(
                  text: '$_upcomingCount upcoming events',
                  style: TextStyle(
                    color: VesparaColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const TextSpan(text: ' and '),
                TextSpan(
                  text: '$_invitesCount invites waiting',
                  style: TextStyle(
                    color: VesparaColors.glow,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final filters = [
      ('Search', null, Icons.search),
      ('Upcoming', _upcomingCount, null),
      ('Invites', _invitesCount, null),
      ('Hosting', _hostingCount, null),
      ('Open invite', null, null),
      ('Attended', _attendedCount, null),
      ('All past events', _pastCount, null),
    ];

    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (label, count, icon) = filters[index];
          final isSelected = _selectedFilter == label;
          final isSearch = label == 'Search';
          final hasNotification = label == 'Invites' && (count ?? 0) > 0;
          
          return GestureDetector(
            onTap: () {
              if (isSearch) {
                _showSearch();
              } else {
                setState(() => _selectedFilter = label);
              }
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSearch ? 12 : 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: isSelected 
                    ? VesparaColors.primary 
                    : VesparaColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected 
                      ? VesparaColors.primary 
                      : VesparaColors.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 18,
                      color: isSelected 
                          ? VesparaColors.background 
                          : VesparaColors.primary,
                    ),
                    if (!isSearch) const SizedBox(width: 6),
                  ],
                  if (!isSearch) ...[
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isSelected 
                            ? VesparaColors.background 
                            : VesparaColors.primary,
                      ),
                    ),
                    if (count != null && count > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? VesparaColors.background.withOpacity(0.2) 
                              : VesparaColors.glow.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          count.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected 
                                ? VesparaColors.background 
                                : VesparaColors.glow,
                          ),
                        ),
                      ),
                    ],
                    if (hasNotification)
                      Container(
                        margin: const EdgeInsets.only(left: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: VesparaColors.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEventGrid() {
    final events = _filteredEvents;
    
    if (events.isEmpty) {
      return SliverToBoxAdapter(
        child: _buildEmptyState(),
      );
    }

    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final event = events[index];
          return EventTileCard(
            event: event,
            currentUserId: 'current-user',
            onTap: () => _openEvent(event),
            onMoreTap: () => _showEventOptions(event),
          );
        },
        childCount: events.length,
      ),
    );
  }

  Widget _buildEmptyState() {
    String title;
    String subtitle;
    IconData icon;
    
    switch (_selectedFilter) {
      case 'Invites':
        title = 'No pending invites';
        subtitle = 'When someone invites you, it\'ll show up here';
        icon = Icons.mail_outline;
        break;
      case 'Hosting':
        title = 'You\'re not hosting anything yet';
        subtitle = 'Create your first event!';
        icon = Icons.celebration_outlined;
        break;
      case 'Attended':
        title = 'No past events';
        subtitle = 'Events you\'ve attended will appear here';
        icon = Icons.history;
        break;
      default:
        title = 'No events found';
        subtitle = 'Create an event or wait for invites';
        icon = Icons.event_busy;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: VesparaColors.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: VesparaColors.glow.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: VesparaColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: VesparaColors.secondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (_selectedFilter == 'Hosting') ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _createEvent,
                icon: const Icon(Icons.add),
                label: const Text('Create Event'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: VesparaColors.glow,
                  foregroundColor: VesparaColors.background,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showSearch() {
    showSearch(
      context: context,
      delegate: EventSearchDelegate(_allEvents),
    );
  }

  void _createEvent() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EventCreationScreen(),
      ),
    );
  }

  void _openEvent(VesparaEvent event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetailScreen(event: event),
      ),
    );
  }

  void _showEventOptions(VesparaEvent event) {
    final isHost = event.hostId == 'current-user';
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: VesparaColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: VesparaColors.secondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            if (isHost) ...[
              _buildOptionTile(
                Icons.edit,
                'Edit Event',
                () => Navigator.pop(context),
              ),
              _buildOptionTile(
                Icons.share,
                'Share Event',
                () => Navigator.pop(context),
              ),
              _buildOptionTile(
                Icons.content_copy,
                'Duplicate Event',
                () => Navigator.pop(context),
              ),
              _buildOptionTile(
                Icons.cancel,
                'Cancel Event',
                () => Navigator.pop(context),
                isDestructive: true,
              ),
            ] else ...[
              _buildOptionTile(
                Icons.share,
                'Share Event',
                () => Navigator.pop(context),
              ),
              _buildOptionTile(
                Icons.calendar_today,
                'Add to Calendar',
                () => Navigator.pop(context),
              ),
              _buildOptionTile(
                Icons.notifications_off,
                'Mute Notifications',
                () => Navigator.pop(context),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(IconData icon, String label, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? VesparaColors.error : VesparaColors.glow,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isDestructive ? VesparaColors.error : VesparaColors.primary,
        ),
      ),
      onTap: onTap,
    );
  }

  List<VesparaEvent> _getMockEvents() {
    final now = DateTime.now();
    return [
      VesparaEvent(
        id: 'event-1',
        hostId: 'sophia-domina',
        hostName: 'Sophia Domina',
        hostAvatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100',
        title: 'Decadence Dinner',
        titleStyle: EventTitleStyle.elegant,
        description: 'A supper for the sinfully curious. Temple of Domina presents an evening of culinary indulgence.',
        coverImageUrl: 'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=600',
        startTime: now.add(const Duration(days: 1, hours: 19)),
        venueName: 'Temple of Domina',
        venueAddress: 'Secret Location',
        visibility: EventVisibility.private,
        contentRating: 'spicy',
        rsvps: [
          EventRsvp(
            id: 'rsvp-1',
            eventId: 'event-1',
            userId: 'current-user',
            userName: 'Marc',
            status: 'invited',
            createdAt: now,
          ),
        ],
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      VesparaEvent(
        id: 'event-2',
        hostId: 'user-2',
        hostName: 'Alex & Jamie',
        title: 'Eat&Learn: Ethiopia',
        description: 'Alternative Book Club meets Ethiopian Restaurant. Discuss literature over authentic cuisine.',
        coverImageUrl: 'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=600',
        startTime: now.add(const Duration(days: 3, hours: 19)),
        venueName: 'Ethiopian Kitchen',
        venueAddress: '456 Cultural Ave',
        visibility: EventVisibility.openInvite,
        contentRating: 'PG',
        rsvps: [
          EventRsvp(
            id: 'rsvp-2',
            eventId: 'event-2',
            userId: 'current-user',
            userName: 'Marc',
            status: 'going',
            createdAt: now,
            respondedAt: now,
          ),
        ],
        createdAt: now.subtract(const Duration(days: 7)),
      ),
      VesparaEvent(
        id: 'event-3',
        hostId: 'user-3',
        hostName: 'Luna & Co',
        title: 'Vision Board Making Night \'26',
        description: 'Dream big! Create your 2026 vision board with friends, wine, and good vibes.',
        coverImageUrl: 'https://images.unsplash.com/photo-1529543544277-750e01f8e4b6?w=600',
        startTime: now.add(const Duration(days: 8, hours: 19)),
        venueName: 'Rooftop Lounge',
        venueAddress: '789 Dream Street',
        visibility: EventVisibility.private,
        contentRating: 'PG',
        maxSpots: 12,
        currentAttendees: 8,
        rsvps: [
          EventRsvp(
            id: 'rsvp-3',
            eventId: 'event-3',
            userId: 'current-user',
            userName: 'Marc',
            status: 'going',
            createdAt: now,
            respondedAt: now,
          ),
        ],
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      VesparaEvent(
        id: 'event-4',
        hostId: 'sophia-domina',
        hostName: 'Sophia Domina',
        hostAvatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100',
        title: 'Sophia Domina\'s Boudoir Soirée',
        titleStyle: EventTitleStyle.fancy,
        description: 'An intimate evening of elegance and mystery. Black tie optional, curiosity required.',
        coverImageUrl: 'https://images.unsplash.com/photo-1533174072545-7a4b6ad7a6c3?w=600',
        startTime: now.add(const Duration(days: 9, hours: 20, minutes: 30)),
        venueName: 'The Velvet Room',
        venueAddress: 'By invitation only',
        visibility: EventVisibility.private,
        contentRating: 'explicit',
        ageRestriction: 21,
        rsvps: [
          EventRsvp(
            id: 'rsvp-4',
            eventId: 'event-4',
            userId: 'current-user',
            userName: 'Marc',
            status: 'invited',
            createdAt: now,
          ),
        ],
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      VesparaEvent(
        id: 'event-5',
        hostId: 'current-user',
        hostName: 'Marc Mercury',
        title: 'Game Night',
        description: 'Board games, card games, and good company. BYOB!',
        coverImageUrl: 'https://images.unsplash.com/photo-1606503153255-59d8b2e4b5cf?w=600',
        startTime: now.add(const Duration(days: 5, hours: 18)),
        venueName: 'My Place',
        venueAddress: '123 Main St',
        visibility: EventVisibility.private,
        contentRating: 'PG',
        maxSpots: 8,
        currentAttendees: 4,
        rsvps: [
          EventRsvp(id: 'r1', eventId: 'event-5', userId: 'u1', userName: 'Alex', status: 'going', createdAt: now),
          EventRsvp(id: 'r2', eventId: 'event-5', userId: 'u2', userName: 'Jordan', status: 'going', createdAt: now),
          EventRsvp(id: 'r3', eventId: 'event-5', userId: 'u3', userName: 'Casey', status: 'maybe', createdAt: now),
          EventRsvp(id: 'r4', eventId: 'event-5', userId: 'u4', userName: 'Morgan', status: 'invited', createdAt: now),
        ],
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      // Past event
      VesparaEvent(
        id: 'event-past-1',
        hostId: 'user-5',
        hostName: 'Wine Club',
        title: 'Holiday Wine Tasting',
        description: 'Seasonal wines from around the world.',
        coverImageUrl: 'https://images.unsplash.com/photo-1510812431401-41d2bd2722f3?w=600',
        startTime: now.subtract(const Duration(days: 14, hours: 18)),
        venueName: 'Vineyard Lounge',
        venueAddress: '999 Wine Lane',
        visibility: EventVisibility.private,
        contentRating: 'PG',
        rsvps: [
          EventRsvp(
            id: 'rsvp-past-1',
            eventId: 'event-past-1',
            userId: 'current-user',
            userName: 'Marc',
            status: 'going',
            createdAt: now.subtract(const Duration(days: 20)),
            respondedAt: now.subtract(const Duration(days: 20)),
          ),
        ],
        createdAt: now.subtract(const Duration(days: 30)),
      ),
    ];
  }
}

/// Search delegate for events
class EventSearchDelegate extends SearchDelegate<VesparaEvent?> {
  final List<VesparaEvent> events;

  EventSearchDelegate(this.events);

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: VesparaColors.surface,
        foregroundColor: VesparaColors.primary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: VesparaColors.secondary),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final results = events.where((e) =>
      e.title.toLowerCase().contains(query.toLowerCase()) ||
      (e.description?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
      e.hostName.toLowerCase().contains(query.toLowerCase())
    ).toList();

    return Container(
      color: VesparaColors.background,
      child: ListView.builder(
        itemCount: results.length,
        itemBuilder: (context, index) {
          final event = results[index];
          return ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: event.coverImageUrl != null
                  ? Image.network(
                      event.coverImageUrl!,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholder(),
                    )
                  : _buildPlaceholder(),
            ),
            title: Text(
              event.title,
              style: TextStyle(color: VesparaColors.primary),
            ),
            subtitle: Text(
              '${event.dateTimeLabel} · ${event.hostName}',
              style: TextStyle(color: VesparaColors.secondary),
            ),
            onTap: () => close(context, event),
          );
        },
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 56,
      height: 56,
      color: VesparaColors.surface,
      child: Icon(Icons.event, color: VesparaColors.glow.withOpacity(0.5)),
    );
  }
}
