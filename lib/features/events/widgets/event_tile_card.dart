import 'package:flutter/material.dart';

import '../../../core/domain/models/vespara_event.dart';
import '../../../core/theme/app_theme.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// EVENT TILE CARD - Partiful-Style Event Card
/// Beautiful tile card with cover image, date badge, and RSVP status
/// ════════════════════════════════════════════════════════════════════════════

class EventTileCard extends StatelessWidget {
  const EventTileCard({
    super.key,
    required this.event,
    required this.currentUserId,
    required this.onTap,
    this.onMoreTap,
  });
  final VesparaEvent event;
  final String currentUserId;
  final VoidCallback onTap;
  final VoidCallback? onMoreTap;

  /// Get user's status for this event
  UserEventStatus get _userStatus {
    if (event.hostId == currentUserId) return UserEventStatus.hosting;
    if (event.coHosts.any((c) => c.userId == currentUserId)) {
      return UserEventStatus.cohosting;
    }

    final rsvp =
        event.rsvps.where((r) => r.userId == currentUserId).firstOrNull;
    if (rsvp == null) return UserEventStatus.none;

    switch (rsvp.status) {
      case 'invited':
        return UserEventStatus.invited;
      case 'going':
        return UserEventStatus.going;
      case 'maybe':
        return UserEventStatus.maybe;
      case 'cant_go':
        return UserEventStatus.cantGo;
      default:
        return UserEventStatus.none;
    }
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: VesparaColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Background image or gradient
              Positioned.fill(
                child: _buildCoverImage(),
              ),

              // Gradient overlay for readability
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.7),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),

              // Content
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: Date badge + More button
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDateBadge(),
                        if (onMoreTap != null) _buildMoreButton(),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Bottom: Title and host
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Event title
                        Text(
                          event.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 8),

                        // Host info
                        Row(
                          children: [
                            Text(
                              'Hosted by',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Host avatars
                            _buildHostAvatars(),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                event.hostName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // RSVP Status badge
              if (_userStatus != UserEventStatus.none)
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: _buildStatusBadge(),
                ),
            ],
          ),
        ),
      );

  Widget _buildCoverImage() {
    if (event.coverImageUrl != null) {
      return Image.network(
        event.coverImageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildGradientPlaceholder(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildGradientPlaceholder();
        },
      );
    }
    return _buildGradientPlaceholder();
  }

  Widget _buildGradientPlaceholder() {
    // Generate a gradient based on event title for consistency
    final colors = _getEventColors();
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Center(
        child: Icon(
          _getEventIcon(),
          size: 48,
          color: Colors.white.withOpacity(0.3),
        ),
      ),
    );
  }

  List<Color> _getEventColors() {
    // Generate colors based on event title hash
    final hash = event.title.hashCode;
    final hue1 = (hash % 360).abs().toDouble();
    final hue2 = ((hash ~/ 360) % 360).abs().toDouble();

    return [
      HSLColor.fromAHSL(1.0, hue1, 0.6, 0.3).toColor(),
      HSLColor.fromAHSL(1.0, hue2, 0.5, 0.2).toColor(),
    ];
  }

  IconData _getEventIcon() {
    final title = event.title.toLowerCase();
    if (title.contains('dinner') ||
        title.contains('eat') ||
        title.contains('food')) {
      return Icons.restaurant;
    }
    if (title.contains('party') || title.contains('celebration')) {
      return Icons.celebration;
    }
    if (title.contains('game') || title.contains('board')) {
      return Icons.casino;
    }
    if (title.contains('music') || title.contains('concert')) {
      return Icons.music_note;
    }
    if (title.contains('wine') || title.contains('drink')) {
      return Icons.wine_bar;
    }
    if (title.contains('art') || title.contains('paint')) {
      return Icons.palette;
    }
    if (title.contains('vision') || title.contains('board')) {
      return Icons.auto_awesome;
    }
    return Icons.event;
  }

  Widget _buildDateBadge() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          event.dateTimeLabel,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      );

  Widget _buildMoreButton() => GestureDetector(
        onTap: onMoreTap,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.more_horiz,
            size: 18,
            color: Colors.white,
          ),
        ),
      );

  Widget _buildHostAvatars() {
    final avatars = <String?>[];
    if (event.hostAvatarUrl != null) avatars.add(event.hostAvatarUrl);
    for (final coHost in event.coHosts.take(2)) {
      avatars.add(coHost.avatarUrl);
    }

    if (avatars.isEmpty) {
      return CircleAvatar(
        radius: 10,
        backgroundColor: VesparaColors.glow.withOpacity(0.5),
        child: Text(
          event.hostName[0].toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return SizedBox(
      width: 20.0 + (avatars.length - 1) * 12,
      height: 20,
      child: Stack(
        children: List.generate(
          avatars.length,
          (index) => Positioned(
            left: index * 12.0,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(),
              ),
              child: ClipOval(
                child: avatars[index] != null
                    ? Image.network(
                        avatars[index]!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _buildAvatarPlaceholder(index),
                      )
                    : _buildAvatarPlaceholder(index),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder(int index) {
    String initial;
    if (index == 0) {
      initial = event.hostName[0].toUpperCase();
    } else if (index - 1 < event.coHosts.length) {
      initial = event.coHosts[index - 1].name[0].toUpperCase();
    } else {
      initial = '?';
    }

    return Container(
      color: VesparaColors.glow.withOpacity(0.5),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 10,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color bgColor;
    Color textColor;

    switch (_userStatus) {
      case UserEventStatus.hosting:
      case UserEventStatus.cohosting:
        bgColor = VesparaColors.glow;
        textColor = VesparaColors.background;
        break;
      case UserEventStatus.invited:
        bgColor = VesparaColors.error;
        textColor = Colors.white;
        break;
      case UserEventStatus.going:
        bgColor = VesparaColors.success;
        textColor = Colors.white;
        break;
      case UserEventStatus.maybe:
        bgColor = VesparaColors.tagsYellow;
        textColor = VesparaColors.background;
        break;
      default:
        bgColor = VesparaColors.surface;
        textColor = VesparaColors.primary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _userStatus.emoji,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(width: 4),
          Text(
            _userStatus.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Larger event card for featured/highlighted events
class EventFeatureCard extends StatelessWidget {
  const EventFeatureCard({
    super.key,
    required this.event,
    required this.currentUserId,
    required this.onTap,
  });
  final VesparaEvent event;
  final String currentUserId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 280,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: VesparaColors.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: VesparaColors.glow.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Cover image
              Positioned.fill(
                child: event.coverImageUrl != null
                    ? Image.network(
                        event.coverImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildGradient(),
                      )
                    : _buildGradient(),
              ),

              // Gradient overlay
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                ),
              ),

              // Content
              Positioned(
                left: 20,
                right: 20,
                bottom: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6,),
                      decoration: BoxDecoration(
                        color: VesparaColors.glow,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        event.dateTimeLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: VesparaColors.background,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Title
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),

                    if (event.description != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        event.description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    const SizedBox(height: 12),

                    // Bottom row
                    Row(
                      children: [
                        // Host info
                        if (event.hostAvatarUrl != null)
                          CircleAvatar(
                            radius: 14,
                            backgroundImage: NetworkImage(event.hostAvatarUrl!),
                          )
                        else
                          CircleAvatar(
                            radius: 14,
                            backgroundColor:
                                VesparaColors.glow.withOpacity(0.5),
                            child: Text(
                              event.hostName[0],
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        Text(
                          event.hostName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),

                        const Spacer(),

                        // Attendee count
                        if (event.goingCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6,),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.people,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${event.goingCount} going',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Content rating badge
              if (event.contentRating != 'PG')
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: VesparaColors.warning,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      event.contentRating.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: VesparaColors.background,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );

  Widget _buildGradient() => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              VesparaColors.glow.withOpacity(0.3),
              VesparaColors.surface,
            ],
          ),
        ),
      );
}

/// Horizontal scrollable event card (for lists)
class EventListCard extends StatelessWidget {
  const EventListCard({
    super.key,
    required this.event,
    required this.currentUserId,
    required this.onTap,
  });
  final VesparaEvent event;
  final String currentUserId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 100,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: VesparaColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: VesparaColors.border),
          ),
          child: Row(
            children: [
              // Cover image thumbnail
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: VesparaColors.background,
                ),
                clipBehavior: Clip.antiAlias,
                child: event.coverImageUrl != null
                    ? Image.network(
                        event.coverImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildThumbPlaceholder(),
                      )
                    : _buildThumbPlaceholder(),
              ),

              const SizedBox(width: 12),

              // Event info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      event.dateTimeLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: VesparaColors.glow,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: VesparaColors.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'By ${event.hostName}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: VesparaColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Chevron
              const Icon(
                Icons.chevron_right,
                color: VesparaColors.secondary,
              ),
            ],
          ),
        ),
      );

  Widget _buildThumbPlaceholder() => ColoredBox(
        color: VesparaColors.glow.withOpacity(0.2),
        child: Icon(
          Icons.event,
          color: VesparaColors.glow.withOpacity(0.5),
          size: 32,
        ),
      );
}
