import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/domain/models/match.dart';
import '../../../core/domain/models/vespara_event.dart';
import '../../../core/domain/models/wire_models.dart';
import '../../../core/providers/events_provider.dart';
import '../../../core/providers/match_state_provider.dart';
import '../../../core/providers/wire_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../wire/presentation/wire_chat_screen.dart';
import 'event_creation_screen.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// EVENT DETAIL SCREEN - Full Event View with RSVP
/// Shows all event details, guest list, and RSVP options
/// ════════════════════════════════════════════════════════════════════════════

class EventDetailScreen extends ConsumerStatefulWidget {
  const EventDetailScreen({super.key, required this.event});
  final VesparaEvent event;

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  late VesparaEvent _event;

  String get _currentUserId =>
      Supabase.instance.client.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _event = widget.event;
  }

  bool get _isHost => _event.hostId == _currentUserId;

  String? get _myRsvpStatus {
    final rsvp =
        _event.rsvps.where((r) => r.userId == _currentUserId).firstOrNull;
    return rsvp?.status;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: VesparaColors.background,
        body: CustomScrollView(
          slivers: [
            // Cover image header
            _buildCoverHeader(),

            // Event content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildEventTitle(),
                    const SizedBox(height: 24),
                    _buildDateTime(),
                    const SizedBox(height: 16),
                    _buildLocation(),
                    const SizedBox(height: 24),
                    _buildHostSection(),
                    if (_event.description != null) ...[
                      const SizedBox(height: 24),
                      _buildDescription(),
                    ],
                    if (_event.links.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildLinks(),
                    ],
                    const SizedBox(height: 24),
                    _buildGuestList(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomBar(),
      );

  Widget _buildCoverHeader() => SliverAppBar(
        expandedHeight: 300,
        pinned: true,
        backgroundColor: VesparaColors.surface,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _showEventOptions,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.more_horiz, color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
        ],
        flexibleSpace: FlexibleSpaceBar(
          background: Stack(
            fit: StackFit.expand,
            children: [
              // Cover image
              if (_event.coverImageUrl != null)
                Image.network(
                  _event.coverImageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildCoverGradient(),
                )
              else
                _buildCoverGradient(),

              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.5),
                    ],
                  ),
                ),
              ),

              // Content rating badge
              if (_event.contentRating != 'PG')
                Positioned(
                  top: 100,
                  right: 16,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getContentRatingColor(),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.local_fire_department,
                          size: 16,
                          color: VesparaColors.background,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _event.contentRating.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: VesparaColors.background,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );

  Widget _buildCoverGradient() => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              VesparaColors.glow.withOpacity(0.5),
              const Color(0xFF2D1B4E),
              VesparaColors.surface,
            ],
          ),
        ),
        child: Center(
          child: Icon(
            Icons.event,
            size: 80,
            color: VesparaColors.primary.withOpacity(0.3),
          ),
        ),
      );

  Color _getContentRatingColor() {
    switch (_event.contentRating.toLowerCase()) {
      case 'flirty':
        return VesparaColors.tagsYellow;
      case 'spicy':
        return const Color(0xFFFF6B35);
      case 'explicit':
        return VesparaColors.tagsRed;
      default:
        return VesparaColors.secondary;
    }
  }

  Widget _buildEventTitle() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Visibility badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _event.visibility == EventVisibility.public
                  ? VesparaColors.success.withOpacity(0.2)
                  : VesparaColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _event.visibility == EventVisibility.public
                      ? Icons.public
                      : Icons.lock_outline,
                  size: 14,
                  color: _event.visibility == EventVisibility.public
                      ? VesparaColors.success
                      : VesparaColors.secondary,
                ),
                const SizedBox(width: 4),
                Text(
                  _event.visibility.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _event.visibility == EventVisibility.public
                        ? VesparaColors.success
                        : VesparaColors.secondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Event title
          Text(
            _event.title,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: VesparaColors.primary,
              height: 1.2,
            ),
          ),
        ],
      );

  Widget _buildDateTime() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: VesparaColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: VesparaColors.border),
        ),
        child: Row(
          children: [
            // Date icon with calendar style
            Container(
              width: 56,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: VesparaColors.glow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    _getMonthAbbr(_event.startTime.month),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: VesparaColors.background,
                    ),
                  ),
                  Text(
                    _event.startTime.day.toString(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: VesparaColors.background,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // Date & time details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatFullDate(_event.startTime),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: VesparaColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTimeRange(),
                    style: const TextStyle(
                      fontSize: 14,
                      color: VesparaColors.secondary,
                    ),
                  ),
                ],
              ),
            ),

            // Add to calendar
            IconButton(
              onPressed: _addToCalendar,
              icon: const Icon(
                Icons.calendar_today_outlined,
                color: VesparaColors.glow,
              ),
            ),
          ],
        ),
      );

  Widget _buildLocation() {
    if (_event.venueAddress == null && _event.venueName == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VesparaColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VesparaColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: VesparaColors.glow.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _event.isVirtual ? Icons.videocam : Icons.location_on,
              color: VesparaColors.glow,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_event.venueName != null)
                  Text(
                    _event.venueName!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: VesparaColors.primary,
                    ),
                  ),
                if (_event.venueAddress != null)
                  Text(
                    _event.venueAddress!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: VesparaColors.secondary,
                    ),
                  ),
              ],
            ),
          ),
          if (!_event.isVirtual)
            IconButton(
              onPressed: _openMaps,
              icon: const Icon(
                Icons.directions,
                color: VesparaColors.glow,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHostSection() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: VesparaColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: VesparaColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hosted by',
              style: TextStyle(
                fontSize: 12,
                color: VesparaColors.secondary,
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                // Host avatar
                CircleAvatar(
                  radius: 28,
                  backgroundColor: VesparaColors.glow.withOpacity(0.3),
                  backgroundImage: _event.hostAvatarUrl != null
                      ? NetworkImage(_event.hostAvatarUrl!)
                      : null,
                  child: _event.hostAvatarUrl == null
                      ? Text(
                          _event.hostName[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: VesparaColors.glow,
                          ),
                        )
                      : null,
                ),

                const SizedBox(width: 12),

                // Host info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _event.hostName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: VesparaColors.primary,
                            ),
                          ),
                          if (_event.hostNickname != null) ...[
                            const SizedBox(width: 4),
                            Text(
                              '(${_event.hostNickname})',
                              style: const TextStyle(
                                fontSize: 14,
                                color: VesparaColors.secondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Row(
                        children: [
                          Icon(Icons.verified,
                              size: 14, color: VesparaColors.success,),
                          SizedBox(width: 4),
                          Text(
                            'Verified Host',
                            style: TextStyle(
                              fontSize: 12,
                              color: VesparaColors.success,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                if (!_isHost)
                  OutlinedButton(
                    onPressed: _messageHost,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: VesparaColors.glow),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Message',
                      style: TextStyle(color: VesparaColors.glow),
                    ),
                  ),
              ],
            ),

            // Co-hosts
            if (_event.coHosts.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(color: VesparaColors.border),
              const SizedBox(height: 12),
              const Text(
                'Co-hosts',
                style: TextStyle(
                  fontSize: 12,
                  color: VesparaColors.secondary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _event.coHosts
                    .map(
                      (coHost) => Chip(
                        avatar: CircleAvatar(
                          backgroundColor: VesparaColors.glow.withOpacity(0.3),
                          backgroundImage: coHost.avatarUrl != null
                              ? NetworkImage(coHost.avatarUrl!)
                              : null,
                          child: coHost.avatarUrl == null
                              ? Text(coHost.name[0])
                              : null,
                        ),
                        label: Text(coHost.name),
                        backgroundColor: VesparaColors.surface,
                        side: const BorderSide(color: VesparaColors.border),
                        labelStyle:
                            const TextStyle(color: VesparaColors.primary),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      );

  Widget _buildDescription() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: VesparaColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _event.description!,
            style: const TextStyle(
              fontSize: 16,
              color: VesparaColors.primary,
              height: 1.5,
            ),
          ),
        ],
      );

  Widget _buildLinks() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Links',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: VesparaColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          ..._event.links.map(
            (link) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: VesparaColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: VesparaColors.border),
              ),
              child: Row(
                children: [
                  Text(link.type.icon, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          link.label ?? link.type.label,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: VesparaColors.primary,
                          ),
                        ),
                        Text(
                          link.url,
                          style: const TextStyle(
                            fontSize: 12,
                            color: VesparaColors.glow,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.open_in_new,
                      color: VesparaColors.glow, size: 20,),
                ],
              ),
            ),
          ),
        ],
      );

  Widget _buildGuestList() {
    final going = _event.rsvps.where((r) => r.status == 'going').toList();
    final maybe = _event.rsvps.where((r) => r.status == 'maybe').toList();
    final invited = _event.rsvps.where((r) => r.status == 'invited').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Guest List',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: VesparaColors.primary,
              ),
            ),
            if (_event.maxSpots != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _event.isFull
                      ? VesparaColors.error.withOpacity(0.2)
                      : VesparaColors.glow.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _event.isFull
                      ? 'FULL'
                      : '${_event.spotsRemaining} spots left',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _event.isFull
                        ? VesparaColors.error
                        : VesparaColors.glow,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 16),

        // RSVP summary chips
        Row(
          children: [
            _buildGuestChip('👍 ${going.length} Going', VesparaColors.success),
            const SizedBox(width: 8),
            _buildGuestChip(
                '🤔 ${maybe.length} Maybe', VesparaColors.tagsYellow,),
            const SizedBox(width: 8),
            _buildGuestChip(
                '💌 ${invited.length} Invited', VesparaColors.secondary,),
          ],
        ),

        const SizedBox(height: 16),

        // Guest list
        if (going.isNotEmpty) ...[
          _buildGuestSection('Going', going, VesparaColors.success),
          const SizedBox(height: 12),
        ],
        if (maybe.isNotEmpty) ...[
          _buildGuestSection('Maybe', maybe, VesparaColors.tagsYellow),
          const SizedBox(height: 12),
        ],
        if (_isHost && invited.isNotEmpty) ...[
          _buildGuestSection('Pending', invited, VesparaColors.secondary),
        ],
      ],
    );
  }

  Widget _buildGuestChip(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      );

  Widget _buildGuestSection(
          String title, List<EventRsvp> guests, Color color,) =>
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: VesparaColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: VesparaColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: guests.map(_buildGuestAvatar).toList(),
            ),
          ],
        ),
      );

  Widget _buildGuestAvatar(EventRsvp guest) => Column(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: VesparaColors.glow.withOpacity(0.3),
            backgroundImage: guest.userAvatarUrl != null
                ? NetworkImage(guest.userAvatarUrl!)
                : null,
            child: guest.userAvatarUrl == null
                ? Text(
                    guest.userName[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: VesparaColors.glow,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 4),
          Text(
            guest.userName.split(' ').first,
            style: const TextStyle(
              fontSize: 11,
              color: VesparaColors.secondary,
            ),
          ),
        ],
      );

  Widget _buildBottomBar() => Container(
        padding: EdgeInsets.fromLTRB(
            20, 16, 20, 16 + MediaQuery.of(context).padding.bottom,),
        decoration: BoxDecoration(
          color: VesparaColors.surface,
          border: const Border(
            top: BorderSide(color: VesparaColors.border),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: _isHost ? _buildHostActions() : _buildRsvpActions(),
      );

  Widget _buildHostActions() => Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _editEvent,
              icon: const Icon(Icons.edit, color: VesparaColors.glow),
              label: const Text('Edit',
                  style: TextStyle(color: VesparaColors.glow),),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: VesparaColors.glow),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _inviteGuests,
              icon:
                  const Icon(Icons.person_add, color: VesparaColors.background),
              label: const Text('Invite Guests',
                  style: TextStyle(color: VesparaColors.background),),
              style: ElevatedButton.styleFrom(
                backgroundColor: VesparaColors.glow,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );

  Widget _buildRsvpActions() => Row(
        children: [
          // Going button
          Expanded(
            child: _buildRsvpButton(
              '👍',
              'Going',
              VesparaColors.success,
              _myRsvpStatus == 'going',
              () => _updateRsvp('going'),
            ),
          ),
          const SizedBox(width: 8),
          // Maybe button
          Expanded(
            child: _buildRsvpButton(
              '🤔',
              'Maybe',
              VesparaColors.tagsYellow,
              _myRsvpStatus == 'maybe',
              () => _updateRsvp('maybe'),
            ),
          ),
          const SizedBox(width: 8),
          // Can't go button
          Expanded(
            child: _buildRsvpButton(
              '😢',
              "Can't Go",
              VesparaColors.error,
              _myRsvpStatus == 'cant_go',
              () => _updateRsvp('cant_go'),
            ),
          ),
        ],
      );

  Widget _buildRsvpButton(String emoji, String label, Color color,
          bool isSelected, VoidCallback onTap,) =>
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? color : VesparaColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : VesparaColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : VesparaColors.primary,
                ),
              ),
            ],
          ),
        ),
      );

  // Helper methods
  String _getMonthAbbr(int month) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return months[month - 1];
  }

  String _formatFullDate(DateTime date) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
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
    return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }

  String _formatTimeRange() {
    final startHour = _event.startTime.hour > 12
        ? _event.startTime.hour - 12
        : (_event.startTime.hour == 0 ? 12 : _event.startTime.hour);
    final startPeriod = _event.startTime.hour >= 12 ? 'PM' : 'AM';

    if (_event.endTime != null) {
      final endHour = _event.endTime!.hour > 12
          ? _event.endTime!.hour - 12
          : (_event.endTime!.hour == 0 ? 12 : _event.endTime!.hour);
      final endPeriod = _event.endTime!.hour >= 12 ? 'PM' : 'AM';
      return '$startHour:${_event.startTime.minute.toString().padLeft(2, '0')} $startPeriod - $endHour:${_event.endTime!.minute.toString().padLeft(2, '0')} $endPeriod';
    }

    return '$startHour:${_event.startTime.minute.toString().padLeft(2, '0')} $startPeriod';
  }

  // Action methods
  void _showEventOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: VesparaColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isHost) ...[
              ListTile(
                leading: const Icon(Icons.edit, color: VesparaColors.glow),
                title: const Text('Edit Event',
                    style: TextStyle(color: VesparaColors.primary),),
                onTap: () {
                  Navigator.pop(context);
                  _editEvent();
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.content_copy, color: VesparaColors.glow),
                title: const Text('Duplicate Event',
                    style: TextStyle(color: VesparaColors.primary),),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.cancel, color: VesparaColors.error),
                title: const Text('Cancel Event',
                    style: TextStyle(color: VesparaColors.error),),
                onTap: () => Navigator.pop(context),
              ),
            ] else ...[
              ListTile(
                leading:
                    const Icon(Icons.calendar_today, color: VesparaColors.glow),
                title: const Text('Add to Calendar',
                    style: TextStyle(color: VesparaColors.primary),),
                onTap: () {
                  Navigator.pop(context);
                  _addToCalendar();
                },
              ),
              ListTile(
                leading: const Icon(Icons.report, color: VesparaColors.error),
                title: const Text('Report Event',
                    style: TextStyle(color: VesparaColors.error),),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _addToCalendar() {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Added to calendar!'),
        backgroundColor: VesparaColors.success,
      ),
    );
  }

  void _openMaps() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening maps...')),
    );
  }

  void _messageHost() async {
    // Get or create a direct conversation with the host
    final conversationId = await ref
        .read(wireProvider.notifier)
        .getOrCreateDirectConversation(_event.hostId);

    if (conversationId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open chat. Please try again.'),
            backgroundColor: VesparaColors.error,
          ),
        );
      }
      return;
    }

    // Navigate to the Wire chat screen
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WireChatScreen(
            conversation: WireConversation(
              id: conversationId,
              name: _event.hostName,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ),
        ),
      );
    }
  }

  void _editEvent() async {
    final result = await Navigator.push<VesparaEvent>(
      context,
      MaterialPageRoute(
        builder: (context) => EventCreationScreen(eventToEdit: _event),
      ),
    );

    // If the event was updated, refresh the local state
    if (result != null && mounted) {
      setState(() {
        _event = result;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event updated!'),
          backgroundColor: VesparaColors.success,
        ),
      );
    }
  }

  void _inviteGuests() {
    showModalBottomSheet(
      context: context,
      backgroundColor: VesparaColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _InviteGuestsSheet(
        event: _event,
        onInvitesSent: (invitedCount) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sent $invitedCount invite${invitedCount == 1 ? '' : 's'}! 🎉'),
              backgroundColor: VesparaColors.success,
            ),
          );
        },
      ),
    );
  }

  Future<void> _updateRsvp(String status) async {
    HapticFeedback.heavyImpact();

    // Persist to database via provider
    final success = await ref.read(eventsProvider.notifier).respondToInvite(
          eventId: _event.id,
          status: status,
        );

    if (!success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update RSVP. Please try again.'),
            backgroundColor: VesparaColors.error,
          ),
        );
      }
      return;
    }

    // Update the event's RSVPs locally for immediate UI feedback
    final updatedRsvps = _event.rsvps.map((r) {
      if (r.userId == _currentUserId) {
        return EventRsvp(
          id: r.id,
          eventId: r.eventId,
          userId: r.userId,
          userName: r.userName,
          userAvatarUrl: r.userAvatarUrl,
          status: status,
          createdAt: r.createdAt,
          respondedAt: DateTime.now(),
        );
      }
      return r;
    }).toList();

    // If user wasn't in the list, add them
    if (!updatedRsvps.any((r) => r.userId == _currentUserId)) {
      updatedRsvps.add(
        EventRsvp(
          id: 'rsvp-${DateTime.now().millisecondsSinceEpoch}',
          eventId: _event.id,
          userId: _currentUserId,
          userName: 'You',
          status: status,
          createdAt: DateTime.now(),
          respondedAt: DateTime.now(),
        ),
      );
    }

    setState(() {
      _event = _event.copyWith(rsvps: updatedRsvps);
    });

    String message;
    switch (status) {
      case 'going':
        message = "You're going! 🎉";
        break;
      case 'maybe':
        message = 'Marked as maybe 🤔';
        break;
      case 'cant_go':
        message = "Sorry you can't make it 😢";
        break;
      default:
        message = 'RSVP updated';
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: VesparaColors.success,
        ),
      );
    }
  }
}

