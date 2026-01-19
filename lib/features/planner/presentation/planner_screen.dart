import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/domain/models/events.dart';
import '../../../core/providers/events_provider.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// THE PLANNER - Module 5
/// AI-powered calendar with date scheduling and conflict detection
/// Syncs with Google/iCal, analyzes conversations for smart scheduling
/// ════════════════════════════════════════════════════════════════════════════

class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    // Watch the events provider for real-time updates
    final eventsState = ref.watch(eventsProvider);
    final events = eventsState.calendarEvents;
    return Scaffold(
      backgroundColor: VesparaColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildQuickStats(events),
            _buildWeekStrip(events),
            Expanded(child: _buildEventsList(events)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEvent,
        backgroundColor: VesparaColors.glow,
        child: Icon(Icons.add, color: VesparaColors.background),
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
                'THE PLANNER',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 4,
                  color: VesparaColors.primary,
                ),
              ),
              Text(
                _getMonthYear(_selectedDate),
                style: TextStyle(
                  fontSize: 12,
                  color: VesparaColors.secondary,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () => _showCalendarDialog(),
            icon: Icon(Icons.calendar_month, color: VesparaColors.secondary),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(List<CalendarEvent> events) {
    final thisWeekEvents = events.where((e) {
      final diff = e.startTime.difference(DateTime.now()).inDays;
      return diff >= 0 && diff <= 7;
    }).length;
    
    final conflicts = events.where((e) => e.aiConflictDetected).length;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            VesparaColors.glow.withOpacity(0.2),
            VesparaColors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VesparaColors.glow.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('This Week', thisWeekEvents.toString(), Icons.event),
          Container(width: 1, height: 40, color: VesparaColors.glow.withOpacity(0.2)),
          _buildStatItem('Total', events.length.toString(), Icons.calendar_today),
          Container(width: 1, height: 40, color: VesparaColors.glow.withOpacity(0.2)),
          _buildStatItem('Conflicts', conflicts.toString(), Icons.warning_amber, highlight: conflicts > 0),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, {bool highlight = false}) {
    return Column(
      children: [
        Icon(icon, size: 20, color: highlight ? VesparaColors.warning : VesparaColors.glow),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: highlight ? VesparaColors.warning : VesparaColors.primary)),
        Text(label, style: TextStyle(fontSize: 11, color: VesparaColors.secondary)),
      ],
    );
  }

  Widget _buildWeekStrip(List<CalendarEvent> events) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (index) {
          final day = weekStart.add(Duration(days: index));
          final isSelected = day.day == _selectedDate.day && day.month == _selectedDate.month;
          final isToday = day.day == now.day && day.month == now.month;
          final hasEvent = events.any((e) => e.startTime.day == day.day && e.startTime.month == day.month);
          
          return GestureDetector(
            onTap: () => setState(() => _selectedDate = day),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? VesparaColors.glow : (isToday ? VesparaColors.glow.withOpacity(0.2) : Colors.transparent),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(_getDayName(day.weekday), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: isSelected ? VesparaColors.background : VesparaColors.secondary)),
                  const SizedBox(height: 4),
                  Text(day.day.toString(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isSelected ? VesparaColors.background : VesparaColors.primary)),
                  const SizedBox(height: 4),
                  if (hasEvent) Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: isSelected ? VesparaColors.background : VesparaColors.glow)) else const SizedBox(width: 6, height: 6),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEventsList(List<CalendarEvent> events) {
    final dayEvents = events.where((e) => e.startTime.day == _selectedDate.day && e.startTime.month == _selectedDate.month && e.startTime.year == _selectedDate.year).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));
    
    if (dayEvents.isEmpty) return _buildEmptyDay();
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: dayEvents.length,
      itemBuilder: (context, index) => _buildEventCard(dayEvents[index]),
    );
  }

  Widget _buildEmptyDay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_available, size: 64, color: VesparaColors.glow.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text('No plans for this day', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: VesparaColors.primary)),
          const SizedBox(height: 8),
          Text('Tap + to schedule a date', style: TextStyle(fontSize: 14, color: VesparaColors.secondary)),
        ],
      ),
    );
  }

  Widget _buildEventCard(CalendarEvent event) {
    final statusColor = _getStatusColor(event.status);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VesparaColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: event.aiConflictDetected ? VesparaColors.warning.withOpacity(0.5) : VesparaColors.glow.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 4, height: 40, decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: VesparaColors.primary)),
                    const SizedBox(height: 2),
                    Text('with ${event.matchName ?? 'someone special'}', style: TextStyle(fontSize: 13, color: VesparaColors.glow)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(event.status.label.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.access_time, size: 14, color: VesparaColors.secondary),
              const SizedBox(width: 4),
              Text(event.formattedTimeRange, style: TextStyle(fontSize: 12, color: VesparaColors.secondary)),
              const SizedBox(width: 16),
              Icon(Icons.location_on, size: 14, color: VesparaColors.secondary),
              const SizedBox(width: 4),
              Expanded(child: Text(event.location ?? 'Location TBD', style: TextStyle(fontSize: 12, color: VesparaColors.secondary), overflow: TextOverflow.ellipsis)),
            ],
          ),
          if (event.aiConflictDetected) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: VesparaColors.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  Icon(Icons.warning, size: 14, color: VesparaColors.warning),
                  const SizedBox(width: 8),
                  Expanded(child: Text(event.aiConflictReason ?? 'Potential scheduling conflict detected', style: TextStyle(fontSize: 11, color: VesparaColors.warning))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(EventStatus status) {
    switch (status) {
      case EventStatus.confirmed:
        return VesparaColors.success;
      case EventStatus.tentative:
        return VesparaColors.tagsYellow;
      case EventStatus.cancelled:
        return VesparaColors.error;
    }
  }

  String _getDayName(int weekday) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return days[weekday - 1];
  }

  String _getMonthYear(DateTime date) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return '${months[date.month - 1]} ${date.year}';
  }

  void _showAddEvent() {
    showModalBottomSheet(
      context: context,
      backgroundColor: VesparaColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: VesparaColors.secondary, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('Schedule a Date', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: VesparaColors.primary)),
            const SizedBox(height: 24),
            ListTile(
              onTap: () => _scheduleDateOption('Drinks Tonight', 'Find a bar nearby'),
              leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: VesparaColors.glow.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.local_bar, color: VesparaColors.glow)),
              title: Text('Drinks Tonight', style: TextStyle(fontWeight: FontWeight.w600, color: VesparaColors.primary)),
              subtitle: Text('Quick cocktails or wine', style: TextStyle(color: VesparaColors.secondary)),
            ),
            ListTile(
              onTap: () => _scheduleDateOption('Dinner Date', 'Make a reservation'),
              leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: VesparaColors.glow.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.restaurant, color: VesparaColors.glow)),
              title: Text('Dinner Date', style: TextStyle(fontWeight: FontWeight.w600, color: VesparaColors.primary)),
              subtitle: Text('Restaurant reservation', style: TextStyle(color: VesparaColors.secondary)),
            ),
            ListTile(
              onTap: () => _scheduleDateOption('Coffee Meetup', 'Low-key first date'),
              leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: VesparaColors.glow.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.coffee, color: VesparaColors.glow)),
              title: Text('Coffee Meetup', style: TextStyle(fontWeight: FontWeight.w600, color: VesparaColors.primary)),
              subtitle: Text('Low-key first date', style: TextStyle(color: VesparaColors.secondary)),
            ),
            ListTile(
              onTap: () => _showCustomEventDialog(),
              leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: VesparaColors.glow.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.edit_calendar, color: VesparaColors.glow)),
              title: Text('Custom Event', style: TextStyle(fontWeight: FontWeight.w600, color: VesparaColors.primary)),
              subtitle: Text('Create your own date', style: TextStyle(color: VesparaColors.secondary)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _scheduleDateOption(String type, String subtitle) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VesparaColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(type, style: TextStyle(color: VesparaColors.glow)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(subtitle, style: TextStyle(color: VesparaColors.secondary)),
            const SizedBox(height: 20),
            _buildTimeSlot('Tonight, 7 PM', type),
            _buildTimeSlot('Tomorrow, 8 PM', type),
            _buildTimeSlot('This Weekend', type),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: VesparaColors.secondary)),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlot(String time, String dateType) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(time, style: TextStyle(color: VesparaColors.primary)),
      trailing: Icon(Icons.chevron_right, color: VesparaColors.glow),
      onTap: () async {
        Navigator.pop(context);
        
        // Calculate the actual date/time based on selection
        DateTime eventTime;
        if (time.contains('Tonight')) {
          eventTime = DateTime.now().copyWith(hour: 19, minute: 0, second: 0);
        } else if (time.contains('Tomorrow')) {
          eventTime = DateTime.now().add(const Duration(days: 1)).copyWith(hour: 20, minute: 0, second: 0);
        } else {
          // This Weekend - next Saturday at 7 PM
          final now = DateTime.now();
          final daysUntilSaturday = (6 - now.weekday + 7) % 7;
          eventTime = now.add(Duration(days: daysUntilSaturday == 0 ? 7 : daysUntilSaturday)).copyWith(hour: 19, minute: 0, second: 0);
        }
        
        // Create event using the provider
        HapticFeedback.mediumImpact();
        await ref.read(eventsProvider.notifier).scheduleQuickDate(
          type: dateType,
          dateTime: eventTime,
          matchName: 'Someone Special',
          location: 'Downtown',
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Date scheduled for $time'),
              backgroundColor: VesparaColors.success,
            ),
          );
        }
      },
    );
  }

  void _showCustomEventDialog() {
    Navigator.pop(context);
    final titleController = TextEditingController();
    final locationController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VesparaColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Create Custom Event', style: TextStyle(color: VesparaColors.primary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                hintText: 'Event name',
                hintStyle: TextStyle(color: VesparaColors.secondary),
                prefixIcon: Icon(Icons.event, color: VesparaColors.glow),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              style: TextStyle(color: VesparaColors.primary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: locationController,
              decoration: InputDecoration(
                hintText: 'Location',
                hintStyle: TextStyle(color: VesparaColors.secondary),
                prefixIcon: Icon(Icons.location_on, color: VesparaColors.glow),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              style: TextStyle(color: VesparaColors.primary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: VesparaColors.secondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (titleController.text.isNotEmpty) {
                HapticFeedback.mediumImpact();
                
                // Create event using the provider - saves to database
                await ref.read(eventsProvider.notifier).createCalendarEvent(
                  title: titleController.text,
                  startTime: DateTime.now().add(const Duration(days: 1)),
                  endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
                  matchName: 'Custom Event',
                  location: locationController.text.isEmpty ? 'TBD' : locationController.text,
                  status: EventStatus.tentative,
                );
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Event "${titleController.text}" created'),
                      backgroundColor: VesparaColors.success,
                    ),
                  );
                }
              }
            },
            child: Text('Create', style: TextStyle(color: VesparaColors.glow)),
          ),
        ],
      ),
    );
  }

  void _showCalendarDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VesparaColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Calendar Options', style: TextStyle(color: VesparaColors.primary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.sync, color: VesparaColors.glow),
              title: Text('Sync Now', style: TextStyle(color: VesparaColors.primary)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Syncing with calendar...')),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.calendar_today, color: VesparaColors.glow),
              title: Text('Google Calendar', style: TextStyle(color: VesparaColors.primary)),
              subtitle: Text('Connected', style: TextStyle(color: VesparaColors.success)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening Google Calendar settings...')),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.event, color: VesparaColors.glow),
              title: Text('Apple Calendar', style: TextStyle(color: VesparaColors.primary)),
              subtitle: Text('Not connected', style: TextStyle(color: VesparaColors.secondary)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Connecting to Apple Calendar...')),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.settings, color: VesparaColors.glow),
              title: Text('Calendar Settings', style: TextStyle(color: VesparaColors.primary)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening calendar settings...')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
