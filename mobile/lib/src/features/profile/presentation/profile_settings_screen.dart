import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/common_widgets/common_avatar.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../../auth/presentation/login_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileSettingsScreen extends ConsumerWidget {
  const ProfileSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Settings')),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          Center(
            child: Column(
              children: [
                CommonAvatar(
                  radius: 50,
                  imageUrl: user?.profilePictureUrl,
                ),
                const SizedBox(height: 16),
                Text(
                  user?.email ?? 'Unknown User',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  user?.roleName ?? 'Employee',
                  style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const _SettingsSection(
            title: 'Account Settings',
            items: [
              _SettingsItem(icon: Icons.person_outline, label: 'Personal Information'),
              _SettingsItem(icon: Icons.lock_outline, label: 'Change Password'),
              _SettingsItem(icon: Icons.notifications_none, label: 'Notifications'),
            ],
          ),
          const SizedBox(height: 24),
          const _SettingsSection(
            title: 'Preferences',
            items: [
              _SettingsItem(icon: Icons.dark_mode_outlined, label: 'Dark Mode', trailing: Icon(Icons.toggle_off_outlined)),
              _SettingsItem(icon: Icons.language, label: 'Language', value: 'English'),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsSection(
            title: 'Legal',
            items: [
              _SettingsItem(
                icon: Icons.privacy_tip_outlined,
                label: 'Privacy Policy',
                onTap: () async {
                  final url = Uri.parse('https://example.com/privacy-policy');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  }
                },
              ),
              _SettingsItem(
                icon: Icons.description_outlined,
                label: 'Terms & Conditions',
                onTap: () async {
                  final url = Uri.parse('https://example.com/terms');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Request Account Deletion'),
                  content: const Text('To delete your account, please contact the HR department.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: AppTheme.textSecondary,
              minimumSize: const Size.fromHeight(50),
              elevation: 0,
            ),
            child: const Text('Request Account Deletion', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).logout();
              // main.dart watches authNotifierProvider and automatically
              // navigates to LoginScreen when user becomes null.
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.1),
              foregroundColor: Colors.red,
              minimumSize: const Size.fromHeight(50),
              elevation: 0,
            ),
            child: const Text('LOGOUT', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> items;

  const _SettingsSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
        const SizedBox(height: 8),
        Card(child: Column(children: items)),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsItem({required this.icon, required this.label, this.value, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 20, color: AppTheme.primaryAccent),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: trailing ?? (value != null ? Text(value!, style: const TextStyle(color: AppTheme.textSecondary)) : const Icon(Icons.chevron_right, size: 20, color: AppTheme.textSecondary)),
      onTap: onTap ?? () {},
    );
  }
}