/// ════════════════════════════════════════════════════════════════════════════
/// INVITE GUESTS SHEET - Shows matches to invite to event
/// ════════════════════════════════════════════════════════════════════════════

class _InviteGuestsSheet extends ConsumerStatefulWidget {
  const _InviteGuestsSheet({
    required this.event,
    required this.onInvitesSent,
  });

  final VesparaEvent event;
  final void Function(int invitedCount) onInvitesSent;

  @override
  ConsumerState<_InviteGuestsSheet> createState() => _InviteGuestsSheetState();
}

class _InviteGuestsSheetState extends ConsumerState<_InviteGuestsSheet> {
  final Set<String> _selectedIds = {};
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Match> get _filteredMatches {
    final matchState = ref.watch(matchStateProvider);
    final matches = matchState.matches.where((m) => !m.isArchived).toList();
    
    if (_searchQuery.isEmpty) return matches;
    
    return matches.where((m) {
      final name = m.matchedUserName?.toLowerCase() ?? '';
      return name.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final matches = _filteredMatches;
    
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Invite from Sanctum',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: VesparaColors.primary,
                        ),
                      ),
                    ),
                    if (_selectedIds.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: VesparaColors.glow.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${_selectedIds.length} selected',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: VesparaColors.glow,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search matches...',
                    hintStyle: const TextStyle(color: VesparaColors.secondary),
                    prefixIcon: const Icon(Icons.search, color: VesparaColors.secondary),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: VesparaColors.secondary),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: VesparaColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: VesparaColors.glow),
                    ),
                  ),
                  style: const TextStyle(color: VesparaColors.primary),
                ),
              ],
            ),
          ),

          // Matches list
          Expanded(
            child: matches.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: matches.length,
                    itemBuilder: (context, index) {
                      final match = matches[index];
                      final isSelected = _selectedIds.contains(match.matchedUserId);
                      
                      return _buildMatchTile(match, isSelected);
                    },
                  ),
          ),

          // Send button
          Padding(
            padding: EdgeInsets.fromLTRB(
              20, 12, 20, 12 + MediaQuery.of(context).padding.bottom,
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedIds.isEmpty ? null : _sendInvites,
                style: ElevatedButton.styleFrom(
                  backgroundColor: VesparaColors.glow,
                  disabledBackgroundColor: VesparaColors.surface,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _selectedIds.isEmpty
                      ? 'Select people to invite'
                      : 'Send ${_selectedIds.length} Invite${_selectedIds.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _selectedIds.isEmpty
                        ? VesparaColors.secondary
                        : VesparaColors.background,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasMatches = ref.watch(matchStateProvider).matches.isNotEmpty;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasMatches ? Icons.search_off : Icons.favorite_border,
              size: 64,
              color: VesparaColors.secondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              hasMatches ? 'No matches found' : 'No matches yet',
              style: const TextStyle(
                color: VesparaColors.primary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasMatches
                  ? 'Try a different search'
                  : 'Match with people in Discover to invite them to events',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: VesparaColors.secondary.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchTile(Match match, bool isSelected) => GestureDetector(
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedIds.remove(match.matchedUserId);
            } else {
              _selectedIds.add(match.matchedUserId);
            }
          });
          HapticFeedback.selectionClick();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? VesparaColors.glow.withOpacity(0.15)
                : VesparaColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? VesparaColors.glow : VesparaColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: VesparaColors.glow.withOpacity(0.3),
                backgroundImage: match.matchedUserAvatar != null
                    ? NetworkImage(match.matchedUserAvatar!)
                    : null,
                child: match.matchedUserAvatar == null
                    ? Text(
                        (match.matchedUserName ?? '?')[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: VesparaColors.glow,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),

              // Name and status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      match.matchedUserName ?? 'Unknown',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? VesparaColors.glow
                            : VesparaColors.primary,
                      ),
                    ),
                    Text(
                      match.priority.label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: VesparaColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Checkbox
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected ? VesparaColors.glow : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected ? VesparaColors.glow : VesparaColors.secondary,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 16, color: VesparaColors.background)
                    : null,
              ),
            ],
          ),
        ),
      );

  void _sendInvites() {
    // TODO: Actually send invites via eventsProvider
    Navigator.pop(context);
    widget.onInvitesSent(_selectedIds.length);
  }
}