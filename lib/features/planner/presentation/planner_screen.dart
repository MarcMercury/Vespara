import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/models/plan_event.dart';
import '../../../core/providers/plan_provider.dart';
import '../../../core/theme/app_theme.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// THE PLAN - Enhanced Planner Screen
/// One-stop shop for:
/// - Viewing availability and scheduled events
/// - Adding quick events with certainty levels
/// - AI-powered "Find Me a Date" suggestions
/// - Calendar integration (Google/Apple)
/// ════════════════════════════════════════════════════════════════════════════

class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  final bool _showAiSuggestions = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final planState = ref.watch(planProvider);

    return Scaffold(
      backgroundColor: VesparaColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildQuickStats(planState),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCalendarTab(planState),
                  _buildFindDateTab(planState),
                  _buildIntegrationsTab(planState),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEventWizard,
        backgroundColor: VesparaColors.glow,
        child: const Icon(Icons.add, color: VesparaColors.background),
      ),
    );
  }

  Widget _buildHeader() => Padding(
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
                const Text(
                  'THE PLAN',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 4,
                    color: VesparaColors.primary,
                  ),
                ),
                Text(
                  _getMonthYear(_selectedDate),
                  style: const TextStyle(
                    fontSize: 12,
                    color: VesparaColors.secondary,
                  ),
                ),
              ],
            ),
            IconButton(
              onPressed: _showCalendarPicker,
              icon: const Icon(Icons.calendar_month,
                  color: VesparaColors.secondary),
            ),
          ],
        ),
      );

  Widget _buildQuickStats(PlanState state) => Container(
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
            _buildStatItem('This Week', state.thisWeekEvents.length.toString(),
                Icons.event),
            Container(
                width: 1,
                height: 40,
                color: VesparaColors.glow.withOpacity(0.2)),
            _buildStatItem(
              'Experiences',
              state.experienceEventCount.toString(),
              Icons.celebration,
              color: const Color(0xFFEC4899),
            ),
            Container(
                width: 1,
                height: 40,
                color: VesparaColors.glow.withOpacity(0.2)),
            _buildStatItem(
              'Locked',
              state.confirmedCount.toString(),
              Icons.lock,
              color: EventCertainty.locked.color,
            ),
            Container(
                width: 1,
                height: 40,
                color: VesparaColors.glow.withOpacity(0.2)),
            _buildStatItem(
              'AI Ideas',
              state.aiSuggestions.length.toString(),
              Icons.auto_awesome,
              color: VesparaColors.glow,
            ),
          ],
        ),
      );

  Widget _buildStatItem(String label, String value, IconData icon,
          {Color? color}) =>
      Column(
        children: [
          Icon(icon, size: 18, color: color ?? VesparaColors.secondary),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: VesparaColors.primary,
            ),
          ),
          Text(
            label,
            style:
                const TextStyle(fontSize: 10, color: VesparaColors.secondary),
          ),
        ],
      );

  Widget _buildTabBar() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: VesparaColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: VesparaColors.glow,
            borderRadius: BorderRadius.circular(10),
          ),
          labelColor: VesparaColors.background,
          unselectedLabelColor: VesparaColors.secondary,
          labelStyle:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'CALENDAR'),
            Tab(text: 'FIND A DATE'),
            Tab(text: 'SYNC'),
          ],
        ),
      );

  // ═══════════════════════════════════════════════════════════════════════════
  // CALENDAR TAB
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCalendarTab(PlanState state) => Column(
        children: [
          _buildWeekStrip(state),
          Expanded(child: _buildEventsList(state)),
        ],
      );

  Widget _buildWeekStrip(PlanState state) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (index) {
          final day = weekStart.add(Duration(days: index));
          final isSelected =
              day.day == _selectedDate.day && day.month == _selectedDate.month;
          final isToday = day.day == now.day && day.month == now.month;
          final dayEvents = state.eventsForDate(day);
          final hasEvent = dayEvents.isNotEmpty;

          // Get the most "certain" event color for the indicator
          Color? eventIndicatorColor;
          if (hasEvent) {
            final mostCertain = dayEvents.reduce(
              (a, b) => a.certainty.percentage > b.certainty.percentage ? a : b,
            );
            eventIndicatorColor = mostCertain.certainty.color;
          }

          return GestureDetector(
            onTap: () => setState(() => _selectedDate = day),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? VesparaColors.glow
                    : (isToday
                        ? VesparaColors.glow.withOpacity(0.2)
                        : Colors.transparent),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    _getDayName(day.weekday),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? VesparaColors.background
                          : VesparaColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    day.day.toString(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? VesparaColors.background
                          : VesparaColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (hasEvent)
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? VesparaColors.background
                            : eventIndicatorColor,
                      ),
                    )
                  else
                    const SizedBox(width: 6, height: 6),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEventsList(PlanState state) {
    final dayEvents = state.eventsForDate(_selectedDate);

    if (dayEvents.isEmpty) {
      return _buildEmptyDay();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: dayEvents.length,
      itemBuilder: (context, index) => _buildEventCard(dayEvents[index]),
    );
  }

  Widget _buildEmptyDay() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available,
                size: 64, color: VesparaColors.glow.withOpacity(0.3)),
            const SizedBox(height: 16),
            const Text(
              'No plans for this day',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: VesparaColors.primary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap + to schedule something',
              style: TextStyle(fontSize: 14, color: VesparaColors.secondary),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                _tabController.animateTo(1); // Go to Find a Date tab
              },
              icon: const Icon(Icons.auto_awesome, color: VesparaColors.glow),
              label: const Text('Let Vespara find you a date',
                  style: TextStyle(color: VesparaColors.glow)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: VesparaColors.glow),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );

  Widget _buildEventCard(PlanEvent event) => GestureDetector(
        onTap: () => _showEventDetails(event),
        onLongPress: () => _showEventOptions(event),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: VesparaColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: event.isConflicted
                  ? VesparaColors.warning.withOpacity(0.5)
                  : event.certainty.color.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Certainty indicator bar
                  Container(
                    width: 4,
                    height: 50,
                    decoration: BoxDecoration(
                      color: event.certainty.color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                event.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: VesparaColors.primary,
                                ),
                              ),
                            ),
                            if (event.isAiSuggested)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: VesparaColors.glow.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.auto_awesome,
                                        size: 10, color: VesparaColors.glow),
                                    SizedBox(width: 2),
                                    Text('AI',
                                        style: TextStyle(
                                            fontSize: 9,
                                            color: VesparaColors.glow)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          event.isFromExperience
                              ? (event.isHosting
                                  ? 'Hosting this Experience'
                                  : 'Hosted by ${event.experienceHostName ?? "Someone"}')
                              : event.connectionNames,
                          style: const TextStyle(
                              fontSize: 13, color: VesparaColors.glow),
                        ),
                      ],
                    ),
                  ),
                  // Certainty badge or Experience badge
                  if (event.isFromExperience)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF6366F1),
                            Color(0xFFEC4899),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.celebration,
                              size: 10, color: Colors.white),
                          SizedBox(width: 3),
                          Text(
                            'EXPERIENCE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: event.certainty.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        event.certainty.label.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: event.certainty.color,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.access_time,
                      size: 14, color: VesparaColors.secondary),
                  const SizedBox(width: 4),
                  Text(
                    event.formattedTimeRange,
                    style: const TextStyle(
                        fontSize: 12, color: VesparaColors.secondary),
                  ),
                  if (event.location != null) ...[
                    const SizedBox(width: 16),
                    const Icon(Icons.location_on,
                        size: 14, color: VesparaColors.secondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event.location!,
                        style: const TextStyle(
                            fontSize: 12, color: VesparaColors.secondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
              if (event.isConflicted) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: VesparaColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning,
                          size: 14, color: VesparaColors.warning),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          event.conflictReason ??
                              'Potential scheduling conflict',
                          style: const TextStyle(
                              fontSize: 11, color: VesparaColors.warning),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      );

  // ═══════════════════════════════════════════════════════════════════════════
  // FIND A DATE TAB
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildFindDateTab(PlanState state) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Find Me a Date button
            _buildFindMeADateButton(state),
            const SizedBox(height: 24),

            // AI Suggestions section
            if (state.aiSuggestions.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'AI SUGGESTIONS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                      color: VesparaColors.secondary,
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        ref.read(planProvider.notifier).findMeADate(),
                    child: const Text('Refresh',
                        style:
                            TextStyle(color: VesparaColors.glow, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...state.aiSuggestions.map(_buildAiSuggestionCard),
            ] else ...[
              _buildNoSuggestionsState(state),
            ],
          ],
        ),
      );

  Widget _buildFindMeADateButton(PlanState state) => GestureDetector(
        onTap: state.isLoadingSuggestions
            ? null
            : () => ref.read(planProvider.notifier).findMeADate(),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF6366F1),
                Color(0xFFEC4899),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              if (state.isLoadingSuggestions)
                const CircularProgressIndicator(color: Colors.white)
              else
                const Icon(Icons.auto_awesome, size: 48, color: Colors.white),
              const SizedBox(height: 16),
              const Text(
                'FIND ME A DATE',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'AI analyzes your connections, chat history,\nand availability to suggest the perfect match',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildAiSuggestionCard(AiDateSuggestion suggestion) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: VesparaColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: suggestion.isHotMatch
                ? VesparaColors.glow.withOpacity(0.5)
                : VesparaColors.glow.withOpacity(0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: VesparaColors.glow.withOpacity(0.2),
                  backgroundImage: suggestion.connection.avatarUrl != null
                      ? NetworkImage(suggestion.connection.avatarUrl!)
                      : null,
                  child: suggestion.connection.avatarUrl == null
                      ? Text(
                          suggestion.connection.name[0].toUpperCase(),
                          style: const TextStyle(
                            color: VesparaColors.glow,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            suggestion.connection.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: VesparaColors.primary,
                            ),
                          ),
                          if (suggestion.isHotMatch) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: VesparaColors.glow,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '🔥 HOT MATCH',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: VesparaColors.background,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${(suggestion.compatibilityScore * 100).toInt()}% compatibility',
                        style: const TextStyle(
                            fontSize: 12, color: VesparaColors.glow),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => ref
                      .read(planProvider.notifier)
                      .dismissSuggestion(suggestion.id),
                  icon: const Icon(Icons.close,
                      size: 18, color: VesparaColors.secondary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // AI Reason
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: VesparaColors.glow.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome,
                      size: 16, color: VesparaColors.glow),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      suggestion.reason,
                      style: const TextStyle(
                          fontSize: 12, color: VesparaColors.secondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Suggested times
            const Text(
              'SUGGESTED TIMES',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
                color: VesparaColors.secondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: suggestion.suggestedTimes
                  .take(3)
                  .map(
                    (time) => GestureDetector(
                      onTap: () => _confirmAiSuggestion(suggestion, time),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: VesparaColors.glow.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _formatSuggestedTime(time),
                          style: const TextStyle(
                              fontSize: 12, color: VesparaColors.primary),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      );

  Widget _buildNoSuggestionsState(PlanState state) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off,
                size: 48, color: VesparaColors.secondary.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text(
              'No suggestions yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: VesparaColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap "Find Me a Date" to get AI-powered suggestions',
              style: TextStyle(fontSize: 13, color: VesparaColors.secondary),
            ),
          ],
        ),
      );

  // ═══════════════════════════════════════════════════════════════════════════
  // INTEGRATIONS TAB
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildIntegrationsTab(PlanState state) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CALENDAR INTEGRATIONS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
                color: VesparaColors.secondary,
              ),
            ),
            const SizedBox(height: 16),

            // Google Calendar
            _buildCalendarIntegrationCard(
              name: 'Google Calendar',
              icon: Icons.calendar_today,
              iconColor: const Color(0xFF4285F4),
              isConnected: state.googleCalendarConnected,
              onConnect: () =>
                  ref.read(planProvider.notifier).connectGoogleCalendar(),
              onDisconnect: () =>
                  ref.read(planProvider.notifier).disconnectGoogleCalendar(),
            ),
            const SizedBox(height: 12),

            // Apple Calendar
            _buildCalendarIntegrationCard(
              name: 'Apple Calendar',
              icon: Icons.event,
              iconColor: const Color(0xFFFF3B30),
              isConnected: state.appleCalendarConnected,
              onConnect: () =>
                  ref.read(planProvider.notifier).connectAppleCalendar(),
              onDisconnect: () =>
                  ref.read(planProvider.notifier).disconnectAppleCalendar(),
            ),

            if (state.hasCalendarConnected) ...[
              const SizedBox(height: 24),

              // Sync section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: VesparaColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Sync Status',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: VesparaColors.primary,
                          ),
                        ),
                        if (state.isLoading)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: VesparaColors.glow,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (state.lastSyncTime != null)
                      Text(
                        'Last synced: ${_formatSyncTime(state.lastSyncTime!)}',
                        style: const TextStyle(
                            fontSize: 13, color: VesparaColors.secondary),
                      )
                    else
                      const Text(
                        'Not synced yet',
                        style: TextStyle(
                            fontSize: 13, color: VesparaColors.secondary),
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: state.isLoading
                            ? null
                            : () =>
                                ref.read(planProvider.notifier).syncCalendars(),
                        icon: const Icon(Icons.sync, color: VesparaColors.glow),
                        label: const Text('Sync Now',
                            style: TextStyle(color: VesparaColors.glow)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: VesparaColors.glow),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // How it works
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: VesparaColors.glow.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: VesparaColors.glow.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 20, color: VesparaColors.glow),
                      SizedBox(width: 8),
                      Text(
                        'How Calendar Sync Works',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: VesparaColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoItem('AI sees your busy times (not event details)'),
                  _buildInfoItem('Suggests dates when you\'re both free'),
                  _buildInfoItem('Detects scheduling conflicts automatically'),
                  _buildInfoItem(
                      'Events you create sync back to your calendar'),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildCalendarIntegrationCard({
    required String name,
    required IconData icon,
    required Color iconColor,
    required bool isConnected,
    required VoidCallback onConnect,
    required VoidCallback onDisconnect,
  }) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: VesparaColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: isConnected
              ? Border.all(color: VesparaColors.success.withOpacity(0.3))
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: VesparaColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isConnected ? 'Connected' : 'Not connected',
                    style: TextStyle(
                      fontSize: 12,
                      color: isConnected
                          ? VesparaColors.success
                          : VesparaColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: isConnected ? onDisconnect : onConnect,
              child: Text(
                isConnected ? 'Disconnect' : 'Connect',
                style: TextStyle(
                  color: isConnected ? VesparaColors.error : VesparaColors.glow,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildInfoItem(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.check, size: 16, color: VesparaColors.glow),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                    fontSize: 12, color: VesparaColors.secondary),
              ),
            ),
          ],
        ),
      );

  // ═══════════════════════════════════════════════════════════════════════════
  // ADD EVENT WIZARD
  // ═══════════════════════════════════════════════════════════════════════════

  void _showAddEventWizard() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const AddEventWizard(),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  String _getDayName(int weekday) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return days[weekday - 1];
  }

  String _getMonthYear(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _formatSuggestedTime(DateTime time) {
    final now = DateTime.now();
    final diff = time.difference(now).inDays;

    String dayStr;
    if (diff == 0) {
      dayStr = 'Today';
    } else if (diff == 1) {
      dayStr = 'Tomorrow';
    } else if (diff < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      dayStr = days[time.weekday - 1];
    } else {
      dayStr = '${time.month}/${time.day}';
    }

    final hour =
        time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final period = time.hour >= 12 ? 'PM' : 'AM';

    return '$dayStr $hour$period';
  }

  String _formatSyncTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _showCalendarPicker() {
    showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: VesparaColors.glow,
            surface: VesparaColors.surface,
          ),
        ),
        child: child!,
      ),
    ).then((date) {
      if (date != null) {
        setState(() => _selectedDate = date);
      }
    });
  }

  void _showEventDetails(PlanEvent event) {
    showModalBottomSheet(
      context: context,
      backgroundColor: VesparaColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => EventDetailSheet(event: event),
    );
  }

  void _showEventOptions(PlanEvent event) {
    showModalBottomSheet(
      context: context,
      backgroundColor: VesparaColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            ListTile(
              leading: const Icon(Icons.edit, color: VesparaColors.glow),
              title: const Text('Edit Event',
                  style: TextStyle(color: VesparaColors.primary)),
              onTap: () {
                Navigator.pop(context);
                // TODO: Open edit wizard
              },
            ),
            ListTile(
              leading: const Icon(Icons.tune, color: VesparaColors.secondary),
              title: const Text('Change Certainty',
                  style: TextStyle(color: VesparaColors.primary)),
              onTap: () {
                Navigator.pop(context);
                _showCertaintyPicker(event);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: VesparaColors.error),
              title: const Text('Delete Event',
                  style: TextStyle(color: VesparaColors.error)),
              onTap: () {
                Navigator.pop(context);
                ref.read(planProvider.notifier).deleteEvent(event.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCertaintyPicker(PlanEvent event) {
    showModalBottomSheet(
      context: context,
      backgroundColor: VesparaColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
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
            const Text(
              'How certain is this?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: VesparaColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            ...EventCertainty.values.map(
              (certainty) => ListTile(
                leading: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: certainty.color,
                    shape: BoxShape.circle,
                  ),
                  child: event.certainty == certainty
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
                title: Text(certainty.label,
                    style: const TextStyle(color: VesparaColors.primary)),
                subtitle: Text(
                  certainty.description,
                  style: const TextStyle(
                      fontSize: 11, color: VesparaColors.secondary),
                ),
                onTap: () {
                  Navigator.pop(context);
                  ref
                      .read(planProvider.notifier)
                      .updateCertainty(event.id, certainty);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmAiSuggestion(AiDateSuggestion suggestion, DateTime time) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VesparaColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Schedule Date?',
          style: TextStyle(color: VesparaColors.primary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date with ${suggestion.connection.name}',
              style: const TextStyle(color: VesparaColors.primary),
            ),
            const SizedBox(height: 8),
            Text(
              _formatSuggestedTime(time),
              style: const TextStyle(
                  color: VesparaColors.glow, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: VesparaColors.secondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(planProvider.notifier)
                  .acceptSuggestion(suggestion, time);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Date scheduled with ${suggestion.connection.name}!'),
                  backgroundColor: VesparaColors.success,
                ),
              );
            },
            child: const Text('Schedule',
                style: TextStyle(color: VesparaColors.glow)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ADD EVENT WIZARD
// ═══════════════════════════════════════════════════════════════════════════════

class AddEventWizard extends ConsumerStatefulWidget {
  const AddEventWizard({super.key});

  @override
  ConsumerState<AddEventWizard> createState() => _AddEventWizardState();
}

class _AddEventWizardState extends ConsumerState<AddEventWizard> {
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 19, minute: 0);
  EventCertainty _certainty = EventCertainty.tentative;
  final List<EventConnection> _selectedConnections = [];
  int _step = 0; // 0: basics, 1: who, 2: certainty

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: VesparaColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: VesparaColors.secondary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_step > 0)
                    IconButton(
                      onPressed: () => setState(() => _step--),
                      icon: const Icon(Icons.arrow_back,
                          color: VesparaColors.primary),
                    )
                  else
                    const SizedBox(width: 48),
                  Text(
                    _stepTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: VesparaColors.primary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon:
                        const Icon(Icons.close, color: VesparaColors.secondary),
                  ),
                ],
              ),
            ),

            // Progress indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: List.generate(
                  3,
                  (index) => Expanded(
                    child: Container(
                      height: 3,
                      margin: EdgeInsets.only(right: index < 2 ? 4 : 0),
                      decoration: BoxDecoration(
                        color: index <= _step
                            ? VesparaColors.glow
                            : VesparaColors.glow.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildStepContent(),
              ),
            ),

            // Action button
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canProceed ? _handleNext : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VesparaColors.glow,
                    disabledBackgroundColor:
                        VesparaColors.glow.withOpacity(0.3),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    _step == 2 ? 'Create Event' : 'Next',
                    style: const TextStyle(
                      color: VesparaColors.background,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  String get _stepTitle {
    switch (_step) {
      case 0:
        return 'Event Details';
      case 1:
        return 'Who\'s Invited?';
      case 2:
        return 'How Certain?';
      default:
        return '';
    }
  }

  bool get _canProceed {
    switch (_step) {
      case 0:
        return _titleController.text.isNotEmpty;
      case 1:
        return true; // Connections are optional
      case 2:
        return true;
      default:
        return false;
    }
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 0:
        return _buildBasicsStep();
      case 1:
        return _buildConnectionsStep();
      case 2:
        return _buildCertaintyStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildBasicsStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event name
          TextField(
            controller: _titleController,
            style: const TextStyle(color: VesparaColors.primary),
            decoration: InputDecoration(
              labelText: 'Event Name',
              labelStyle: const TextStyle(color: VesparaColors.secondary),
              hintText: 'e.g., Drinks at The Roosevelt',
              hintStyle:
                  TextStyle(color: VesparaColors.secondary.withOpacity(0.5)),
              prefixIcon: const Icon(Icons.event, color: VesparaColors.glow),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: VesparaColors.glow.withOpacity(0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: VesparaColors.glow),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Date & Time row
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: VesparaColors.glow.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 20, color: VesparaColors.glow),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(_selectedDate),
                          style: const TextStyle(color: VesparaColors.primary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: _pickTime,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: VesparaColors.glow.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time,
                            size: 20, color: VesparaColors.glow),
                        const SizedBox(width: 8),
                        Text(
                          _selectedTime.format(context),
                          style: const TextStyle(color: VesparaColors.primary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Location
          TextField(
            controller: _locationController,
            style: const TextStyle(color: VesparaColors.primary),
            decoration: InputDecoration(
              labelText: 'Location (optional)',
              labelStyle: const TextStyle(color: VesparaColors.secondary),
              hintText: 'e.g., Blue Bottle Coffee',
              hintStyle:
                  TextStyle(color: VesparaColors.secondary.withOpacity(0.5)),
              prefixIcon:
                  const Icon(Icons.location_on, color: VesparaColors.glow),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: VesparaColors.glow.withOpacity(0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: VesparaColors.glow),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Notes
          TextField(
            controller: _notesController,
            style: const TextStyle(color: VesparaColors.primary),
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Notes (optional)',
              labelStyle: const TextStyle(color: VesparaColors.secondary),
              hintText: 'Any details you want to remember...',
              hintStyle:
                  TextStyle(color: VesparaColors.secondary.withOpacity(0.5)),
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 48),
                child: Icon(Icons.notes, color: VesparaColors.glow),
              ),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: VesparaColors.glow.withOpacity(0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: VesparaColors.glow),
              ),
            ),
          ),
        ],
      );

  Widget _buildConnectionsStep() {
    final connectionsAsync = ref.watch(planConnectionsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select who this event is with',
          style: TextStyle(color: VesparaColors.secondary),
        ),
        const SizedBox(height: 8),
        Text(
          'You can skip this if it\'s a solo event',
          style: TextStyle(
              fontSize: 12, color: VesparaColors.secondary.withOpacity(0.7)),
        ),
        const SizedBox(height: 20),
        connectionsAsync.when(
          data: (connections) => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: connections.map((c) {
              final isSelected =
                  _selectedConnections.any((sc) => sc.id == c.id);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedConnections.removeWhere((sc) => sc.id == c.id);
                    } else {
                      _selectedConnections.add(c);
                    }
                  });
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? VesparaColors.glow : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? VesparaColors.glow
                          : VesparaColors.glow.withOpacity(0.3),
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: isSelected
                            ? VesparaColors.background.withOpacity(0.3)
                            : VesparaColors.glow.withOpacity(0.2),
                        backgroundImage: c.avatarUrl != null
                            ? NetworkImage(c.avatarUrl!)
                            : null,
                        child: c.avatarUrl == null
                            ? Text(
                                c.name[0].toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isSelected
                                      ? VesparaColors.background
                                      : VesparaColors.glow,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        c.name,
                        style: TextStyle(
                          color: isSelected
                              ? VesparaColors.background
                              : VesparaColors.primary,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.check,
                            size: 16, color: VesparaColors.background),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Text(
            'Failed to load connections',
            style: TextStyle(color: VesparaColors.error),
          ),
        ),
        if (_selectedConnections.isNotEmpty) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: VesparaColors.glow.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.people, size: 20, color: VesparaColors.glow),
                const SizedBox(width: 8),
                Text(
                  '${_selectedConnections.length} ${_selectedConnections.length == 1 ? 'person' : 'people'} selected',
                  style: const TextStyle(color: VesparaColors.primary),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCertaintyStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How likely is this to happen?',
            style: TextStyle(color: VesparaColors.secondary),
          ),
          const SizedBox(height: 8),
          Text(
            'This helps you and your connections know what to expect',
            style: TextStyle(
                fontSize: 12, color: VesparaColors.secondary.withOpacity(0.7)),
          ),
          const SizedBox(height: 24),
          ...EventCertainty.values.map(
            (certainty) => GestureDetector(
              onTap: () => setState(() => _certainty = certainty),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _certainty == certainty
                      ? certainty.color.withOpacity(0.1)
                      : VesparaColors.background,
                  border: Border.all(
                    color: _certainty == certainty
                        ? certainty.color
                        : VesparaColors.glow.withOpacity(0.1),
                    width: _certainty == certainty ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: certainty.color,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${(certainty.percentage * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            certainty.label,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: VesparaColors.primary,
                            ),
                          ),
                          Text(
                            certainty.description,
                            style: const TextStyle(
                              fontSize: 12,
                              color: VesparaColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_certainty == certainty)
                      Icon(Icons.check_circle, color: certainty.color),
                  ],
                ),
              ),
            ),
          ),
        ],
      );

  void _handleNext() {
    if (_step < 2) {
      setState(() => _step++);
    } else {
      _createEvent();
    }
  }

  void _createEvent() {
    final event = PlanEvent(
      id: 'event-${DateTime.now().millisecondsSinceEpoch}',
      userId: 'current-user', // Would come from auth
      title: _titleController.text,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      startTime: DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      ),
      endTime: DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour + 2,
        _selectedTime.minute,
      ),
      location:
          _locationController.text.isEmpty ? null : _locationController.text,
      connections: _selectedConnections,
      certainty: _certainty,
      createdAt: DateTime.now(),
    );

    ref.read(planProvider.notifier).createEvent(event);

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Event "${event.title}" created!'),
        backgroundColor: VesparaColors.success,
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: VesparaColors.glow,
            surface: VesparaColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: VesparaColors.glow,
            surface: VesparaColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// EVENT DETAIL SHEET
// ═══════════════════════════════════════════════════════════════════════════════

class EventDetailSheet extends StatelessWidget {
  const EventDetailSheet({super.key, required this.event});
  final PlanEvent event;

  @override
  Widget build(BuildContext context) => Container(
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

            // Title with certainty badge
            Row(
              children: [
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: event.certainty.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: VesparaColors.primary,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: event.certainty.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    event.certainty.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: event.certainty.color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Date & Time
            _buildDetailRow(Icons.calendar_today, event.formattedDate),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.access_time, event.formattedTimeRange),

            if (event.location != null) ...[
              const SizedBox(height: 12),
              _buildDetailRow(Icons.location_on, event.location!),
            ],

            // Connections
            if (event.connections.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text(
                'WITH',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                  color: VesparaColors.secondary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: event.connections
                    .map(
                      (c) => Chip(
                        avatar: CircleAvatar(
                          radius: 12,
                          backgroundColor: VesparaColors.glow.withOpacity(0.2),
                          backgroundImage: c.avatarUrl != null
                              ? NetworkImage(c.avatarUrl!)
                              : null,
                          child: c.avatarUrl == null
                              ? Text(
                                  c.name[0].toUpperCase(),
                                  style: const TextStyle(
                                      fontSize: 10, color: VesparaColors.glow),
                                )
                              : null,
                        ),
                        label: Text(c.name),
                        backgroundColor: VesparaColors.surface,
                        labelStyle:
                            const TextStyle(color: VesparaColors.primary),
                      ),
                    )
                    .toList(),
              ),
            ],

            // Notes
            if (event.notes != null) ...[
              const SizedBox(height: 20),
              const Text(
                'NOTES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                  color: VesparaColors.secondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                event.notes!,
                style: const TextStyle(color: VesparaColors.primary),
              ),
            ],

            // AI badge
            if (event.isAiSuggested) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: VesparaColors.glow.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome,
                        size: 18, color: VesparaColors.glow),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        event.aiSuggestionReason ??
                            'AI suggested this date based on your activity',
                        style: const TextStyle(
                            fontSize: 12, color: VesparaColors.secondary),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
          ],
        ),
      );

  Widget _buildDetailRow(IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 18, color: VesparaColors.glow),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(fontSize: 15, color: VesparaColors.primary),
          ),
        ],
      );
}
