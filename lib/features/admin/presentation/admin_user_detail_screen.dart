import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/services/admin_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animated_background.dart';

/// Admin User Detail — view profile, actions, token usage, audit log
class AdminUserDetailScreen extends StatefulWidget {
  final String userId;

  const AdminUserDetailScreen({super.key, required this.userId});

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen>
    with SingleTickerProviderStateMixin {
  AdminUserDetail? _detail;
  bool _isLoading = true;
  String? _error;
  bool _actionLoading = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDetail();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final detail = await AdminService.getUserDetail(widget.userId);
      setState(() {
        _detail = detail;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _disableUser() async {
    final confirm = await _showConfirmDialog(
      'Disable User',
      'This will suspend the account and prevent sign-in. Continue?',
    );
    if (!confirm) return;

    setState(() => _actionLoading = true);
    try {
      await AdminService.disableUser(widget.userId);
      _showSnack('User disabled', VesparaColors.error);
      _loadDetail();
    } catch (e) {
      _showSnack('Error: $e', VesparaColors.error);
    }
    setState(() => _actionLoading = false);
  }

  Future<void> _enableUser() async {
    final confirm = await _showConfirmDialog(
      'Enable User',
      'This will re-activate the account and allow sign-in. Continue?',
    );
    if (!confirm) return;

    setState(() => _actionLoading = true);
    try {
      await AdminService.enableUser(widget.userId);
      _showSnack('User enabled', VesparaColors.success);
      _loadDetail();
    } catch (e) {
      _showSnack('Error: $e', VesparaColors.error);
    }
    setState(() => _actionLoading = false);
  }

  Future<void> _resetPassword() async {
    final confirm = await _showConfirmDialog(
      'Reset Password',
      'This will email a password reset link to the user. Continue?',
    );
    if (!confirm) return;

    setState(() => _actionLoading = true);
    try {
      final email = await AdminService.resetPassword(widget.userId);
      _showSnack('Reset link sent to $email', VesparaColors.success);
    } catch (e) {
      _showSnack('Error: $e', VesparaColors.error);
    }
    setState(() => _actionLoading = false);
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: VesparaColors.surfaceElevated,
            title: Text(title,
                style: const TextStyle(color: VesparaColors.primary)),
            content: Text(message,
                style: const TextStyle(color: VesparaColors.secondary)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel',
                    style: TextStyle(color: VesparaColors.secondary)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: VesparaColors.glow.withOpacity(0.2),
                ),
                child: const Text('Confirm',
                    style: TextStyle(color: VesparaColors.primary)),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VesparaColors.background,
      body: VesparaAnimatedBackground(
        enableParticles: true,
        particleCount: 6,
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child:
                      CircularProgressIndicator(color: VesparaColors.glow))
              : _error != null
                  ? _buildError()
                  : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildError() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                color: VesparaColors.error, size: 48),
            const SizedBox(height: 16),
            Text(_error!,
                style: const TextStyle(color: VesparaColors.error),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: _loadDetail, child: const Text('Retry')),
          ],
        ),
      );

  Widget _buildContent() {
    final d = _detail!;

    return Column(
      children: [
        // Header with back button
        _buildHeader(d),
        // Profile card
        _buildProfileCard(d),
        // Action buttons
        _buildActions(d),
        // Tabs: Token Usage | Audit Log | Sessions
        _buildTabBar(),
        Expanded(child: _buildTabContent(d)),
      ],
    );
  }

