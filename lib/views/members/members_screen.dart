import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/providers/member_provider.dart';
import 'package:pbak/widgets/loading_widget.dart';
import 'package:pbak/widgets/error_widget.dart';
import 'package:pbak/widgets/empty_state_widget.dart';
import 'package:pbak/widgets/animated_card.dart';

class MembersScreen extends ConsumerWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final membersAsync = ref.watch(membersProvider);
    final statsAsync = ref.watch(memberStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Members'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () {
              _showStatsDialog(context, statsAsync);
            },
            tooltip: 'Member Statistics',
          ),
        ],
      ),
      body: membersAsync.when(
        data: (members) {
          if (members.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.people_outline_rounded,
              title: 'No Members Yet',
              message: 'Be the first to join PBAK!',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(membersProvider);
            },
            child: Column(
              children: [
                // Stats Summary Card
                _buildStatsCard(context, statsAsync),
                // Members List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppTheme.paddingM),
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final member = members[index];
                      return AnimatedCard(
                        margin: const EdgeInsets.only(bottom: AppTheme.paddingM),
                        onTap: () => context.push('/members/${member.memberId}'),
                        child: Row(
                          children: [
                            // Avatar
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: theme.colorScheme.primary,
                              backgroundImage: member.profilePhotoUrl != null
                                  ? NetworkImage(member.profilePhotoUrl!)
                                  : null,
                              child: member.profilePhotoUrl == null
                                  ? Text(
                                      member.firstName.isNotEmpty
                                          ? member.firstName[0].toUpperCase()
                                          : 'M',
                                      style: theme.textTheme.headlineMedium?.copyWith(
                                        color: theme.colorScheme.onPrimary,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: AppTheme.paddingM),
                            // Member Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    member.fullName,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.badge_outlined,
                                        size: 14,
                                        color: theme.textTheme.bodySmall?.color,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          member.membershipNumber,
                                          style: theme.textTheme.bodySmall,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (member.clubName != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.groups_rounded,
                                          size: 14,
                                          color: theme.textTheme.bodySmall?.color,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            member.clubName!,
                                            style: theme.textTheme.bodySmall,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            // Status Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(member.approvalStatus)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                member.approvalStatus.toUpperCase(),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: _getStatusColor(member.approvalStatus),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const LoadingWidget(message: 'Loading members...'),
        error: (error, stack) => CustomErrorWidget(
          message: 'Failed to load members',
          onRetry: () => ref.invalidate(membersProvider),
        ),
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, AsyncValue<Map<String, dynamic>> statsAsync) {
    final theme = Theme.of(context);
    
    return statsAsync.when(
      data: (stats) {
        final totalMembers = stats['total'] ?? 0;
        final activeMembers = stats['active'] ?? 0;
        final pendingMembers = stats['pending'] ?? 0;
        
        return Container(
          margin: const EdgeInsets.all(AppTheme.paddingM),
          padding: const EdgeInsets.all(AppTheme.paddingM),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                context,
                'Total',
                totalMembers.toString(),
                Icons.people_rounded,
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.3),
              ),
              _buildStatItem(
                context,
                'Active',
                activeMembers.toString(),
                Icons.check_circle_rounded,
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.3),
              ),
              _buildStatItem(
                context,
                'Pending',
                pendingMembers.toString(),
                Icons.pending_rounded,
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 28,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white.withOpacity(0.9),
              ),
        ),
      ],
    );
  }

  void _showStatsDialog(BuildContext context, AsyncValue<Map<String, dynamic>> statsAsync) {
    statsAsync.when(
      data: (stats) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Member Statistics'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatRow('Total Members', stats['total'] ?? 0),
                _buildStatRow('Active Members', stats['active'] ?? 0),
                _buildStatRow('Pending Approval', stats['pending'] ?? 0),
                _buildStatRow('Inactive Members', stats['inactive'] ?? 0),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
      loading: () {},
      error: (_, __) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load statistics')),
        );
      },
    );
  }

  Widget _buildStatRow(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
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
