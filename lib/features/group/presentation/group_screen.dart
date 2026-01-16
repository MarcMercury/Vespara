import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/data/vespara_mock_data.dart';
import '../../../core/domain/models/events.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// GROUP STUFF - Module 6
/// Eventbrite/Partiful style event planning for group activities
/// Multi-person events, invites, RSVP tracking
/// ════════════════════════════════════════════════════════════════════════════

class GroupScreen extends ConsumerStatefulWidget {
  const GroupScreen({super.key});

  @override
  ConsumerState<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends ConsumerState<GroupScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<GroupEvent> _events;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _events = MockDataProvider.groupEvents;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VesparaColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildUpcomingEvents(),
                  _buildMyEvents(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateEvent,
        backgroundColor: VesparaColors.glow,
        icon: Icon(Icons.add, color: VesparaColors.background),
        label: Text(
          'Create Event',
          style: TextStyle(color: VesparaColors.background, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: VesparaColors.primary),
          ),
          Column(
            children: [
              Text(
                'GROUP STUFF',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 4,
                  color: VesparaColors.primary,
                ),
              ),
              Text(
                '${_events.length} events',
                style: TextStyle(
                  fontSize: 12,
                  color: VesparaColors.secondary,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined, color: VesparaColors.secondary),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: VesparaColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: VesparaColors.glow,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: VesparaColors.background,
        unselectedLabelColor: VesparaColors.secondary,
        labelStyle: TextStyle(fontWeight: FontWeight.w600),
        dividerHeight: 0,
        tabs: [
          Tab(text: 'Upcoming'),
          Tab(text: 'My Events'),
        ],
      ),
    );
  }

  Widget _buildUpcomingEvents() {
    final upcoming = _events.where((e) => e.startTime.isAfter(DateTime.now())).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    
    if (upcoming.isEmpty) {
      return _buildEmptyState(
        'No Upcoming Events',
        'Create an event to invite your roster',
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: upcoming.length,
      itemBuilder: (context, index) => _buildEventCard(upcoming[index]),
    );
  }

  Widget _buildMyEvents() {
    final myEvents = _events.where((e) => e.hostId == 'demo-user-001').toList();
    
    if (myEvents.isEmpty) {
      return _buildEmptyState(
        'No Events Yet',
        'You haven\'t created any events',
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: myEvents.length,
      itemBuilder: (context, index) => _buildEventCard(myEvents[index], isHost: true),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.celebration,
            size: 80,
            color: VesparaColors.glow.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: VesparaColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: VesparaColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(GroupEvent event, {bool isHost = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: VesparaColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: VesparaColors.glow.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover image
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  VesparaColors.glow.withOpacity(0.4),
                  VesparaColors.surface,
                ],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    _getEventIcon(event.eventType),
                    size: 60,
                    color: VesparaColors.primary.withOpacity(0.5),
                  ),
                ),
                // Date badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: VesparaColors.background.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          event.startTime.day.toString(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: VesparaColors.glow,
                          ),
                        ),
                        Text(
                          _getMonthAbbr(event.startTime.month),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: VesparaColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Content rating
                if (event.contentRating != 'PG')
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: VesparaColors.warning.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        event.contentRating,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: VesparaColors.background,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: VesparaColors.primary,
                        ),
                      ),
                    ),
                    if (isHost)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: VesparaColors.glow.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'HOST',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: VesparaColors.glow,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  event.description ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: VesparaColors.secondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: VesparaColors.secondary),
                    const SizedBox(width: 4),
                    Text(
                      _formatEventTime(event.startTime),
                      style: TextStyle(
                        fontSize: 12,
                        color: VesparaColors.secondary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.location_on, size: 14, color: VesparaColors.secondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event.venueAddress ?? 'Location TBD',
                        style: TextStyle(
                          fontSize: 12,
                          color: VesparaColors.secondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Invites summary
                _buildInvitesSummary(event),
                
                const SizedBox(height: 16),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          foregroundColor: VesparaColors.glow,
                          side: BorderSide(color: VesparaColors.glow),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(isHost ? 'Manage' : 'Details'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: VesparaColors.glow,
                          foregroundColor: VesparaColors.background,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(isHost ? 'Invite' : 'RSVP'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvitesSummary(GroupEvent event) {
    final going = event.invites.where((i) => i.status == InviteStatus.accepted).length;
    final maybe = event.invites.where((i) => i.status == InviteStatus.maybe).length;
    final pending = event.invites.where((i) => i.status == InviteStatus.pending).length;
    
    return Row(
      children: [
        _buildInviteChip('$going Going', VesparaColors.success),
        const SizedBox(width: 8),
        _buildInviteChip('$maybe Maybe', VesparaColors.tagsYellow),
        const SizedBox(width: 8),
        _buildInviteChip('$pending Pending', VesparaColors.secondary),
      ],
    );
  }

  Widget _buildInviteChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  IconData _getEventIcon(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'party':
        return Icons.celebration;
      case 'dinner':
        return Icons.restaurant;
      case 'trip':
        return Icons.flight;
      case 'adventure':
        return Icons.terrain;
      default:
        return Icons.event;
    }
  }

  String _getMonthAbbr(int month) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 
                   'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return months[month - 1];
  }

  String _formatEventTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${dateTime.minute.toString().padLeft(2, '0')} $period';
  }

  void _showCreateEvent() {
    showModalBottomSheet(
      context: context,
      backgroundColor: VesparaColors.surface,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: VesparaColors.secondary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Create Group Event',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: VesparaColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Invite people from your roster to something fun',
                style: TextStyle(
                  fontSize: 14,
                  color: VesparaColors.secondary,
                ),
              ),
              const SizedBox(height: 24),
              _buildEventTypeOption(
                'Dinner Party',
                'Host an intimate gathering',
                Icons.restaurant,
              ),
              _buildEventTypeOption(
                'Night Out',
                'Clubs, bars, dancing',
                Icons.nightlife,
              ),
              _buildEventTypeOption(
                'Adventure',
                'Something exciting and new',
                Icons.explore,
              ),
              _buildEventTypeOption(
                'Chill Hangout',
                'Low-key vibes only',
                Icons.weekend,
              ),
              _buildEventTypeOption(
                'Custom',
                'Plan something unique',
                Icons.edit,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventTypeOption(String title, String subtitle, IconData icon) {
    return ListTile(
      onTap: () => Navigator.pop(context),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: VesparaColors.glow.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: VesparaColors.glow),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: VesparaColors.primary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: VesparaColors.secondary),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: VesparaColors.secondary,
      ),
    );
  }
}
