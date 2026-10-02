import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../state/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & About'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Application Overview
              Text('Application Overview', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          AppConstants.appLogoIcon,
                          width: 52,
                          height: 52,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppConstants.appName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${AppConstants.appTagline} • Local & Offline Processing',
                              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.65)),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'v${AppConstants.appVersion}',
                        style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.primary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Appearance Section
              Text('Appearance & Theme', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    RadioListTile<AppThemeMode>(
                      title: const Text('Corporate Executive Mode (Default)'),
                      subtitle: const Text('High-end navy and slate theme tailored for enterprise productivity'),
                      value: AppThemeMode.corporate,
                      groupValue: settings.themeMode,
                      onChanged: (val) => ref.read(settingsProvider.notifier).setTheme(val!),
                    ),
                    RadioListTile<AppThemeMode>(
                      title: const Text('Light Mode'),
                      subtitle: const Text('Clean high-contrast theme for daytime reading'),
                      value: AppThemeMode.light,
                      groupValue: settings.themeMode,
                      onChanged: (val) => ref.read(settingsProvider.notifier).setTheme(val!),
                    ),
                    RadioListTile<AppThemeMode>(
                      title: const Text('Dark Mode'),
                      subtitle: const Text('Sleek dark theme reducing eye strain in low light'),
                      value: AppThemeMode.dark,
                      groupValue: settings.themeMode,
                      onChanged: (val) => ref.read(settingsProvider.notifier).setTheme(val!),
                    ),
                    RadioListTile<AppThemeMode>(
                      title: const Text('Sepia / Eye-Care Mode'),
                      subtitle: const Text('Warm paper tone designed for prolonged reading'),
                      value: AppThemeMode.sepia,
                      groupValue: settings.themeMode,
                      onChanged: (val) => ref.read(settingsProvider.notifier).setTheme(val!),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Offline Architecture & Privacy
              Text('Privacy & Offline Processing', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_outlined, color: Colors.green, size: 36),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('100% Offline-First Architecture', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text(
                              'All PDF operations, compression, OCR, conversion, and editing run strictly on your local device. Documents are never uploaded to any cloud server.',
                              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.7), height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Developer & About Info
              Text('About ReadNext', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    children: [
                      _buildInfoRow('Product Name', AppConstants.appName),
                      const Divider(),
                      _buildInfoRow('Tagline', AppConstants.appTagline),
                      const Divider(),
                      _buildInfoRow('Developer', AppConstants.developerName),
                      const Divider(),
                      _buildInfoRow('Version', AppConstants.appVersion),
                      const Divider(),
                      _buildInfoRow('Platform', 'Windows (Desktop Native)'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
