import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animated_background.dart';
import '../widgets/planner_day_card.dart';
import 'create_event_screen.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// PLANNER SCREEN
/// Unified calendar view of all activity, events, travel & dates
/// One place to see everything for the user and their connections.
/// ════════════════════════════════════════════════════════════════════════════

class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDay;
  bool _loading = true;
  List<PlannerEntry> _entries = [];

  String? get _userId => Supabase.instance.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedDay = DateTime.now();
    _loadEntries();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEntries() async {
    setState(() => _loading = true);
    // TODO: Load from travel_plans, events, dates, etc.
    // For now, populate with empty list
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      setState(() {
        _entries = [];
        _loading = false;
      });
    }
  }

  List<PlannerEntry> get _entriesForSelectedDay {
    if (_selectedDay == null) return [];
    return _entries.where((e) {
      return e.startDate.year == _selectedDay!.year &&
          e.startDate.month == _selectedDay!.month &&
          e.startDate.day == _selectedDay!.day;
    }).toList();
  }

  Set<DateTime> get _datesWithEntries {
    return _entries
        .map((e) =>
            DateTime(e.startDate.year, e.startDate.month, e.startDate.day))
        .toSet();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VesparaColors.background,
      body: VesparaAnimatedBackground(
        enableAurora: true,
        enableParticles: false,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCalendarView(),
                    _buildListView(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white70, size: 18),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PLANNER',
                  style: GoogleFonts.orbitron(
                    color: const Color(0xFFCE93D8),
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Your world at a glance',
                  style: GoogleFonts.inter(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _loadEntries,
            icon: const Icon(Icons.refresh_rounded,
                color: Colors.white54, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: const Color(0xFFCE93D8).withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: const Color(0xFFCE93D8),
        unselectedLabelColor: Colors.white38,
        labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
        tabs: const [
          Tab(text: 'Calendar'),
          Tab(text: 'Agenda'),
        ],
      ),
    );
  }

  Widget _buildCalendarView() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFCE93D8)),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildMonthNavigation(),
          _buildCalendarGrid(),
          const SizedBox(height: 16),
          if (_selectedDay != null) ...[
            _buildSelectedDayHeader(),
            ..._buildSelectedDayEntries(),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildMonthNavigation() {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                _focusedMonth = DateTime(
                    _focusedMonth.year, _focusedMonth.month - 1);
              });
            },
            icon: const Icon(Icons.chevron_left, color: Colors.white54),
          ),
          Text(
            '${months[_focusedMonth.month - 1]} ${_focusedMonth.year}',
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.16),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _focusedMonth = DateTime(
                    _focusedMonth.year, _focusedMonth.month + 1);
              });
            },
            icon: const Icon(Icons.chevron_right, color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDayOfMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday % 7; // Sunday = 0
    final daysInMonth = lastDayOfMonth.day;
    final today = DateTime.now();

    const dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Column(
      children: [
        // Day-of-week header
        Row(
          children: dayLabels
              .map((d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: GoogleFonts.inter(
                          color: Colors.white24,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 4),
        // Calendar cells
        ...List.generate(6, (weekIndex) {
          return Row(
            children: List.generate(7, (dayOfWeek) {
              final dayNum =
                  weekIndex * 7 + dayOfWeek - firstWeekday + 1;
              if (dayNum < 1 || dayNum > daysInMonth) {
                return const Expanded(child: SizedBox(height: 44));
              }

              final date = DateTime(
                  _focusedMonth.year, _focusedMonth.month, dayNum);
              final isToday = date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day;
              final isSelected = _selectedDay != null &&
                  date.year == _selectedDay!.year &&
                  date.month == _selectedDay!.month &&
                  date.day == _selectedDay!.day;
              final hasEvents = _datesWithEntries.contains(date);

              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedDay = date),
                  child: Container(
                    height: 44,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFCE93D8).withOpacity(0.25)
                          : isToday
                              ? Colors.white.withOpacity(0.06)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: isToday
                          ? Border.all(
                              color: const Color(0xFFCE93D8).withOpacity(0.5),
                              width: 1)
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$dayNum',
                          style: GoogleFonts.inter(
                            color: isSelected
                                ? const Color(0xFFCE93D8)
                                : Colors.white70,
                            fontSize: 13,
                            fontWeight: isSelected || isToday
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                        if (hasEvents)
                          Container(
                            width: 4,
                            height: 4,
                            margin: const EdgeInsets.only(top: 2),
                            decoration: const BoxDecoration(
                              color: Color(0xFFCE93D8),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          );
        }),
      ],
    );
  }

  Widget _buildSelectedDayHeader() {
    final day = _selectedDay!;
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            '${weekdays[day.weekday - 1]}, ${months[day.month - 1]} ${day.day}',
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            '${_entriesForSelectedDay.length} events',
            style: GoogleFonts.inter(
              color: Colors.white30,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSelectedDayEntries() {
    final entries = _entriesForSelectedDay;
    if (entries.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(Icons.event_available_rounded,
                  color: Colors.white12, size: 48),
              const SizedBox(height: 12),
              Text(
                'Nothing planned',
                style: GoogleFonts.inter(
                  color: Colors.white24,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap + to add an event',
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.16),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ];
    }
    return entries.map((e) => PlannerDayCard(entry: e)).toList();
  }

  Widget _buildListView() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFCE93D8)),
      );
    }

    if (_entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_month_rounded,
                color: Colors.white12, size: 64),
            const SizedBox(height: 16),
            Text(
              'No upcoming plans',
              style: GoogleFonts.inter(
                color: Colors.white30,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Events, travel, and dates will appear here',
              style: GoogleFonts.inter(
                color: Colors.white16,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    // Group entries by date
    final grouped = <DateTime, List<PlannerEntry>>{};
    for (final entry in _entries) {
      final key = DateTime(
          entry.startDate.year, entry.startDate.month, entry.startDate.day);
      grouped.putIfAbsent(key, () => []).add(entry);
    }
    final sortedDates = grouped.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final dayEntries = grouped[date]!;
        final months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Text(
                '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}',
                style: GoogleFonts.inter(
                  color: Colors.white54,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ...dayEntries.map((e) => PlannerDayCard(entry: e)),
          ],
        );
      },
    );
  }

  Widget _buildFab() {
    return FloatingActionButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateEventScreen()),
        ).then((_) => _loadEntries());
      },
      backgroundColor: const Color(0xFFCE93D8),
      child: const Icon(Icons.add_rounded, color: Colors.white),
    );
  }
}

/// Unified planner entry — represents any schedulable item
class PlannerEntry {
  final String id;
  final String title;
  final String? subtitle;
  final PlannerEntryType type;
  final DateTime startDate;
  final DateTime? endDate;
  final String? location;
  final String? ownerName;
  final String? ownerId;

  const PlannerEntry({
    required this.id,
    required this.title,
    this.subtitle,
    required this.type,
    required this.startDate,
    this.endDate,
    this.location,
    this.ownerName,
    this.ownerId,
  });
}

enum PlannerEntryType {
  event,
  travel,
  date,
  connectionTravel,
  connectionEvent,
}
