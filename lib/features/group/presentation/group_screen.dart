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
            onPressed: () => _showNotificationsDialog(),
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
                        onPressed: () => isHost ? _showManageEventDialog(event) : _showEventDetailsDialog(event),
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
                        onPressed: () => isHost ? _showInviteDialog(event) : _showRSVPDialog(event),
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
      onTap: () => _createEventOfType(title),
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

  void _createEventOfType(String type) {
    Navigator.pop(context);
    final titleController = TextEditingController(text: type == 'Custom' ? '' : 'My $type');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VesparaColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Create $type', style: TextStyle(color: VesparaColors.glow)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                hintText: 'Event name',
                hintStyle: TextStyle(color: VesparaColors.secondary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              style: TextStyle(color: VesparaColors.primary),
            ),
            const SizedBox(height: 12),
            Text('When?', style: TextStyle(color: VesparaColors.secondary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['Tonight', 'Tomorrow', 'This Weekend'].map((time) =>
                ActionChip(
                  label: Text(time),
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${titleController.text} scheduled for $time!'),
                        backgroundColor: VesparaColors.success,
                      ),
                    );
                  },
                  backgroundColor: VesparaColors.glow.withOpacity(0.2),
                  labelStyle: TextStyle(color: VesparaColors.glow),
                ),
              ).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationsDialog() {
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
            Text('Notifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: VesparaColors.primary)),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.person_add, color: VesparaColors.success),
              title: Text('Sarah accepted your invite!', style: TextStyle(color: VesparaColors.primary)),
              subtitle: Text('2 hours ago', style: TextStyle(color: VesparaColors.secondary)),
            ),
            ListTile(
              leading: Icon(Icons.event, color: VesparaColors.glow),
              title: Text('New event: Game Night', style: TextStyle(color: VesparaColors.primary)),
              subtitle: Text('5 hours ago', style: TextStyle(color: VesparaColors.secondary)),
            ),
            ListTile(
              leading: Icon(Icons.question_mark, color: VesparaColors.tagsYellow),
              title: Text('Mark marked "maybe" for Dinner', style: TextStyle(color: VesparaColors.primary)),
              subtitle: Text('Yesterday', style: TextStyle(color: VesparaColors.secondary)),
            ),
          ],
        ),
      ),
    );
  }

  void _showManageEventDialog(GroupEvent event) {
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Manage Event', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: VesparaColors.primary)),
            const SizedBox(height: 8),
            Text(event.title, style: TextStyle(color: VesparaColors.glow)),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.edit, color: VesparaColors.glow),
              title: Text('Edit Details', style: TextStyle(color: VesparaColors.primary)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening event editor...')));
              },
            ),
            ListTile(
              leading: Icon(Icons.share, color: VesparaColors.glow),
              title: Text('Share Event', style: TextStyle(color: VesparaColors.primary)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sharing event link...')));
              },
            ),
            ListTile(
              leading: Icon(Icons.message, color: VesparaColors.glow),
              title: Text('Message Guests', style: TextStyle(color: VesparaColors.primary)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening group chat...')));
              },
            ),
            ListTile(
              leading: Icon(Icons.cancel, color: VesparaColors.error),
              title: Text('Cancel Event', style: TextStyle(color: VesparaColors.error)),
              onTap: () {
                Navigator.pop(context);
                _showCancelEventConfirmation(event);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelEventConfirmation(GroupEvent event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VesparaColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Cancel Event?', style: TextStyle(color: VesparaColors.error)),
        content: Text('This will notify all ${event.invites.length} guests that "${event.title}" has been cancelled.',
          style: TextStyle(color: VesparaColors.secondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Keep Event', style: TextStyle(color: VesparaColors.secondary))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Event cancelled. Guests notified.'), backgroundColor: VesparaColors.error));
            },
            child: Text('Cancel Event', style: TextStyle(color: VesparaColors.error)),
          ),
        ],
      ),
    );
  }

  void _showEventDetailsDialog(GroupEvent event) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: VesparaColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(event.title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: VesparaColors.glow)),
            const SizedBox(height: 8),
            Text(event.description, style: TextStyle(color: VesparaColors.secondary)),
            const SizedBox(height: 20),
            Row(children: [
              Icon(Icons.calendar_today, size: 16, color: VesparaColors.glow),
              const SizedBox(width: 8),
              Text(_formatDate(event.dateTime), style: TextStyle(color: VesparaColors.primary)),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.location_on, size: 16, color: VesparaColors.glow),
              const SizedBox(width: 8),
              Text(event.venueAddress ?? 'TBD', style: TextStyle(color: VesparaColors.primary)),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.group, size: 16, color: VesparaColors.glow),
              const SizedBox(width: 8),
              Text('${event.invites.length} invited', style: TextStyle(color: VesparaColors.primary)),
            ]),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: VesparaColors.glow,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _showRSVPDialog(event);
                },
                child: Text('RSVP Now', style: TextStyle(color: VesparaColors.background, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInviteDialog(GroupEvent event) {
    final contacts = ['Alex', 'Jordan', 'Casey', 'Morgan', 'Riley', 'Sam'];
    final selected = <String>{};
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: VesparaColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Invite to ${event.title}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: VesparaColors.primary)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: contacts.map((name) => FilterChip(
                  label: Text(name),
                  selected: selected.contains(name),
                  onSelected: (v) => setModalState(() => v ? selected.add(name) : selected.remove(name)),
                  selectedColor: VesparaColors.glow.withOpacity(0.3),
                  checkmarkColor: VesparaColors.glow,
                  backgroundColor: VesparaColors.background,
                  labelStyle: TextStyle(color: selected.contains(name) ? VesparaColors.glow : VesparaColors.primary),
                )).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VesparaColors.glow,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: selected.isEmpty ? null : () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Invited ${selected.length} people!'), backgroundColor: VesparaColors.success),
                    );
                  },
                  child: Text('Send ${selected.isEmpty ? '' : selected.length} Invite${selected.length == 1 ? '' : 's'}',
                    style: TextStyle(color: VesparaColors.background, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRSVPDialog(GroupEvent event) {
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
            Text('RSVP to ${event.title}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: VesparaColors.primary)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildRSVPOption('Going', Icons.check_circle, VesparaColors.success, event),
                _buildRSVPOption('Maybe', Icons.help_outline, VesparaColors.tagsYellow, event),
                _buildRSVPOption('Can\'t Go', Icons.cancel, VesparaColors.error, event),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRSVPOption(String label, IconData icon, Color color, GroupEvent event) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You\'re marked as "$label" for ${event.title}'),
            backgroundColor: color,
          ),
        );
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.2),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: VesparaColors.primary)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day} at ${date.hour}:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'PM' : 'AM'}';
  }
}
