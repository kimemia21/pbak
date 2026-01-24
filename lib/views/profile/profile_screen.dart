import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/providers/auth_provider.dart';
import 'package:pbak/providers/member_provider.dart';
import 'package:intl/intl.dart';
import 'package:pbak/models/user_model.dart';
import 'package:pbak/widgets/loading_widget.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF8F9FA),
      body: authState.when(
        data: (authUser) {
          if (authUser == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) context.go('/login');
            });
            return const LoadingWidget(message: 'Redirecting...');
          }

          final profileAsync = ref.watch(memberByIdProvider(authUser.memberId));

          return profileAsync.when(
            data: (profile) {
              final user = profile ?? authUser;
              return _ProfileContent(user: user, isDark: isDark);
            },
            loading: () => const LoadingWidget(message: 'Loading profile...'),
            error: (e, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppTheme.deepRed),
                  const SizedBox(height: 16),
                  Text('Failed to load profile', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => ref.invalidate(memberByIdProvider(authUser.memberId)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const LoadingWidget(message: 'Loading...'),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  final UserModel user;
  final bool isDark;

  const _ProfileContent({required this.user, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat('MMM d, yyyy');

    String fmtDate(DateTime? d) => d == null ? '—' : dateFmt.format(d);
    String textOrDash(String? v) => (v == null || v.trim().isEmpty) ? '—' : v;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Hero App Bar
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          backgroundColor: isDark ? const Color(0xFF1A1A1A) : theme.colorScheme.primary,
          actions: [
            _ActionButton(
              icon: Icons.edit_rounded,
              onTap: () => context.push('/profile/edit'),
              tooltip: 'Edit Profile',
            ),
            _ActionButton(
              icon: Icons.settings_rounded,
              onTap: () => context.push('/profile/settings'),
              tooltip: 'Settings',
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF2D2D2D), const Color(0xFF1A1A1A)]
                      : [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.8)],
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    // Avatar
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.3), width: 3),
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        backgroundImage: user.profilePhotoUrl != null
                            ? NetworkImage(user.profilePhotoUrl!)
                            : null,
                        child: user.profilePhotoUrl == null
                            ? Text(
                                user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                                style: theme.textTheme.headlineLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Name
                    Text(
                      user.displayName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Email
                    Text(
                      user.email,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    if (user.nickname != null && user.nickname!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '@${user.nickname}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    // Status Chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        _StatusChip(
                          icon: user.isVerified ? Icons.verified_rounded : Icons.pending_rounded,
                          label: user.isVerified ? 'Verified' : user.approvalStatus,
                          color: user.isVerified ? AppTheme.successGreen : AppTheme.warningOrange,
                        ),
                        _StatusChip(
                          icon: Icons.badge_rounded,
                          label: user.membershipNumber,
                          color: AppTheme.goldAccent,
                        ),
                      ],
                    ),
                  ],
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
              children: [
                // Quick Info Card
                _QuickInfoCard(user: user, isDark: isDark),
                const SizedBox(height: 20),

                // Contact Section
                _SectionCard(
                  title: 'Contact Information',
                  icon: Icons.contact_phone_rounded,
                  isDark: isDark,
                  children: [
                    _InfoRow(icon: Icons.phone_rounded, label: 'Phone', value: textOrDash(user.phone)),
                    _InfoRow(icon: Icons.phone_android_rounded, label: 'Alt. Phone', value: textOrDash(user.alternativePhone)),
                    _InfoRow(icon: Icons.emergency_rounded, label: 'Emergency', value: textOrDash(user.emergencyContact), isImportant: true),
                  ],
                ),
                const SizedBox(height: 16),

                // Membership Section
                _SectionCard(
                  title: 'Membership Details',
                  icon: Icons.card_membership_rounded,
                  isDark: isDark,
                  children: [
                    _InfoRow(icon: Icons.confirmation_number_rounded, label: 'Member ID', value: user.membershipNumber),
                    _InfoRow(icon: Icons.groups_rounded, label: 'Club', value: user.clubName ?? user.club?.clubName ?? '—'),
                    _InfoRow(icon: Icons.calendar_month_rounded, label: 'Joined', value: fmtDate(user.joinedDate)),
                    _InfoRow(icon: Icons.verified_user_rounded, label: 'Status', value: user.approvalStatus),
                  ],
                ),
                const SizedBox(height: 16),

                // Identity Section
                _SectionCard(
                  title: 'Identity',
                  icon: Icons.badge_rounded,
                  isDark: isDark,
                  children: [
                    _InfoRow(icon: Icons.credit_card_rounded, label: 'National ID', value: textOrDash(user.nationalId)),
                    _InfoRow(icon: Icons.drive_eta_rounded, label: 'License No.', value: textOrDash(user.drivingLicenseNumber)),
                    _InfoRow(icon: Icons.cake_rounded, label: 'Date of Birth', value: fmtDate(user.dateOfBirth)),
                    _InfoRow(icon: Icons.person_rounded, label: 'Gender', value: textOrDash(user.gender)),
                  ],
                ),
                const SizedBox(height: 16),

                // Address Section
                _SectionCard(
                  title: 'Address',
                  icon: Icons.location_on_rounded,
                  isDark: isDark,
                  children: [
                    if (user.roadName != null && user.roadName!.isNotEmpty)
                      _InfoRow(icon: Icons.route_rounded, label: 'Road', value: user.roadName!),
                    _InfoRow(icon: Icons.home_rounded, label: 'Address', value: textOrDash(user.addressLine1)),
                    _InfoRow(icon: Icons.location_city_rounded, label: 'City', value: textOrDash(user.city)),
                    _InfoRow(icon: Icons.flag_rounded, label: 'Country', value: textOrDash(user.country)),
                  ],
                ),
                const SizedBox(height: 16),

                // Medical Section
                _SectionCard(
                  title: 'Medical Information',
                  icon: Icons.medical_information_rounded,
                  isDark: isDark,
                  children: [
                    _InfoRow(icon: Icons.bloodtype_rounded, label: 'Blood Group', value: textOrDash(user.bloodGroup), isImportant: true),
                    _InfoRow(icon: Icons.warning_rounded, label: 'Allergies', value: textOrDash(user.allergies)),
                    _InfoRow(icon: Icons.medical_services_rounded, label: 'Medical Policy', value: textOrDash(user.medicalPolicyNo)),
                  ],
                ),
                const SizedBox(height: 16),

                // Work Section
                if (user.employer != null || user.industry != null)
                  _SectionCard(
                    title: 'Work',
                    icon: Icons.work_rounded,
                    isDark: isDark,
                    children: [
                      _InfoRow(icon: Icons.apartment_rounded, label: 'Employer', value: textOrDash(user.employer)),
                      _InfoRow(icon: Icons.business_center_rounded, label: 'Industry', value: textOrDash(user.industry)),
                    ],
                  ),
                const SizedBox(height: 32),

                // Edit Profile Button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => context.push('/profile/edit'),
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Edit Profile'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Action Button for App Bar
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  const _ActionButton({required this.icon, required this.onTap, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

// Status Chip
class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// Quick Info Card
class _QuickInfoCard extends StatelessWidget {
  final UserModel user;
  final bool isDark;

  const _QuickInfoCard({required this.user, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.goldAccent, AppTheme.darkGold],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.goldAccent.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _QuickStat(
              icon: Icons.two_wheeler_rounded,
              label: 'Bikes',
              value: '${user.bikes.length}',
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.3),
          ),
          Expanded(
            child: _QuickStat(
              icon: Icons.groups_rounded,
              label: 'Club',
              value: user.clubName ?? user.club?.clubName ?? 'None',
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.3),
          ),
          Expanded(
            child: _QuickStat(
              icon: Icons.bloodtype_rounded,
              label: 'Blood',
              value: user.bloodGroup ?? '—',
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _QuickStat({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

// Section Card
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isDark;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.isDark,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 20, color: colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.1)),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

// Info Row
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isImportant;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isImportant = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 18, color: isImportant ? AppTheme.deepRed : Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isImportant ? AppTheme.deepRed : null,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
