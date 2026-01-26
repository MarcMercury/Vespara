import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/models/match.dart';
import '../../../core/providers/groups_provider.dart';
import '../../../core/providers/match_state_provider.dart';
import '../../../core/theme/app_theme.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// CREATE GROUP SCREEN - Wizard Flow
/// Step 1: Name & Description
/// Step 2: Invite Members (from matches)
/// Step 3: Confirmation
/// ════════════════════════════════════════════════════════════════════════════

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Step 1: Group info
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Step 2: Selected members to invite
  final Set<String> _selectedMemberIds = {};

  // Loading state
  bool _isCreating = false;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _canProceedStep1 => _nameController.text.trim().length >= 3;
  bool get _canCreate => _canProceedStep1;

  void _nextStep() {
    if (_currentStep < 2) {
      HapticFeedback.lightImpact();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      HapticFeedback.lightImpact();
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _createGroup() async {
    if (!_canCreate) return;

    setState(() => _isCreating = true);
    HapticFeedback.heavyImpact();

    try {
      final group = await ref.read(groupsProvider.notifier).createGroup(
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
          );

      if (group != null) {
        // Send invitations to selected members
        for (final memberId in _selectedMemberIds) {
          await ref.read(groupsProvider.notifier).sendInvitation(
                groupId: group.id,
                inviteeId: memberId,
                message: 'Join my new group: ${group.name}!',
              );
        }

        if (mounted) {
          HapticFeedback.heavyImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${group.name} created successfully! 🎉'),
              backgroundColor: VesparaColors.success,
            ),
          );
          Navigator.pop(context, group);
        }
      } else {
        final error = ref.read(groupsProvider).error;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error ?? 'Failed to create group'),
              backgroundColor: VesparaColors.error,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: VesparaColors.background,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildProgressIndicator(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStep1GroupInfo(),
                    _buildStep2InviteMembers(),
                    _buildStep3Confirmation(),
                  ],
                ),
              ),
              _buildBottomBar(),
            ],
          ),
        ),
      );

  Widget _buildHeader() {
    final titles = ['Create Circle', 'Invite People', 'Review & Create'];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: _previousStep,
            icon: Icon(
              _currentStep == 0 ? Icons.close : Icons.arrow_back,
              color: VesparaColors.primary,
            ),
          ),
          Expanded(
            child: Text(
              titles[_currentStep],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: VesparaColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 48), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Row(
          children: List.generate(3, (index) {
            final isActive = index <= _currentStep;
            final isComplete = index < _currentStep;

            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                decoration: BoxDecoration(
                  color: isComplete
                      ? VesparaColors.success
                      : isActive
                          ? VesparaColors.glow
                          : VesparaColors.surface,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
      );

  // ════════════════════════════════════════════════════════════════════════════
  // STEP 1: GROUP INFO
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildStep1GroupInfo() => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            // Icon
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: VesparaColors.glow.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: VesparaColors.glow.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.group_add,
                  size: 48,
                  color: VesparaColors.glow,
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Name field
            const Text(
              'CIRCLE NAME',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
                color: VesparaColors.secondary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              onChanged: (_) => setState(() {}),
              maxLength: 30,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: VesparaColors.primary,
              ),
              decoration: InputDecoration(
                hintText: 'e.g., Wine Wednesday Crew',
                hintStyle: const TextStyle(
                  color: VesparaColors.inactive,
                  fontWeight: FontWeight.normal,
                ),
                filled: true,
                fillColor: VesparaColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: VesparaColors.glow),
                ),
                counterStyle: const TextStyle(color: VesparaColors.secondary),
              ),
            ),
            const SizedBox(height: 24),
            // Description field
            const Text(
              'DESCRIPTION (OPTIONAL)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
                color: VesparaColors.secondary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              maxLength: 100,
              style: const TextStyle(
                fontSize: 16,
                color: VesparaColors.primary,
              ),
              decoration: InputDecoration(
                hintText: 'What brings this group together?',
                hintStyle: const TextStyle(color: VesparaColors.inactive),
                filled: true,
                fillColor: VesparaColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: VesparaColors.glow),
                ),
                counterStyle: const TextStyle(color: VesparaColors.secondary),
              ),
            ),
            const SizedBox(height: 24),
            // Info box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: VesparaColors.glow.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: VesparaColors.glow.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: VesparaColors.glow, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'As the creator, only you can invite new members. The group chat will appear in Wire.',
                      style: TextStyle(
                        fontSize: 13,
                        color: VesparaColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  // ════════════════════════════════════════════════════════════════════════════
  // STEP 2: INVITE MEMBERS
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildStep2InviteMembers() {
    final matches = ref.watch(matchStateProvider).matches;

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Select people to invite',
                style: TextStyle(
                  fontSize: 16,
                  color: VesparaColors.secondary,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'They\'ll receive an invitation to join',
                style: TextStyle(
                  fontSize: 13,
                  color: VesparaColors.inactive,
                ),
              ),
            ],
          ),
        ),
        if (_selectedMemberIds.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: VesparaColors.surface,
            child: Row(
              children: [
                const Icon(Icons.check_circle,
                    color: VesparaColors.success, size: 18),
                const SizedBox(width: 8),
                Text(
                  '${_selectedMemberIds.length} selected',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: VesparaColors.success,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(_selectedMemberIds.clear),
                  child: const Text(
                    'Clear all',
                    style: TextStyle(
                      fontSize: 13,
                      color: VesparaColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: matches.isEmpty
              ? _buildNoMatchesState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: matches.length,
                  itemBuilder: (context, index) =>
                      _buildMemberTile(matches[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildNoMatchesState() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: VesparaColors.inactive,
            ),
            SizedBox(height: 16),
            Text(
              'No matches yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: VesparaColors.primary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'You can invite people after you match with them',
              style: TextStyle(
                fontSize: 14,
                color: VesparaColors.secondary,
              ),
            ),
          ],
        ),
      );

  Widget _buildMemberTile(Match match) {
    final isSelected = _selectedMemberIds.contains(match.matchedUserId);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          if (isSelected) {
            _selectedMemberIds.remove(match.matchedUserId);
          } else {
            _selectedMemberIds.add(match.matchedUserId);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? VesparaColors.glow.withOpacity(0.15)
              : VesparaColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? VesparaColors.glow : VesparaColors.border,
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: VesparaColors.glow.withOpacity(0.2),
              ),
              child: match.matchedUserAvatar != null
                  ? ClipOval(
                      child: Image.network(
                        match.matchedUserAvatar!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.person,
                          color: VesparaColors.glow,
                        ),
                      ),
                    )
                  : const Icon(Icons.person, color: VesparaColors.glow),
            ),
            const SizedBox(width: 12),
            // Name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    match.matchedUserName ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: VesparaColors.primary,
                    ),
                  ),
                  Text(
                    'Matched ${_formatDate(match.matchedAt)}',
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
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isSelected ? VesparaColors.glow : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      isSelected ? VesparaColors.glow : VesparaColors.secondary,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check,
                      size: 18, color: VesparaColors.background)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return 'today';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
    return '${(diff.inDays / 30).floor()} months ago';
  }

  // ════════════════════════════════════════════════════════════════════════════
  // STEP 3: CONFIRMATION
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildStep3Confirmation() {
    final matches = ref.watch(matchStateProvider).matches;
    final selectedMembers = matches
        .where((m) => _selectedMemberIds.contains(m.matchedUserId))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Success icon
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [VesparaColors.glow, VesparaColors.secondary],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.group,
              size: 40,
              color: VesparaColors.background,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _nameController.text.trim(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: VesparaColors.primary,
            ),
          ),
          if (_descriptionController.text.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _descriptionController.text.trim(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: VesparaColors.secondary,
              ),
            ),
          ],
          const SizedBox(height: 32),
          // Summary card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: VesparaColors.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                _buildSummaryRow(
                  icon: Icons.person,
                  label: 'You',
                  value: 'Creator & Admin',
                  color: VesparaColors.glow,
                ),
                if (selectedMembers.isNotEmpty) ...[
                  const Divider(height: 24, color: VesparaColors.border),
                  _buildSummaryRow(
                    icon: Icons.mail_outline,
                    label: 'Invitations',
                    value: '${selectedMembers.length} will be sent',
                    color: VesparaColors.warning,
                  ),
                ],
                const Divider(height: 24, color: VesparaColors.border),
                _buildSummaryRow(
                  icon: Icons.chat_bubble_outline,
                  label: 'Group Chat',
                  value: 'Will appear in Wire',
                  color: VesparaColors.success,
                ),
              ],
            ),
          ),
          if (selectedMembers.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'INVITING',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
                color: VesparaColors.secondary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: selectedMembers.map(_buildInviteChip).toList(),
            ),
          ],
          const SizedBox(height: 32),
          // Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: VesparaColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: VesparaColors.warning.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline,
                    color: VesparaColors.warning, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Invited members have 7 days to accept. They can decline but you can re-invite later.',
                    style: TextStyle(
                      fontSize: 13,
                      color: VesparaColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) =>
      Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: VesparaColors.secondary,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: VesparaColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _buildInviteChip(Match match) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: VesparaColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: VesparaColors.glow.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: VesparaColors.glow.withOpacity(0.2),
              ),
              child: match.matchedUserAvatar != null
                  ? ClipOval(
                      child: Image.network(
                        match.matchedUserAvatar!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.person,
                          size: 14,
                          color: VesparaColors.glow,
                        ),
                      ),
                    )
                  : const Icon(Icons.person,
                      size: 14, color: VesparaColors.glow),
            ),
            const SizedBox(width: 8),
            Text(
              match.matchedUserName ?? 'Unknown',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: VesparaColors.primary,
              ),
            ),
          ],
        ),
      );

  // ════════════════════════════════════════════════════════════════════════════
  // BOTTOM BAR
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildBottomBar() {
    final isLastStep = _currentStep == 2;
    final canProceed = _currentStep == 0 ? _canProceedStep1 : true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: VesparaColors.surface,
        border: Border(
          top: BorderSide(color: VesparaColors.border),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousStep,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: VesparaColors.primary,
                    side: const BorderSide(color: VesparaColors.secondary),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Back'),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed:
                    canProceed ? (isLastStep ? _createGroup : _nextStep) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: VesparaColors.glow,
                  foregroundColor: VesparaColors.background,
                  disabledBackgroundColor: VesparaColors.inactive,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isCreating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation(VesparaColors.background),
                        ),
                      )
                    : Text(
                        isLastStep ? 'Create Circle' : 'Continue',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
