import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/providers/auth_provider.dart';
import 'package:pbak/widgets/loading_widget.dart';
import 'package:pbak/widgets/animated_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => context.push('/profile/settings'),
          ),
        ],
      ),
      body: authState.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Not logged in'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.paddingM),
            child: Column(
              children: [
                // Profile Header
                AnimatedCard(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: theme.colorScheme.primary,
                        child: Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                          style: theme.textTheme.displayMedium?.copyWith(
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.paddingM),
                      Text(
                        user.name,
                        style: theme.textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppTheme.paddingS),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            user.isVerified
                                ? Icons.verified_rounded
                                : Icons.pending_rounded,
                            size: 20,
                            color: user.isVerified
                                ? AppTheme.goldAccent
                                : AppTheme.mediumGrey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            user.isVerified ? 'Verified Member' : 'Pending Verification',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.paddingS),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.paddingM,
                          vertical: AppTheme.paddingS,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        ),
                        child: Text(
                          user.role,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.paddingM),
                      OutlinedButton.icon(
                        onPressed: () => context.push('/profile/edit'),
                        icon: const Icon(Icons.edit_rounded),
                        label: const Text('Edit Profile'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.paddingM),

                // Personal Information
                AnimatedCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Personal Information',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppTheme.paddingM),
                      _InfoTile(
                        icon: Icons.email_rounded,
                        label: 'Email',
                        value: user.email,
                      ),
                      const Divider(),
                      _InfoTile(
                        icon: Icons.phone_rounded,
                        label: 'Phone',
                        value: user.phone ?? 'Not provided',
                      ),
                      const Divider(),
                      _InfoTile(
                        icon: Icons.location_on_rounded,
                        label: 'Region',
                        value: user.region.isNotEmpty ? user.region : 'Not assigned',
                      ),
                      const Divider(),
                      _InfoTile(
                        icon: Icons.badge_rounded,
                        label: 'ID Number',
                        value: user.idNumber.isNotEmpty ? user.idNumber : 'Not provided',
                      ),
                      const Divider(),
                      _InfoTile(
                        icon: Icons.card_membership_rounded,
                        label: 'License Number',
                        value: user.licenseNumber.isNotEmpty ? user.licenseNumber : 'Not provided',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.paddingM),

                // Quick Links
                AnimatedCard(
                  child: Column(
                    children: [
                      _MenuTile(
                        icon: Icons.two_wheeler_rounded,
                        title: 'My Bikes',
                        onTap: () => context.push('/bikes'),
                      ),
                      const Divider(),
                      _MenuTile(
                        icon: Icons.security_rounded,
                        title: 'My Insurance',
                        onTap: () => context.push('/insurance'),
                      ),
                      const Divider(),
                      _MenuTile(
                        icon: Icons.payment_rounded,
                        title: 'Payment History',
                        onTap: () => context.push('/payments'),
                      ),
                      const Divider(),
                      _MenuTile(
                        icon: Icons.notifications_rounded,
                        title: 'Notifications',
                        onTap: () => context.push('/profile/notifications'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.paddingM),

                // Logout
                AnimatedCard(
                  child: ListTile(
                    leading: const Icon(
                      Icons.logout_rounded,
                      color: AppTheme.deepRed,
                    ),
                    title: Text(
                      'Logout',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.deepRed,
                      ),
                    ),
                    onTap: () => _handleLogout(context, ref),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const LoadingWidget(),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.pop(context);
                context.go('/login');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.deepRed,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.paddingS),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: AppTheme.paddingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(
        icon,
        color: theme.colorScheme.primary,
      ),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
      onTap: onTap,
    );
  }
}
