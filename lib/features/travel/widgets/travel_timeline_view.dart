import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/domain/models/travel_plan.dart';
import '../../../core/theme/app_theme.dart';

/// Visual timeline showing trips across a date axis
class TravelTimelineView extends StatelessWidget {
  const TravelTimelineView({
    super.key,
    required this.trips,
    this.onTripTap,
  });

  final List<TravelPlan> trips;
  final void Function(TravelPlan)? onTripTap;

  @override
  Widget build(BuildContext context) {
    if (trips.isEmpty) {
      return const Center(
        child: Text(
          'No trips to display',
          style: TextStyle(color: VesparaColors.secondary),
        ),
      );
    }

    // Sort by start date
    final sorted = [...trips]..sort((a, b) => a.startDate.compareTo(b.startDate));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final trip = sorted[index];
        final isLast = index == sorted.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline spine
              SizedBox(
                width: 40,
                child: Column(
                  children: [
                    // Dot
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: trip.certainty.color.withOpacity(0.2),
                        border: Border.all(
                          color: trip.certainty.color,
                          width: 2,
                        ),
                      ),
                    ),
                    // Line
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                trip.certainty.color.withOpacity(0.3),
                                (index + 1 < sorted.length
                                        ? sorted[index + 1].certainty.color
                                        : VesparaColors.secondary)
                                    .withOpacity(0.3),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Trip card
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: GestureDetector(
                    onTap: () => onTripTap?.call(trip),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: VesparaColors.surface.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: trip.certainty.color.withOpacity(0.15),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    trip.travelType.emoji,
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      trip.title,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: VesparaColors.primary,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          trip.certainty.color.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      trip.certainty.label,
                                      style: GoogleFonts.inter(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                        color: trip.certainty.color,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_rounded,
                                    size: 12,
                                    color: VesparaColors.secondary.withOpacity(0.6),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    trip.destinationDisplay,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: VesparaColors.secondary,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    trip.dateRange,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: VesparaColors.secondary,
                                    ),
                                  ),
                                ],
                              ),
                              if (trip.userName != null) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 10,
                                      backgroundColor: const Color(0xFF00BFA6)
                                          .withOpacity(0.15),
                                      child: Text(
                                        trip.userName![0].toUpperCase(),
                                        style: GoogleFonts.inter(
                                          fontSize: 8,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF00BFA6),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      trip.userName!,
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
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
