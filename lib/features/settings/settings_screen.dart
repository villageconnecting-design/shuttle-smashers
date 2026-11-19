import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../services/auth_service.dart';

/// Settings screen with app preferences and account management
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _authService = AuthService();

  // Settings state
  bool _notificationsEnabled = true;
  bool _matchReminders = true;
  bool _tournamentUpdates = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  Future<void> _changePassword() async {
    final emailController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text(
          'Reset Password',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your email to receive a password reset link.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Email address',
                prefixIcon: const Icon(Icons.email_outlined),
                filled: true,
                fillColor: AppColors.surfaceColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send Link'),
          ),
        ],
      ),
    );

    if (result == true && emailController.text.isNotEmpty) {
      try {
        await _authService.sendPasswordResetEmail(emailController.text.trim());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password reset email sent'),
              backgroundColor: AppColors.accentGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.sports_tennis,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Shuttle Smashers',
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version ${AppConstants.appVersion}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            const Text(
              'Score. Compete. Win.',
              style: TextStyle(
                color: AppColors.accentGreen,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'The ultimate badminton scoring and tournament management app for players of all levels.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            const Text(
              'Features:',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildFeatureItem('Live match scoring'),
            _buildFeatureItem('Tournament management'),
            _buildFeatureItem('Player leaderboards'),
            _buildFeatureItem('Match statistics'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: AppColors.accentGreen,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.darkGradient,
        ),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Notifications section
            _buildSectionHeader('Notifications'),
            _buildSettingsCard([
              _buildSwitchTile(
                icon: Icons.notifications_outlined,
                title: 'Push Notifications',
                subtitle: 'Receive app notifications',
                value: _notificationsEnabled,
                onChanged: (value) => setState(() => _notificationsEnabled = value),
              ),
              _buildDivider(),
              _buildSwitchTile(
                icon: Icons.alarm,
                title: 'Match Reminders',
                subtitle: 'Get reminded before matches',
                value: _matchReminders,
                onChanged: _notificationsEnabled
                    ? (value) => setState(() => _matchReminders = value)
                    : null,
              ),
              _buildDivider(),
              _buildSwitchTile(
                icon: Icons.emoji_events_outlined,
                title: 'Tournament Updates',
                subtitle: 'Updates on tournaments you joined',
                value: _tournamentUpdates,
                onChanged: _notificationsEnabled
                    ? (value) => setState(() => _tournamentUpdates = value)
                    : null,
              ),
            ]),
            const SizedBox(height: 24),

            // Sound & Haptics section
            _buildSectionHeader('Sound & Haptics'),
            _buildSettingsCard([
              _buildSwitchTile(
                icon: Icons.volume_up_outlined,
                title: 'Sound Effects',
                subtitle: 'Play sounds for score updates',
                value: _soundEnabled,
                onChanged: (value) => setState(() => _soundEnabled = value),
              ),
              _buildDivider(),
              _buildSwitchTile(
                icon: Icons.vibration,
                title: 'Vibration',
                subtitle: 'Haptic feedback on actions',
                value: _vibrationEnabled,
                onChanged: (value) => setState(() => _vibrationEnabled = value),
              ),
            ]),
            const SizedBox(height: 24),

            // Account section
            _buildSectionHeader('Account'),
            _buildSettingsCard([
              _buildActionTile(
                icon: Icons.lock_outline,
                title: 'Change Password',
                subtitle: 'Update your account password',
                onTap: _changePassword,
              ),
              _buildDivider(),
              _buildActionTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                subtitle: 'View our privacy policy',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Privacy policy coming soon'),
                      backgroundColor: AppColors.info,
                    ),
                  );
                },
              ),
              _buildDivider(),
              _buildActionTile(
                icon: Icons.description_outlined,
                title: 'Terms of Service',
                subtitle: 'View terms and conditions',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Terms of service coming soon'),
                      backgroundColor: AppColors.info,
                    ),
                  );
                },
              ),
            ]),
            const SizedBox(height: 24),

            // About section
            _buildSectionHeader('About'),
            _buildSettingsCard([
              _buildActionTile(
                icon: Icons.info_outline,
                title: 'About Shuttle Smashers',
                subtitle: 'Version ${AppConstants.appVersion}',
                onTap: _showAbout,
              ),
              _buildDivider(),
              _buildActionTile(
                icon: Icons.star_outline,
                title: 'Rate App',
                subtitle: 'Share your feedback',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('App store rating coming soon'),
                      backgroundColor: AppColors.info,
                    ),
                  );
                },
              ),
              _buildDivider(),
              _buildActionTile(
                icon: Icons.help_outline,
                title: 'Help & Support',
                subtitle: 'Get help with the app',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Help center coming soon'),
                      backgroundColor: AppColors.info,
                    ),
                  );
                },
              ),
            ]),
            const SizedBox(height: 24),

            // Danger zone
            _buildSectionHeader('Danger Zone'),
            _buildSettingsCard([
              _buildActionTile(
                icon: Icons.delete_forever_outlined,
                title: 'Delete Account',
                subtitle: 'Permanently delete your account',
                isDestructive: true,
                onTap: _showDeleteAccountDialog,
              ),
            ]),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      color: AppColors.surfaceColor,
      height: 1,
      indent: 56,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    final isEnabled = onChanged != null;

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isEnabled ? AppColors.primaryBlue : AppColors.textMuted,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isEnabled ? AppColors.textPrimary : AppColors.textMuted,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isEnabled ? AppColors.textSecondary : AppColors.textMuted,
          fontSize: 12,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: AppColors.accentGreen.withValues(alpha: 0.5),
        activeThumbColor: AppColors.accentGreen,
        inactiveThumbColor: AppColors.textMuted,
        inactiveTrackColor: AppColors.surfaceColor,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDestructive
              ? AppColors.error.withValues(alpha: 0.1)
              : AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isDestructive ? AppColors.error : AppColors.primaryBlue,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? AppColors.error : AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isDestructive
              ? AppColors.error.withValues(alpha: 0.7)
              : AppColors.textSecondary,
          fontSize: 12,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: isDestructive ? AppColors.error : AppColors.textMuted,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            SizedBox(width: 12),
            Text(
              'Delete Account',
              style: TextStyle(color: AppColors.error),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently lost.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deletion is not available yet'),
                  backgroundColor: AppColors.info,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
