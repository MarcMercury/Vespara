import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/domain/models/vespara_event.dart';
import '../../../core/providers/events_provider.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// EVENT CREATION SCREEN - Partiful-Style Comprehensive Event Builder
/// Full-featured event creation with all options visible
/// ════════════════════════════════════════════════════════════════════════════

class EventCreationScreen extends ConsumerStatefulWidget {
  final VesparaEvent? eventToEdit;

  const EventCreationScreen({super.key, this.eventToEdit});

  @override
  ConsumerState<EventCreationScreen> createState() => _EventCreationScreenState();
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
  String _coverTheme = 'default';
  
  final List<EventLink> _links = [];
  final List<EventCoHost> _coHosts = [];
  
  // Emoji customization for RSVP
  String _goingEmoji = '👍';
  String _maybeEmoji = '🥺';
  String _cantGoEmoji = '😢';
  
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
  Widget build(BuildContext context) {
    return Scaffold(
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
  }

  Widget _buildFormPanel() {
    return Container(
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
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, color: VesparaColors.primary),
          ),
          const Spacer(),
          // Make it public button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: VesparaColors.glow.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: VesparaColors.success,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'New!',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: VesparaColors.background,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Make it public',
                  style: TextStyle(
                    fontSize: 14,
                    color: VesparaColors.primary,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 18, color: VesparaColors.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title input
        TextField(
          controller: _titleController,
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w600,
            color: VesparaColors.primary,
          ),
          decoration: InputDecoration(
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        fontStyle: style == EventTitleStyle.eclectic ? FontStyle.italic : FontStyle.normal,
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
  }

  Widget _buildDateSection() {
    return Column(
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
                Icon(Icons.calendar_today, color: VesparaColors.glow),
                const SizedBox(width: 12),
                Text(
                  _eventDate != null
                      ? _formatDateTime()
                      : 'Set a date...',
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
        
        // Date poll option
        GestureDetector(
          onTap: () => setState(() => _hasDatePoll = !_hasDatePoll),
          child: Row(
            children: [
              Text(
                "Can't decide when?",
                style: TextStyle(
                  fontSize: 14,
                  color: VesparaColors.secondary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Poll your guests →',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: VesparaColors.glow,
                ),
              ),
            ],
          ),
        ),
      ],
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
          Row(
            children: [
              Icon(Icons.person_outline, color: VesparaColors.glow, size: 20),
              const SizedBox(width: 8),
              Text(
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
              CircleAvatar(
                radius: 24,
                backgroundColor: VesparaColors.glow.withOpacity(0.3),
                child: Text('M', style: TextStyle(color: VesparaColors.glow, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 12),
              
              // Host name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Marc Mercury',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: VesparaColors.primary,
                      ),
                    ),
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
              
              // Add co-hosts button
              OutlinedButton.icon(
                onPressed: _addCoHost,
                icon: Icon(Icons.add, size: 18, color: VesparaColors.glow),
                label: Text('Add cohosts', style: TextStyle(color: VesparaColors.glow)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: VesparaColors.glow),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              children: _coHosts.map((coHost) => Chip(
                avatar: CircleAvatar(
                  backgroundColor: VesparaColors.glow.withOpacity(0.3),
                  child: Text(coHost.name[0]),
                ),
                label: Text(coHost.name),
                deleteIcon: Icon(Icons.close, size: 16),
                onDeleted: () => setState(() => _coHosts.remove(coHost)),
                backgroundColor: VesparaColors.surface,
                side: BorderSide(color: VesparaColors.border),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return GestureDetector(
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
            Icon(Icons.location_on_outlined, color: VesparaColors.glow),
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
            Icon(Icons.chevron_right, color: VesparaColors.secondary),
          ],
        ),
      ),
    );
  }

  Widget _buildCapacitySection() {
    return Row(
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
                Icon(Icons.people_outline, color: VesparaColors.glow),
                const SizedBox(width: 12),
                Expanded(
                  child: _unlimitedSpots
                      ? GestureDetector(
                          onTap: () => setState(() => _unlimitedSpots = false),
                          child: Text(
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
                          decoration: InputDecoration(
                            hintText: '# spots',
                            hintStyle: TextStyle(color: VesparaColors.secondary),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: TextStyle(
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
                Icon(Icons.attach_money, color: VesparaColors.glow),
                const SizedBox(width: 12),
                Expanded(
                  child: !_hasCost
                      ? GestureDetector(
                          onTap: () => setState(() => _hasCost = true),
                          child: Text(
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
                          decoration: InputDecoration(
                            prefixText: '\$ ',
                            hintText: '0',
                            hintStyle: TextStyle(color: VesparaColors.secondary),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: TextStyle(
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
  }

  Widget _buildLinksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildLinkButton('Link', Icons.link),
              const SizedBox(width: 8),
              _buildLinkButton('Playlist', Icons.music_note),
              const SizedBox(width: 8),
              _buildLinkButton('Registry', Icons.card_giftcard),
              const SizedBox(width: 8),
              _buildLinkButton('Dress code', Icons.checkroom),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _showMoreLinks,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: VesparaColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: VesparaColors.border),
                  ),
                  child: Text(
                    'Show more',
                    style: TextStyle(
                      fontSize: 14,
                      color: VesparaColors.secondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Added links
        if (_links.isNotEmpty) ...[
          const SizedBox(height: 16),
          Column(
            children: _links.map((link) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: VesparaColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: VesparaColors.border),
              ),
              child: Row(
                children: [
                  Text(link.type.icon, style: const TextStyle(fontSize: 20)),
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
                            color: VesparaColors.secondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 18, color: VesparaColors.secondary),
                    onPressed: () => setState(() => _links.remove(link)),
                  ),
                ],
              ),
            )).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildLinkButton(String label, IconData icon) {
    return GestureDetector(
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
            Icon(Icons.add, size: 18, color: VesparaColors.glow),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: VesparaColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VesparaColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VesparaColors.border),
      ),
      child: TextField(
        controller: _descriptionController,
        maxLines: 4,
        decoration: InputDecoration(
          hintText: 'Add a description of your event',
          hintStyle: TextStyle(color: VesparaColors.secondary),
          border: InputBorder.none,
        ),
        style: TextStyle(
          fontSize: 16,
          color: VesparaColors.primary,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildRsvpOptionsSection() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.settings, color: VesparaColors.glow, size: 20),
                  const SizedBox(width: 8),
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
              // Emoji selector dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: VesparaColors.background,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_goingEmoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 4),
                    Text(
                      'Emojis',
                      style: TextStyle(
                        fontSize: 14,
                        color: VesparaColors.glow,
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, color: VesparaColors.glow),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // RSVP buttons preview
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
  }

  Widget _buildRsvpPreview(String emoji, String label) {
    return GestureDetector(
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
              style: TextStyle(
                fontSize: 12,
                color: VesparaColors.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHostActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.more_horiz, color: VesparaColors.glow, size: 20),
                const SizedBox(width: 8),
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
        
        const SizedBox(height: 24),
        
        // Add section button
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'More to say?',
                style: TextStyle(
                  fontSize: 14,
                  color: VesparaColors.secondary,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _addSection,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: VesparaColors.glow.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 16, color: VesparaColors.glow),
                      const SizedBox(width: 4),
                      Text(
                        'New section',
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
      ],
    );
  }

  Widget _buildHostActionChip(IconData icon, String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? VesparaColors.glow.withOpacity(0.2) : VesparaColors.surface,
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
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VesparaColors.surface,
        border: Border(
          top: BorderSide(color: VesparaColors.border),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _saveDraft,
            child: Text(
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _isEditing ? 'Update Experience' : 'Create Experience',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewPanel() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1A0A2E),
            const Color(0xFF2D1B4E),
          ],
        ),
      ),
      child: Column(
        children: [
          // Preview header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildPreviewButton(Icons.palette_outlined, 'Theme'),
                const SizedBox(width: 16),
                _buildPreviewButton(Icons.auto_fix_high, 'Effect'),
                const SizedBox(width: 16),
                _buildPreviewButton(Icons.settings_outlined, 'Settings'),
                const SizedBox(width: 16),
                _buildPreviewButton(Icons.visibility_outlined, 'Preview'),
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
                    // Cover image
                    Container(
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
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Stack(
                        children: [
                          if (_coverImageUrl != null)
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                              child: Image.network(
                                _coverImageUrl!,
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _buildCoverPlaceholder(),
                              ),
                            )
                          else
                            _buildCoverPlaceholder(),
                          
                          Positioned(
                            right: 12,
                            bottom: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: VesparaColors.background.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.edit, size: 16, color: VesparaColors.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Edit',
                                    style: TextStyle(
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
                    
                    // Event info preview
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            _titleController.text.isEmpty 
                                ? 'Your Event Title' 
                                : _titleController.text,
                            style: TextStyle(
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
                              style: TextStyle(
                                fontSize: 14,
                                color: VesparaColors.secondary,
                              ),
                            ),
                          ],
                          if (_locationController.text.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              _locationController.text,
                              style: TextStyle(
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
  }

  Widget _buildCoverPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 48,
            color: VesparaColors.secondary,
          ),
          const SizedBox(height: 8),
          Text(
            'Add cover image',
            style: TextStyle(
              fontSize: 14,
              color: VesparaColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewButton(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: VesparaColors.surface.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: VesparaColors.primary, size: 24),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: VesparaColors.secondary,
          ),
        ),
      ],
    );
  }

  // Action methods
  void _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _eventDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(
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
            colorScheme: ColorScheme.dark(
              primary: VesparaColors.glow,
              surface: VesparaColors.surface,
            ),
          ),
          child: child!,
        ),
      );
      
      if (time != null) {
        setState(() {
          _eventDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
          _eventTime = time;
        });
      }
    }
  }

  String _formatDateTime() {
    if (_eventDate == null) return '';
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final hour = _eventDate!.hour > 12 ? _eventDate!.hour - 12 : (_eventDate!.hour == 0 ? 12 : _eventDate!.hour);
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
            Text(
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
                hintStyle: TextStyle(color: VesparaColors.secondary),
                prefixIcon: Icon(Icons.location_on, color: VesparaColors.glow),
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
                child: Text('Confirm Location', style: TextStyle(color: VesparaColors.background)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _addCoHost() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Co-host picker would open here')),
    );
  }

  void _addLink(String type) {
    final urlController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VesparaColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Add $type', style: TextStyle(color: VesparaColors.primary)),
        content: TextField(
          controller: urlController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Paste URL',
            hintStyle: TextStyle(color: VesparaColors.secondary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          style: TextStyle(color: VesparaColors.primary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: VesparaColors.secondary)),
          ),
          TextButton(
            onPressed: () {
              if (urlController.text.isNotEmpty) {
                setState(() {
                  _links.add(EventLink(
                    id: 'link-${_links.length}',
                    type: EventLinkType.values.firstWhere(
                      (t) => t.label.toLowerCase() == type.toLowerCase(),
                      orElse: () => EventLinkType.link,
                    ),
                    url: urlController.text,
                  ));
                });
              }
              Navigator.pop(context);
            },
            child: Text('Add', style: TextStyle(color: VesparaColors.glow)),
          ),
        ],
      ),
    );
  }

  void _showMoreLinks() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('More link options...')),
    );
  }

  void _customizeEmoji(String label) {
    final emojis = ['👍', '🔥', '❤️', '🎉', '✨', '🤔', '😅', '🥺', '😢', '💔', '👎', '❌'];
    
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
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: VesparaColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: emojis.map((emoji) => GestureDetector(
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
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: VesparaColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(emoji, style: const TextStyle(fontSize: 28)),
                ),
              )).toList(),
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
              leading: Icon(Icons.visibility, color: VesparaColors.glow),
              title: Text('Visibility Settings', style: TextStyle(color: VesparaColors.primary)),
              subtitle: Text(_visibility.label, style: TextStyle(color: VesparaColors.secondary)),
              onTap: () {
                Navigator.pop(context);
                _showVisibilitySettings();
              },
            ),
            ListTile(
              leading: Icon(Icons.timer, color: VesparaColors.glow),
              title: Text('RSVP Deadline', style: TextStyle(color: VesparaColors.primary)),
              subtitle: Text('No deadline set', style: TextStyle(color: VesparaColors.secondary)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.message, color: VesparaColors.glow),
              title: Text('Guest Messages', style: TextStyle(color: VesparaColors.primary)),
              subtitle: Text('Allow guests to message each other', style: TextStyle(color: VesparaColors.secondary)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.warning_amber, color: VesparaColors.warning),
              title: Text('Content Rating', style: TextStyle(color: VesparaColors.primary)),
              subtitle: Text('PG (default)', style: TextStyle(color: VesparaColors.secondary)),
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
              Text(
                'Event Visibility',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: VesparaColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              ...EventVisibility.values.map((v) => RadioListTile<EventVisibility>(
                value: v,
                groupValue: _visibility,
                onChanged: (value) {
                  setModalState(() => _visibility = value!);
                  setState(() {});
                },
                activeColor: VesparaColors.glow,
                title: Text(v.label, style: TextStyle(color: VesparaColors.primary)),
                subtitle: Text(v.description, style: TextStyle(color: VesparaColors.secondary, fontSize: 12)),
              )),
            ],
          ),
        ),
      ),
    );
  }

  void _addSection() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add custom section...')),
    );
  }

