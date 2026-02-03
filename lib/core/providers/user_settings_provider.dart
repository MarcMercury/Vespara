import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/models/user_settings.dart';
import 'app_providers.dart';

/// Global Supabase client accessor
SupabaseClient get _supabase => Supabase.instance.client;

/// User settings provider - fetches and manages user settings from Supabase
final userSettingsProvider =
    AsyncNotifierProvider<UserSettingsNotifier, UserSettings?>(() {
  return UserSettingsNotifier();
});

class UserSettingsNotifier extends AsyncNotifier<UserSettings?> {
  @override
  Future<UserSettings?> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return null;

    try {
      // Try to fetch existing settings
      final response = await _supabase
          .from('user_settings')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (response != null) {
        return UserSettings.fromJson(response);
      }

      // Create default settings if none exist
      final defaults = UserSettings.defaults(user.id);
      final insertResponse = await _supabase
          .from('user_settings')
          .insert({
            'user_id': user.id,
          })
          .select()
          .single();

      return UserSettings.fromJson(insertResponse);
    } catch (e) {
      debugPrint('[userSettingsProvider] Error: $e');
      return null;
    }
  }

  /// Update a single setting
  Future<void> updateSetting(String key, dynamic value) async {
    final currentSettings = state.valueOrNull;
    if (currentSettings == null) return;

    state = const AsyncValue.loading();

    try {
      await _supabase.from('user_settings').update({
        key: value,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('user_id', currentSettings.userId);

      // Refresh the settings
      ref.invalidateSelf();
    } catch (e) {
      debugPrint('[userSettingsProvider] Update error: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Update multiple settings at once
  Future<void> updateSettings(Map<String, dynamic> updates) async {
    final currentSettings = state.valueOrNull;
    if (currentSettings == null) return;

    state = const AsyncValue.loading();

    try {
      updates['updated_at'] = DateTime.now().toIso8601String();
      await _supabase
          .from('user_settings')
          .update(updates)
          .eq('user_id', currentSettings.userId);

      // Refresh the settings
      ref.invalidateSelf();
    } catch (e) {
      debugPrint('[userSettingsProvider] Update error: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Toggle a boolean setting
  Future<void> toggleSetting(String key) async {
    final currentSettings = state.valueOrNull;
    if (currentSettings == null) return;

    // Get current value based on key
    bool currentValue = false;
    switch (key) {
      case 'notify_new_messages':
        currentValue = currentSettings.notifyNewMessages;
        break;
      case 'notify_new_matches':
        currentValue = currentSettings.notifyNewMatches;
        break;
      case 'notify_date_reminders':
        currentValue = currentSettings.notifyDateReminders;
        break;
      case 'notify_ai_insights':
        currentValue = currentSettings.notifyAiInsights;
        break;
      case 'show_online_status':
        currentValue = currentSettings.showOnlineStatus;
        break;
      case 'read_receipts':
        currentValue = currentSettings.readReceipts;
        break;
      case 'profile_visible':
        currentValue = currentSettings.profileVisible;
        break;
    }

    await updateSetting(key, !currentValue);
  }

  /// Pause/unpause account
  Future<void> togglePause({String? reason}) async {
    final currentSettings = state.valueOrNull;
    if (currentSettings == null) return;

    final newPauseState = !currentSettings.isPaused;

    await updateSettings({
      'is_paused': newPauseState,
      'paused_at': newPauseState ? DateTime.now().toIso8601String() : null,
      'pause_reason': newPauseState ? reason : null,
      'profile_visible': !newPauseState, // Hide profile when paused
    });
  }

  /// Update discovery preferences
  Future<void> updateDiscovery({
    int? minAge,
    int? maxAge,
    int? maxDistance,
    String? showMe,
    List<String>? relationshipTypes,
  }) async {
    final updates = <String, dynamic>{};
    if (minAge != null) updates['min_age'] = minAge;
    if (maxAge != null) updates['max_age'] = maxAge;
    if (maxDistance != null) updates['max_distance'] = maxDistance;
    if (showMe != null) updates['show_me'] = showMe;
    if (relationshipTypes != null) {
      updates['relationship_types'] = relationshipTypes;
    }

    if (updates.isNotEmpty) {
      await updateSettings(updates);
    }
  }

  /// Connect/disconnect calendar
  Future<void> toggleCalendar(String provider, {String? token}) async {
    if (provider == 'Google') {
      final currentSettings = state.valueOrNull;
      final newState = !(currentSettings?.googleCalendarConnected ?? false);
      await updateSettings({
        'google_calendar_connected': newState,
        'google_calendar_token': newState ? token : null,
      });
    } else if (provider == 'Apple') {
      final currentSettings = state.valueOrNull;
      final newState = !(currentSettings?.appleCalendarConnected ?? false);
      await updateSetting('apple_calendar_connected', newState);
    }
  }

  /// Update phone number
  Future<void> updatePhone(String phone) async {
    await updateSetting('phone', phone);
  }

  /// Update email (requires Supabase auth email change)
  Future<void> updateEmail(String email) async {
    final supabase = Supabase.instance.client;
    await supabase.auth.updateUser(UserAttributes(email: email));
    // This will trigger a verification email from Supabase
  }
}
