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
      appBar: AppBar(
        title: const Text('Member Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              // Navigate to edit member screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edit feature coming soon')),
              );
            },
          ),
        ],
      ),
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.paddingM),
              child: Column(
                children: [
                  // Profile Header
                  _buildProfileHeader(context, member),
                  const SizedBox(height: AppTheme.paddingL),

                  // Personal Information
                  _buildSectionCard(
                    context,
                    'Personal Information',
                    Icons.person_outline_rounded,
                    [
                      _buildInfoRow('Full Name', member.fullName),
                      _buildInfoRow('Email', member.email),
                      _buildInfoRow('Phone', member.phone ?? 'N/A'),
                      _buildInfoRow('Alternative Phone', member.alternativePhone ?? 'N/A'),
                      _buildInfoRow('Gender', member.gender ?? 'N/A'),
                      if (member.dateOfBirth != null)
                        _buildInfoRow(
                          'Date of Birth',
                          DateFormat('MMM dd, yyyy').format(member.dateOfBirth!),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.paddingM),

                  // Membership Information
                  _buildSectionCard(
                    context,
                    'Membership Details',
                    Icons.badge_outlined,
                    [
                      _buildInfoRow('Membership Number', member.membershipNumber),
                      _buildInfoRow('Role', member.role),
                      _buildInfoRow('Status', member.approvalStatus.toUpperCase()),
                      if (member.clubName != null)
                        _buildInfoRow('Club', member.clubName!),
                      if (member.joinedDate != null)
                        _buildInfoRow(
                          'Joined Date',
                          DateFormat('MMM dd, yyyy').format(member.joinedDate!),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.paddingM),

                  // Identification
                  _buildSectionCard(
                    context,
                    'Identification',
                    Icons.credit_card_rounded,
                    [
                      _buildInfoRow('National ID', member.nationalId ?? 'N/A'),
                      _buildInfoRow('Driving License', member.drivingLicenseNumber ?? 'N/A'),
                    ],
                  ),
                  const SizedBox(height: AppTheme.paddingM),

                  // Medical Information
                  _buildSectionCard(
                    context,
                    'Medical Information',
                    Icons.medical_services_outlined,
                    [
                      _buildInfoRow('Blood Group', member.bloodGroup ?? 'N/A'),
                      _buildInfoRow('Allergies', member.allergies ?? 'None'),
                      _buildInfoRow('Medical Policy No.', member.medicalPolicyNo ?? 'N/A'),
                      _buildInfoRow('Emergency Contact', member.emergencyContact ?? 'N/A'),
                    ],
                  ),
                  const SizedBox(height: AppTheme.paddingM),

                  // Address Information
                  _buildSectionCard(
                    context,
                    'Address',
                    Icons.location_on_outlined,
                    [
                      _buildInfoRow('Road Name', member.roadName ?? 'N/A'),
                      _buildInfoRow('Estate ID', member.estateId?.toString() ?? 'N/A'),
                    ],
                  ),
                  const SizedBox(height: AppTheme.paddingM),

                  // Account Status
                  _buildSectionCard(
                    context,
                    'Account Status',
                    Icons.info_outline_rounded,
                    [
                      _buildInfoRow(
                        'Active',
                        member.isActive ? 'Yes' : 'No',
                        valueColor: member.isActive ? Colors.green : Colors.red,
                      ),
                      if (member.lastLogin != null)
                        _buildInfoRow(
                          'Last Login',
                          DateFormat('MMM dd, yyyy HH:mm').format(member.lastLogin!),
                        ),
                      _buildInfoRow(
                        'Created At',
                        DateFormat('MMM dd, yyyy').format(member.createdAt),
                      ),
                      _buildInfoRow(
                        'Updated At',
                        DateFormat('MMM dd, yyyy').format(member.updatedAt),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const LoadingWidget(message: 'Loading member details...'),
        error: (error, stack) => CustomErrorWidget(
          message: 'Failed to load member details',
          onRetry: () => ref.invalidate(memberByIdProvider(int.parse(memberId))),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, member) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.primary.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingL),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: theme.colorScheme.primary,
              backgroundImage: member.profilePhotoUrl != null
                  ? NetworkImage(member.profilePhotoUrl!)
                  : null,
              child: member.profilePhotoUrl == null
                  ? Text(
                      member.firstName.isNotEmpty
                          ? member.firstName[0].toUpperCase()
                          : 'M',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: theme.colorScheme.onPrimary,
                      ),
                    )
                  : null,
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
                color: theme.textTheme.bodySmall?.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.paddingM),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                Chip(
                  avatar: Icon(
                    Icons.badge,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  label: Text(member.membershipNumber),
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                ),
                Chip(
                  avatar: Icon(
                    Icons.verified_user,
                    size: 16,
                    color: _getStatusColor(member.approvalStatus),
                  ),
                  label: Text(member.approvalStatus.toUpperCase()),
                  backgroundColor: _getStatusColor(member.approvalStatus).withOpacity(0.1),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context,
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.dividerColor,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.paddingM),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: valueColor,
              ),
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
