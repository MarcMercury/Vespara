import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Admin Service — calls admin-manage-user edge function
class AdminService {
  static final _supabase = Supabase.instance.client;

  static Future<Map<String, dynamic>> _call(Map<String, dynamic> body) async {
    final response = await _supabase.functions.invoke(
      'admin-manage-user',
      body: body,
    );

    final data = response.data is Map
        ? response.data as Map<String, dynamic>
        : jsonDecode(response.data.toString()) as Map<String, dynamic>;
    if (response.status != 200) {
      throw Exception(data['error'] ?? 'Request failed');
    }
    return data;
  }

  /// List users with optional filters
  static Future<List<AdminUser>> listUsers({
    String? search,
    String? status,
    bool? disabled,
    int limit = 50,
    int offset = 0,
  }) async {
    final data = await _call({
      'action': 'list_users',
      'user_id': '_', // required by edge fn, ignored for list
      'search': search,
      'status': status,
      'disabled': disabled,
      'limit': limit,
      'offset': offset,
    });

    final users = (data['users'] as List?) ?? [];
    return users.map((u) => AdminUser.fromJson(u)).toList();
  }

  /// Get detailed user info (profile, tokens, audit log, sessions)
  static Future<AdminUserDetail> getUserDetail(String userId) async {
    final data = await _call({
      'action': 'get_user_detail',
      'user_id': userId,
    });
    return AdminUserDetail.fromJson(data);
  }

  /// Disable a user account
  static Future<void> disableUser(String userId) async {
    await _call({'action': 'disable_user', 'user_id': userId});
  }

  /// Re-enable a user account
  static Future<void> enableUser(String userId) async {
    await _call({'action': 'enable_user', 'user_id': userId});
  }

  /// Send password reset email to user
  static Future<String> resetPassword(String userId) async {
    final data = await _call({'action': 'reset_password', 'user_id': userId});
    return data['email'] as String? ?? '';
  }

  /// Track a login event for the current user
  static Future<void> trackLogin() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase.rpc('track_user_login', params: {'uid': user.id});
  }
}

// ═══════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════

class AdminUser {
  final String id;
  final String? email;
  final String? displayName;
  final String? avatarUrl;
  final String membershipStatus;
  final bool isDisabled;
  final bool isAdmin;
  final DateTime? lastLoginAt;
  final int loginCount;
  final DateTime? createdAt;
  final bool mfaEnrolled;
  final int totalTokens;
  final double totalCost;

  AdminUser({
    required this.id,
    this.email,
    this.displayName,
    this.avatarUrl,
    required this.membershipStatus,
    required this.isDisabled,
    required this.isAdmin,
    this.lastLoginAt,
    required this.loginCount,
    this.createdAt,
    required this.mfaEnrolled,
    required this.totalTokens,
    required this.totalCost,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(
        id: json['id'] ?? '',
        email: json['email'],
        displayName: json['display_name'],
        avatarUrl: json['avatar_url'],
        membershipStatus: json['membership_status'] ?? 'pending',
        isDisabled: json['is_disabled'] ?? false,
        isAdmin: json['is_admin'] ?? false,
        lastLoginAt: json['last_login_at'] != null
            ? DateTime.tryParse(json['last_login_at'])
            : null,
        loginCount: json['login_count'] ?? 0,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'])
            : null,
        mfaEnrolled: json['mfa_enrolled'] ?? false,
        totalTokens: (json['total_tokens'] ?? 0) is int
            ? json['total_tokens'] ?? 0
            : int.tryParse(json['total_tokens'].toString()) ?? 0,
        totalCost: (json['total_cost'] ?? 0).toDouble(),
      );
}

class TokenUsageEntry {
  final String service;
  final int tokensTotal;
  final double costCents;
  final String operation;
  final DateTime? createdAt;

  TokenUsageEntry({
    required this.service,
    required this.tokensTotal,
    required this.costCents,
    required this.operation,
    this.createdAt,
  });

  factory TokenUsageEntry.fromJson(Map<String, dynamic> json) =>
      TokenUsageEntry(
        service: json['service'] ?? '',
        tokensTotal: json['tokens_total'] ?? 0,
        costCents: (json['cost_cents'] ?? 0).toDouble(),
        operation: json['operation'] ?? '',
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'])
            : null,
      );
}

class TokenSummary {
  final String service;
  final int totalTokens;
  final double totalCost;
  final int requestCount;
  final DateTime? lastUsed;

  TokenSummary({
    required this.service,
    required this.totalTokens,
    required this.totalCost,
    required this.requestCount,
    this.lastUsed,
  });

  factory TokenSummary.fromJson(Map<String, dynamic> json) => TokenSummary(
        service: json['service'] ?? '',
        totalTokens: json['total_tokens'] ?? 0,
        totalCost: (json['total_cost'] ?? 0).toDouble(),
        requestCount: json['request_count'] ?? 0,
        lastUsed: json['last_used'] != null
            ? DateTime.tryParse(json['last_used'])
            : null,
      );
}

class AuditEntry {
  final String action;
  final String resourceType;
  final String? resourceId;
  final Map<String, dynamic> metadata;
  final DateTime? createdAt;

  AuditEntry({
    required this.action,
    required this.resourceType,
    this.resourceId,
    required this.metadata,
    this.createdAt,
  });

  factory AuditEntry.fromJson(Map<String, dynamic> json) => AuditEntry(
        action: json['action'] ?? '',
        resourceType: json['resource_type'] ?? '',
        resourceId: json['resource_id'],
        metadata: json['metadata'] ?? {},
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'])
            : null,
      );
}

class AdminUserDetail {
  final Map<String, dynamic> user;
  final List<TokenUsageEntry> tokenUsage;
  final List<TokenSummary> tokenSummary;
  final List<AuditEntry> auditLog;
  final List<Map<String, dynamic>> sessions;

  AdminUserDetail({
    required this.user,
    required this.tokenUsage,
    required this.tokenSummary,
    required this.auditLog,
    required this.sessions,
  });

  factory AdminUserDetail.fromJson(Map<String, dynamic> json) =>
      AdminUserDetail(
        user: json['user'] ?? {},
        tokenUsage: ((json['token_usage'] as List?) ?? [])
            .map((e) => TokenUsageEntry.fromJson(e))
            .toList(),
        tokenSummary: ((json['token_summary'] as List?) ?? [])
            .map((e) => TokenSummary.fromJson(e))
            .toList(),
        auditLog: ((json['audit_log'] as List?) ?? [])
            .map((e) => AuditEntry.fromJson(e))
            .toList(),
        sessions: ((json['sessions'] as List?) ?? [])
            .map((e) => Map<String, dynamic>.from(e))
            .toList(),
      );

  String get displayName => user['display_name'] ?? 'Unknown';
  String? get email => user['auth_email'] ?? user['email'];
  String? get avatarUrl => user['avatar_url'];
  String get membershipStatus => user['membership_status'] ?? 'pending';
  bool get isDisabled => user['is_disabled'] ?? false;
  bool get isAdmin => user['is_admin'] ?? false;
  bool get mfaEnrolled => user['mfa_enrolled'] ?? false;
  bool get isBanned => user['is_banned'] ?? false;
  DateTime? get lastLoginAt => user['last_login_at'] != null
      ? DateTime.tryParse(user['last_login_at'])
      : null;
  DateTime? get authLastSignIn => user['auth_last_sign_in'] != null
      ? DateTime.tryParse(user['auth_last_sign_in'])
      : null;
  DateTime? get createdAt => user['created_at'] != null
      ? DateTime.tryParse(user['created_at'])
      : null;
  int get loginCount => user['login_count'] ?? 0;
}
