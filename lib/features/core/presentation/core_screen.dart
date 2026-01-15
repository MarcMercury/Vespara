import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/providers/app_providers.dart';

/// The Core Screen - Settings & Vouch Chain
/// User profile, preferences, and verification link generation
class CoreScreen extends ConsumerStatefulWidget {
  const CoreScreen({super.key});

  @override
  ConsumerState<CoreScreen> createState() => _CoreScreenState();
}

class _CoreScreenState extends ConsumerState<CoreScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    
    return Scaffold(
      backgroundColor: VesparaColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(child: _buildHeader(context)),
            
            // Profile section
            SliverToBoxAdapter(
              child: user.when(
                data: (profile) => _buildProfileSection(context, profile),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
            
            // Vouch Chain section
            SliverToBoxAdapter(child: _buildVouchChainSection(context)),
            
            // Settings sections
            SliverToBoxAdapter(child: _buildAppearanceSection(context)),
            SliverToBoxAdapter(child: _buildNotificationsSection(context)),
            SliverToBoxAdapter(child: _buildPrivacySection(context)),
            SliverToBoxAdapter(child: _buildDataSection(context)),
            SliverToBoxAdapter(child: _buildAboutSection(context)),
            
            // Logout button
            SliverToBoxAdapter(child: _buildLogoutButton(context)),
            
            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: VesparaSpacing.xl),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(VesparaSpacing.md),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              VesparaHaptics.lightTap();
              context.go('/home');
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: VesparaColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: VesparaColors.border),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: VesparaColors.primary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: VesparaSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'THE CORE',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    letterSpacing: 3,
                  ),
                ),
                Text(
                  'Settings & Identity',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: VesparaColors.glow.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.settings_outlined,
              color: VesparaColors.primary,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProfileSection(BuildContext context, dynamic profile) {
    return Container(
      margin: const EdgeInsets.all(VesparaSpacing.md),
      padding: const EdgeInsets.all(VesparaSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            VesparaColors.surface,
            VesparaColors.glow.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(VesparaBorderRadius.tile),
        border: Border.all(color: VesparaColors.border),
      ),
      child: Column(
        children: [
          // Avatar
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: VesparaColors.background,
                  border: Border.all(
                    color: VesparaColors.glow.withOpacity(0.5),
                    width: 3,
                  ),
                ),
                child: const Icon(
                  Icons.person,
                  color: VesparaColors.secondary,
                  size: 48,
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: () {
                    VesparaHaptics.lightTap();
                    // Open photo picker
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: VesparaColors.glow,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: VesparaColors.surface,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: VesparaColors.background,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: VesparaSpacing.md),
          
          // Name
          Text(
            profile?.displayName ?? 'Your Name',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            profile?.email ?? 'email@example.com',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          
          const SizedBox(height: VesparaSpacing.lg),
          
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildProfileStat(context, '12', 'Active'),
              Container(
                width: 1,
                height: 30,
                color: VesparaColors.border,
              ),
              _buildProfileStat(context, '3', 'Vouches'),
              Container(
                width: 1,
                height: 30,
                color: VesparaColors.border,
              ),
              _buildProfileStat(context, '89%', 'Score'),
            ],
          ),
          
          const SizedBox(height: VesparaSpacing.lg),
          
          // Edit profile button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                VesparaHaptics.lightTap();
                _showEditProfileSheet(context);
              },
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('EDIT PROFILE'),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProfileStat(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: VesparaColors.glow,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
  
  Widget _buildVouchChainSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: VesparaSpacing.md),
      padding: const EdgeInsets.all(VesparaSpacing.lg),
      decoration: BoxDecoration(
        color: VesparaColors.surface,
        borderRadius: BorderRadius.circular(VesparaBorderRadius.tile),
        border: Border.all(
          color: VesparaColors.glow.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: VesparaColors.glow.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.verified_user,
                  color: VesparaColors.glow,
                  size: 24,
                ),
              ),
              const SizedBox(width: VesparaSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'THE VOUCH CHAIN',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      'Trust verification network',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: VesparaSpacing.lg),
          
          // Verification status
          Container(
            padding: const EdgeInsets.all(VesparaSpacing.md),
            decoration: BoxDecoration(
              color: VesparaColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: VesparaColors.tagsGreen.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    color: VesparaColors.tagsGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: VesparaSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'VERIFIED',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: VesparaColors.tagsGreen,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.check_circle,
                            color: VesparaColors.tagsGreen,
                            size: 16,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '3 people have vouched for you',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: VesparaSpacing.md),
          
          // Your vouches
          Text(
            'YOUR VOUCHES',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: VesparaSpacing.sm),
          
          // Vouch avatars
          Row(
            children: [
              ...List.generate(3, (index) => Container(
                width: 40,
                height: 40,
                margin: EdgeInsets.only(left: index > 0 ? 0 : 0, right: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: VesparaColors.background,
                  border: Border.all(
                    color: VesparaColors.glow.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.person,
                  color: VesparaColors.secondary,
                  size: 20,
                ),
              )),
              GestureDetector(
                onTap: () => _showVouchRequestSheet(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: VesparaColors.glow.withOpacity(0.1),
                    border: Border.all(
                      color: VesparaColors.glow.withOpacity(0.5),
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: const Icon(
                    Icons.add,
                    color: VesparaColors.glow,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: VesparaSpacing.lg),
          
          // Generate link button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showVouchLinkSheet(context),
              icon: const Icon(Icons.link, size: 18),
              label: const Text('GENERATE VOUCH LINK'),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAppearanceSection(BuildContext context) {
    return _buildSettingsSection(
      context,
      title: 'APPEARANCE',
      icon: Icons.palette_outlined,
      children: [
        _buildSettingsTile(
          context,
          icon: Icons.dark_mode_outlined,
          title: 'Dark Mode',
          subtitle: 'Always on (Vespara Night)',
          trailing: Switch(
            value: true,
            onChanged: null, // Locked to dark mode
            activeColor: VesparaColors.glow,
          ),
        ),
        _buildSettingsTile(
          context,
          icon: Icons.text_fields,
          title: 'Text Size',
          subtitle: 'Medium',
          onTap: () {},
        ),
      ],
    );
  }
  
  Widget _buildNotificationsSection(BuildContext context) {
    return _buildSettingsSection(
      context,
      title: 'NOTIFICATIONS',
      icon: Icons.notifications_outlined,
      children: [
        _buildSettingsTile(
          context,
          icon: Icons.message_outlined,
          title: 'New Messages',
          trailing: Switch(
            value: true,
            onChanged: (v) {},
            activeColor: VesparaColors.glow,
          ),
        ),
        _buildSettingsTile(
          context,
          icon: Icons.person_add_outlined,
          title: 'New Matches',
          trailing: Switch(
            value: true,
            onChanged: (v) {},
            activeColor: VesparaColors.glow,
          ),
        ),
        _buildSettingsTile(
          context,
          icon: Icons.psychology_outlined,
          title: 'Strategist Insights',
          trailing: Switch(
            value: false,
            onChanged: (v) {},
            activeColor: VesparaColors.glow,
          ),
        ),
        _buildSettingsTile(
          context,
          icon: Icons.warning_amber_outlined,
          title: 'Stale Connection Alerts',
          trailing: Switch(
            value: true,
            onChanged: (v) {},
            activeColor: VesparaColors.glow,
          ),
        ),
      ],
    );
  }
  
  Widget _buildPrivacySection(BuildContext context) {
    return _buildSettingsSection(
      context,
      title: 'PRIVACY',
      icon: Icons.shield_outlined,
      children: [
        _buildSettingsTile(
          context,
          icon: Icons.location_off_outlined,
          title: 'Tonight Mode Location',
          subtitle: 'Only while app is open',
          onTap: () {},
        ),
        _buildSettingsTile(
          context,
          icon: Icons.visibility_off_outlined,
          title: 'Hide Profile',
          trailing: Switch(
            value: false,
            onChanged: (v) {},
            activeColor: VesparaColors.glow,
          ),
        ),
        _buildSettingsTile(
          context,
          icon: Icons.block_outlined,
          title: 'Blocked Users',
          subtitle: '0 blocked',
          onTap: () {},
        ),
      ],
    );
  }
  
  Widget _buildDataSection(BuildContext context) {
    return _buildSettingsSection(
      context,
      title: 'DATA',
      icon: Icons.storage_outlined,
      children: [
        _buildSettingsTile(
          context,
          icon: Icons.download_outlined,
          title: 'Export Data',
          subtitle: 'Download all your data',
          onTap: () {},
        ),
        _buildSettingsTile(
          context,
          icon: Icons.delete_outline,
          title: 'Clear Cache',
          subtitle: '24.5 MB',
          onTap: () {},
        ),
      ],
    );
  }
  
  Widget _buildAboutSection(BuildContext context) {
    return _buildSettingsSection(
      context,
      title: 'ABOUT',
      icon: Icons.info_outline,
      children: [
        _buildSettingsTile(
          context,
          icon: Icons.description_outlined,
          title: 'Terms of Service',
          onTap: () {},
        ),
        _buildSettingsTile(
          context,
          icon: Icons.privacy_tip_outlined,
          title: 'Privacy Policy',
          onTap: () {},
        ),
        _buildSettingsTile(
          context,
          icon: Icons.help_outline,
          title: 'Help & Support',
          onTap: () {},
        ),
        _buildSettingsTile(
          context,
          icon: Icons.code,
          title: 'Version',
          subtitle: '1.0.0 (Build 1)',
        ),
      ],
    );
  }
  
  Widget _buildSettingsSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        VesparaSpacing.md,
        VesparaSpacing.lg,
        VesparaSpacing.md,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: VesparaColors.secondary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: VesparaSpacing.sm),
          Container(
            decoration: BoxDecoration(
              color: VesparaColors.surface,
              borderRadius: BorderRadius.circular(VesparaBorderRadius.card),
              border: Border.all(color: VesparaColors.border),
            ),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          VesparaHaptics.lightTap();
          onTap();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: VesparaSpacing.md,
          vertical: VesparaSpacing.sm + 4,
        ),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: VesparaColors.border,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: VesparaColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: VesparaColors.secondary,
                size: 18,
              ),
            ),
            const SizedBox(width: VesparaSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              trailing
            else if (onTap != null)
              const Icon(
                Icons.chevron_right,
                color: VesparaColors.inactive,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(VesparaSpacing.md),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _showLogoutConfirmation(context),
          style: OutlinedButton.styleFrom(
            foregroundColor: VesparaColors.tagsRed,
            side: BorderSide(color: VesparaColors.tagsRed.withOpacity(0.5)),
          ),
          icon: const Icon(Icons.logout, size: 18),
          label: const Text('SIGN OUT'),
        ),
      ),
    );
  }
  
  void _showEditProfileSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const _EditProfileSheet(),
    );
  }
  
  void _showVouchLinkSheet(BuildContext context) {
    VesparaHaptics.mediumTap();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const _VouchLinkSheet(),
    );
  }
  
  void _showVouchRequestSheet(BuildContext context) {
    VesparaHaptics.lightTap();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(VesparaSpacing.lg),
        decoration: BoxDecoration(
          color: VesparaColors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(VesparaBorderRadius.tile),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: VesparaColors.inactive,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: VesparaSpacing.lg),
            Text(
              'REQUEST A VOUCH',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: VesparaSpacing.md),
            Text(
              'Ask someone you trust to vouch for your authenticity',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: VesparaSpacing.lg),
            TextField(
              decoration: InputDecoration(
                hintText: 'Enter email or phone number',
                filled: true,
                fillColor: VesparaColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: VesparaSpacing.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('SEND REQUEST'),
              ),
            ),
            const SizedBox(height: VesparaSpacing.lg),
          ],
        ),
      ),
    );
  }
  
  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VesparaColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VesparaBorderRadius.card),
        ),
        title: Text(
          'Sign Out?',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        content: Text(
          'Are you sure you want to sign out of Vespara?',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/auth');
            },
            style: TextButton.styleFrom(
              foregroundColor: VesparaColors.tagsRed,
            ),
            child: const Text('SIGN OUT'),
          ),
        ],
      ),
    );
  }
}

