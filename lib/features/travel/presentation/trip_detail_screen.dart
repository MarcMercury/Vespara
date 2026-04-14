import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/domain/models/travel_plan.dart';
import '../../../core/services/travel_service.dart';
import '../../../core/theme/app_theme.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// TRIP DETAIL SCREEN
/// Shows full trip details, companions, calendar export, and sharing
/// ════════════════════════════════════════════════════════════════════════════

class TripDetailScreen extends StatefulWidget {
  const TripDetailScreen({super.key, required this.trip});
  final TravelPlan trip;

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  late TravelPlan _trip;
  final _travelService = TravelService.instance;

  @override
  void initState() {
    super.initState();
    _trip = widget.trip;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VesparaColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: VesparaColors.background,
      leading: IconButton(
        icon: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: VesparaColors.background.withOpacity(0.6),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_rounded, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: VesparaColors.background.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.more_horiz_rounded, size: 20),
          ),
          onPressed: _showOptions,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: _buildHeroHeader(),
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _trip.certainty.color.withOpacity(0.3),
            _trip.certainty.color.withOpacity(0.05),
            VesparaColors.background,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -40,
            right: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _trip.certainty.color.withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            left: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _trip.certainty.color.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Content
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _trip.travelType.emoji,
                      style: const TextStyle(fontSize: 28),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _trip.certainty.color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _trip.certainty.color.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _trip.certainty.icon,
                            size: 12,
                            color: _trip.certainty.color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _trip.certainty.label,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _trip.certainty.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_trip.isActive) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00D9A5).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF00D9A5),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'LIVE',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF00D9A5),
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _trip.title,
                  style: GoogleFonts.cinzel(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: VesparaColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Destination & dates
          _buildInfoCard(),
          const SizedBox(height: 16),

          // Description
          if (_trip.description != null && _trip.description!.isNotEmpty) ...[
            _buildDetailSection(
              'About this trip',
              Icons.description_rounded,
              _trip.description!,
            ),
            const SizedBox(height: 16),
          ],

          // Accommodation
          if (_trip.accommodation != null && _trip.accommodation!.isNotEmpty) ...[
            _buildDetailSection(
              'Accommodation',
              Icons.hotel_rounded,
              _trip.accommodation!,
            ),
            const SizedBox(height: 16),
          ],

          // Notes
          if (_trip.notes != null && _trip.notes!.isNotEmpty) ...[
            _buildDetailSection(
              'Notes',
              Icons.sticky_note_2_rounded,
              _trip.notes!,
            ),
            const SizedBox(height: 16),
          ],

          // Companions
          if (_trip.companions.isNotEmpty) ...[
            _buildCompanionsSection(),
            const SizedBox(height: 16),
          ],

          // Calendar export
          _buildCalendarExport(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: VesparaColors.surface.withOpacity(0.2),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _trip.certainty.color.withOpacity(0.15),
            ),
          ),
          child: Column(
            children: [
              // Destination
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00BFA6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: Color(0xFF00BFA6),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Destination',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: VesparaColors.secondary,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _trip.destinationDisplay,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: VesparaColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                height: 1,
                color: VesparaColors.secondary.withOpacity(0.1),
              ),
              const SizedBox(height: 16),
              // Dates
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.date_range_rounded,
                      color: Color(0xFF6366F1),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dates',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: VesparaColors.secondary,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _trip.dateRange,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: VesparaColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: VesparaColors.surface.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_trip.durationDays} day${_trip.durationDays == 1 ? '' : 's'}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: VesparaColors.secondary,
                      ),
                    ),
                  ),
                ],
              ),
              if (_trip.isFlexible) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const SizedBox(width: 54),
                    Icon(
                      Icons.swap_horiz_rounded,
                      size: 14,
                      color: const Color(0xFFFBBF24).withOpacity(0.7),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Dates are flexible',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFFFBBF24).withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, IconData icon, String content) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: VesparaColors.surface.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: VesparaColors.secondary.withOpacity(0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: const Color(0xFF00BFA6).withOpacity(0.7)),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: VesparaColors.secondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                content,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: VesparaColors.primary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompanionsSection() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: VesparaColors.surface.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: VesparaColors.secondary.withOpacity(0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.people_rounded, size: 16, color: Color(0xFF00BFA6)),
                  const SizedBox(width: 8),
                  Text(
                    'Travel Companions',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: VesparaColors.secondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._trip.companions.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: const Color(0xFF00BFA6).withOpacity(0.2),
                          child: Text(
                            (c.userName ?? 'U')[0].toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF00BFA6),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            c.userName ?? 'Unknown',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: VesparaColors.primary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _companionStatusColor(c.status).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            c.status,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _companionStatusColor(c.status),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Color _companionStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return const Color(0xFF00D9A5);
      case 'maybe':
        return const Color(0xFFFBBF24);
      case 'declined':
        return const Color(0xFFEF5350);
      default:
        return VesparaColors.secondary;
    }
  }

  Widget _buildCalendarExport() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: VesparaColors.surface.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: VesparaColors.secondary.withOpacity(0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_month_rounded, size: 16, color: Color(0xFF00BFA6)),
                  const SizedBox(width: 8),
                  Text(
                    'Add to Calendar',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: VesparaColors.secondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildCalendarButton(
                    'Google',
                    Icons.event_rounded,
                    const Color(0xFF4285F4),
                    () => _exportToGoogle(),
                  ),
                  const SizedBox(width: 10),
                  _buildCalendarButton(
                    'Apple / Outlook',
                    Icons.download_rounded,
                    const Color(0xFFFF6B9D),
                    () => _exportIcs(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _exportToGoogle() {
    final url = _travelService.getGoogleCalendarUrl(_trip);
    // In a real app we'd launch the URL
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Google Calendar link copied!',
          style: GoogleFonts.inter(),
        ),
        backgroundColor: const Color(0xFF00BFA6),
      ),
    );
  }

  void _exportIcs() {
    final ics = _travelService.generateIcsContent(_trip);
    Clipboard.setData(ClipboardData(text: ics));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Calendar data copied! Paste into a .ics file to import.',
          style: GoogleFonts.inter(),
        ),
        backgroundColor: const Color(0xFF00BFA6),
      ),
    );
  }

  void _showOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1830),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: VesparaColors.secondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              _buildOptionTile(
                'Edit Trip',
                Icons.edit_rounded,
                const Color(0xFF00BFA6),
                () {
                  Navigator.pop(context);
                  // TODO: Navigate to edit screen
                },
              ),
              _buildOptionTile(
                'Invite Companion',
                Icons.person_add_rounded,
                const Color(0xFF6366F1),
                () {
                  Navigator.pop(context);
                  // TODO: Show invite picker
                },
              ),
              _buildOptionTile(
                'Share Trip',
                Icons.share_rounded,
                const Color(0xFFFFB74D),
                () {
                  Navigator.pop(context);
                  // TODO: Share functionality
                },
              ),
              if (!_trip.isCompleted && _trip.isPast)
                _buildOptionTile(
                  'Mark Completed',
                  Icons.check_circle_rounded,
                  const Color(0xFF00D9A5),
                  () async {
                    Navigator.pop(context);
                    await _travelService.completeTrip(_trip.id);
                    if (mounted) Navigator.pop(context);
                  },
                ),
              _buildOptionTile(
                'Cancel Trip',
                Icons.cancel_rounded,
                const Color(0xFFEF5350),
                () async {
                  Navigator.pop(context);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: const Color(0xFF1E1830),
                      title: Text(
                        'Cancel Trip?',
                        style: GoogleFonts.inter(color: VesparaColors.primary),
                      ),
                      content: Text(
                        'This will cancel "${_trip.title}". This cannot be undone.',
                        style: GoogleFonts.inter(color: VesparaColors.secondary),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text('Keep', style: GoogleFonts.inter()),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text(
                            'Cancel Trip',
                            style: GoogleFonts.inter(color: const Color(0xFFEF5350)),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await _travelService.cancelTrip(_trip.id);
                    if (mounted) Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
      title: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 14,
          color: VesparaColors.primary,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onTap: onTap,
    );
  }
}
