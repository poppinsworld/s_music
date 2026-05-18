import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../../shared/glass_container.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 140, left: 16, right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Card
            GlassContainer(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.person, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PoppinsWorld', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Text('Music Lover', style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text('General', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildSettingSwitch('Dark Mode', true),
            _buildSettingSwitch('Data Saver', false),
            _buildSettingSwitch('Crossfade', true),
            _buildSettingSwitch('Gapless Playback', true),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Audio Quality', style: TextStyle(color: AppColors.textPrimary)),
              subtitle: const Text('High', style: TextStyle(color: AppColors.textSecondary)),
              trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              onTap: () {},
            ),
            const SizedBox(height: 32),
            Text('More', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildSettingLink(Icons.download, 'Downloads'),
            _buildSettingLink(Icons.equalizer, 'Equalizer'),
            _buildSettingLink(Icons.cloud_upload, 'Backup & Restore'),
            _buildSettingLink(Icons.info_outline, 'About'),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingSwitch(String title, bool value) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
      value: value,
      activeColor: AppColors.primary,
      onChanged: (v) {},
    );
  }

  Widget _buildSettingLink(IconData icon, String title) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: () {},
    );
  }
}