  Widget _buildHeader(AdminUserDetail d) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: VesparaColors.primary),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                d.displayName,
                style: GoogleFonts.cinzel(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: VesparaColors.primary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              onPressed: _loadDetail,
              icon:
                  const Icon(Icons.refresh, color: VesparaColors.secondary),
            ),
          ],
        ),
      );

  Widget _buildProfileCard(AdminUserDetail d) {
    final dateFormat = DateFormat('MMM d, yyyy HH:mm');

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VesparaColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: d.isDisabled
              ? VesparaColors.error.withOpacity(0.3)
              : VesparaColors.glow.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: VesparaColors.glow.withOpacity(0.2),
                backgroundImage: d.avatarUrl != null
                    ? NetworkImage(d.avatarUrl!)
                    : null,
                child: d.avatarUrl == null
                    ? Text(
                        d.displayName[0].toUpperCase(),
                        style: const TextStyle(
                          color: VesparaColors.glow,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _statusBadge(d.membershipStatus),
                        if (d.isDisabled) ...[
                          const SizedBox(width: 6),
                          _statusBadge('disabled'),
                        ],
                        if (d.isAdmin) ...[
                          const SizedBox(width: 6),
                          _adminBadge(),
                        ],
                        if (d.mfaEnrolled) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.verified_user,
                              size: 16, color: VesparaColors.success),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () {
                        if (d.email != null) {
                          Clipboard.setData(ClipboardData(text: d.email!));
                          _showSnack(
                              'Email copied', VesparaColors.glow);
                        }
                      },
                      child: Text(
                        d.email ?? 'No email',
                        style: const TextStyle(
                          fontSize: 13,
                          color: VesparaColors.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Info grid
          Row(
            children: [
              _infoTile(
                Icons.login,
                'Last Login',
                d.lastLoginAt != null || d.authLastSignIn != null
                    ? dateFormat
                        .format(d.lastLoginAt ?? d.authLastSignIn!)
                    : 'Never',
              ),
              _infoTile(
                Icons.repeat,
                'Logins',
                d.loginCount.toString(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _infoTile(
                Icons.calendar_today,
                'Joined',
                d.createdAt != null
                    ? dateFormat.format(d.createdAt!)
                    : 'Unknown',
              ),
              _infoTile(
                Icons.fingerprint,
                'User ID',
                widget.userId.substring(0, 8),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) => Expanded(
        child: Row(
          children: [
            Icon(icon, size: 14, color: VesparaColors.secondary.withOpacity(0.5)),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 10,
                          color: VesparaColors.secondary.withOpacity(0.6))),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 12,
                          color: VesparaColors.primary,
                          fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _statusBadge(String status) {
    Color color;
    switch (status) {
      case 'approved':
        color = VesparaColors.success;
        break;
      case 'pending':
        color = VesparaColors.tagsYellow;
        break;
      case 'suspended':
      case 'disabled':
        color = VesparaColors.error;
        break;
      default:
        color = VesparaColors.secondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _adminBadge() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: VesparaColors.glow.withOpacity(0.2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'ADMIN',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: VesparaColors.glow,
            letterSpacing: 0.3,
          ),
        ),
      );

  Widget _buildActions(AdminUserDetail d) {
    if (_actionLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
                color: VesparaColors.glow, strokeWidth: 2),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          // Disable / Enable
          if (d.isDisabled)
            _actionButton(
              icon: Icons.check_circle_outline,
              label: 'Enable',
              color: VesparaColors.success,
              onTap: _enableUser,
            )
          else
            _actionButton(
              icon: Icons.block,
              label: 'Disable',
              color: VesparaColors.error,
              onTap: _disableUser,
            ),
          const SizedBox(width: 10),
          // Reset Password
          _actionButton(
            icon: Icons.lock_reset,
            label: 'Reset PW',
            color: VesparaColors.tagsYellow,
            onTap: _resetPassword,
          ),
          const SizedBox(width: 10),
          // Copy ID
          _actionButton(
            icon: Icons.copy,
            label: 'Copy ID',
            color: VesparaColors.secondary,
            onTap: () {
              Clipboard.setData(ClipboardData(text: widget.userId));
              _showSnack('User ID copied', VesparaColors.glow);
            },
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) =>
      Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(height: 4),
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
        ),
      );

  Widget _buildTabBar() => Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        decoration: BoxDecoration(
          color: VesparaColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: VesparaColors.glow.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: VesparaColors.primary,
          unselectedLabelColor: VesparaColors.secondary,
          labelStyle:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: 'Token Usage'),
            Tab(text: 'Audit Log'),
            Tab(text: 'Sessions'),
          ],
        ),
      );

  Widget _buildTabContent(AdminUserDetail d) => TabBarView(
        controller: _tabController,
        children: [
          _buildTokenUsageTab(d),
          _buildAuditLogTab(d),
          _buildSessionsTab(d),
        ],
      );

  // ═══════════════════════════════════════════════════════════════
  // TOKEN USAGE TAB
  // ═══════════════════════════════════════════════════════════════

  Widget _buildTokenUsageTab(AdminUserDetail d) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary cards
        if (d.tokenSummary.isNotEmpty) ...[
          Text('Summary by Service',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: VesparaColors.secondary.withOpacity(0.7))),
          const SizedBox(height: 8),
          ...d.tokenSummary.map(_buildTokenSummaryCard),
          const SizedBox(height: 16),
        ],

        Text('Recent Activity',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: VesparaColors.secondary.withOpacity(0.7))),
        const SizedBox(height: 8),

        if (d.tokenUsage.isEmpty)
          _emptyState('No token usage recorded')
        else
          ...d.tokenUsage.map(_buildTokenUsageRow),
      ],
    );
  }

  Widget _buildTokenSummaryCard(TokenSummary s) {
    IconData icon;
    Color color;
    switch (s.service) {
      case 'openai':
        icon = Icons.auto_awesome;
        color = VesparaColors.success;
        break;
      case 'gemini':
        icon = Icons.diamond;
        color = VesparaColors.tagsPurple;
        break;
      case 'stream_chat':
        icon = Icons.chat;
        color = VesparaColors.tagsBlue;
        break;
      case 'cloudinary':
        icon = Icons.cloud;
        color = VesparaColors.tagsYellow;
        break;
      default:
        icon = Icons.circle;
        color = VesparaColors.secondary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: VesparaColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.service.toUpperCase(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  '${s.requestCount} requests',
                  style: TextStyle(
                    fontSize: 11,
                    color: VesparaColors.secondary.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatTokenCount(s.totalTokens),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: VesparaColors.primary,
                ),
              ),
              Text(
                '\$${(s.totalCost / 100).toStringAsFixed(4)}',
                style: TextStyle(
                  fontSize: 11,
                  color: VesparaColors.secondary.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTokenUsageRow(TokenUsageEntry e) {
    final dateStr = e.createdAt != null
        ? DateFormat('MMM d HH:mm').format(e.createdAt!)
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: VesparaColors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.operation,
                  style: const TextStyle(
                    fontSize: 13,
                    color: VesparaColors.primary,
                  ),
                ),
                Text(
                  '${e.service} · $dateStr',
                  style: TextStyle(
                    fontSize: 11,
                    color: VesparaColors.secondary.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${e.tokensTotal}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: VesparaColors.glow,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // AUDIT LOG TAB
  // ═══════════════════════════════════════════════════════════════

  Widget _buildAuditLogTab(AdminUserDetail d) {
    if (d.auditLog.isEmpty) {
      return _emptyState('No audit log entries');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: d.auditLog.length,
      itemBuilder: (ctx, i) => _buildAuditRow(d.auditLog[i]),
    );
  }

  Widget _buildAuditRow(AuditEntry e) {
    final dateStr = e.createdAt != null
        ? DateFormat('MMM d, yyyy HH:mm').format(e.createdAt!)
        : '';

    IconData icon;
    Color color;
    if (e.action.contains('disable')) {
      icon = Icons.block;
      color = VesparaColors.error;
    } else if (e.action.contains('enable') || e.action.contains('approve')) {
      icon = Icons.check_circle;
      color = VesparaColors.success;
    } else if (e.action.contains('reset')) {
      icon = Icons.lock_reset;
      color = VesparaColors.tagsYellow;
    } else if (e.action.contains('suspend') || e.action.contains('reject')) {
      icon = Icons.pause_circle;
      color = VesparaColors.error;
    } else {
      icon = Icons.info_outline;
      color = VesparaColors.secondary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: VesparaColors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.action,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: VesparaColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 11,
                    color: VesparaColors.secondary.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SESSIONS TAB
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSessionsTab(AdminUserDetail d) {
    if (d.sessions.isEmpty) {
      return _emptyState('No active sessions');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: d.sessions.length,
      itemBuilder: (ctx, i) {
        final s = d.sessions[i];
        final lastActive = s['last_active_at'] != null
            ? DateTime.tryParse(s['last_active_at'])
            : null;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: VesparaColors.surface.withOpacity(0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.devices,
                  size: 18, color: VesparaColors.secondary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s['device_info'] ?? 'Unknown device',
                      style: const TextStyle(
                        fontSize: 13,
                        color: VesparaColors.primary,
                      ),
                    ),
                    if (s['ip_address'] != null)
                      Text(
                        s['ip_address'],
                        style: TextStyle(
                          fontSize: 11,
                          color: VesparaColors.secondary.withOpacity(0.5),
                        ),
                      ),
                  ],
                ),
              ),
              if (lastActive != null)
                Text(
                  _timeAgo(lastActive),
                  style: TextStyle(
                    fontSize: 11,
                    color: VesparaColors.secondary.withOpacity(0.6),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _emptyState(String text) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox,
                  size: 48, color: VesparaColors.glow.withOpacity(0.2)),
              const SizedBox(height: 12),
              Text(text,
                  style: const TextStyle(
                      color: VesparaColors.secondary, fontSize: 14)),
            ],
          ),
        ),
      );

  String _formatTokenCount(int tokens) {
    if (tokens >= 1000000) return '${(tokens / 1000000).toStringAsFixed(1)}M';
    if (tokens >= 1000) return '${(tokens / 1000).toStringAsFixed(1)}K';
    return tokens.toString();
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}y ago';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
