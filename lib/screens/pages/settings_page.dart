import 'package:flutter/material.dart';
import 'package:meddiet/constants/app_colors.dart';
import 'package:meddiet/widgets/common_header.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Settings states
  bool notificationsEnabled = true;
  bool emailNotifications = true;
  bool pushNotifications = true;
  String selectedLanguage = 'English';
  String selectedTheme = 'Light';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Column(
          children: [
            const CommonHeader(
              title: 'Settings',
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Account Settings Section
                    _buildSettingsSection(
                      'Account Settings',
                      [
                        _buildSettingItem(
                          'Profile Information',
                          Icons.person_outline,
                          'View and edit your profile details',
                          () => _handleProfileTap(context),
                        ),
                        _buildSettingItem(
                          'Change Password',
                          Icons.lock_outline,
                          'Update your password for security',
                          () => _handlePasswordTap(context),
                        ),
                        _buildSettingItem(
                          'Email Preferences',
                          Icons.email_outlined,
                          'Manage your email address',
                          () => _handleEmailTap(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // Notifications Section
                    _buildSettingsSection(
                      'Notifications',
                      [
                        _buildToggleItem(
                          'Enable Notifications',
                          Icons.notifications_outlined,
                          'Receive all notifications',
                          notificationsEnabled,
                          (value) => setState(() => notificationsEnabled = value),
                        ),
                        _buildToggleItem(
                          'Email Notifications',
                          Icons.mail_outline,
                          'Receive notifications via email',
                          emailNotifications,
                          (value) => setState(() => emailNotifications = value),
                          enabled: notificationsEnabled,
                        ),
                        _buildToggleItem(
                          'Push Notifications',
                          Icons.notifications_active_outlined,
                          'Receive push notifications',
                          pushNotifications,
                          (value) => setState(() => pushNotifications = value),
                          enabled: notificationsEnabled,
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // Application Settings Section
                    _buildSettingsSection(
                      'Application Settings',
                      [
                        _buildDropdownItem(
                          'Theme',
                          Icons.palette_outlined,
                          'Choose your preferred theme',
                          selectedTheme,
                          ['Light', 'Dark', 'System'],
                          (value) => setState(() => selectedTheme = value),
                        ),
                        _buildDropdownItem(
                          'Language',
                          Icons.language_outlined,
                          'Select your preferred language',
                          selectedLanguage,
                          ['English', 'Spanish', 'French', 'German'],
                          (value) => setState(() => selectedLanguage = value),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // System Section
                    _buildSettingsSection(
                      'System & Security',
                      [
                        _buildSettingItem(
                          'Backup & Restore',
                          Icons.backup_outlined,
                          'Backup your data or restore from backup',
                          () => _handleBackupTap(context),
                        ),
                        _buildSettingItem(
                          'Privacy Policy',
                          Icons.privacy_tip_outlined,
                          'Read our privacy policy',
                          () => _handlePrivacyTap(context),
                        ),
                        _buildSettingItem(
                          'Terms of Service',
                          Icons.description_outlined,
                          'View terms and conditions',
                          () => _handleTermsTap(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // About Section
                    _buildAboutSection(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.border,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildSettingItem(
    String title,
    IconData icon,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: AppColors.primary.withOpacity(0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppColors.border,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleItem(
    String title,
    IconData icon,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged, {
    bool enabled = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.border,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: enabled ? AppColors.primary : AppColors.textSecondary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: enabled ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: enabled ? value : false,
              onChanged: enabled ? onChanged : null,
              activeColor: AppColors.primary,
              activeTrackColor: AppColors.primary.withOpacity(0.3),
              inactiveThumbColor: AppColors.textSecondary,
              inactiveTrackColor: AppColors.border,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownItem(
    String title,
    IconData icon,
    String subtitle,
    String selectedValue,
    List<String> options,
    ValueChanged<String> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.border,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          DropdownButton<String>(
            value: selectedValue,
            items: options
                .map((option) => DropdownMenuItem(
                  value: option,
                  child: Text(option),
                ))
                .toList(),
            onChanged: (newValue) {
              if (newValue != null) {
                onChanged(newValue);
                _showSnackBar('$title changed to $newValue');
              }
            },
            underline: const SizedBox(),
            icon: const Icon(Icons.expand_more),
            style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About MedDiet Admin',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.textWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Version 1.0.0',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textWhite.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'The MedDiet Admin panel is designed to help you manage your medical diet plans efficiently.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textWhite.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _handleCheckUpdatesTap(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                  ),
                  child: const Text('Check Updates'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _handleContactSupportTap(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Contact Support'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Handler methods
  void _handleProfileTap(BuildContext context) {
    _showSnackBar('Profile Information clicked');
    // TODO: Navigate to profile edit page
  }

  void _handlePasswordTap(BuildContext context) {
    _showSnackBar('Change Password clicked');
    // TODO: Navigate to change password page
  }

  void _handleEmailTap(BuildContext context) {
    _showSnackBar('Email Preferences clicked');
    // TODO: Navigate to email preferences page
  }

  void _handleBackupTap(BuildContext context) {
    _showSnackBar('Backup & Restore clicked');
    // TODO: Show backup dialog
  }

  void _handlePrivacyTap(BuildContext context) {
    _showSnackBar('Privacy Policy clicked');
    // TODO: Navigate to privacy policy page
  }

  void _handleTermsTap(BuildContext context) {
    _showSnackBar('Terms of Service clicked');
    // TODO: Navigate to terms page
  }

  void _handleCheckUpdatesTap() {
    _showSnackBar('Checking for updates...');
  }

  void _handleContactSupportTap() {
    _showSnackBar('Opening contact support...');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