/// Edit Profile Sheet
class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet();

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  
  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(VesparaSpacing.lg),
      decoration: BoxDecoration(
        color: VesparaColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(VesparaBorderRadius.tile),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: VesparaColors.inactive,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: VesparaSpacing.lg),
          
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'EDIT PROFILE',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  letterSpacing: 2,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: VesparaColors.secondary),
              ),
            ],
          ),
          
          const SizedBox(height: VesparaSpacing.lg),
          
          // Fields
          Text(
            'DISPLAY NAME',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: VesparaSpacing.sm),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Your display name',
              filled: true,
              fillColor: VesparaColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          
          const SizedBox(height: VesparaSpacing.lg),
          
          Text(
            'BIO',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: VesparaSpacing.sm),
          TextField(
            controller: _bioController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Tell matches about yourself...',
              filled: true,
              fillColor: VesparaColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          
          const Spacer(),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                VesparaHaptics.mediumTap();
                Navigator.pop(context);
              },
              child: const Text('SAVE CHANGES'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Vouch Link Generation Sheet
class _VouchLinkSheet extends StatefulWidget {
  const _VouchLinkSheet();

  @override
  State<_VouchLinkSheet> createState() => _VouchLinkSheetState();
}

class _VouchLinkSheetState extends State<_VouchLinkSheet> {
  bool _linkGenerated = false;
  final String _vouchLink = 'https://vespara.app/vouch/abc123xyz';
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(VesparaSpacing.lg),
      decoration: BoxDecoration(
        color: VesparaColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(VesparaBorderRadius.tile),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: VesparaColors.inactive,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: VesparaSpacing.lg),
          
          // Icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: VesparaColors.glow.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.link,
              color: VesparaColors.glow,
              size: 32,
            ),
          ),
          const SizedBox(height: VesparaSpacing.lg),
          
          Text(
            'VOUCH CHAIN LINK',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: VesparaSpacing.sm),
          Text(
            'Share this link with someone to receive their vouch',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: VesparaSpacing.lg),
          
          if (_linkGenerated) ...[
            // Link display
            Container(
              padding: const EdgeInsets.all(VesparaSpacing.md),
              decoration: BoxDecoration(
                color: VesparaColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: VesparaColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _vouchLink,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: VesparaColors.glow,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      VesparaHaptics.lightTap();
                      Clipboard.setData(ClipboardData(text: _vouchLink));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Link copied to clipboard'),
                          backgroundColor: VesparaColors.surface,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: VesparaColors.glow.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.copy,
                        color: VesparaColors.glow,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: VesparaSpacing.md),
            
            // Share button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  VesparaHaptics.mediumTap();
                  // Would use share_plus here
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.share, size: 18),
                label: const Text('SHARE LINK'),
              ),
            ),
          ] else ...[
            // Generate button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  VesparaHaptics.mediumTap();
                  setState(() {
                    _linkGenerated = true;
                  });
                },
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: const Text('GENERATE LINK'),
              ),
            ),
          ],
          
          const SizedBox(height: VesparaSpacing.sm),
          Text(
            'Links expire after 7 days',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: VesparaSpacing.lg),
        ],
      ),
    );
  }
}
