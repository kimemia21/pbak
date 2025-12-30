import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/providers/auth_provider.dart';
import 'package:pbak/providers/member_provider.dart';
import 'package:intl/intl.dart';
import 'package:pbak/models/user_model.dart';
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
        data: (authUser) {
          if (authUser == null) {
            // If the user is logged out while still on this route, redirect to login.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) context.go('/login');
            });
            return const LoadingWidget(message: 'Redirecting...');
          }

          final profileAsync = ref.watch(memberByIdProvider(authUser.memberId));

          return profileAsync.when(
            data: (profile) {
              final user = profile ?? authUser;

              final dateFmt = DateFormat('MMM d, yyyy');
              final dateTimeFmt = DateFormat('MMM d, yyyy • HH:mm');

              String fmtDate(DateTime? d) => d == null ? '—' : dateFmt.format(d);
              String fmtDateTime(DateTime? d) => d == null ? '—' : dateTimeFmt.format(d);

              String textOrDash(String? v) => (v == null || v.trim().isEmpty) ? '—' : v;

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(memberByIdProvider(authUser.memberId));
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppTheme.paddingM),
                  child: Column(
                    children: [
                      // Header
                      AnimatedCard(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 52,
                              backgroundColor: theme.colorScheme.primary,
                              backgroundImage: user.profilePhotoUrl != null
                                  ? NetworkImage(user.profilePhotoUrl!)
                                  : null,
                              child: user.profilePhotoUrl == null
                                  ? Text(
                                      user.fullName.isNotEmpty
                                          ? user.fullName[0].toUpperCase()
                                          : 'U',
                                      style: theme.textTheme.displayMedium?.copyWith(
                                        color: theme.colorScheme.onPrimary,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(height: AppTheme.paddingM),
                            Text(
                              user.fullName,
                              style: theme.textTheme.headlineSmall,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.email,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.textTheme.bodySmall?.color,
                              ),
                            ),
                            const SizedBox(height: AppTheme.paddingS),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: [
                                _StatusChip(
                                  icon: user.isVerified
                                      ? Icons.verified_rounded
                                      : Icons.pending_rounded,
                                  label: user.isVerified
                                      ? 'Approved'
                                      : user.approvalStatus,
                                  color: user.isVerified
                                      ? AppTheme.goldAccent
                                      : AppTheme.mediumGrey,
                                ),
                                _StatusChip(
                                  icon: Icons.badge_rounded,
                                  label: user.membershipNumber,
                                  color: theme.colorScheme.primary,
                                ),
                                _StatusChip(
                                  icon: Icons.person_rounded,
                                  label: user.role,
                                  color: theme.colorScheme.primary,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppTheme.paddingM),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => context.push('/profile/edit'),
                                    icon: const Icon(Icons.edit_rounded),
                                    label: const Text('Edit Profile'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.paddingM),

                      // Contact
                      _SectionCard(
                        title: 'Contact',
                        icon: Icons.contact_phone_rounded,
                        child: Column(
                          children: [
                            _InfoTile(
                              icon: Icons.phone_rounded,
                              label: 'Phone',
                              value: textOrDash(user.phone),
                            ),
                            const Divider(),
                            _InfoTile(
                              icon: Icons.phone_android_rounded,
                              label: 'Alternative Phone',
                              value: textOrDash(user.alternativePhone),
                            ),
                            const Divider(),
                            _InfoTile(
                              icon: Icons.crisis_alert_rounded,
                              label: 'Emergency Contact',
                              value: textOrDash(user.emergencyContact),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.paddingM),

                      // Membership
                      _SectionCard(
                        title: 'Membership',
                        icon: Icons.card_membership_rounded,
                        child: Column(
                          children: [
                            _InfoTile(
                              icon: Icons.confirmation_number_rounded,
                              label: 'Membership Number',
                              value: user.membershipNumber,
                            ),
                            const Divider(),
                            _InfoTile(
                              icon: Icons.groups_rounded,
                              label: 'Club',
                              value: user.clubName ?? user.club?.clubName ?? '—',
                            ),
                            const Divider(),
                            _InfoTile(
                              icon: Icons.calendar_month_rounded,
                              label: 'Joined Date',
                              value: fmtDate(user.joinedDate),
                            ),
                            const Divider(),
                            _InfoTile(
                              icon: Icons.verified_user_rounded,
                              label: 'Approval Status',
                              value: user.approvalStatus,
                            ),
                            const Divider(),
                            _InfoTile(
                              icon: Icons.event_available_rounded,
                              label: 'Approval Date',
                              value: fmtDateTime(user.approvalDate),
                            ),
                            const Divider(),
                            _InfoTile(
                              icon: Icons.person_pin_rounded,
                              label: 'Approved By',
                              value: user.approver?.fullName ?? (user.approvedBy?.toString() ?? '—'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.paddingM),

                      // Identity
                      _SectionCard(
                        title: 'Identity',
                        icon: Icons.badge_rounded,
                        child: Column(
                          children: [
                            _InfoTile(
                              icon: Icons.credit_card_rounded,
                              label: 'National ID',
                              value: textOrDash(user.nationalId),
                            ),
                            const Divider(),
                            _InfoTile(
                              icon: Icons.card_membership_rounded,
                              label: 'Driving License No.',
                              value: textOrDash(user.drivingLicenseNumber),
                            ),
                            const Divider(),
                            _InfoTile(
                              icon: Icons.cake_rounded,
                              label: 'Date of Birth',
                              value: fmtDate(user.dateOfBirth),
                            ),
                            const Divider(),
                            _InfoTile(
                              icon: Icons.wc_rounded,
                              label: 'Gender',
                              value: textOrDash(user.gender),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.paddingM),

                      // Address
                      _SectionCard(
                        title: 'Address',
                        icon: Icons.location_on_rounded,
                        child: Column(
                          children: [
                            _InfoTile(
                              icon: Icons.route_rounded,
                              label: 'Road Name',
                              value: textOrDash(user.roadName),
                            ),
                            const Divider(),
                            _InfoTile(
                              icon: Icons.home_rounded,
                              label: 'Address Line 1',
                              value: textOrDash(user.addressLine1),
                            ),
                            const Divider(),
                            _InfoTile(
                              icon: Icons.home_work_rounded,
                              label: 'Address Line 2',
                              value: textOrDash(user.addressLine2),
                            ),
                            const Divider(),
                            _InfoTile(
                              icon: Icons.location_city_rounded,
                              label: 'City',
                              value: textOrDash(user.city),
                            ),
                            const Divider(),
                            _InfoTile(
                              icon: Icons.map_rounded,
                              label: 'State/Province',
                              value: textOrDash(user.stateProvince),
                            ),
                            const Divider(),
                            _InfoTile(
                              icon: Icons.markunread_mailbox_rounded,
                              label: 'Postal Code',
                              value: textOrDash(user.postalCode),
                            ),
                            const Divider(),
                            _InfoTile(
                              icon: Icons.flag_rounded,
                              label: 'Country',
                              value: textOrDash(user.country),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.paddingM),

                      // Work
                      _SectionCard(
                        title: 'Work',
                        icon: Icons.work_rounded,
                        child: Column(
                          children: [
                            _InfoTile(
                              icon: Icons.apartment_rounded,
                              label: 'Employer',
                              value: textOrDash(user.employer),
                            ),
                            const Divider(),
                            _InfoTile(
                              icon: Icons.business_center_rounded,
                              label: 'Industry',
                              value: textOrDash(user.industry),
                            ),
                            const Divider(),
                            _InfoTile(
                              icon: Icons.my_location_rounded,
                              label: 'Work Lat/Long',
                              value: textOrDash(user.workLatLong),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.paddingM),

                      // Medical
                      _SectionCard(
                        title: 'Medical',
                        icon: Icons.medical_services_rounded,
                        child: Column(
                          children: [
                            _InfoTile(
                              icon: Icons.bloodtype_rounded,
                              label: 'Blood Group',
                              value: textOrDash(user.bloodGroup),
                            ),
                            const Divider(),
                            _InfoTile(
                              icon: Icons.healing_rounded,
                              label: 'Allergies',
                              value: textOrDash(user.allergies),
                            ),
                            const Divider(),
                            _InfoTile(
                              icon: Icons.policy_rounded,
                              label: 'Medical Policy No.',
                              value: textOrDash(user.medicalPolicyNo),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.paddingM),

                      // Interests
                      _SectionCard(
                        title: 'Interests',
                        icon: Icons.interests_rounded,
                        child: _InterestChips(user: user),
                      ),
                      const SizedBox(height: AppTheme.paddingM),

                      // Bikes (summary)
                      _SectionCard(
                        title: 'Bikes',
                        icon: Icons.two_wheeler_rounded,
                        child: Column(
                          children: [
                            if (user.bikes.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: AppTheme.paddingS),
                                child: Text('No bikes found for this member.'),
                              )
                            else
                              ...user.bikes.map(
                                (b) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                                    child: Icon(
                                      Icons.two_wheeler_rounded,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  title: Text(b.registrationNumber ?? b.displayName),
                                  subtitle: Text(
                                    [
                                      if (b.color != null && b.color!.isNotEmpty) b.color,
                                      if (b.registrationExpiry != null)
                                        'Reg exp: ${fmtDate(b.registrationExpiry)}',
                                    ].whereType<String>().join(' • '),
                                  ),
                                ),
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

                      // Account
                      _SectionCard(
                        title: 'Account',
                        icon: Icons.manage_accounts_rounded,
                        child: Column(
                          children: [
                            _InfoTile(
                              icon: Icons.login_rounded,
                              label: 'Last Login',
                              value: fmtDateTime(user.lastLogin),
                            ),
                            const Divider(),
                            _InfoTile(
                              icon: Icons.toggle_on_rounded,
                              label: 'Active',
                              value: user.isActive ? 'Yes' : 'No',
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
                ),
              );
            },
            loading: () => const LoadingWidget(message: 'Loading profile...'),
            error: (error, stack) => Center(child: Text('Error: $error')),
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

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.paddingM),
          child,
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.paddingM,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _InterestChips extends StatelessWidget {
  final UserModel user;

  const _InterestChips({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final interests = <MapEntry<String, bool?>>[
      MapEntry('Safety Training', user.interestSafetyTraining),
      MapEntry('Association', user.interestAssociation),
      MapEntry('Biker Advocacy', user.interestBikerAdvocacy),
      MapEntry('Certification Training', user.interestCertTrain),
      MapEntry('Safety Workshops', user.interestSafetyWorkshops),
      MapEntry('Member Welfare', user.interestMemberWelfare),
      MapEntry('Legal Support', user.interestLegalSupport),
      MapEntry('Medical', user.interestMedical),
    ];

    final selected = interests.where((e) => e.value == true).map((e) => e.key).toList();

    if (selected.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.paddingS),
        child: Text(
          'No interests selected.',
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final name in selected)
          Chip(
            label: Text(name),
            backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
            side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.2)),
          ),
      ],
    );
  }
}
