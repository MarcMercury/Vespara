import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animated_background.dart';
import '../../admin/presentation/admin_portal_screen.dart';

/// Admin Panel — Approve / Reject / Suspend pending members
class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _pendingMembers = [];
  bool _isLoading = true;
  String? _error;
  String _filterStatus = 'pending';

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _supabase
          .from('profiles')
          .select('id, display_name, avatar_url, membership_status, created_at, invited_by')
          .eq('membership_status', _filterStatus)
          .order('created_at', ascending: false)
          .limit(100);

      setState(() {
        _pendingMembers = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _performAction(String memberId, String action) async {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) return;

      final response = await http.post(
        Uri.parse('${Env.supabaseUrl}/functions/v1/admin-approve-member'),
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
          'Content-Type': 'application/json',
          'apikey': Env.supabaseAnonKey,
        },
        body: jsonEncode({'member_id': memberId, 'action': action}),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Member ${action}d successfully'),
              backgroundColor: action == 'approve'
                  ? VesparaColors.success
                  : VesparaColors.error,
            ),
          );
        }
        _loadMembers(); // Refresh list
      } else {
        final body = jsonDecode(response.body);
        throw Exception(body['error'] ?? 'Unknown error');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: VesparaColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VesparaColors.background,
      body: VesparaAnimatedBackground(
        enableParticles: true,
        particleCount: 10,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildStatusFilter(),
              Expanded(child: _buildMembersList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() => Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: VesparaColors.primary),
            ),
            const SizedBox(width: 8),
            Text(
              'Admin Panel',
              style: GoogleFonts.cinzel(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: VesparaColors.primary,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminPortalScreen()),
              ),
              icon: const Icon(Icons.admin_panel_settings,
                  color: VesparaColors.glow),
              tooltip: 'Full Admin Portal',
            ),
            IconButton(
              onPressed: _loadMembers,
              icon: const Icon(Icons.refresh, color: VesparaColors.secondary),
            ),
          ],
        ),
      );

  Widget _buildStatusFilter() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: VesparaColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: ['pending', 'approved', 'suspended', 'rejected']
              .map((status) => Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _filterStatus = status);
                        _loadMembers();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _filterStatus == status
                              ? VesparaColors.glow.withOpacity(0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status[0].toUpperCase() + status.substring(1),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            color: _filterStatus == status
                                ? VesparaColors.primary
                                : VesparaColors.secondary,
                          ),
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
      );

  Widget _buildMembersList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: VesparaColors.glow),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: VesparaColors.error, size: 48),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: VesparaColors.error)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadMembers, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_pendingMembers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _filterStatus == 'pending' ? Icons.inbox : Icons.people,
              size: 64,
              color: VesparaColors.glow.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No $_filterStatus members',
              style: const TextStyle(
                fontSize: 18,
                color: VesparaColors.secondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingMembers.length,
      itemBuilder: (context, index) =>
          _buildMemberCard(_pendingMembers[index]),
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> member) {
    final name = member['display_name'] ?? 'Unknown';
    final status = member['membership_status'] ?? 'pending';
    final createdAt = member['created_at'] != null
        ? DateTime.tryParse(member['created_at'])
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VesparaColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: VesparaColors.glow.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: VesparaColors.glow.withOpacity(0.2),
            backgroundImage: member['avatar_url'] != null
                ? NetworkImage(member['avatar_url'])
                : null,
            child: member['avatar_url'] == null
                ? Text(
                    name[0].toUpperCase(),
                    style: const TextStyle(
                      color: VesparaColors.glow,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: VesparaColors.primary,
                  ),
                ),
                if (createdAt != null)
                  Text(
                    'Joined ${_timeAgo(createdAt)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: VesparaColors.secondary,
                    ),
                  ),
              ],
            ),
          ),

          // Action buttons
          if (status == 'pending') ...[
            IconButton(
              onPressed: () => _performAction(member['id'], 'reject'),
              icon: const Icon(Icons.close, color: VesparaColors.error),
              tooltip: 'Reject',
            ),
            IconButton(
              onPressed: () => _performAction(member['id'], 'approve'),
              icon: const Icon(Icons.check, color: VesparaColors.success),
              tooltip: 'Approve',
            ),
          ] else if (status == 'approved') ...[
            IconButton(
              onPressed: () => _performAction(member['id'], 'suspend'),
              icon: const Icon(Icons.block, color: VesparaColors.tagsYellow),
              tooltip: 'Suspend',
            ),
          ] else if (status == 'suspended' || status == 'rejected') ...[
            IconButton(
              onPressed: () => _performAction(member['id'], 'approve'),
              icon: const Icon(Icons.check_circle_outline,
                  color: VesparaColors.success),
              tooltip: 'Re-approve',
            ),
          ],
        ],
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }
}
