import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/services/admin_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animated_background.dart';
import 'admin_user_detail_screen.dart';

/// Admin Portal — Full user management dashboard
class AdminPortalScreen extends StatefulWidget {
  const AdminPortalScreen({super.key});

  @override
  State<AdminPortalScreen> createState() => _AdminPortalScreenState();
}

class _AdminPortalScreenState extends State<AdminPortalScreen> {
  List<AdminUser> _users = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String? _statusFilter;
  bool? _disabledFilter;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  bool _loadingMore = false;
  int _offset = 0;
  static const _pageSize = 50;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_loadingMore) {
      _loadMoreUsers();
    }
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _offset = 0;
    });

    try {
      final users = await AdminService.listUsers(
        search: _searchQuery.isEmpty ? null : _searchQuery,
        status: _statusFilter,
        disabled: _disabledFilter,
        limit: _pageSize,
        offset: 0,
      );
      setState(() {
        _users = users;
        _isLoading = false;
        _offset = users.length;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadMoreUsers() async {
    if (_loadingMore) return;
    setState(() => _loadingMore = true);

    try {
      final more = await AdminService.listUsers(
        search: _searchQuery.isEmpty ? null : _searchQuery,
        status: _statusFilter,
        disabled: _disabledFilter,
        limit: _pageSize,
        offset: _offset,
      );
      setState(() {
        _users.addAll(more);
        _offset += more.length;
        _loadingMore = false;
      });
    } catch (_) {
      setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VesparaColors.background,
      body: VesparaAnimatedBackground(
        enableParticles: true,
        particleCount: 8,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchBar(),
              _buildFilters(),
              _buildStats(),
              Expanded(child: _buildUserList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: VesparaColors.primary),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Portal',
                  style: GoogleFonts.cinzel(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: VesparaColors.primary,
                  ),
                ),
                Text(
                  'User Management',
                  style: TextStyle(
                    fontSize: 12,
                    color: VesparaColors.secondary.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            const Spacer(),
            IconButton(
              onPressed: _loadUsers,
              icon: const Icon(Icons.refresh, color: VesparaColors.secondary),
            ),
          ],
        ),
      );

  Widget _buildSearchBar() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: TextField(
          controller: _searchController,
          onSubmitted: (val) {
            _searchQuery = val.trim();
            _loadUsers();
          },
          style: const TextStyle(color: VesparaColors.primary),
          decoration: InputDecoration(
            hintText: 'Search by name or email...',
            hintStyle: TextStyle(
              color: VesparaColors.secondary.withOpacity(0.5),
            ),
            prefixIcon:
                const Icon(Icons.search, color: VesparaColors.secondary),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchController.clear();
                      _searchQuery = '';
                      _loadUsers();
                    },
                    icon: const Icon(Icons.clear,
                        color: VesparaColors.secondary, size: 18),
                  )
                : null,
            filled: true,
            fillColor: VesparaColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      );

  Widget _buildFilters() => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _filterChip('All', _statusFilter == null && _disabledFilter == null,
                () {
              _statusFilter = null;
              _disabledFilter = null;
              _loadUsers();
            }),
            const SizedBox(width: 8),
            _filterChip('Pending', _statusFilter == 'pending', () {
              _statusFilter = 'pending';
              _disabledFilter = null;
              _loadUsers();
            }),
            const SizedBox(width: 8),
            _filterChip('Approved', _statusFilter == 'approved', () {
              _statusFilter = 'approved';
              _disabledFilter = null;
              _loadUsers();
            }),
            const SizedBox(width: 8),
            _filterChip('Suspended', _statusFilter == 'suspended', () {
              _statusFilter = 'suspended';
              _disabledFilter = null;
              _loadUsers();
            }),
            const SizedBox(width: 8),
            _filterChip('Disabled', _disabledFilter == true, () {
              _statusFilter = null;
              _disabledFilter = true;
              _loadUsers();
            }),
          ],
        ),
      );

  Widget _filterChip(String label, bool selected, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? VesparaColors.glow.withOpacity(0.2)
                : VesparaColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  selected ? VesparaColors.glow : VesparaColors.surface,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color:
                  selected ? VesparaColors.primary : VesparaColors.secondary,
            ),
          ),
        ),
      );

  Widget _buildStats() {
    if (_isLoading || _users.isEmpty) return const SizedBox.shrink();

    final total = _users.length;
    final disabled = _users.where((u) => u.isDisabled).length;
    final pending =
        _users.where((u) => u.membershipStatus == 'pending').length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          _statBadge('$total', 'Loaded', VesparaColors.glow),
          const SizedBox(width: 12),
          _statBadge('$pending', 'Pending', VesparaColors.tagsYellow),
          const SizedBox(width: 12),
          _statBadge('$disabled', 'Disabled', VesparaColors.error),
        ],
      ),
    );
  }

  Widget _statBadge(String value, String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );

  Widget _buildUserList() {
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
            const Icon(Icons.error_outline,
                color: VesparaColors.error, size: 48),
            const SizedBox(height: 16),
            Text(_error!,
                style: const TextStyle(color: VesparaColors.error),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadUsers, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_users.isEmpty) {
      return const Center(
        child: Text('No users found',
            style: TextStyle(color: VesparaColors.secondary, fontSize: 16)),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _users.length + (_loadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _users.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(color: VesparaColors.glow),
            ),
          );
        }
        return _buildUserCard(_users[index]);
      },
    );
  }

  Widget _buildUserCard(AdminUser user) {
    final name = user.displayName ?? 'Unknown';
    final createdAt = user.createdAt;
    final lastLogin = user.lastLoginAt;

    Color statusColor;
    switch (user.membershipStatus) {
      case 'approved':
        statusColor = VesparaColors.success;
        break;
      case 'pending':
        statusColor = VesparaColors.tagsYellow;
        break;
      case 'suspended':
        statusColor = VesparaColors.error;
        break;
      default:
        statusColor = VesparaColors.secondary;
    }

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminUserDetailScreen(userId: user.id),
          ),
        );
        _loadUsers(); // Refresh after returning
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: VesparaColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: user.isDisabled
                ? VesparaColors.error.withOpacity(0.3)
                : VesparaColors.glow.withOpacity(0.08),
          ),
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 22,
              backgroundColor: VesparaColors.glow.withOpacity(0.2),
              backgroundImage: user.avatarUrl != null
                  ? NetworkImage(user.avatarUrl!)
                  : null,
              child: user.avatarUrl == null
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
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: user.isDisabled
                                ? VesparaColors.secondary
                                : VesparaColors.primary,
                            decoration: user.isDisabled
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (user.isAdmin) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: VesparaColors.glow.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'ADMIN',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: VesparaColors.glow,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email ?? 'No email',
                    style: TextStyle(
                      fontSize: 12,
                      color: VesparaColors.secondary.withOpacity(0.7),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          user.membershipStatus.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      if (user.isDisabled) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: VesparaColors.error.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'DISABLED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: VesparaColors.error,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      // Last login
                      Icon(Icons.access_time,
                          size: 12,
                          color: VesparaColors.secondary.withOpacity(0.5)),
                      const SizedBox(width: 4),
                      Text(
                        lastLogin != null
                            ? _timeAgo(lastLogin)
                            : 'Never',
                        style: TextStyle(
                          fontSize: 11,
                          color: VesparaColors.secondary.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Token usage indicator
            Column(
              children: [
                Icon(Icons.token,
                    size: 16,
                    color: user.totalTokens > 0
                        ? VesparaColors.glow
                        : VesparaColors.secondary.withOpacity(0.3)),
                const SizedBox(height: 2),
                Text(
                  _formatTokens(user.totalTokens),
                  style: TextStyle(
                    fontSize: 10,
                    color: user.totalTokens > 0
                        ? VesparaColors.glow
                        : VesparaColors.secondary.withOpacity(0.3),
                  ),
                ),
              ],
            ),

            const SizedBox(width: 4),
            const Icon(Icons.chevron_right,
                color: VesparaColors.secondary, size: 20),
          ],
        ),
      ),
    );
  }

  String _formatTokens(int tokens) {
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
