import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';

/// Security Settings Screen - MFA management, session controls, data requests
class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool _isLoading = true;
  bool _mfaEnrolled = false;
  List<Map<String, dynamic>> _sessions = [];

  @override
  void initState() {
    super.initState();
    _loadSecurityInfo();
  }

  Future<void> _loadSecurityInfo() async {
    try {
      final supabase = Supabase.instance.client;

      // Check MFA status
      final factors = await supabase.auth.mfa.listFactors();
      _mfaEnrolled =
          factors.totp.any((f) => f.status == FactorStatus.verified);

      // Load active sessions
      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        final sessionsData = await supabase
            .from('user_sessions')
            .select()
            .eq('user_id', userId)
            .eq('is_active', true)
            .order('last_active_at', ascending: false);
        _sessions = List<Map<String, dynamic>>.from(sessionsData);
      }
    } catch (e) {
      debugPrint('Error loading security info: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _revokeSession(String sessionId) async {
    try {
      await Supabase.instance.client
          .from('user_sessions')
          .update({'is_active': false})
          .eq('id', sessionId);
      await _loadSecurityInfo();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to revoke session: $e')),
        );
      }
    }
  }

  Future<void> _requestDataExport() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      await Supabase.instance.client.from('data_requests').insert({
        'user_id': userId,
        'request_type': 'export',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data export requested. You will receive an email.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request failed: $e')),
        );
      }
    }
  }

  Future<void> _requestAccountDeletion() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: VesparaColors.surface,
        title: const Text('Delete Account',
            style: TextStyle(color: VesparaColors.error)),
        content: const Text(
          'This action is permanent. All your data, messages, and profile '
          'will be permanently deleted. This cannot be undone.',
          style: TextStyle(color: VesparaColors.secondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: VesparaColors.secondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: VesparaColors.error,
            ),
            child: const Text('Delete My Account'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      await Supabase.instance.client.from('data_requests').insert({
        'user_id': userId,
        'request_type': 'delete',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Account deletion requested. Processing within 30 days.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: VesparaColors.background,
        appBar: AppBar(
          backgroundColor: VesparaColors.background,
          foregroundColor: VesparaColors.primary,
          title: const Text('Security & Privacy'),
          elevation: 0,
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: VesparaColors.glow))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // MFA Status
                    _buildSection(
                      'Two-Factor Authentication',
                      Icons.shield_rounded,
                      [
                        _buildStatusRow(
                          'TOTP Authenticator',
                          _mfaEnrolled ? 'Active' : 'Not Set Up',
                          _mfaEnrolled,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Active Sessions
                    _buildSection(
                      'Active Sessions',
                      Icons.devices_rounded,
                      _sessions.isEmpty
                          ? [
                              const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text(
                                  'No active sessions tracked yet.',
                                  style: TextStyle(
                                      color: VesparaColors.secondary),
                                ),
                              ),
                            ]
                          : _sessions
                              .map(
                                (s) => _buildSessionRow(s),
                              )
                              .toList(),
                    ),

                    const SizedBox(height: 24),

                    // Data Controls
                    _buildSection(
                      'Your Data',
                      Icons.folder_rounded,
                      [
                        ListTile(
                          title: const Text('Export My Data',
                              style: TextStyle(color: VesparaColors.primary)),
                          subtitle: const Text(
                            'Download all your data as a file',
                            style:
                                TextStyle(color: VesparaColors.secondary),
                          ),
                          trailing: const Icon(Icons.download,
                              color: VesparaColors.glow),
                          onTap: _requestDataExport,
                        ),
                        const Divider(color: VesparaColors.surface),
                        ListTile(
                          title: const Text('Delete My Account',
                              style: TextStyle(color: VesparaColors.error)),
                          subtitle: const Text(
                            'Permanently remove all data',
                            style:
                                TextStyle(color: VesparaColors.secondary),
                          ),
                          trailing: const Icon(Icons.delete_forever,
                              color: VesparaColors.error),
                          onTap: _requestAccountDeletion,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      );

  Widget _buildSection(String title, IconData icon, List<Widget> children) =>
      Container(
        decoration: BoxDecoration(
          color: VesparaColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(icon, color: VesparaColors.glow, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: VesparaColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            ...children,
          ],
        ),
      );

  Widget _buildStatusRow(String label, String status, bool isActive) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: const TextStyle(color: VesparaColors.primary)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.green.withOpacity(0.15)
                    : Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: isActive ? Colors.green : Colors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildSessionRow(Map<String, dynamic> session) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.phone_android,
                color: VesparaColors.secondary, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session['device_info'] ?? 'Unknown device',
                    style: const TextStyle(
                        color: VesparaColors.primary, fontSize: 14),
                  ),
                  Text(
                    'Last active: ${session['last_active_at'] ?? 'unknown'}',
                    style: const TextStyle(
                        color: VesparaColors.secondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _revokeSession(session['id']),
              child: const Text('Revoke',
                  style: TextStyle(color: VesparaColors.error, fontSize: 12)),
            ),
          ],
        ),
      );
}
