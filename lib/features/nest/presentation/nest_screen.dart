import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/data/vespara_mock_data.dart';
import '../../../core/domain/models/match.dart';
import '../../../core/domain/models/group.dart';
import '../../../core/providers/match_state_provider.dart';
import '../../../core/providers/groups_provider.dart';
import '../../wire/presentation/wire_screen.dart';
import '../../planner/presentation/planner_screen.dart';
import '../../ludus/presentation/tags_screen.dart';
import 'groups_section.dart';
import 'group_detail_screen.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// NEST SCREEN - Module 3
/// CRM-style match management with AI-driven priorities
/// Columns: Priority | In Waiting | On the Way Out | Legacy
/// ════════════════════════════════════════════════════════════════════════════

class NestScreen extends ConsumerStatefulWidget {
  const NestScreen({super.key});

  @override
  ConsumerState<NestScreen> createState() => _NestScreenState();
}

class _NestScreenState extends ConsumerState<NestScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _glowController;
  
  final List<MatchPriority> _priorities = [
    MatchPriority.new_,
    MatchPriority.priority,
    MatchPriority.inWaiting,
    MatchPriority.onWayOut,
    MatchPriority.legacy,
  ];

  @override
  void initState() {
    super.initState();
    // +1 for Circles tab
    _tabController = TabController(length: _priorities.length + 1, vsync: this);
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  List<Match> _getMatchesForPriority(MatchPriority priority) {
    // Get matches from global state provider
    final state = ref.watch(matchStateProvider);
    return state.getMatchesByPriority(priority);
  }

  void _updateMatchPriority(Match match, MatchPriority newPriority) {
    // Use global state notifier
    ref.read(matchStateProvider.notifier).updateMatchPriority(match.id, newPriority);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${match.matchedUserName} moved to ${newPriority.label}'),
        backgroundColor: VesparaColors.surface,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VesparaColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const GroupsSection(),
                    const SizedBox(height: 16),
                    _buildStats(),
                    _buildTabBar(),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: _buildTabBarView(),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: VesparaColors.primary),
          ),
          Column(
            children: [
              Text(
                'THE SANCTUM',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 4,
                  color: VesparaColors.primary,
                ),
              ),
              Text(
                'Your connections, organized',
                style: TextStyle(
                  fontSize: 12,
                  color: VesparaColors.secondary,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () => _showSearchDialog(),
            icon: const Icon(Icons.search, color: VesparaColors.secondary),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    final matchState = ref.watch(matchStateProvider);
    final totalMatches = matchState.matches.where((m) => !m.isArchived).length;
    final priorityCount = matchState.getMatchesByPriority(MatchPriority.priority).length;
    final newCount = matchState.getMatchesByPriority(MatchPriority.new_).length;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VesparaColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VesparaColors.glow.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total', totalMatches.toString(), VesparaColors.primary),
          _buildStatDivider(),
          _buildStatItem('New', newCount.toString(), VesparaColors.tagsYellow),
          _buildStatDivider(),
          _buildStatItem('Priority', priorityCount.toString(), VesparaColors.success),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: VesparaColors.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 30,
      color: VesparaColors.glow.withOpacity(0.2),
    );
  }

  Widget _buildTabBar() {
    final groupsState = ref.watch(groupsProvider);
    
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: VesparaColors.primary,
        unselectedLabelColor: VesparaColors.secondary,
        indicatorColor: VesparaColors.glow,
        indicatorWeight: 3,
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
        tabs: [
          // Priority tabs
          ..._priorities.map((p) {
            final count = _getMatchesForPriority(p).length;
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(p.emoji),
                  const SizedBox(width: 6),
                  Text(p.label.toUpperCase()),
                  if (count > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: VesparaColors.glow.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        count.toString(),
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
          // Circles tab at the end
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⭕'),
                const SizedBox(width: 6),
                const Text('CIRCLES'),
                if (groupsState.groupCount > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: VesparaColors.glow.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      groupsState.groupCount.toString(),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: [
        // Priority tabs content
        ..._priorities.map((priority) {
          final matches = _getMatchesForPriority(priority);
          
          if (matches.isEmpty) {
            return _buildEmptyColumn(priority);
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: matches.length,
            itemBuilder: (context, index) {
              return _buildMatchCard(matches[index]);
            },
          );
        }),
        // Circles tab content
        _buildCirclesTab(),
      ],
    );
  }

  Widget _buildCirclesTab() {
    final groupsState = ref.watch(groupsProvider);
    
    if (groupsState.isLoading) {
      return const Center(child: CircularProgressIndicator(color: VesparaColors.glow));
    }
    
    if (groupsState.groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_outlined, size: 48, color: VesparaColors.secondary),
            const SizedBox(height: 16),
            Text(
              'No circles yet',
              style: TextStyle(fontSize: 16, color: VesparaColors.secondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a circle to organize your connections',
              style: TextStyle(fontSize: 13, color: VesparaColors.secondary.withOpacity(0.7)),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupsState.groups.length,
      itemBuilder: (context, index) {
        return _buildCircleListItem(groupsState.groups[index]);
      },
    );
  }

  Widget _buildCircleListItem(VesparaGroup group) {
    // Calculate idle members (those who haven't communicated in 7+ days)
    // For now we'll use a placeholder since we need to track last_message_at per member
    final idleCount = 0; // TODO: Calculate from message activity
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VesparaColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: group.isCreator 
              ? VesparaColors.glow.withOpacity(0.3) 
              : VesparaColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: VesparaColors.glow.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: group.avatarUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(group.avatarUrl!, fit: BoxFit.cover),
                      )
                    : Icon(Icons.group, color: VesparaColors.glow, size: 24),
              ),
              const SizedBox(width: 12),
              
              // Name and stats
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            group.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: VesparaColors.primary,
                            ),
                          ),
                        ),
                        if (group.isCreator)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: VesparaColors.glow.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'OWNER',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: VesparaColors.glow,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildStatChip('${group.memberCount} members', VesparaColors.glow),
                        const SizedBox(width: 8),
                        if (idleCount > 0)
                          _buildStatChip('$idleCount idle', VesparaColors.warning),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Action buttons
          Row(
            children: [
              if (group.isCreator) ...[
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showInviteWizard(group),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [VesparaColors.glow, VesparaColors.secondary],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_add, color: VesparaColors.background, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Invite',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: VesparaColors.background,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _confirmDeleteGroup(group),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: VesparaColors.error.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: VesparaColors.error.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delete_outline, color: VesparaColors.error, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Delete',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: VesparaColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => GroupDetailScreen(groupId: group.id)),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: VesparaColors.glow.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: VesparaColors.glow.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.visibility, color: VesparaColors.glow, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'View Circle',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: VesparaColors.glow,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  void _showInviteWizard(VesparaGroup group) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GroupDetailScreen(groupId: group.id)),
    );
  }

  void _confirmDeleteGroup(VesparaGroup group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VesparaColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Circle?',
          style: TextStyle(color: VesparaColors.primary),
        ),
        content: Text(
          'Are you sure you want to delete "${group.name}"? This will remove all members and cannot be undone.',
          style: TextStyle(color: VesparaColors.secondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: VesparaColors.secondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(groupsProvider.notifier).deleteGroup(group.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Circle deleted'),
                      backgroundColor: VesparaColors.surface,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete circle'),
                      backgroundColor: VesparaColors.error,
                    ),
                  );
                }
              }
            },
            child: Text('Delete', style: TextStyle(color: VesparaColors.error)),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(Match match) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        final isHot = match.priority == MatchPriority.priority;
        
        return GestureDetector(
          onTap: () => _showMatchDetails(match),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: VesparaColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isHot 
                    ? VesparaColors.glow.withOpacity(0.2 + _glowController.value * 0.2)
                    : VesparaColors.glow.withOpacity(0.1),
              ),
              boxShadow: isHot ? [
                BoxShadow(
                  color: VesparaColors.glow.withOpacity(0.1 + _glowController.value * 0.1),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ] : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: VesparaColors.glow.withOpacity(0.2),
                        border: Border.all(
                          color: match.isSuperMatch 
                              ? VesparaColors.tagsYellow 
                              : VesparaColors.glow.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          match.matchedUserName?[0].toUpperCase() ?? '?',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: VesparaColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Name and info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                match.matchedUserName ?? 'Unknown',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: VesparaColors.primary,
                                ),
                              ),
                              if (match.matchedUserAge != null) ...[
                                Text(
                                  ', ${match.matchedUserAge}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: VesparaColors.secondary,
                                  ),
                                ),
                              ],
                              if (match.isSuperMatch) ...[
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.star,
                                  size: 16,
                                  color: VesparaColors.tagsYellow,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              // Compatibility
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8, 
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _getCompatibilityColor(match.compatibilityScore).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${match.compatibilityPercent}% match',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: _getCompatibilityColor(match.compatibilityScore),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Last active
                              Text(
                                match.lastMessage != null 
                                    ? '${match.daysSinceLastMessage}d ago'
                                    : 'New match!',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: match.isGoingCold 
                                      ? VesparaColors.warning 
                                      : VesparaColors.secondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Unread badge
                    if (match.unreadCount > 0)
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: VesparaColors.glow,
                        ),
                        child: Center(
                          child: Text(
                            match.unreadCount.toString(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: VesparaColors.background,
                            ),
                          ),
                        ),
                      ),
                      
                    // Priority menu
                    PopupMenuButton<MatchPriority>(
                      icon: Icon(
                        Icons.more_vert,
                        color: VesparaColors.secondary,
                      ),
                      color: VesparaColors.surfaceElevated,
                      onSelected: (priority) => _updateMatchPriority(match, priority),
                      itemBuilder: (context) => _priorities.map((p) {
                        return PopupMenuItem(
                          value: p,
                          child: Row(
                            children: [
                              Text(p.emoji),
                              const SizedBox(width: 8),
                              Text(
                                'Move to ${p.label}',
                                style: TextStyle(
                                  color: VesparaColors.primary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                
                // Last message preview
                if (match.lastMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: VesparaColors.background.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 14,
                          color: VesparaColors.secondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            match.lastMessage!,
                            style: TextStyle(
                              fontSize: 12,
                              color: VesparaColors.secondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                // AI suggestions
                if (match.suggestedTopics.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 14,
                        color: VesparaColors.tagsYellow,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          match.suggestedTopics.first,
                          style: TextStyle(
                            fontSize: 11,
                            color: VesparaColors.tagsYellow.withOpacity(0.8),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                
                // Shared interests
                if (match.sharedInterests.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: match.sharedInterests.map((interest) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8, 
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: VesparaColors.glow.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          interest,
                          style: TextStyle(
                            fontSize: 10,
                            color: VesparaColors.glow,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMatchDetails(Match match) {
    showModalBottomSheet(
      context: context,
      backgroundColor: VesparaColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: VesparaColors.glow.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: VesparaColors.glow.withOpacity(0.2),
                        ),
                        child: Center(
                          child: Text(
                            match.matchedUserName?[0].toUpperCase() ?? '?',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w600,
                              color: VesparaColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              match.matchedUserName ?? 'Unknown',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: VesparaColors.primary,
                              ),
                            ),
                            Text(
                              'Matched ${_formatMatchDate(match.matchedAt)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: VesparaColors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Quick actions
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickAction(
                          icon: Icons.chat,
                          label: 'Message',
                          color: VesparaColors.glow,
                          onTap: () {
                            Navigator.pop(context);
                            // Navigate to Wire screen for chat
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const WireScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickAction(
                          icon: Icons.calendar_today,
                          label: 'Plan Date',
                          color: VesparaColors.success,
                          onTap: () {
                            Navigator.pop(context);
                            // Navigate to Planner screen
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const PlannerScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickAction(
                          icon: Icons.games,
                          label: 'Play TAG',
                          color: VesparaColors.tagsYellow,
                          onTap: () {
                            Navigator.pop(context);
                            // Navigate to TAG screen
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const TagScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // AI Insights
                  _buildSectionTitle('AI Insights'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: VesparaColors.background.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: VesparaColors.glow.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...match.suggestedDateIdeas.map((idea) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(Icons.lightbulb, size: 16, color: VesparaColors.tagsYellow),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  idea,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: VesparaColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Notes
                  _buildSectionTitle('Notes'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: VesparaColors.background.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Add personal notes about ${match.matchedUserName}...',
                        hintStyle: TextStyle(color: VesparaColors.secondary),
                        border: InputBorder.none,
                      ),
                      style: TextStyle(color: VesparaColors.primary),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Danger zone
                  _buildSectionTitle('Danger Zone'),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _moveToShredder(match),
                    icon: Icon(Icons.delete_sweep, color: VesparaColors.error),
                    label: Text('Move to Shredder', style: TextStyle(color: VesparaColors.error)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: VesparaColors.error.withOpacity(0.5)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 1,
        color: VesparaColors.secondary,
      ),
    );
  }

  Widget _buildEmptyColumn(MatchPriority priority) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              priority.emoji,
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 16),
            Text(
              'No ${priority.label} matches',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: VesparaColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getEmptyMessage(priority),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: VesparaColors.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getEmptyMessage(MatchPriority priority) {
    switch (priority) {
      case MatchPriority.new_:
        return 'Keep swiping in Discover to find new connections!';
      case MatchPriority.priority:
        return 'Move promising matches here to focus your energy.';
      case MatchPriority.inWaiting:
        return 'Matches that need a bit more time go here.';
      case MatchPriority.onWayOut:
        return 'Connections fading? They\'ll appear here.';
      case MatchPriority.legacy:
        return 'Past connections live here for reference.';
    }
  }

  Color _getCompatibilityColor(double score) {
    if (score >= 0.8) return VesparaColors.success;
    if (score >= 0.6) return VesparaColors.glow;
    if (score >= 0.4) return VesparaColors.warning;
    return VesparaColors.secondary;
  }

  void _showSearchDialog() {
    final searchController = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: VesparaColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: searchController,
              autofocus: true,
              style: TextStyle(color: VesparaColors.primary),
              decoration: InputDecoration(
                hintText: 'Search your roster...',
                hintStyle: TextStyle(color: VesparaColors.secondary),
                prefixIcon: Icon(Icons.search, color: VesparaColors.glow),
                filled: true,
                fillColor: VesparaColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
              onSubmitted: (query) {
                Navigator.pop(context);
                final matchState = ref.read(matchStateProvider);
                final results = matchState.matches.where((m) => m.matchedUserName?.toLowerCase().contains(query.toLowerCase()) ?? false).toList();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Found ${results.length} matches for "$query"'), backgroundColor: VesparaColors.glow));
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showPlanDateDialog(Match match) {
    showModalBottomSheet(
      context: context,
      backgroundColor: VesparaColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: VesparaColors.secondary, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('Plan a Date with ${match.matchedUserName}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: VesparaColors.primary)),
            const SizedBox(height: 20),
            ...['Drinks Tonight', 'Dinner This Week', 'Weekend Adventure', 'Something Special'].map((option) => ListTile(
              leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: VesparaColors.success.withOpacity(0.2), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.calendar_today, color: VesparaColors.success, size: 20)),
              title: Text(option, style: TextStyle(color: VesparaColors.primary, fontWeight: FontWeight.w500)),
              trailing: Icon(Icons.chevron_right, color: VesparaColors.secondary),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Scheduling "$option" with ${match.matchedUserName}...'), backgroundColor: VesparaColors.success));
              },
            )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showPlayTagDialog(Match match) {
    showModalBottomSheet(
      context: context,
      backgroundColor: VesparaColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: VesparaColors.secondary, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('Play TAG with ${match.matchedUserName} 🎮', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: VesparaColors.primary)),
            const SizedBox(height: 12),
            Text('Choose a game to play together:', style: TextStyle(color: VesparaColors.secondary)),
            const SizedBox(height: 16),
            ...['🧊 Icebreakers', '🃏 Truth or Dare', '🔥 Spicy Edition', '💜 Fantasy Exploration'].map((game) => ListTile(
              title: Text(game, style: TextStyle(color: VesparaColors.primary, fontWeight: FontWeight.w500)),
              trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: VesparaColors.tagsYellow.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: Text('Play', style: TextStyle(color: VesparaColors.tagsYellow, fontWeight: FontWeight.w600, fontSize: 12))),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Starting $game with ${match.matchedUserName}...'), backgroundColor: VesparaColors.tagsYellow));
              },
            )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _moveToShredder(Match match) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: VesparaColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [Icon(Icons.delete_sweep, color: VesparaColors.error), const SizedBox(width: 8), Text('Move to Shredder?', style: TextStyle(color: VesparaColors.primary))]),
        content: Text('${match.matchedUserName} will be flagged for review in The Shredder. You can always bring them back.', style: TextStyle(color: VesparaColors.secondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: VesparaColors.secondary))),
          ElevatedButton(
            onPressed: () {
              setState(() { _updateMatchPriority(match, MatchPriority.onWayOut); });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${match.matchedUserName} moved to On The Way Out'), backgroundColor: VesparaColors.error));
            },
            style: ElevatedButton.styleFrom(backgroundColor: VesparaColors.error),
            child: Text('Move', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatMatchDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return 'today';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${diff.inDays ~/ 7} weeks ago';
    return '${diff.inDays ~/ 30} months ago';
  }
}
