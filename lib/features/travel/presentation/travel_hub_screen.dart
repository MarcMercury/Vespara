import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/domain/models/travel_plan.dart';
import '../../../core/services/travel_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animated_background.dart';
import '../widgets/travel_map_view.dart';
import '../widgets/travel_timeline_view.dart';
import '../widgets/overlap_card.dart';
import '../widgets/trip_card.dart';
import 'add_trip_screen.dart';
import 'trip_detail_screen.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// TRAVEL HUB SCREEN
/// The main dashboard for Trip sharing with:
/// - My Trips tab
/// - Connection Trips / Map view
/// - Travel Overlaps ("Who's nearby?")
/// ════════════════════════════════════════════════════════════════════════════

class TravelHubScreen extends StatefulWidget {
  const TravelHubScreen({super.key});

  @override
  State<TravelHubScreen> createState() => _TravelHubScreenState();
}

class _TravelHubScreenState extends State<TravelHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _travelService = TravelService.instance;

  List<TravelPlan> _myTrips = [];
  List<TravelPlan> _connectionTrips = [];
  List<TravelOverlap> _overlaps = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      _travelService.getMyTrips(),
      _travelService.getConnectionTrips(),
      _travelService.findOverlaps(),
    ]);
    if (mounted) {
      setState(() {
        _myTrips = results[0] as List<TravelPlan>;
        _connectionTrips = results[1] as List<TravelPlan>;
        _overlaps = results[2] as List<TravelOverlap>;
        _loading = false;
      });
    }
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
                child: _loading
                    ? _buildLoadingState()
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildMyTripsTab(),
                          _buildMapTab(),
                          _buildOverlapsTab(),
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: VesparaColors.surface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF00BFA6).withOpacity(0.2),
                ),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: VesparaColors.primary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'VOYAGER',
                  style: GoogleFonts.cinzel(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 4,
                    color: VesparaColors.primary,
                  ),
                ),
                Text(
                  'Travel Plans & Meetups',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: VesparaColors.secondary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          _buildStatsChip(),
        ],
      ),
    );
  }

  Widget _buildStatsChip() {
    final activeCount = _myTrips.where((t) => t.isActive).length;
    final upcomingCount = _myTrips.where((t) => t.isUpcoming).length;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: VesparaColors.surface.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF00BFA6).withOpacity(0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (activeCount > 0) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF00D9A5),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '$activeCount live',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF00D9A5),
                  ),
                ),
                if (upcomingCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(width: 1, height: 12, color: VesparaColors.secondary.withOpacity(0.3)),
                  const SizedBox(width: 8),
                ],
              ],
              if (upcomingCount > 0)
                Text(
                  '$upcomingCount upcoming',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: VesparaColors.secondary,
                  ),
                ),
              if (activeCount == 0 && upcomingCount == 0)
                Text(
                  'No trips yet',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: VesparaColors.secondary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: VesparaColors.surface.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF00BFA6).withOpacity(0.1),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: VesparaColors.primary,
              unselectedLabelColor: VesparaColors.secondary,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: const Color(0xFF00BFA6).withOpacity(0.15),
                border: Border.all(
                  color: const Color(0xFF00BFA6).withOpacity(0.3),
                ),
              ),
              dividerColor: Colors.transparent,
              labelStyle: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              unselectedLabelStyle: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.luggage_rounded, size: 16),
                      const SizedBox(width: 6),
                      const Text('My Trips'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.map_rounded, size: 16),
                      const SizedBox(width: 6),
                      const Text('Map'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.people_rounded, size: 16),
                      const SizedBox(width: 6),
                      Text('Overlaps${_overlaps.isNotEmpty ? ' (${_overlaps.length})' : ''}'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MY TRIPS TAB
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildMyTripsTab() {
    if (_myTrips.isEmpty) {
      return _buildEmptyState(
        icon: Icons.flight_takeoff_rounded,
        title: 'No trips planned',
        subtitle: 'Add your first trip and see who\'s nearby!',
      );
    }

    final active = _myTrips.where((t) => t.isActive).toList();
    final upcoming = _myTrips.where((t) => t.isUpcoming && !t.isActive).toList();

    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF00BFA6),
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        children: [
          if (active.isNotEmpty) ...[
            _buildSectionHeader('🟢 Currently Traveling', '${active.length} active'),
            const SizedBox(height: 12),
            ...active.map((trip) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TripCard(
                    trip: trip,
                    isActive: true,
                    onTap: () => _openTripDetail(trip),
                  ),
                )),
            const SizedBox(height: 20),
          ],
          if (upcoming.isNotEmpty) ...[
            _buildSectionHeader('✈️ Upcoming', '${upcoming.length} planned'),
            const SizedBox(height: 12),
            ...upcoming.map((trip) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TripCard(
                    trip: trip,
                    onTap: () => _openTripDetail(trip),
                  ),
                )),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MAP TAB
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildMapTab() {
    final allTrips = [..._myTrips, ..._connectionTrips];
    if (allTrips.isEmpty) {
      return _buildEmptyState(
        icon: Icons.public_rounded,
        title: 'No trips to show',
        subtitle: 'Add a trip or wait for connections to share theirs',
      );
    }

    return TravelMapView(
      myTrips: _myTrips,
      connectionTrips: _connectionTrips,
      onTripTap: _openTripDetail,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // OVERLAPS TAB
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildOverlapsTab() {
    if (_overlaps.isEmpty) {
      return _buildEmptyState(
        icon: Icons.connect_without_contact_rounded,
        title: 'No travel overlaps yet',
        subtitle: 'When your trips overlap with connections,\nyou\'ll see them here',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildSectionHeader(
          '🎯 Travel Matches',
          '${_overlaps.length} overlap${_overlaps.length == 1 ? '' : 's'}',
        ),
        const SizedBox(height: 12),
        ..._overlaps.map((overlap) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: OverlapCard(overlap: overlap),
            )),
        const SizedBox(height: 80),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SHARED WIDGETS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSectionHeader(String title, String trailing) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: VesparaColors.primary,
          ),
        ),
        Text(
          trailing,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: VesparaColors.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF00BFA6).withOpacity(0.1),
              border: Border.all(
                color: const Color(0xFF00BFA6).withOpacity(0.2),
              ),
            ),
            child: Icon(icon, size: 36, color: const Color(0xFF00BFA6).withOpacity(0.6)),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: VesparaColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: VesparaColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFF00BFA6),
        strokeWidth: 2,
      ),
    );
  }

  Widget _buildFab() {
    return FloatingActionButton.extended(
      onPressed: _addTrip,
      backgroundColor: const Color(0xFF00BFA6),
      foregroundColor: VesparaColors.background,
      icon: const Icon(Icons.add_rounded),
      label: Text(
        'Add Trip',
        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
      ),
    );
  }

  void _addTrip() async {
    final result = await Navigator.push<TravelPlan>(
      context,
      MaterialPageRoute(builder: (_) => const AddTripScreen()),
    );
    if (result != null) {
      _loadData();
    }
  }

  void _openTripDetail(TravelPlan trip) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TripDetailScreen(trip: trip)),
    );
    _loadData();
  }
}
