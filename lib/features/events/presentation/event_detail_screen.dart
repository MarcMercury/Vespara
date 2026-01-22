import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/domain/models/vespara_event.dart';
import '../../../core/providers/events_provider.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// EVENT DETAIL SCREEN - Full Event View with RSVP
/// Shows all event details, guest list, and RSVP options
/// ════════════════════════════════════════════════════════════════════════════

class EventDetailScreen extends ConsumerStatefulWidget {
  final VesparaEvent event;

  const EventDetailScreen({super.key, required this.event});

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  late VesparaEvent _event;
  final String _currentUserId = 'current-user';

  @override
  void initState() {
    super.initState();
    _event = widget.event;
  }

  bool get _isHost => _event.hostId == _currentUserId;
  
  String? get _myRsvpStatus {
    final rsvp = _event.rsvps.where((r) => r.userId == _currentUserId).firstOrNull;
    return rsvp?.status;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
  }

  Widget _buildCoverHeader() {
    return SliverAppBar(
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
          onPressed: _shareEvent,
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.share, color: Colors.white),
          ),
        ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getContentRatingColor(),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        size: 16,
                        color: VesparaColors.background,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _event.contentRating.toUpperCase(),
                        style: TextStyle(
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
  }

  Widget _buildCoverGradient() {
    return Container(
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
  }

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

  Widget _buildEventTitle() {
    return Column(
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
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: VesparaColors.primary,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildDateTime() {
    return Container(
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
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: VesparaColors.background,
                  ),
                ),
                Text(
                  _event.startTime.day.toString(),
                  style: TextStyle(
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: VesparaColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTimeRange(),
                  style: TextStyle(
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
            icon: Icon(
              Icons.calendar_today_outlined,
              color: VesparaColors.glow,
            ),
          ),
        ],
      ),
    );
  }

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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: VesparaColors.primary,
                    ),
                  ),
                if (_event.venueAddress != null)
                  Text(
                    _event.venueAddress!,
                    style: TextStyle(
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
              icon: Icon(
                Icons.directions,
                color: VesparaColors.glow,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHostSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VesparaColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VesparaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
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
                        style: TextStyle(
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
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: VesparaColors.primary,
                          ),
                        ),
                        if (_event.hostNickname != null) ...[
                          const SizedBox(width: 4),
                          Text(
                            '(${_event.hostNickname})',
                            style: TextStyle(
                              fontSize: 14,
                              color: VesparaColors.secondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.verified, size: 14, color: VesparaColors.success),
                        const SizedBox(width: 4),
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
                    side: BorderSide(color: VesparaColors.glow),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Message',
                    style: TextStyle(color: VesparaColors.glow),
                  ),
                ),
            ],
          ),
          
          // Co-hosts
          if (_event.coHosts.isNotEmpty) ...[
            const SizedBox(height: 16),
            Divider(color: VesparaColors.border),
            const SizedBox(height: 12),
            Text(
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
              children: _event.coHosts.map((coHost) => Chip(
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
                side: BorderSide(color: VesparaColors.border),
                labelStyle: TextStyle(color: VesparaColors.primary),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
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
          style: TextStyle(
            fontSize: 16,
            color: VesparaColors.primary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildLinks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Links',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: VesparaColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        ..._event.links.map((link) => Container(
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
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: VesparaColors.primary,
                      ),
                    ),
                    Text(
                      link.url,
                      style: TextStyle(
                        fontSize: 12,
                        color: VesparaColors.glow,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.open_in_new, color: VesparaColors.glow, size: 20),
            ],
          ),
        )),
      ],
    );
  }

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
            Text(
              'Guest List',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: VesparaColors.primary,
              ),
            ),
            if (_event.maxSpots != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
            _buildGuestChip('🤔 ${maybe.length} Maybe', VesparaColors.tagsYellow),
            const SizedBox(width: 8),
            _buildGuestChip('💌 ${invited.length} Invited', VesparaColors.secondary),
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

  Widget _buildGuestChip(String text, Color color) {
    return Container(
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
  }

  Widget _buildGuestSection(String title, List<EventRsvp> guests, Color color) {
    return Container(
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
            children: guests.map((g) => _buildGuestAvatar(g)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestAvatar(EventRsvp guest) {
    return Column(
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
                  style: TextStyle(
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
          style: TextStyle(
            fontSize: 11,
            color: VesparaColors.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: VesparaColors.surface,
        border: Border(
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
  }

  Widget _buildHostActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _editEvent,
            icon: Icon(Icons.edit, color: VesparaColors.glow),
            label: Text('Edit', style: TextStyle(color: VesparaColors.glow)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: VesparaColors.glow),
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
            icon: Icon(Icons.person_add, color: VesparaColors.background),
            label: Text('Invite Guests', style: TextStyle(color: VesparaColors.background)),
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
  }

  Widget _buildRsvpActions() {
    return Row(
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
  }

  Widget _buildRsvpButton(String emoji, String label, Color color, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
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
  }

  // Helper methods
  String _getMonthAbbr(int month) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 
                   'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return months[month - 1];
  }

  String _formatFullDate(DateTime date) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['January', 'February', 'March', 'April', 'May', 'June',
                   'July', 'August', 'September', 'October', 'November', 'December'];
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
  void _shareEvent() {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sharing event link...')),
    );
  }

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
                leading: Icon(Icons.edit, color: VesparaColors.glow),
                title: Text('Edit Event', style: TextStyle(color: VesparaColors.primary)),
                onTap: () {
                  Navigator.pop(context);
                  _editEvent();
                },
              ),
              ListTile(
                leading: Icon(Icons.content_copy, color: VesparaColors.glow),
                title: Text('Duplicate Event', style: TextStyle(color: VesparaColors.primary)),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: Icon(Icons.cancel, color: VesparaColors.error),
                title: Text('Cancel Event', style: TextStyle(color: VesparaColors.error)),
                onTap: () => Navigator.pop(context),
              ),
            ] else ...[
              ListTile(
                leading: Icon(Icons.share, color: VesparaColors.glow),
                title: Text('Share', style: TextStyle(color: VesparaColors.primary)),
                onTap: () {
                  Navigator.pop(context);
                  _shareEvent();
                },
              ),
              ListTile(
                leading: Icon(Icons.calendar_today, color: VesparaColors.glow),
                title: Text('Add to Calendar', style: TextStyle(color: VesparaColors.primary)),
                onTap: () {
                  Navigator.pop(context);
                  _addToCalendar();
                },
              ),
              ListTile(
                leading: Icon(Icons.report, color: VesparaColors.error),
                title: Text('Report Event', style: TextStyle(color: VesparaColors.error)),
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
      SnackBar(
        content: const Text('Added to calendar!'),
        backgroundColor: VesparaColors.success,
      ),
    );
  }

  void _openMaps() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening maps...')),
    );
  }

  void _messageHost() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening chat with ${_event.hostName}...')),
    );
  }

  void _editEvent() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening event editor...')),
    );
  }

  void _inviteGuests() {
    showModalBottomSheet(
      context: context,
      backgroundColor: VesparaColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Invite Guests',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: VesparaColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search your roster...',
                      hintStyle: TextStyle(color: VesparaColors.secondary),
                      prefixIcon: Icon(Icons.search, color: VesparaColors.secondary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: VesparaColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: VesparaColors.glow),
                      ),
                    ),
                    style: TextStyle(color: VesparaColors.primary),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 64,
                      color: VesparaColors.secondary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No connections yet',
                      style: TextStyle(
                        color: VesparaColors.secondary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add connections to invite them to events',
                      style: TextStyle(
                        color: VesparaColors.secondary.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + MediaQuery.of(context).padding.bottom),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Invites sent!'),
                        backgroundColor: VesparaColors.success,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VesparaColors.glow,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Send Invites',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: VesparaColors.background,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateRsvp(String status) async {
    HapticFeedback.heavyImpact();
    
    // Persist to database via provider
    final success = await ref.read(eventsProvider.notifier).respondToInvite(
      eventId: _event.id,
      status: status,
    );
    
    if (!success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to update RSVP. Please try again.'),
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
      updatedRsvps.add(EventRsvp(
        id: 'rsvp-${DateTime.now().millisecondsSinceEpoch}',
        eventId: _event.id,
        userId: _currentUserId,
        userName: 'You',
        status: status,
        createdAt: DateTime.now(),
        respondedAt: DateTime.now(),
      ));
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
        message = "Marked as maybe 🤔";
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
