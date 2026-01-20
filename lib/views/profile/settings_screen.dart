import 'package:flutter/material.dart';
import 'package:pbak/widgets/terms_and_conditions_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/providers/theme_provider.dart';
import 'package:pbak/providers/crash_detection_provider.dart';
import 'package:pbak/providers/auth_provider.dart';
import 'package:pbak/services/crash_detection/background_crash_service.dart';
import 'package:pbak/widgets/animated_card.dart';
import 'package:pbak/widgets/app_logo.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final user = authState.value;

    // If the user is logged out while on settings, send them to login.
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/login');
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;
    final crashState = ref.watch(crashDetectorProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.all(10),
          child: AppLogo(size: 24),
        ),
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.paddingM),
        children: [
          // Crash Detection
          Text(
            'Safety',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: AppTheme.paddingM),
          AnimatedCard(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Icon(
                    Icons.sensors_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('Crash Detection (24/7)'),
                  subtitle: Text(
                    crashState.isMonitoring 
                        ? '🛡️ Active - Monitoring always, even when app is closed'
                        : 'Inactive - Enable for 24/7 protection',
                  ),
                  value: crashState.isMonitoring,
                  onChanged: (value) async {
                    final authState = ref.read(authProvider);
                    final user = authState.value;
                    
                    if (value && user != null) {
                      // Check if emergency contact is available
                      if (user.emergencyContact == null || user.emergencyContact!.isEmpty) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('⚠️ Please add an emergency contact in your profile first'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                        return;
                      }
                      
                      // Enable background + foreground detection
                      await BackgroundCrashService.enable(user.emergencyContact!);
                      await ref.read(crashDetectorProvider.notifier).startMonitoring();
                      
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ 24/7 Crash Detection Enabled'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } else {
                      // Disable both
                      await BackgroundCrashService.disable();
                      ref.read(crashDetectorProvider.notifier).stopMonitoring();
                      
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Crash Detection Disabled'),
                          ),
                        );
                      }
                    }
                  },
                ),
                const Divider(),
                ListTile(
                  leading: Icon(
                    Icons.science_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('Test Crash Detection'),
                  subtitle: const Text('Test the crash detection system'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () => context.push('/crash-test'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.paddingL),

          // Appearance
          Text(
            'Appearance',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: AppTheme.paddingM),
          AnimatedCard(
            child: SwitchListTile(
              secondary: Icon(
                isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                color: theme.colorScheme.primary,
              ),
              title: const Text('Dark Mode'),
              subtitle: Text(isDarkMode ? 'Enabled' : 'Disabled'),
              value: isDarkMode,
              onChanged: (value) {
                ref.read(themeModeProvider.notifier).toggleTheme();
              },
            ),
          ),
          const SizedBox(height: AppTheme.paddingL),

          // Notifications
          Text(
            'Notifications',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: AppTheme.paddingM),
          AnimatedCard(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Icon(
                    Icons.notifications_active_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('Push Notifications'),
                  subtitle: const Text('Receive notifications for events and updates'),
                  value: true,
                  onChanged: (value) {},
                ),
                const Divider(),
                SwitchListTile(
                  secondary: Icon(
                    Icons.event_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('Event Reminders'),
                  subtitle: const Text('Get notified about upcoming events'),
                  value: true,
                  onChanged: (value) {},
                ),
                const Divider(),
                SwitchListTile(
                  secondary: Icon(
                    Icons.security_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('Insurance Alerts'),
                  subtitle: const Text('Expiry and renewal reminders'),
                  value: true,
                  onChanged: (value) {},
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.paddingL),

          // Account
          Text(
            'Account',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: AppTheme.paddingM),
          AnimatedCard(
            child: ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppTheme.deepRed),
              title: const Text('Logout'),
              subtitle: const Text('Sign out of your account'),
              onTap: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              },
            ),
          ),
          const SizedBox(height: AppTheme.paddingL),

          // About
          Row(
            children: [
              const AppLogo(size: 22),
              const SizedBox(width: 10),
              Text(
                'About',
                style: theme.textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.paddingM),
          AnimatedCard(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.info_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('App Version'),
                  subtitle: const Text('1.0.0'),
                ),
                const Divider(),
                ListTile(
                  leading: Icon(
                    Icons.privacy_tip_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () => showPrivacyPolicyDialog(context),
                ),
                const Divider(),
                ListTile(
                  leading: Icon(
                    Icons.description_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('Terms of Service'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () => showTermsAndConditionsDialog(context),
                ),
                const Divider(),
                ListTile(
                  leading: Icon(
                    Icons.help_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('Help & Support'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () => showHelpAndSupportDialog(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
