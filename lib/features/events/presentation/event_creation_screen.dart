import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/domain/models/plan_event.dart';
import '../../../core/domain/models/vespara_event.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/events_provider.dart';
import '../../../core/providers/plan_provider.dart';
import '../../../core/theme/app_theme.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// EVENT CREATION SCREEN - Partiful-Style Comprehensive Event Builder
/// Full-featured event creation with all options visible
/// ════════════════════════════════════════════════════════════════════════════

class EventCreationScreen extends ConsumerStatefulWidget {
  const EventCreationScreen({super.key, this.eventToEdit});
  final VesparaEvent? eventToEdit;

  @override
  ConsumerState<EventCreationScreen> createState() =>
      _EventCreationScreenState();
}

class _EventCreationScreenState extends ConsumerState<EventCreationScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _spotsController = TextEditingController();
  final _costController = TextEditingController();
  final _hostNicknameController = TextEditingController();

  EventTitleStyle _titleStyle = EventTitleStyle.classic;
  DateTime? _eventDate;
  TimeOfDay? _eventTime;
  bool _hasDatePoll = false;
  EventVisibility _visibility = EventVisibility.private;
  bool _unlimitedSpots = true;
  bool _hasCost = false;
  bool _requiresApproval = false;
  bool _collectGuestInfo = false;
  bool _sendReminders = true;

  String? _coverImageUrl;
  final String _coverTheme = 'default';
  bool _isUploadingImage = false;

  final List<EventLink> _links = [];
  final List<EventCoHost> _coHosts = [];

  // Emoji customization for RSVP - alluring and sophisticated
  String _goingEmoji = '🙌';
  String _maybeEmoji = '🤔';
  String _cantGoEmoji = '🥀';

  bool get _isEditing => widget.eventToEdit != null;

  @override
  void initState() {
    super.initState();
    if (widget.eventToEdit != null) {
      _loadEventData(widget.eventToEdit!);
    }
  }

  void _loadEventData(VesparaEvent event) {
    _titleController.text = event.title;
    _descriptionController.text = event.description ?? '';
    _locationController.text = event.venueAddress ?? '';
    _titleStyle = event.titleStyle;
    _eventDate = event.startTime;
    _eventTime = TimeOfDay.fromDateTime(event.startTime);
    _visibility = event.visibility;
    _unlimitedSpots = event.maxSpots == null;
    if (event.maxSpots != null) {
      _spotsController.text = event.maxSpots.toString();
    }
    _hasCost = event.costPerPerson != null;
    if (event.costPerPerson != null) {
      _costController.text = event.costPerPerson!.toStringAsFixed(0);
    }
    _coverImageUrl = event.coverImageUrl;
    _requiresApproval = event.requiresApproval;
    _collectGuestInfo = event.collectGuestInfo;
    _sendReminders = event.sendReminders;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _spotsController.dispose();
    _costController.dispose();
    _hostNicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: VesparaColors.background,
        body: Row(
          children: [
            // Left panel - Form
            Expanded(
              flex: 5,
              child: _buildFormPanel(),
            ),

            // Right panel - Preview (on larger screens)
            if (MediaQuery.of(context).size.width > 800)
              Expanded(
                flex: 4,
                child: _buildPreviewPanel(),
              ),
          ],
        ),
      );

  Widget _buildFormPanel() => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2D1B4E).withOpacity(0.8),
              VesparaColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitleSection(),
                      const SizedBox(height: 32),
                      _buildDateSection(),
                      const SizedBox(height: 32),
                      _buildHostSection(),
                      const SizedBox(height: 32),
                      _buildLocationSection(),
                      const SizedBox(height: 32),
                      _buildCapacitySection(),
                      const SizedBox(height: 32),
                      _buildLinksSection(),
                      const SizedBox(height: 32),
                      _buildDescriptionSection(),
                      const SizedBox(height: 32),
                      _buildRsvpOptionsSection(),
                      const SizedBox(height: 32),
                      _buildHostActionsSection(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
              _buildBottomBar(),
            ],
          ),
        ),
      );

  Widget _buildHeader() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: VesparaColors.primary),
            ),
            const Spacer(),
            // Make it public toggle button
            GestureDetector(
              onTap: () {
                setState(() {
                  _visibility = _visibility == EventVisibility.public
                      ? EventVisibility.private
                      : EventVisibility.public;
                });
                HapticFeedback.mediumImpact();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _visibility == EventVisibility.public
                      ? VesparaColors.success.withOpacity(0.2)
                      : VesparaColors.glow.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _visibility == EventVisibility.public
                        ? VesparaColors.success
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _visibility == EventVisibility.public
                          ? Icons.public
                          : Icons.lock_outline,
                      size: 16,
                      color: _visibility == EventVisibility.public
                          ? VesparaColors.success
                          : VesparaColors.glow,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _visibility == EventVisibility.public
                          ? 'Public event'
                          : 'Make it public',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: _visibility == EventVisibility.public
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: _visibility == EventVisibility.public
                            ? VesparaColors.success
                            : VesparaColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildTitleSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title input
          TextField(
            controller: _titleController,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w600,
              color: VesparaColors.primary,
            ),
            decoration: const InputDecoration(
              hintText: 'Untitled Event',
              hintStyle: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w600,
                color: VesparaColors.secondary,
              ),
              border: InputBorder.none,
            ),
            onChanged: (_) => setState(() {}),
          ),

          const SizedBox(height: 16),

          // Title style chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: EventTitleStyle.values.map((style) {
                final isSelected = _titleStyle == style;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _titleStyle = style),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10,),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? VesparaColors.primary
                            : VesparaColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? VesparaColors.primary
                              : VesparaColors.border,
                        ),
                      ),
                      child: Text(
                        style.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          fontStyle: style == EventTitleStyle.eclectic
                              ? FontStyle.italic
                              : FontStyle.normal,
                          color: isSelected
                              ? VesparaColors.background
                              : VesparaColors.primary,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      );

  Widget _buildDateSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date & Time selector
          GestureDetector(
            onTap: _selectDateTime,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: VesparaColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: VesparaColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: VesparaColors.glow),
                  const SizedBox(width: 12),
                  Text(
                    _eventDate != null ? _formatDateTime() : 'Set a date...',
                    style: TextStyle(
                      fontSize: 18,
                      color: _eventDate != null
                          ? VesparaColors.primary
                          : VesparaColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Date poll option - removed as not implemented
        ],
      );

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
            Row(
              children: [
                const Icon(Icons.person_outline,
                    color: VesparaColors.glow, size: 20,),
                const SizedBox(width: 8),
                const Text(
                  'Hosted by',
                  style: TextStyle(
                    fontSize: 14,
                    color: VesparaColors.secondary,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '(optional) host nickname',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: VesparaColors.secondary.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                // Host avatar
                Builder(
                  builder: (context) {
                    final profile = ref.watch(userProfileProvider).valueOrNull;
                    final displayName = profile?.displayName ?? 'You';
                    return CircleAvatar(
                      radius: 24,
                      backgroundColor: VesparaColors.glow.withOpacity(0.3),
                      backgroundImage: profile?.avatarUrl != null
                          ? NetworkImage(profile!.avatarUrl!)
                          : null,
                      child: profile?.avatarUrl == null
                          ? Text(displayName[0].toUpperCase(),
                              style: const TextStyle(
                                  color: VesparaColors.glow,
                                  fontWeight: FontWeight.w600,),)
                          : null,
                    );
                  },
                ),
                const SizedBox(width: 12),

                // Host name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Builder(
                        builder: (context) {
                          final profile =
                              ref.watch(userProfileProvider).valueOrNull;
                          return Text(
                            profile?.displayName ?? 'You',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: VesparaColors.primary,
                            ),
                          );
                        },
                      ),
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

                // Add co-hosts button
                OutlinedButton.icon(
                  onPressed: _addCoHost,
                  icon: const Icon(Icons.add,
                      size: 18, color: VesparaColors.glow,),
                  label: const Text('Add cohosts',
                      style: TextStyle(color: VesparaColors.glow),),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: VesparaColors.glow),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),

            // Co-hosts list
            if (_coHosts.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _coHosts
                    .map(
                      (coHost) => Chip(
                        avatar: CircleAvatar(
                          backgroundColor: VesparaColors.glow.withOpacity(0.3),
                          child: Text(coHost.name[0]),
                        ),
                        label: Text(coHost.name),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () =>
                            setState(() => _coHosts.remove(coHost)),
                        backgroundColor: VesparaColors.surface,
                        side: const BorderSide(color: VesparaColors.border),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      );

  Widget _buildLocationSection() => GestureDetector(
        onTap: _selectLocation,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: VesparaColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: VesparaColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on_outlined, color: VesparaColors.glow),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _locationController.text.isNotEmpty
                      ? _locationController.text
                      : 'Location',
                  style: TextStyle(
                    fontSize: 16,
                    color: _locationController.text.isNotEmpty
                        ? VesparaColors.primary
                        : VesparaColors.secondary,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: VesparaColors.secondary),
            ],
          ),
        ),
      );

  Widget _buildCapacitySection() => Row(
        children: [
          // Spots
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: VesparaColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: VesparaColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.people_outline, color: VesparaColors.glow),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _unlimitedSpots
                        ? GestureDetector(
                            onTap: () =>
                                setState(() => _unlimitedSpots = false),
                            child: const Text(
                              'Unlimited spots',
                              style: TextStyle(
                                fontSize: 16,
                                color: VesparaColors.secondary,
                              ),
                            ),
                          )
                        : TextField(
                            controller: _spotsController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: '# spots',
                              hintStyle:
                                  TextStyle(color: VesparaColors.secondary),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            style: const TextStyle(
                              fontSize: 16,
                              color: VesparaColors.primary,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Cost
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: VesparaColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: VesparaColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.attach_money, color: VesparaColors.glow),
                  const SizedBox(width: 12),
                  Expanded(
                    child: !_hasCost
                        ? GestureDetector(
                            onTap: () => setState(() => _hasCost = true),
                            child: const Text(
                              'Cost per person',
                              style: TextStyle(
                                fontSize: 16,
                                color: VesparaColors.secondary,
                              ),
                            ),
                          )
                        : TextField(
                            controller: _costController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              prefixText: '\$ ',
                              hintText: '0',
                              hintStyle:
                                  TextStyle(color: VesparaColors.secondary),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            style: const TextStyle(
                              fontSize: 16,
                              color: VesparaColors.primary,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );

  Widget _buildLinksSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add Links',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: VesparaColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildLinkButton('Website', Icons.link),
                const SizedBox(width: 8),
                _buildLinkButton('Playlist', Icons.music_note),
                const SizedBox(width: 8),
                _buildLinkButton('Tickets', Icons.confirmation_number),
                const SizedBox(width: 8),
                _buildLinkButton('Menu', Icons.restaurant_menu),
              ],
            ),
          ),

          // Added links
          if (_links.isNotEmpty) ...[
            const SizedBox(height: 16),
            Column(
              children: _links
                  .map(
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
                          Text(link.type.icon,
                              style: const TextStyle(fontSize: 20),),
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
                                    color: VesparaColors.secondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close,
                                size: 18, color: VesparaColors.secondary,),
                            onPressed: () =>
                                setState(() => _links.remove(link)),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      );

  Widget _buildLinkButton(String label, IconData icon) => GestureDetector(
        onTap: () => _addLink(label),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: VesparaColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: VesparaColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add, size: 18, color: VesparaColors.glow),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: VesparaColors.primary,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildDescriptionSection() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: VesparaColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: VesparaColors.border),
        ),
        child: TextField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Add a description of your event',
            hintStyle: TextStyle(color: VesparaColors.secondary),
            border: InputBorder.none,
          ),
          style: const TextStyle(
            fontSize: 16,
            color: VesparaColors.primary,
            height: 1.5,
          ),
        ),
      );

  Widget _buildRsvpOptionsSection() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: VesparaColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: VesparaColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.how_to_vote, color: VesparaColors.glow, size: 20),
                SizedBox(width: 8),
                Text(
                  'RSVP Options',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: VesparaColors.primary,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            const Text(
              'Tap an emoji to customize it',
              style: TextStyle(
                fontSize: 12,
                color: VesparaColors.secondary,
              ),
            ),

            const SizedBox(height: 20),

            // RSVP buttons preview - clickable to change emoji
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildRsvpPreview(_goingEmoji, 'Going'),
                _buildRsvpPreview(_maybeEmoji, 'Maybe'),
                _buildRsvpPreview(_cantGoEmoji, "Can't Go"),
              ],
            ),
          ],
        ),
      );

  Widget _buildRsvpPreview(String emoji, String label) => GestureDetector(
        onTap: () => _customizeEmoji(label),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: VesparaColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: VesparaColors.border),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: VesparaColors.secondary,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildHostActionsSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick actions for hosts',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: VesparaColors.primary,
            ),
          ),
          const SizedBox(height: 16),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildHostActionChip(
                  Icons.assignment_outlined,
                  'Collect Info',
                  _collectGuestInfo,
                  () => setState(() => _collectGuestInfo = !_collectGuestInfo),
                ),
                const SizedBox(width: 8),
                _buildHostActionChip(
                  Icons.notifications_outlined,
                  'Reminders',
                  _sendReminders,
                  () => setState(() => _sendReminders = !_sendReminders),
                ),
                const SizedBox(width: 8),
                _buildHostActionChip(
                  Icons.person_add_outlined,
                  'Require Guest Approval',
                  _requiresApproval,
                  () => setState(() => _requiresApproval = !_requiresApproval),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // More options button
          GestureDetector(
            onTap: _showMoreHostOptions,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: VesparaColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: VesparaColors.border),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.more_horiz, color: VesparaColors.glow, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'More',
                    style: TextStyle(
                      fontSize: 14,
                      color: VesparaColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Removed "More to say" section - description field already handles this
        ],
      );

  Widget _buildHostActionChip(
          IconData icon, String label, bool isActive, VoidCallback onTap,) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isActive
                ? VesparaColors.glow.withOpacity(0.2)
                : VesparaColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive ? VesparaColors.glow : VesparaColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isActive ? VesparaColors.glow : VesparaColors.secondary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive ? VesparaColors.glow : VesparaColors.primary,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildBottomBar() => Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: VesparaColors.surface,
          border: Border(
            top: BorderSide(color: VesparaColors.border),
          ),
        ),
        child: Row(
          children: [
            // Review button - shows preview modal on mobile
            if (MediaQuery.of(context).size.width <= 800)
              OutlinedButton.icon(
                onPressed: _showPreviewModal,
                icon: const Icon(Icons.visibility_outlined, size: 18, color: VesparaColors.glow),
                label: const Text(
                  'Review',
                  style: TextStyle(
                    fontSize: 14,
                    color: VesparaColors.glow,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: VesparaColors.glow),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            const Spacer(),
            TextButton(
              onPressed: _saveDraft,
              child: const Text(
                'Save draft',
                style: TextStyle(
                  fontSize: 16,
                  color: VesparaColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: _publishEvent,
              style: ElevatedButton.styleFrom(
                backgroundColor: VesparaColors.glow,
                foregroundColor: VesparaColors.background,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _isEditing ? 'Update Event' : 'Create Event',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildPreviewPanel() => DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A0A2E),
              Color(0xFF2D1B4E),
            ],
          ),
        ),
        child: Column(
          children: [
            // Preview header - simplified, just show preview button that scrolls to preview
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () {
                      // Just a visual preview - the panel already shows a live preview
                      HapticFeedback.lightImpact();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: VesparaColors.glow.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.visibility_outlined, size: 18, color: VesparaColors.glow),
                          SizedBox(width: 8),
                          Text(
                            'Live Preview',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: VesparaColors.glow,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Event card preview
            Expanded(
              child: Center(
                child: Container(
                  width: 300,
                  margin: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: VesparaColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: VesparaColors.glow.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Cover image - clickable for photo upload
                      GestureDetector(
                        onTap: _pickCoverImage,
                        child: Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                VesparaColors.glow.withOpacity(0.4),
                                VesparaColors.surface,
                              ],
                            ),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(20),),
                          ),
                          child: Stack(
                            children: [
                              if (_coverImageUrl != null)
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(20),),
                                  child: Image.network(
                                    _coverImageUrl!,
                                    width: double.infinity,
                                    height: 200,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _buildCoverPlaceholder(),
                                  ),
                                )
                              else
                                _buildCoverPlaceholder(),
                              if (_isUploadingImage)
                                Container(
                                  decoration: BoxDecoration(
                                    color: VesparaColors.background.withOpacity(0.7),
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(20),),
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: VesparaColors.glow,
                                    ),
                                  ),
                                ),
                              Positioned(
                                right: 12,
                                bottom: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6,),
                                  decoration: BoxDecoration(
                                    color:
                                        VesparaColors.background.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _coverImageUrl != null ? Icons.edit : Icons.add_a_photo,
                                        size: 16,
                                        color: VesparaColors.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _coverImageUrl != null ? 'Change' : 'Add Photo',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: VesparaColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Event info preview
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Text(
                              _titleController.text.isEmpty
                                  ? 'Your Event Title'
                                  : _titleController.text,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: VesparaColors.primary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (_eventDate != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                _formatDateTime(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: VesparaColors.secondary,
                                ),
                              ),
                            ],
                            if (_locationController.text.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                _locationController.text,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: VesparaColors.secondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildCoverPlaceholder() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 48,
              color: VesparaColors.secondary,
            ),
            SizedBox(height: 8),
            Text(
              'Tap to add cover image',
              style: TextStyle(
                fontSize: 14,
                color: VesparaColors.secondary,
              ),
            ),
          ],
        ),
      );

  /// Pick and upload a cover image for the event
  Future<void> _pickCoverImage() async {
    final picker = ImagePicker();
    
    // Show option to choose camera or gallery
    final source = await showModalBottomSheet<ImageSource>(
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
            const Text(
              'Add Cover Photo',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: VesparaColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.photo_library, color: VesparaColors.glow),
              title: const Text('Choose from Gallery',
                  style: TextStyle(color: VesparaColors.primary)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: VesparaColors.glow),
              title: const Text('Take a Photo',
                  style: TextStyle(color: VesparaColors.primary)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            if (_coverImageUrl != null)
              ListTile(
                leading: const Icon(Icons.delete, color: VesparaColors.error),
                title: const Text('Remove Photo',
                    style: TextStyle(color: VesparaColors.error)),
                onTap: () {
                  setState(() => _coverImageUrl = null);
                  Navigator.pop(context);
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _isUploadingImage = true);
      HapticFeedback.lightImpact();

      // Upload to Supabase Storage
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id ?? 'anonymous';
      final fileName = '${const Uuid().v4()}.jpg';
      final filePath = 'events/$userId/$fileName';

      if (kIsWeb) {
        // Web: read as bytes
        final bytes = await image.readAsBytes();
        await supabase.storage.from('photos').uploadBinary(
              filePath,
              bytes,
              fileOptions: const FileOptions(contentType: 'image/jpeg'),
            );
      } else {
        // Mobile: use file
        final file = File(image.path);
        await supabase.storage.from('photos').upload(
              filePath,
              file,
              fileOptions: const FileOptions(contentType: 'image/jpeg'),
            );
      }

      // Get the public URL
      final publicUrl = supabase.storage.from('photos').getPublicUrl(filePath);

      setState(() {
        _coverImageUrl = publicUrl;
        _isUploadingImage = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cover photo added!'),
            backgroundColor: VesparaColors.success,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error uploading cover image: $e');
      setState(() => _isUploadingImage = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: ${e.toString().split(':').last}'),
            backgroundColor: VesparaColors.error,
          ),
        );
      }
    }
  }

  // Action methods
  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _eventDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: VesparaColors.glow,
            surface: VesparaColors.surface,
          ),
        ),
        child: child!,
      ),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: _eventTime ?? const TimeOfDay(hour: 19, minute: 0),
        builder: (context, child) => Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: VesparaColors.glow,
              surface: VesparaColors.surface,
            ),
          ),
          child: child!,
        ),
      );

      if (time != null) {
        setState(() {
          _eventDate =
              DateTime(date.year, date.month, date.day, time.hour, time.minute);
          _eventTime = time;
        });
      }
    }
  }

  String _formatDateTime() {
    if (_eventDate == null) return '';
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final hour = _eventDate!.hour > 12
        ? _eventDate!.hour - 12
        : (_eventDate!.hour == 0 ? 12 : _eventDate!.hour);
    final period = _eventDate!.hour >= 12 ? 'PM' : 'AM';
    return '${days[_eventDate!.weekday - 1]}, ${months[_eventDate!.month - 1]} ${_eventDate!.day} · $hour:${_eventDate!.minute.toString().padLeft(2, '0')} $period';
  }

  void _selectLocation() {
    showModalBottomSheet(
      context: context,
      backgroundColor: VesparaColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Event Location',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: VesparaColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _locationController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Enter address or venue name',
                hintStyle: const TextStyle(color: VesparaColors.secondary),
                prefixIcon:
                    const Icon(Icons.location_on, color: VesparaColors.glow),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: VesparaColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: VesparaColors.glow),
                ),
              ),
              style: const TextStyle(color: VesparaColors.primary),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: VesparaColors.glow,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Confirm Location',
                    style: TextStyle(color: VesparaColors.background),),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _addCoHost() {
    final nameController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: VesparaColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Co-Host',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: VesparaColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter the name of your co-host',
              style: TextStyle(
                fontSize: 14,
                color: VesparaColors.secondary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Co-host name',
                hintStyle: const TextStyle(color: VesparaColors.secondary),
                prefixIcon: const Icon(Icons.person_add, color: VesparaColors.glow),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: VesparaColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: VesparaColors.glow),
                ),
              ),
              style: const TextStyle(color: VesparaColors.primary),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty) {
                    setState(() {
                      _coHosts.add(EventCoHost(
                        id: 'cohost-${_coHosts.length}',
                        userId: 'user-${_coHosts.length}',
                        name: nameController.text,
                      ));
                    });
                    Navigator.pop(context);
                    HapticFeedback.mediumImpact();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: VesparaColors.glow,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Add Co-Host',
                    style: TextStyle(color: VesparaColors.background)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _addLink(String type) {
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VesparaColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Add $type',
            style: const TextStyle(color: VesparaColors.primary),),
        content: TextField(
          controller: urlController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Paste URL',
            hintStyle: const TextStyle(color: VesparaColors.secondary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          style: const TextStyle(color: VesparaColors.primary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: VesparaColors.secondary),),
          ),
          TextButton(
            onPressed: () {
              if (urlController.text.isNotEmpty) {
                setState(() {
                  _links.add(
                    EventLink(
                      id: 'link-${_links.length}',
                      type: EventLinkType.values.firstWhere(
                        (t) => t.label.toLowerCase() == type.toLowerCase(),
                        orElse: () => EventLinkType.link,
                      ),
                      url: urlController.text,
                    ),
                  );
                });
              }
              Navigator.pop(context);
            },
            child:
                const Text('Add', style: TextStyle(color: VesparaColors.glow)),
          ),
        ],
      ),
    );
  }

  void _customizeEmoji(String label) {
    // Curated emoji options - sophisticated and alluring for events
    final emojis = [
      '🙌',
      '🔥',
      '❤️‍🔥',
      '🥂',
      '✨',
      '🤔',
      '🤭',
      '💌',
      '🥀',
      '💔',
      '🫠',
      '❌',
    ];

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose emoji for "$label"',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: VesparaColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: emojis
                  .map(
                    (emoji) => GestureDetector(
                      onTap: () {
                        setState(() {
                          switch (label) {
                            case 'Going':
                              _goingEmoji = emoji;
                              break;
                            case 'Maybe':
                              _maybeEmoji = emoji;
                              break;
                            case "Can't Go":
                              _cantGoEmoji = emoji;
                              break;
                          }
                        });
                        Navigator.pop(context);
                        HapticFeedback.lightImpact();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: VesparaColors.background,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child:
                            Text(emoji, style: const TextStyle(fontSize: 28)),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showMoreHostOptions() {
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
            ListTile(
              leading: const Icon(Icons.visibility, color: VesparaColors.glow),
              title: const Text('Visibility Settings',
                  style: TextStyle(color: VesparaColors.primary),),
              subtitle: Text(_visibility.label,
                  style: const TextStyle(color: VesparaColors.secondary),),
              onTap: () {
                Navigator.pop(context);
                _showVisibilitySettings();
              },
            ),
            ListTile(
              leading: const Icon(Icons.timer, color: VesparaColors.glow),
              title: const Text('RSVP Deadline',
                  style: TextStyle(color: VesparaColors.primary),),
              subtitle: const Text('No deadline set',
                  style: TextStyle(color: VesparaColors.secondary),),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.message, color: VesparaColors.glow),
              title: const Text('Guest Messages',
                  style: TextStyle(color: VesparaColors.primary),),
              subtitle: const Text('Allow guests to message each other',
                  style: TextStyle(color: VesparaColors.secondary),),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading:
                  const Icon(Icons.warning_amber, color: VesparaColors.warning),
              title: const Text('Content Rating',
                  style: TextStyle(color: VesparaColors.primary),),
              subtitle: const Text('PG (default)',
                  style: TextStyle(color: VesparaColors.secondary),),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showVisibilitySettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: VesparaColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Event Visibility',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: VesparaColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              ...EventVisibility.values.map(
                (v) => RadioListTile<EventVisibility>(
                  value: v,
                  groupValue: _visibility,
                  onChanged: (value) {
                    setModalState(() => _visibility = value!);
                    setState(() {});
                  },
                  activeColor: VesparaColors.glow,
                  title: Text(v.label,
                      style: const TextStyle(color: VesparaColors.primary),),
                  subtitle: Text(v.description,
                      style: const TextStyle(
                          color: VesparaColors.secondary, fontSize: 12,),),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show event preview modal for mobile devices
  void _showPreviewModal() {
    HapticFeedback.lightImpact();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: VesparaColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: VesparaColors.secondary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Event Preview',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: VesparaColors.primary,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: VesparaColors.secondary),
                    ),
                  ],
                ),
              ),
              const Divider(color: VesparaColors.border),
              // Preview content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Event card preview
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: VesparaColors.background,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: VesparaColors.glow.withOpacity(0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Cover image
                            Container(
                              height: 180,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    VesparaColors.glow.withOpacity(0.4),
                                    VesparaColors.surface,
                                  ],
                                ),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(20),
                                ),
                              ),
                              child: _coverImageUrl != null
                                  ? ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(20),
                                      ),
                                      child: Image.network(
                                        _coverImageUrl!,
                                        width: double.infinity,
                                        height: 180,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Center(
                                          child: Icon(
                                            Icons.image_outlined,
                                            size: 48,
                                            color: VesparaColors.secondary,
                                          ),
                                        ),
                                      ),
                                    )
                                  : const Center(
                                      child: Icon(
                                        Icons.image_outlined,
                                        size: 48,
                                        color: VesparaColors.secondary,
                                      ),
                                    ),
                            ),
                            // Event info
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _titleController.text.isEmpty
                                        ? 'Your Event Title'
                                        : _titleController.text,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                      color: VesparaColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  if (_eventDate != null)
                                    _buildPreviewInfoRow(
                                      Icons.calendar_today,
                                      _formatDateTime(),
                                    ),
                                  if (_locationController.text.isNotEmpty)
                                    _buildPreviewInfoRow(
                                      Icons.location_on,
                                      _locationController.text,
                                    ),
                                  if (_descriptionController.text.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      _descriptionController.text,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: VesparaColors.secondary,
                                        height: 1.5,
                                      ),
                                      maxLines: 4,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  // RSVP buttons preview
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _buildMiniRsvpButton(_goingEmoji, 'Going'),
                                      const SizedBox(width: 12),
                                      _buildMiniRsvpButton(_maybeEmoji, 'Maybe'),
                                      const SizedBox(width: 12),
                                      _buildMiniRsvpButton(_cantGoEmoji, "Can't"),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Event settings summary
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: VesparaColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: VesparaColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Event Settings',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: VesparaColors.primary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildSettingRow(
                              'Visibility',
                              _visibility.label,
                              _visibility == EventVisibility.public
                                  ? Icons.public
                                  : Icons.lock_outline,
                            ),
                            _buildSettingRow(
                              'Capacity',
                              _unlimitedSpots
                                  ? 'Unlimited'
                                  : '${_spotsController.text} spots',
                              Icons.people,
                            ),
                            if (_hasCost)
                              _buildSettingRow(
                                'Cost',
                                '\$${_costController.text}',
                                Icons.attach_money,
                              ),
                            _buildSettingRow(
                              'Approval',
                              _requiresApproval ? 'Required' : 'Not required',
                              Icons.verified_user,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Action button
              Container(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _publishEvent();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VesparaColors.glow,
                      foregroundColor: VesparaColors.background,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _isEditing ? 'Update Event' : 'Create Event',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewInfoRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(icon, size: 16, color: VesparaColors.glow),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  color: VesparaColors.secondary,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildMiniRsvpButton(String emoji, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: VesparaColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: VesparaColors.border),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: VesparaColors.secondary,
              ),
            ),
          ],
        ),
      );

  Widget _buildSettingRow(String label, String value, IconData icon) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(icon, size: 16, color: VesparaColors.secondary),
            const SizedBox(width: 8),
            Text(
              '$label:',
              style: const TextStyle(
                fontSize: 13,
                color: VesparaColors.secondary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: VesparaColors.primary,
              ),
            ),
          ],
        ),
      );

  Future<void> _saveDraft() async {
    HapticFeedback.mediumImpact();

    // Create and save event as draft
    if (_titleController.text.isNotEmpty) {
      final profile = ref.read(userProfileProvider).valueOrNull;
      final draftEvent = VesparaEvent(
        id: 'draft-${DateTime.now().millisecondsSinceEpoch}',
        hostId: 'current-user',
        hostName: profile?.displayName ?? 'You',
        title: _titleController.text,
        titleStyle: _titleStyle,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        coverImageUrl: _coverImageUrl,
        startTime: _eventDate ?? DateTime.now().add(const Duration(days: 1)),
        endTime: _eventDate?.add(const Duration(hours: 3)),
        venueName:
            _locationController.text.isEmpty ? null : _locationController.text,
        venueAddress:
            _locationController.text.isEmpty ? null : _locationController.text,
        maxSpots: _unlimitedSpots ? null : int.tryParse(_spotsController.text),
        costPerPerson: _hasCost ? double.tryParse(_costController.text) : null,
        visibility: _visibility,
        requiresApproval: _requiresApproval,
        collectGuestInfo: _collectGuestInfo,
        sendReminders: _sendReminders,
        links: _links,
        coHosts: _coHosts,
        createdAt: DateTime.now(),
        isDraft: true, // Mark as draft
      );

      // Save to database as draft
      await ref.read(eventsProvider.notifier).createVesparaEvent(draftEvent);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event saved as draft'),
          backgroundColor: VesparaColors.surface,
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _publishEvent() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add an event title'),
          backgroundColor: VesparaColors.error,
        ),
      );
      return;
    }

    HapticFeedback.heavyImpact();

    // Create the event
    final profile = ref.read(userProfileProvider).valueOrNull;
    final event = VesparaEvent(
      id: 'event-${DateTime.now().millisecondsSinceEpoch}',
      hostId: 'current-user',
      hostName: profile?.displayName ?? 'You',
      title: _titleController.text,
      titleStyle: _titleStyle,
      description: _descriptionController.text.isEmpty
          ? null
          : _descriptionController.text,
      coverImageUrl: _coverImageUrl,
      startTime: _eventDate ?? DateTime.now().add(const Duration(days: 1)),
      endTime: _eventDate?.add(const Duration(hours: 3)),
      venueName:
          _locationController.text.isEmpty ? null : _locationController.text,
      venueAddress:
          _locationController.text.isEmpty ? null : _locationController.text,
      maxSpots: _unlimitedSpots ? null : int.tryParse(_spotsController.text),
      costPerPerson: _hasCost ? double.tryParse(_costController.text) : null,
      visibility: _visibility,
      requiresApproval: _requiresApproval,
      collectGuestInfo: _collectGuestInfo,
      sendReminders: _sendReminders,
      links: _links,
      coHosts: _coHosts,
      createdAt: DateTime.now(),
    );

    // SAVE TO DATABASE using the events provider
    await ref.read(eventsProvider.notifier).createVesparaEvent(event);

    // Also create a calendar event for visibility in The Planner
    await ref.read(eventsProvider.notifier).createCalendarEvent(
          title: event.title,
          startTime: event.startTime,
          endTime:
              event.endTime ?? event.startTime.add(const Duration(hours: 3)),
          description: event.description,
          location: event.venueName ?? event.venueAddress,
        );

    // Also add to The Plan calendar for visibility
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final planEvent = PlanEvent(
      id: const Uuid().v4(),
      userId: userId,
      title: event.title,
      startTime: event.startTime,
      endTime: event.endTime ?? event.startTime.add(const Duration(hours: 3)),
      certainty: EventCertainty.locked, // Hosting = confirmed
      location: event.venueName ?? event.venueAddress,
      notes: event.description,
      isHosting: true,
      isFromExperience: true,
      createdAt: DateTime.now(),
    );
    ref.read(planProvider.notifier).createEvent(planEvent);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 "${event.title}" created and added to your Plan!'),
          backgroundColor: VesparaColors.success,
        ),
      );

      Navigator.pop(context, event); // Return the created event
    }
  }
}
