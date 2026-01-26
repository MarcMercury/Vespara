import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/models/vespara_event.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/events_provider.dart';
import '../../../core/theme/app_theme.dart';
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

  String get _userName {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    return profile?.displayName ?? 'Friend';
  }

  List<VesparaEvent> get _allEvents => ref.watch(allVesparaEventsProvider);

  List<VesparaEvent> get _filteredEvents {
    final now = DateTime.now();
    final events = _allEvents;
    switch (_selectedFilter) {
      case 'Upcoming':
        return events
            .where((e) => e.startTime.isAfter(now) && !e.isDraft)
            .toList();
      case 'Invites':
        return events
            .where(
              (e) => e.rsvps.any(
                  (r) => r.userId == 'current-user' && r.status == 'invited'),
            )
            .toList();
      case 'Hosting':
        return events.where((e) => e.hostId == 'current-user').toList();
      case 'Open invite':
        return events
            .where((e) => e.visibility == EventVisibility.openInvite)
            .toList();
      case 'Attended':
        return events
            .where(
              (e) =>
                  e.isPast &&
                  e.rsvps.any(
                      (r) => r.userId == 'current-user' && r.status == 'going'),
            )
            .toList();
      case 'All past events':
        return events.where((e) => e.isPast).toList();
      default:
        return events;
    }
  }

  // Get counts for filter badges
  int get _upcomingCount => _allEvents
      .where((e) => e.startTime.isAfter(DateTime.now()) && !e.isDraft)
      .length;
  int get _invitesCount => _allEvents
      .where(
        (e) => e.rsvps
            .any((r) => r.userId == 'current-user' && r.status == 'invited'),
      )
      .length;
  int get _hostingCount =>
      _allEvents.where((e) => e.hostId == 'current-user').length;
  int get _attendedCount => _allEvents
      .where(
        (e) =>
            e.isPast &&
            e.rsvps
                .any((r) => r.userId == 'current-user' && r.status == 'going'),
      )
      .length;
  int get _pastCount => _allEvents.where((e) => e.isPast).length;

  @override
  Widget build(BuildContext context) => Scaffold(
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
          icon: const Icon(Icons.add, color: VesparaColors.background),
          label: const Text(
            'Create Experience',
            style: TextStyle(
              color: VesparaColors.background,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );

  Widget _buildHeader() => Container(
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
                  icon: const Icon(Icons.arrow_back,
                      color: VesparaColors.primary),
                ),
                IconButton(
                  onPressed: _showSearch,
                  icon: const Icon(Icons.search, color: VesparaColors.primary),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Welcome message
            Text(
              'Welcome back $_userName!',
              style: const TextStyle(
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
                style: const TextStyle(
                  fontSize: 16,
                  color: VesparaColors.secondary,
                ),
                children: [
                  const TextSpan(text: 'You have '),
                  TextSpan(
                    text: '$_upcomingCount upcoming experiences',
                    style: const TextStyle(
                      color: VesparaColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: '$_invitesCount invites waiting',
                    style: const TextStyle(
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

  Widget _buildFilterBar() {
    final filters = [
      ('Search', null, Icons.search),
      ('Upcoming', _upcomingCount, null),
      ('Invites', _invitesCount, null),
      ('Hosting', _hostingCount, null),
      ('Open invite', null, null),
      ('Attended', _attendedCount, null),
      ('All past', _pastCount, null),
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
                color:
                    isSelected ? VesparaColors.primary : VesparaColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      isSelected ? VesparaColors.primary : VesparaColors.border,
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
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
                        decoration: const BoxDecoration(
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
              decoration: const BoxDecoration(
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
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: VesparaColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
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
                label: const Text('Create Experience'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: VesparaColors.glow,
                  foregroundColor: VesparaColors.background,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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

  Future<void> _createEvent() async {
    final result = await Navigator.push<VesparaEvent>(
      context,
      MaterialPageRoute(
        builder: (context) => const EventCreationScreen(),
      ),
    );

    // If an event was created, refresh the list
    if (result != null) {
      // The provider already has the event, just trigger rebuild
      setState(() {});
    }
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
        decoration: const BoxDecoration(
          color: VesparaColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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

  Widget _buildOptionTile(IconData icon, String label, VoidCallback onTap,
          {bool isDestructive = false}) =>
      ListTile(
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

/// Search delegate for events
class EventSearchDelegate extends SearchDelegate<VesparaEvent?> {
  EventSearchDelegate(this.events);
  final List<VesparaEvent> events;

  @override
  ThemeData appBarTheme(BuildContext context) => Theme.of(context).copyWith(
        appBarTheme: const AppBarTheme(
          backgroundColor: VesparaColors.surface,
          foregroundColor: VesparaColors.primary,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          hintStyle: TextStyle(color: VesparaColors.secondary),
        ),
      );

  @override
  List<Widget> buildActions(BuildContext context) => [
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) => _buildSearchResults();

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchResults();

  Widget _buildSearchResults() {
    final results = events
        .where(
          (e) =>
              e.title.toLowerCase().contains(query.toLowerCase()) ||
              (e.description?.toLowerCase().contains(query.toLowerCase()) ??
                  false) ||
              e.hostName.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();

    return ColoredBox(
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
              style: const TextStyle(color: VesparaColors.primary),
            ),
            subtitle: Text(
              '${event.dateTimeLabel} · ${event.hostName}',
              style: const TextStyle(color: VesparaColors.secondary),
            ),
            onTap: () => close(context, event),
          );
        },
      ),
    );
  }

  Widget _buildPlaceholder() => Container(
        width: 56,
        height: 56,
        color: VesparaColors.surface,
        child: Icon(Icons.event, color: VesparaColors.glow.withOpacity(0.5)),
      );
}
