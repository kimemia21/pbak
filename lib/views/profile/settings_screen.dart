import 'package:flutter/material.dart';
import 'package:pbak/widgets/terms_and_conditions_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/providers/theme_provider.dart';
import 'package:pbak/providers/crash_detection_provider.dart';
import 'package:pbak/providers/auth_provider.dart';
import 'package:pbak/services/crash_detection/background_crash_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final user = authState.value;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/login');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;
    final crashState = ref.watch(crashDetectorProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF8F9FA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: isDark ? const Color(0xFF1A1A1A) : theme.colorScheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [const Color(0xFF2D2D2D), const Color(0xFF1A1A1A)]
                        : [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.85)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.settings_rounded, color: Colors.white, size: 32),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Settings',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Customize your experience',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Safety Section
                  // _SectionHeader(icon: Icons.shield_rounded, title: 'Safety', color: AppTheme.deepRed),
                  // const SizedBox(height: 12),
                  // _SettingsCard(
                  //   isDark: isDark,
                  //   children: [
                  //     _SwitchTile(
                  //       icon: Icons.sensors_rounded,
                  //       iconColor: crashState.isMonitoring ? AppTheme.successGreen : Colors.grey,
                  //       title: 'Crash Detection (24/7)',
                  //       subtitle: crashState.isMonitoring
                  //           ? '🛡️ Active - Monitoring always'
                  //           : 'Enable for 24/7 protection',
                  //       value: crashState.isMonitoring,
                  //       onChanged: (value) => _toggleCrashDetection(context, ref, value, user.emergencyContact),
                  //       isDark: isDark,
                  //     ),
                  //     _Divider(isDark: isDark),
                  //     _NavigationTile(
                  //       icon: Icons.science_rounded,
                  //       title: 'Test Crash Detection',
                  //       subtitle: 'Verify the system works',
                  //       onTap: () => context.push('/crash-test'),
                  //       isDark: isDark,
                  //     ),
                  //   ],
                  // ),
                  // const SizedBox(height: 24),

                  // Appearance Section
                  _SectionHeader(icon: Icons.palette_rounded, title: 'Appearance', color: theme.colorScheme.primary),
                  const SizedBox(height: 12),
                  _SettingsCard(
                    isDark: isDark,
                    children: [
                      _SwitchTile(
                        icon: isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        iconColor: isDarkMode ? Colors.indigo : AppTheme.goldAccent,
                        title: 'Dark Mode',
                        subtitle: isDarkMode ? 'Dark theme enabled' : 'Light theme enabled',
                        value: isDarkMode,
                        onChanged: (_) => ref.read(themeModeProvider.notifier).toggleTheme(),
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Notifications Section
                  _SectionHeader(icon: Icons.notifications_rounded, title: 'Notifications', color: AppTheme.warningOrange),
                  const SizedBox(height: 12),
                  _SettingsCard(
                    isDark: isDark,
                    children: [
                      _SwitchTile(
                        icon: Icons.notifications_active_rounded,
                        iconColor: AppTheme.successGreen,
                        title: 'Push Notifications',
                        subtitle: 'Events and updates',
                        value: true,
                        onChanged: (_) {},
                        isDark: isDark,
                      ),
                      _Divider(isDark: isDark),
                      _SwitchTile(
                        icon: Icons.event_rounded,
                        iconColor: theme.colorScheme.primary,
                        title: 'Event Reminders',
                        subtitle: 'Upcoming events alerts',
                        value: true,
                        onChanged: (_) {},
                        isDark: isDark,
                      ),
                      _Divider(isDark: isDark),
                      _SwitchTile(
                        icon: Icons.security_rounded,
                        iconColor: AppTheme.successGreen,
                        title: 'Insurance Alerts',
                        subtitle: 'Expiry reminders',
                        value: true,
                        onChanged: (_) {},
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Account Section
                  _SectionHeader(icon: Icons.person_rounded, title: 'Account', color: theme.colorScheme.primary),
                  const SizedBox(height: 12),
                  _SettingsCard(
                    isDark: isDark,
                    children: [
                      _NavigationTile(
                        icon: Icons.edit_rounded,
                        title: 'Edit Profile',
                        subtitle: 'Update your information',
                        onTap: () => context.push('/profile/edit'),
                        isDark: isDark,
                      ),
                      _Divider(isDark: isDark),
                      _DisabledTile(
                        icon: Icons.lock_rounded,
                        title: 'Change Password',
                        subtitle: 'Coming soon',
                        isDark: isDark,
                      ),
                      _Divider(isDark: isDark),
                      _ActionTile(
                        icon: Icons.logout_rounded,
                        iconColor: AppTheme.deepRed,
                        title: 'Logout',
                        subtitle: 'Sign out of your account',
                        onTap: () => _showLogoutDialog(context, ref),
                        isDark: isDark,
                        isDestructive: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // About Section
                  _SectionHeader(icon: Icons.info_rounded, title: 'About', color: Colors.grey),
                  const SizedBox(height: 12),
                  _SettingsCard(
                    isDark: isDark,
                    children: [
                      _InfoTile(
                        icon: Icons.smartphone_rounded,
                        title: 'App Version',
                        value: '1.0.0',
                        isDark: isDark,
                      ),
                      _Divider(isDark: isDark),
                      _NavigationTile(
                        icon: Icons.privacy_tip_rounded,
                        title: 'Privacy Policy',
                        onTap: () => showPrivacyPolicyDialog(context),
                        isDark: isDark,
                      ),
                      _Divider(isDark: isDark),
                      _NavigationTile(
                        icon: Icons.description_rounded,
                        title: 'Terms of Service',
                        onTap: () => showTermsAndConditionsDialog(context),
                        isDark: isDark,
                      ),
                      _Divider(isDark: isDark),
                      _NavigationTile(
                        icon: Icons.help_rounded,
                        title: 'Help & Support',
                        onTap: () => showHelpAndSupportDialog(context),
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleCrashDetection(BuildContext context, WidgetRef ref, bool value, String? emergencyContact) async {
    if (value) {
      if (emergencyContact == null || emergencyContact.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.warning_rounded, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(child: Text('Please add an emergency contact first')),
                ],
              ),
              backgroundColor: AppTheme.warningOrange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
        return;
      }

      await BackgroundCrashService.enable(emergencyContact);
      await ref.read(crashDetectorProvider.notifier).startMonitoring();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 12),
                Text('Crash Detection Enabled'),
              ],
            ),
            backgroundColor: AppTheme.successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } else {
      await BackgroundCrashService.disable();
      ref.read(crashDetectorProvider.notifier).stopMonitoring();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Crash Detection Disabled'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.deepRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.logout_rounded, color: AppTheme.deepRed, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Logout'),
          ],
        ),
        content: const Text('Are you sure you want to sign out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.deepRed),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

// Section Header
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionHeader({required this.icon, required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 10),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

// Settings Card Container
class _SettingsCard extends StatelessWidget {
  final bool isDark;
  final List<Widget> children;

  const _SettingsCard({required this.isDark, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

// Divider
class _Divider extends StatelessWidget {
  final bool isDark;

  const _Divider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 56,
      color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.1),
    );
  }
}

// Switch Tile
class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isDark;

  const _SwitchTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }
}

// Navigation Tile
class _NavigationTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isDark;

  const _NavigationTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                    ],
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}

// Action Tile (for logout etc.)
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDark;
  final bool isDestructive;

  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.isDark,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDestructive ? iconColor : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Info Tile
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool isDark;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: Colors.grey),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          ),
          Text(value, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
        ],
      ),
    );
  }
}

// Disabled Tile (greyed out)
class _DisabledTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;

  const _DisabledTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Opacity(
      opacity: 0.5,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: Colors.grey),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                ],
              ),
            ),
            Icon(Icons.lock_outline_rounded, size: 18, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
