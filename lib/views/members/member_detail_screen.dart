import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/providers/member_provider.dart';
import 'package:pbak/widgets/loading_widget.dart';
import 'package:pbak/widgets/error_widget.dart';
import 'package:intl/intl.dart';

class MemberDetailScreen extends ConsumerWidget {
  final String memberId;

  const MemberDetailScreen({
    super.key,
    required this.memberId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final memberAsync = ref.watch(memberByIdProvider(int.parse(memberId)));

    return Scaffold(
      body: memberAsync.when(
        data: (member) {
          if (member == null) {
            return const Center(
              child: Text('Member not found'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(memberByIdProvider(int.parse(memberId)));
            },
            child: CustomScrollView(
              slivers: [
                // Custom App Bar with Hero Image
                _buildSliverAppBar(context, member),
                
                // Content
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      // Profile Header Card (overlapping)
                      Transform.translate(
                        offset: const Offset(0, -30),
                        child: _buildProfileCard(context, member),
                      ),
                      
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppTheme.paddingM,
                          0,
                          AppTheme.paddingM,
                          AppTheme.paddingM,
                        ),
                        child: Column(
                          children: [
                            // Quick Stats
                            _buildQuickStats(context, member),
                            const SizedBox(height: AppTheme.paddingL),

                            // Personal Information
                            _buildModernSectionCard(
                              context,
                              'Personal Information',
                              Icons.person_outline_rounded,
                              [
                                _buildModernInfoTile(context, Icons.badge_outlined, 'Full Name', member.fullName),
                                _buildModernInfoTile(context, Icons.email_outlined, 'Email', member.email),
                                _buildModernInfoTile(context, Icons.phone_outlined, 'Phone', member.phone ?? 'N/A'),
                                if (member.alternativePhone != null)
                                  _buildModernInfoTile(context, Icons.phone_android_outlined, 'Alt. Phone', member.alternativePhone!),
                                _buildModernInfoTile(context, Icons.wc_outlined, 'Gender', member.gender ?? 'N/A'),
                                if (member.dateOfBirth != null)
                                  _buildModernInfoTile(
                                    context,
                                    Icons.cake_outlined,
                                    'Date of Birth',
                                    DateFormat('MMM dd, yyyy').format(member.dateOfBirth!),
                                  ),
                              ],
                            ),
                            const SizedBox(height: AppTheme.paddingM),

                            // Membership Information
                            _buildModernSectionCard(
                              context,
                              'Membership Details',
                              Icons.card_membership_outlined,
                              [
                                _buildModernInfoTile(context, Icons.numbers_outlined, 'Membership No.', member.membershipNumber),
                                _buildModernInfoTile(context, Icons.admin_panel_settings_outlined, 'Role', member.role),
                                _buildStatusTile(context, member.approvalStatus),
                                if (member.clubName != null)
                                  _buildModernInfoTile(context, Icons.groups_outlined, 'Club', member.clubName!),
                                if (member.joinedDate != null)
                                  _buildModernInfoTile(
                                    context,
                                    Icons.event_outlined,
                                    'Joined Date',
                                    DateFormat('MMM dd, yyyy').format(member.joinedDate!),
                                  ),
                              ],
                            ),
                            const SizedBox(height: AppTheme.paddingM),

                            // Identification
                            _buildModernSectionCard(
                              context,
                              'Identification',
                              Icons.fingerprint_outlined,
                              [
                                _buildModernInfoTile(context, Icons.credit_card_outlined, 'National ID', member.nationalId ?? 'N/A'),
                                _buildModernInfoTile(context, Icons.two_wheeler_outlined, 'Driving License', member.drivingLicenseNumber ?? 'N/A'),
                              ],
                            ),
                            const SizedBox(height: AppTheme.paddingM),

                            // Medical Information
                            _buildModernSectionCard(
                              context,
                              'Medical Information',
                              Icons.medical_services_outlined,
                              [
                                _buildModernInfoTile(context, Icons.water_drop_outlined, 'Blood Group', member.bloodGroup ?? 'N/A'),
                                _buildModernInfoTile(context, Icons.warning_amber_outlined, 'Allergies', member.allergies ?? 'None'),
                                _buildModernInfoTile(context, Icons.health_and_safety_outlined, 'Medical Policy', member.medicalPolicyNo ?? 'N/A'),
                                _buildModernInfoTile(context, Icons.contact_phone_outlined, 'Emergency Contact', member.emergencyContact ?? 'N/A'),
                              ],
                            ),
                            const SizedBox(height: AppTheme.paddingM),

                            // Address Information
                            _buildModernSectionCard(
                              context,
                              'Address',
                              Icons.location_on_outlined,
                              [
                                _buildModernInfoTile(context, Icons.signpost_outlined, 'Road Name', member.roadName ?? 'N/A'),
                                _buildModernInfoTile(context, Icons.home_outlined, 'Estate ID', member.estateId?.toString() ?? 'N/A'),
                              ],
                            ),
                            const SizedBox(height: AppTheme.paddingM),

                            // Account Timeline
                            _buildTimelineCard(context, member),
                            
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const LoadingWidget(message: 'Loading member details...'),
        error: (error, stack) => CustomErrorWidget(
          message: 'Failed to load member details',
          onRetry: () => ref.invalidate(memberByIdProvider(int.parse(memberId))),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Edit feature coming soon')),
          );
        },
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Edit Profile'),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, member) {
    final theme = Theme.of(context);
    
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Gradient background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            // Pattern overlay
            Positioned.fill(
              child: Opacity(
                opacity: 0.1,
                child: CustomPaint(
                  painter: _TireTreadPainter(),
                ),
              ),
            ),
            // Dark overlay at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 100,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, member) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingM),
      child: Card(
        elevation: 8,
        shadowColor: theme.colorScheme.primary.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.paddingL),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.surface,
                theme.colorScheme.surface.withOpacity(0.8),
              ],
            ),
          ),
          child: Column(
            children: [
              // Avatar with status ring
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor: theme.colorScheme.surface,
                      backgroundImage: member.profilePhotoUrl != null
                          ? NetworkImage(member.profilePhotoUrl!)
                          : null,
                      child: member.profilePhotoUrl == null
                          ? Text(
                              member.firstName.isNotEmpty
                                  ? member.firstName[0].toUpperCase()
                                  : 'M',
                              style: theme.textTheme.headlineLarge?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                  ),
                  // Active status indicator
                  if (member.isActive)
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.surface,
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppTheme.paddingM),
              
              Text(
                member.fullName,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                member.email,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.paddingM),
              
              // Status badges
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStatusChip(
                    context,
                    member.membershipNumber,
                    Icons.badge_outlined,
                    theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  _buildStatusChip(
                    context,
                    member.approvalStatus.toUpperCase(),
                    Icons.verified_user_outlined,
                    _getStatusColor(member.approvalStatus),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, member) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            Icons.two_wheeler_outlined,
            'Member Since',
            member.joinedDate != null
                ? DateFormat('yyyy').format(member.joinedDate!)
                : 'N/A',
            theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: AppTheme.paddingM),
        Expanded(
          child: _buildStatCard(
            context,
            Icons.timeline_outlined,
            'Status',
            member.isActive ? 'Active' : 'Inactive',
            member.isActive ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, IconData icon, String label, String value, Color color) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildModernSectionCard(
    BuildContext context,
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shadowColor: theme.colorScheme.primary.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surface.withOpacity(0.95),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.paddingM),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppTheme.paddingM),
              child: Column(
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernInfoTile(BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 18,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTile(BuildContext context, String status) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(status);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.check_circle_outline,
              size: 18,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      status.toUpperCase(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(BuildContext context, member) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      shadowColor: theme.colorScheme.primary.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.history_outlined,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Account Timeline',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.paddingM),
            _buildTimelineItem(
              context,
              Icons.person_add_outlined,
              'Account Created',
              DateFormat('MMM dd, yyyy · HH:mm').format(member.createdAt),
              Colors.blue,
            ),
            if (member.lastLogin != null)
              _buildTimelineItem(
                context,
                Icons.login_outlined,
                'Last Login',
                DateFormat('MMM dd, yyyy · HH:mm').format(member.lastLogin!),
                Colors.green,
              ),
            _buildTimelineItem(
              context,
              Icons.update_outlined,
              'Last Updated',
              DateFormat('MMM dd, yyyy · HH:mm').format(member.updatedAt),
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(BuildContext context, IconData icon, String title, String time, Color color) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

// Custom painter for motorcycle tire tread pattern
class _TireTreadPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final spacing = 30.0;
    final angle = 0.5;

    for (double i = 0; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i - size.height * angle, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}