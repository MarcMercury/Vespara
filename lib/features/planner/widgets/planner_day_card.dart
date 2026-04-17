import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../presentation/planner_screen.dart';

/// A card representing a single planner entry in the day view or agenda.
class PlannerDayCard extends StatelessWidget {
  final PlannerEntry entry;

  const PlannerDayCard({super.key, required this.entry});

  Color get _typeColor {
    switch (entry.type) {
      case PlannerEntryType.event:
        return const Color(0xFFCE93D8);
      case PlannerEntryType.travel:
        return const Color(0xFF00BFA6);
      case PlannerEntryType.date:
        return const Color(0xFFFF6B9D);
      case PlannerEntryType.connectionTravel:
        return const Color(0xFF4ECDC4);
      case PlannerEntryType.connectionEvent:
        return const Color(0xFF7C4DFF);
    }
  }

  IconData get _typeIcon {
    switch (entry.type) {
      case PlannerEntryType.event:
        return Icons.event_rounded;
      case PlannerEntryType.travel:
        return Icons.flight_takeoff_rounded;
      case PlannerEntryType.date:
        return Icons.favorite_rounded;
      case PlannerEntryType.connectionTravel:
        return Icons.people_alt_rounded;
      case PlannerEntryType.connectionEvent:
        return Icons.groups_rounded;
    }
  }

  String get _typeLabel {
    switch (entry.type) {
      case PlannerEntryType.event:
        return 'Event';
      case PlannerEntryType.travel:
        return 'Travel';
      case PlannerEntryType.date:
        return 'Date';
      case PlannerEntryType.connectionTravel:
        return 'Connection Trip';
      case PlannerEntryType.connectionEvent:
        return 'Connection Event';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(color: _typeColor, width: 3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _typeColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_typeIcon, color: _typeColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      _typeLabel,
                      style: GoogleFonts.inter(
                        color: _typeColor.withOpacity(0.8),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (entry.location != null) ...[
                      Text(' · ',
                          style: GoogleFonts.inter(
                              color: Colors.white24, fontSize: 11)),
                      Expanded(
                        child: Text(
                          entry.location!,
                          style: GoogleFonts.inter(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                if (entry.ownerName != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      entry.ownerName!,
                      style: GoogleFonts.inter(
                        color: Colors.white24,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white16, size: 20),
        ],
      ),
    );
  }
}
