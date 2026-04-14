import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/domain/models/travel_plan.dart';
import '../../../core/theme/app_theme.dart';

/// Overlap card showing when two travel plans intersect
class OverlapCard extends StatelessWidget {
  const OverlapCard({super.key, required this.overlap});
  final TravelOverlap overlap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: VesparaColors.surface.withOpacity(0.2),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: overlap.isSameCity
                  ? const Color(0xFF00D9A5).withOpacity(0.3)
                  : const Color(0xFF6366F1).withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: user info + badge
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFF00BFA6).withOpacity(0.2),
                    backgroundImage: overlap.overlapUserAvatar != null
                        ? NetworkImage(overlap.overlapUserAvatar!)
                        : null,
                    child: overlap.overlapUserAvatar == null
                        ? Text(
                            overlap.overlapUserName[0].toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF00BFA6),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          overlap.overlapUserName,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: VesparaColors.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          overlap.overlapPlanTitle,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: VesparaColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildBadge(),
                ],
              ),
              const SizedBox(height: 14),

              // Overlap visual
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: VesparaColors.surface.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // Your trip
                    _buildTripRow(
                      'You',
                      overlap.planDestination,
                      _formatDateRange(overlap.planStart, overlap.planEnd),
                      const Color(0xFF00BFA6),
                    ),
                    const SizedBox(height: 8),
                    // Overlap indicator
                    Row(
                      children: [
                        const SizedBox(width: 32),
                        Expanded(
                          child: Container(
                            height: 2,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  const Color(0xFFFFB74D).withOpacity(0.6),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.sync_rounded,
                            size: 14,
                            color: const Color(0xFFFFB74D).withOpacity(0.8),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${overlap.overlapDays} day${overlap.overlapDays == 1 ? '' : 's'} overlap',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFFFB74D),
                            ),
                          ),
                          if (overlap.distanceKm != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              '• ${overlap.distanceKm!.round()} km apart',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: VesparaColors.secondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Their trip
                    _buildTripRow(
                      overlap.overlapUserName.split(' ').first,
                      overlap.overlapPlanDestination,
                      _formatDateRange(
                          overlap.overlapPlanStart, overlap.overlapPlanEnd),
                      const Color(0xFF6366F1),
                    ),
                  ],
                ),
              ),

              // CTA
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      'Message',
                      Icons.chat_bubble_outline_rounded,
                      const Color(0xFF00BFA6),
                      () {
                        // TODO: Navigate to Wire chat
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildActionButton(
                      'Plan Meetup',
                      Icons.event_rounded,
                      const Color(0xFF6366F1),
                      () {
                        // TODO: Create shared event
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge() {
    if (overlap.isSameCity) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF00D9A5).withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFF00D9A5).withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_on_rounded,
              size: 12,
              color: Color(0xFF00D9A5),
            ),
            const SizedBox(width: 4),
            Text(
              'Same City!',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF00D9A5),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Nearby',
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF6366F1),
        ),
      ),
    );
  }

  Widget _buildTripRow(
    String who,
    String destination,
    String dates,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.15),
          ),
          child: Center(
            child: Text(
              who[0].toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$who → $destination',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: VesparaColors.primary,
                ),
              ),
              Text(
                dates,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: VesparaColors.secondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
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
    );
  }

  String _formatDateRange(DateTime start, DateTime end) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    if (start.month == end.month) {
      return '${months[start.month - 1]} ${start.day}–${end.day}';
    }
    return '${months[start.month - 1]} ${start.day} – ${months[end.month - 1]} ${end.day}';
  }
}
