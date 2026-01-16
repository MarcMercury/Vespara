import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/providers/wire_provider.dart';
import '../../../core/domain/models/wire_models.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// WIRE CREATE GROUP SCREEN - WhatsApp-Style Group Creation Flow
/// ════════════════════════════════════════════════════════════════════════════

class WireCreateGroupScreen extends ConsumerStatefulWidget {
  const WireCreateGroupScreen({super.key});

  @override
  ConsumerState<WireCreateGroupScreen> createState() => _WireCreateGroupScreenState();
}

class _WireCreateGroupScreenState extends ConsumerState<WireCreateGroupScreen> {
  // Step tracking
  int _currentStep = 0;
  
  // Step 1: Select participants
  final Set<String> _selectedParticipants = {};
  String _searchQuery = '';
  
  // Step 2: Group info
  final _groupNameController = TextEditingController();
  final _groupDescriptionController = TextEditingController();
  String? _groupAvatarPath;
  
  // Loading state
  bool _isLoading = false;
  bool _isCreating = false;
  
  // Mock connections data (in production, fetch from roster)
  List<Map<String, dynamic>> _connections = [];

  @override
  void initState() {
    super.initState();
    _loadConnections();
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _groupDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadConnections() async {
    setState(() => _isLoading = true);
    
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      
      // Fetch user's connections from roster
      final response = await Supabase.instance.client
          .from('roster')
          .select('''
            id,
            connected_user_id,
            connected_user:users!roster_connected_user_id_fkey (
              id,
              name,
              avatar_url,
              last_seen
            )
          ''')
          .eq('user_id', userId)
          .eq('status', 'accepted');
      
      setState(() {
        _connections = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Use mock data if roster fetch fails
      _connections = [
        {'id': '1', 'connected_user': {'id': 'user1', 'name': 'Emma Wilson', 'avatar_url': null}},
        {'id': '2', 'connected_user': {'id': 'user2', 'name': 'Sarah Chen', 'avatar_url': null}},
        {'id': '3', 'connected_user': {'id': 'user3', 'name': 'Mike Johnson', 'avatar_url': null}},
        {'id': '4', 'connected_user': {'id': 'user4', 'name': 'Alex Rivera', 'avatar_url': null}},
        {'id': '5', 'connected_user': {'id': 'user5', 'name': 'Jordan Lee', 'avatar_url': null}},
      ];
      setState(() {});
    }
  }

  List<Map<String, dynamic>> get _filteredConnections {
    if (_searchQuery.isEmpty) return _connections;
    
    return _connections.where((conn) {
      final name = (conn['connected_user']?['name'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _toggleParticipant(String participantId) {
    VesparaHaptics.lightTap();
    setState(() {
      if (_selectedParticipants.contains(participantId)) {
        _selectedParticipants.remove(participantId);
      } else {
        _selectedParticipants.add(participantId);
      }
    });
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_selectedParticipants.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Select at least one person'),
            backgroundColor: VesparaColors.tagsRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      VesparaHaptics.lightTap();
      setState(() => _currentStep = 1);
    }
  }

  void _previousStep() {
    VesparaHaptics.lightTap();
    setState(() => _currentStep = 0);
  }

  Future<void> _createGroup() async {
    final name = _groupNameController.text.trim();
    
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Enter a group name'),
          backgroundColor: VesparaColors.tagsRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    setState(() => _isCreating = true);
    VesparaHaptics.mediumTap();
    
    try {
      await ref.read(wireProvider.notifier).createGroup(
        name: name,
        description: _groupDescriptionController.text.trim().isNotEmpty 
            ? _groupDescriptionController.text.trim() 
            : null,
        participantIds: _selectedParticipants.toList(),
        avatarUrl: _groupAvatarPath,
      );
      
      if (mounted) {
        VesparaHaptics.success();
        Navigator.of(context).pop(true); // Return success
      }
    } catch (e) {
      VesparaHaptics.error();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create group: $e'),
            backgroundColor: VesparaColors.tagsRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  Future<void> _pickGroupAvatar() async {
    VesparaHaptics.lightTap();
    
    // Show options bottom sheet
    showModalBottomSheet(
      context: context,
      backgroundColor: VesparaColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: VesparaColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: VesparaColors.glow.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt, color: VesparaColors.glow),
              ),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                // In production: Use image_picker to capture camera photo
                _simulateImagePick();
              },
            ),
            ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: VesparaColors.glow.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.photo_library, color: VesparaColors.glow),
              ),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                // In production: Use image_picker to pick from gallery
                _simulateImagePick();
              },
            ),
            if (_groupAvatarPath != null)
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: VesparaColors.tagsRed.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_outline, color: VesparaColors.tagsRed),
                ),
                title: const Text('Remove Photo'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _groupAvatarPath = null);
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _simulateImagePick() {
    // Simulate successful image pick
    // In production, this would be the path from image_picker
    setState(() {
      _groupAvatarPath = 'https://picsum.photos/200';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VesparaColors.background,
      appBar: _buildAppBar(),
      body: _currentStep == 0 
          ? _buildParticipantSelection() 
          : _buildGroupInfo(),
      floatingActionButton: _buildFAB(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: VesparaColors.surface,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          _currentStep == 0 ? Icons.close : Icons.arrow_back,
          color: VesparaColors.primary,
        ),
        onPressed: _currentStep == 0 
            ? () => Navigator.pop(context) 
            : _previousStep,
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _currentStep == 0 ? 'New Group' : 'Group Info',
            style: const TextStyle(
              color: VesparaColors.primary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (_currentStep == 0 && _selectedParticipants.isNotEmpty)
            Text(
              '${_selectedParticipants.length} selected',
              style: TextStyle(
                color: VesparaColors.secondary,
                fontSize: 13,
              ),
            ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STEP 1: PARTICIPANT SELECTION
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildParticipantSelection() {
    return Column(
      children: [
        // Search bar
        Container(
          padding: const EdgeInsets.all(16),
          color: VesparaColors.surface,
          child: TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            style: const TextStyle(color: VesparaColors.primary),
            decoration: InputDecoration(
              hintText: 'Search connections...',
              hintStyle: TextStyle(color: VesparaColors.secondary),
              prefixIcon: Icon(Icons.search, color: VesparaColors.secondary),
              filled: true,
              fillColor: VesparaColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        
        // Selected participants chips
        if (_selectedParticipants.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: VesparaColors.surface,
            width: double.infinity,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedParticipants.map((participantId) {
                final connection = _connections.firstWhere(
                  (c) => c['connected_user']?['id'] == participantId,
                  orElse: () => {'connected_user': {'name': 'Unknown'}},
                );
                final name = connection['connected_user']?['name'] ?? 'Unknown';
                
                return Chip(
                  avatar: CircleAvatar(
                    backgroundColor: VesparaColors.glow,
                    child: Text(
                      name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: VesparaColors.background,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  label: Text(
                    name.split(' ').first,
                    style: const TextStyle(fontSize: 13),
                  ),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => _toggleParticipant(participantId),
                  backgroundColor: VesparaColors.background,
                  side: BorderSide(color: VesparaColors.border),
                );
              }).toList(),
            ),
          ),
        
        const Divider(height: 1, color: VesparaColors.border),
        
        // Connections list
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: VesparaColors.glow),
                )
              : _filteredConnections.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      itemCount: _filteredConnections.length,
                      itemBuilder: (context, index) {
                        final connection = _filteredConnections[index];
                        return _buildConnectionTile(connection);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildConnectionTile(Map<String, dynamic> connection) {
    final user = connection['connected_user'] as Map<String, dynamic>?;
    final userId = user?['id'] ?? '';
    final name = user?['name'] ?? 'Unknown';
    final avatarUrl = user?['avatar_url'];
    final isSelected = _selectedParticipants.contains(userId);
    
    return ListTile(
      onTap: () => _toggleParticipant(userId),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: VesparaColors.surface,
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null
                ? Text(
                    name.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: VesparaColors.glow,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : null,
          ),
          if (isSelected)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: VesparaColors.glow,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: VesparaColors.background,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.check,
                  color: VesparaColors.background,
                  size: 12,
                ),
              ),
            ),
        ],
      ),
      title: Text(
        name,
        style: TextStyle(
          color: VesparaColors.primary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: VesparaColors.glow)
          : Icon(Icons.circle_outlined, color: VesparaColors.secondary),
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
            _searchQuery.isNotEmpty
                ? 'No connections found'
                : 'No connections yet',
            style: TextStyle(
              color: VesparaColors.secondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start connecting to create groups',
            style: TextStyle(
              color: VesparaColors.secondary.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STEP 2: GROUP INFO
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildGroupInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group avatar
          Center(
            child: GestureDetector(
              onTap: _pickGroupAvatar,
              child: Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: VesparaColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: VesparaColors.glow.withOpacity(0.3),
                        width: 2,
                      ),
                      image: _groupAvatarPath != null
                          ? DecorationImage(
                              image: NetworkImage(_groupAvatarPath!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _groupAvatarPath == null
                        ? Icon(
                            Icons.camera_alt,
                            size: 40,
                            color: VesparaColors.secondary,
                          )
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: VesparaColors.glow,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: VesparaColors.background,
                          width: 3,
                        ),
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: VesparaColors.background,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Group name
          Text(
            'GROUP NAME',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: VesparaColors.secondary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _groupNameController,
            style: const TextStyle(color: VesparaColors.primary, fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Enter group name',
              hintStyle: TextStyle(color: VesparaColors.secondary),
              filled: true,
              fillColor: VesparaColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: VesparaColors.glow, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Group description
          Text(
            'DESCRIPTION (OPTIONAL)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: VesparaColors.secondary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _groupDescriptionController,
            style: const TextStyle(color: VesparaColors.primary, fontSize: 16),
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'What\'s this group about?',
              hintStyle: TextStyle(color: VesparaColors.secondary),
              filled: true,
              fillColor: VesparaColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: VesparaColors.glow, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Participants preview
          Text(
            'PARTICIPANTS (${_selectedParticipants.length})',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: VesparaColors.secondary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: VesparaColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _selectedParticipants.map((participantId) {
                final connection = _connections.firstWhere(
                  (c) => c['connected_user']?['id'] == participantId,
                  orElse: () => {'connected_user': {'name': 'Unknown', 'avatar_url': null}},
                );
                final user = connection['connected_user'] as Map<String, dynamic>?;
                final name = user?['name'] ?? 'Unknown';
                final avatarUrl = user?['avatar_url'];
                
                return Column(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: VesparaColors.background,
                      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                      child: avatarUrl == null
                          ? Text(
                              name.substring(0, 1).toUpperCase(),
                              style: TextStyle(
                                color: VesparaColors.glow,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 60,
                      child: Text(
                        name.split(' ').first,
                        style: TextStyle(
                          fontSize: 12,
                          color: VesparaColors.primary,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FAB
  // ══════════════════════════════════════════════════════════════════════════

  Widget? _buildFAB() {
    if (_currentStep == 0 && _selectedParticipants.isEmpty) {
      return null;
    }
    
    return FloatingActionButton.extended(
      onPressed: _isCreating 
          ? null 
          : (_currentStep == 0 ? _nextStep : _createGroup),
      backgroundColor: VesparaColors.glow,
      icon: _isCreating
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: VesparaColors.background,
              ),
            )
          : Icon(
              _currentStep == 0 ? Icons.arrow_forward : Icons.check,
              color: VesparaColors.background,
            ),
      label: Text(
        _currentStep == 0 
            ? 'Next' 
            : (_isCreating ? 'Creating...' : 'Create Group'),
        style: const TextStyle(
          color: VesparaColors.background,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