  void _saveDraft() {
    HapticFeedback.mediumImpact();
    
    // Create and save as draft
    final event = _buildEventFromForm(isDraft: true);
    ref.read(eventsProvider.notifier).createVesparaEvent(event);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Event saved as draft'),
        backgroundColor: VesparaColors.surface,
      ),
    );
    Navigator.pop(context);
  }

  void _publishEvent() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please add an event title'),
          backgroundColor: VesparaColors.error,
        ),
      );
      return;
    }
    
    HapticFeedback.heavyImpact();
    
    // Create the event
    final event = _buildEventFromForm(isDraft: false);
    
    // Save to provider (which saves to database)
    final result = await ref.read(eventsProvider.notifier).createVesparaEvent(event);
    
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 "${event.title}" created successfully!'),
          backgroundColor: VesparaColors.success,
        ),
      );
      Navigator.pop(context, result); // Return the created event
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to create experience. Please try again.'),
          backgroundColor: VesparaColors.error,
        ),
      );
    }
  }
  
  VesparaEvent _buildEventFromForm({required bool isDraft}) {
    return VesparaEvent(
      id: 'event-${DateTime.now().millisecondsSinceEpoch}',
      hostId: 'current-user',
      hostName: 'Marc Mercury',
      title: _titleController.text,
      titleStyle: _titleStyle,
      description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
      coverImageUrl: _coverImageUrl,
      startTime: _eventDate ?? DateTime.now().add(const Duration(days: 1)),
      endTime: _eventDate?.add(const Duration(hours: 3)),
      venueName: _locationController.text.isEmpty ? null : _locationController.text,
      venueAddress: _locationController.text.isEmpty ? null : _locationController.text,
      maxSpots: _unlimitedSpots ? null : int.tryParse(_spotsController.text),
      costPerPerson: _hasCost ? double.tryParse(_costController.text) : null,
      visibility: _visibility,
      requiresApproval: _requiresApproval,
      collectGuestInfo: _collectGuestInfo,
      sendReminders: _sendReminders,
      links: _links,
      coHosts: _coHosts,
      createdAt: DateTime.now(),
      isDraft: isDraft,
    );
  }
}
