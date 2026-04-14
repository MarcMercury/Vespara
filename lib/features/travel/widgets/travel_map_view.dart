import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/domain/models/travel_plan.dart';
import '../../../core/theme/app_theme.dart';

/// Map-style view showing where connections are traveling
/// Uses a stylized card grid since google_maps requires platform-specific setup
class TravelMapView extends StatelessWidget {
  const TravelMapView({
    super.key,
    required this.myTrips,
    required this.connectionTrips,
    this.onTripTap,
  });

  final List<TravelPlan> myTrips;
  final List<TravelPlan> connectionTrips;
  final void Function(TravelPlan)? onTripTap;

  @override
  Widget build(BuildContext context) {
    // Group trips by destination city
    final cityGroups = <String, List<TravelPlan>>{};
    for (final trip in [...myTrips, ...connectionTrips]) {
      final city = trip.destinationCity.toLowerCase();
      cityGroups.putIfAbsent(city, () => []).add(trip);
    }

    final cities = cityGroups.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        // Summary header
        _buildSummaryHeader(cities.length),
        const SizedBox(height: 16),

        // City cards
        ...cities.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _buildCityCard(context, entry.key, entry.value),
            )),

        // Timeline view
        if (connectionTrips.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildTimelineHeader(),
          const SizedBox(height: 12),
          ...connectionTrips.map((trip) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildTimelineTripRow(trip),
              )),
        ],

        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildSummaryHeader(int cityCount) {
    final totalPeople =
        connectionTrips.map((t) => t.userId).toSet().length;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF00BFA6).withOpacity(0.1),
                const Color(0xFF6366F1).withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF00BFA6).withOpacity(0.15),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF00BFA6).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.public_rounded,
                  color: Color(0xFF00BFA6),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Travel Network',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: VesparaColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$totalPeople connection${totalPeople == 1 ? '' : 's'} traveling to $cityCount cit${cityCount == 1 ? 'y' : 'ies'}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: VesparaColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCityCard(
    BuildContext context,
    String city,
    List<TravelPlan> trips,
  ) {
    final myTripsHere = trips.where((t) => myTrips.contains(t)).toList();
    final theirTripsHere = trips.where((t) => connectionTrips.contains(t)).toList();
    final isMyDestination = myTripsHere.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: VesparaColors.surface.withOpacity(0.2),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isMyDestination
                  ? const Color(0xFF00BFA6).withOpacity(0.3)
                  : VesparaColors.secondary.withOpacity(0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // City header
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isMyDestination
                            ? [
                                const Color(0xFF00BFA6).withOpacity(0.2),
                                const Color(0xFF00BFA6).withOpacity(0.1),
                              ]
                            : [
                                const Color(0xFF6366F1).withOpacity(0.15),
                                const Color(0xFF6366F1).withOpacity(0.05),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.location_city_rounded,
                      size: 20,
                      color: isMyDestination
                          ? const Color(0xFF00BFA6)
                          : const Color(0xFF6366F1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          city[0].toUpperCase() + city.substring(1),
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: VesparaColors.primary,
                          ),
                        ),
                        Text(
                          '${trips.length} trip${trips.length == 1 ? '' : 's'}${isMyDestination ? ' • You\'re going!' : ''}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: isMyDestination
                                ? const Color(0xFF00BFA6)
                                : VesparaColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isMyDestination)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00BFA6).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '✨ You too!',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF00BFA6),
                        ),
                      ),
                    ),
                ],
              ),
              if (theirTripsHere.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...theirTripsHere.take(3).map((trip) => GestureDetector(
                      onTap: () => onTripTap?.call(trip),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor:
                                  const Color(0xFF6366F1).withOpacity(0.15),
                              backgroundImage: trip.userAvatar != null
                                  ? NetworkImage(trip.userAvatar!)
                                  : null,
                              child: trip.userAvatar == null
                                  ? Text(
                                      (trip.userName ?? '?')[0].toUpperCase(),
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF6366F1),
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                trip.userName ?? 'Connection',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: VesparaColors.primary,
                                ),
                              ),
                            ),
                            Text(
                              trip.dateRange,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: VesparaColors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
                if (theirTripsHere.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(left: 38),
                    child: Text(
                      '+${theirTripsHere.length - 3} more',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF00BFA6),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineHeader() {
    return Text(
      'UPCOMING TRIPS',
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
        color: VesparaColors.secondary,
      ),
    );
  }

  Widget _buildTimelineTripRow(TravelPlan trip) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: VesparaColors.surface.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: VesparaColors.secondary.withOpacity(0.08),
        ),
      ),
      child: Row(
        children: [
          // Date badge
          Container(
            width: 44,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: trip.certainty.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(
                  _monthAbbr(trip.startDate.month),
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: trip.certainty.color,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  '${trip.startDate.day}',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: trip.certainty.color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip.userName ?? 'Connection',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: VesparaColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 11,
                      color: VesparaColors.secondary.withOpacity(0.6),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      trip.destinationDisplay,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: VesparaColors.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '${trip.durationDays}d',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: VesparaColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  String _monthAbbr(int month) {
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
    ];
    return months[month - 1];
  }
}
