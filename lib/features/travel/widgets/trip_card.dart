import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/domain/models/travel_plan.dart';
import '../../../core/theme/app_theme.dart';

/// Trip card widget used in the My Trips list
class TripCard extends StatelessWidget {
  const TripCard({
    super.key,
    required this.trip,
    this.isActive = false,
    this.showUser = false,
    this.onTap,
  });

  final TravelPlan trip;
  final bool isActive;
  final bool showUser;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: VesparaColors.surface.withOpacity(0.2),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isActive
                    ? const Color(0xFF00D9A5).withOpacity(0.3)
                    : trip.certainty.color.withOpacity(0.15),
                width: isActive ? 1.5 : 1,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: const Color(0xFF00D9A5).withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: -5,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: type emoji + destination + certainty badge
                Row(
                  children: [
                    Text(
                      trip.travelType.emoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trip.title,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: VesparaColors.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: 12,
                                color: const Color(0xFF00BFA6).withOpacity(0.7),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  trip.destinationDisplay,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: VesparaColors.secondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _buildCertaintyBadge(),
                  ],
                ),
                const SizedBox(height: 12),

                // Date bar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: VesparaColors.surface.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.date_range_rounded,
                        size: 14,
                        color: VesparaColors.secondary.withOpacity(0.7),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        trip.dateRange,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: VesparaColors.primary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${trip.durationDays}d',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: VesparaColors.secondary,
                        ),
                      ),
                      if (isActive) ...[
                        const SizedBox(width: 10),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF00D9A5),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00D9A5).withOpacity(0.5),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'NOW',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF00D9A5),
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // User row (for connection trips)
                if (showUser && trip.userName != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: const Color(0xFF00BFA6).withOpacity(0.2),
                        child: Text(
                          trip.userName![0].toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF00BFA6),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        trip.userName!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: VesparaColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ],

                // Companions count
                if (trip.companions.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.people_outline_rounded,
                        size: 14,
                        color: VesparaColors.secondary.withOpacity(0.6),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${trip.companions.length} companion${trip.companions.length == 1 ? '' : 's'}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: VesparaColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCertaintyBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: trip.certainty.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: trip.certainty.color.withOpacity(0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(trip.certainty.icon, size: 12, color: trip.certainty.color),
          const SizedBox(width: 4),
          Text(
            trip.certainty.label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: trip.certainty.color,
            ),
          ),
        ],
      ),
    );
  }
}
