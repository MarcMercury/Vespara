import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/domain/models/user_settings.dart';
import '../../../core/providers/user_settings_provider.dart';
import '../../../core/theme/app_theme.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// NOTIFICATION SETTINGS SCREEN
/// Comprehensive notification preferences for all app features.
/// ════════════════════════════════════════════════════════════════════════════

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  TimeOfDay? _quietStart;
  TimeOfDay? _quietEnd;

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(userSettingsProvider);

    return Scaffold(
      backgroundColor: VesparaColors.background,
      appBar: AppBar(
        title: Text('Notifications',
            style: GoogleFonts.cinzel(
              fontSize: 18,
              letterSpacing: 3,
            )),
        backgroundColor: VesparaColors.background,
        elevation: 0,
      ),
      body: settingsAsync.when(
        data: (settings) =>
            settings == null ? _buildNoSettings() : _buildSettings(settings),
        loading: () => const Center(
            child: CircularProgressIndicator(color: VesparaColors.glow)),
        error: (e, _) => Center(
            child: Text('Error: $e',
                style: const TextStyle(color: VesparaColors.error))),
      ),
    );
  }

  Widget _buildNoSettings() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off,
                size: 48, color: VesparaColors.glow.withOpacity(0.3)),
            const SizedBox(height: 16),
            const Text('Settings not available',
                style: TextStyle(color: VesparaColors.secondary)),
          ],
        ),
      );

  Widget _buildSettings(UserSettings settings) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Delivery Channels
          _buildSection(
            title: 'DELIVERY CHANNELS',
            icon: Icons.send_rounded,
            children: [
              _buildToggle(
                title: 'Push Notifications',
                subtitle: 'Real-time alerts on your device',
                icon: Icons.notifications_active,
                value: settings.notifyNewMessages, // Proxy for push_enabled
                settingKey: 'push_enabled',
              ),
              _buildToggle(
                title: 'Email Notifications',
                subtitle: 'Important updates to your inbox',
                icon: Icons.email_rounded,
                value: true, // Default
                settingKey: 'email_enabled',
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Messages & Chat
          _buildSection(
            title: 'MESSAGES & CHAT',
            icon: Icons.chat_bubble_rounded,
            color: VesparaColors.accentViolet,
            children: [
              _buildToggle(
                title: 'New Messages',
                subtitle: 'When someone sends you a message',
                icon: Icons.message_rounded,
                value: settings.notifyNewMessages,
                settingKey: 'notify_new_messages',
              ),
              _buildToggle(
                title: 'Group Activity',
                subtitle: 'Messages in your groups',
                icon: Icons.group_rounded,
                value: true,
                settingKey: 'notify_group_activity',
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Community & Social
          _buildSection(
            title: 'COMMUNITY & SOCIAL',
            icon: Icons.people_rounded,
            color: VesparaColors.accentTeal,
            children: [
              _buildToggle(
                title: 'New Connections',
                subtitle: 'When someone connects with you',
                icon: Icons.person_add_rounded,
                value: settings.notifyNewMatches,
                settingKey: 'notify_new_matches',
              ),
              _buildToggle(
                title: 'Photo Views',
                subtitle: 'When someone views your photos',
                icon: Icons.visibility_rounded,
                value: true,
                settingKey: 'notify_photo_views',
              ),
              _buildToggle(
                title: 'Photo Expiring',
                subtitle: 'Reminder before time-sensitive photos expire',
                icon: Icons.timer_rounded,
                value: true,
                settingKey: 'notify_photo_expiring',
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Events & Travel
          _buildSection(
            title: 'EVENTS & TRAVEL',
            icon: Icons.flight_takeoff_rounded,
            color: VesparaColors.accentCyan,
            children: [
              _buildToggle(
                title: 'Event Updates',
                subtitle: 'New events, RSVPs, and reminders',
                icon: Icons.event_rounded,
                value: settings.notifyDateReminders,
                settingKey: 'notify_new_events',
              ),
              _buildToggle(
                title: 'Travel Overlaps',
                subtitle: 'When members are in the same area',
                icon: Icons.travel_explore_rounded,
                value: true,
                settingKey: 'notify_travel_overlaps',
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Games
          _buildSection(
            title: 'GAMES & ACTIVITIES',
            icon: Icons.local_fire_department_rounded,
            color: VesparaColors.accentGold,
            children: [
              _buildToggle(
                title: 'Game Invites',
                subtitle: 'When someone invites you to play',
                icon: Icons.sports_esports_rounded,
                value: true,
                settingKey: 'notify_game_invites',
              ),
            ],
          ),

          const SizedBox(height: 20),

          // AI & Insights
          _buildSection(
            title: 'INSIGHTS',
            icon: Icons.auto_awesome_rounded,
            color: VesparaColors.glow,
            children: [
              _buildToggle(
                title: 'Insights',
                subtitle: 'Personalized tips and recommendations',
                icon: Icons.psychology_rounded,
                value: settings.notifyAiInsights,
                settingKey: 'notify_ai_insights',
              ),
              _buildToggle(
                title: 'Weekly Digest',
                subtitle: 'Summary of your activity and connections',
                icon: Icons.summarize_rounded,
                value: true,
                settingKey: 'notify_weekly_digest',
              ),
              _buildToggle(
                title: 'Community Updates',
                subtitle: 'New features and community news',
                icon: Icons.campaign_rounded,
                value: false,
                settingKey: 'notify_community_updates',
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Quiet Hours
          _buildSection(
            title: 'QUIET HOURS',
            icon: Icons.do_not_disturb_on_rounded,
            children: [
              _buildQuietHours(),
            ],
          ),

          const SizedBox(height: 40),
        ],
      );

  Widget _buildSection({
    required String title,
    required IconData icon,
    Color? color,
    required List<Widget> children,
  }) {
    final accent = color ?? VesparaColors.secondary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: VesparaColors.surface.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withOpacity(0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Icon(icon, size: 18, color: accent),
                    const SizedBox(width: 10),
                    Text(
                      title,
                      style: GoogleFonts.cinzel(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: accent,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              ...children,
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggle({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required String settingKey,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          title: Text(title,
              style: GoogleFonts.inter(
                  fontSize: 14,
                  color: VesparaColors.primary,
                  fontWeight: FontWeight.w500)),
          subtitle: Text(subtitle,
              style: GoogleFonts.inter(
                  fontSize: 11, color: VesparaColors.secondary)),
          secondary: Icon(icon, color: VesparaColors.secondary, size: 20),
          value: value,
          activeColor: VesparaColors.accentRose,
          onChanged: (newValue) {
            ref.read(userSettingsProvider.notifier).updateSetting(
                  settingKey,
                  newValue,
                );
          },
        ),
      );

  Widget _buildQuietHours() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Silence notifications during these hours',
              style: GoogleFonts.inter(
                  fontSize: 12, color: VesparaColors.secondary),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _timePickerButton(
                    label: 'Start',
                    time: _quietStart ?? const TimeOfDay(hour: 22, minute: 0),
                    onPick: (time) => setState(() => _quietStart = time),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('to',
                      style: GoogleFonts.inter(
                          color: VesparaColors.secondary, fontSize: 13)),
                ),
                Expanded(
                  child: _timePickerButton(
                    label: 'End',
                    time: _quietEnd ?? const TimeOfDay(hour: 8, minute: 0),
                    onPick: (time) => setState(() => _quietEnd = time),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _timePickerButton({
    required String label,
    required TimeOfDay time,
    required ValueChanged<TimeOfDay> onPick,
  }) =>
      GestureDetector(
        onTap: () async {
          final picked = await showTimePicker(
            context: context,
            initialTime: time,
            builder: (context, child) => Theme(
              data: Theme.of(context).copyWith(
                timePickerTheme: TimePickerThemeData(
                  backgroundColor: VesparaColors.surfaceElevated,
                  hourMinuteTextColor: VesparaColors.primary,
                  dayPeriodTextColor: VesparaColors.primary,
                  dialHandColor: VesparaColors.accentViolet,
                  dialBackgroundColor: VesparaColors.surface,
                ),
              ),
              child: child!,
            ),
          );
          if (picked != null) onPick(picked);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: VesparaColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: VesparaColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(label == 'Start' ? Icons.nightlight : Icons.wb_sunny,
                  size: 16, color: VesparaColors.secondary),
              const SizedBox(width: 8),
              Text(
                time.format(context),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: VesparaColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
}
