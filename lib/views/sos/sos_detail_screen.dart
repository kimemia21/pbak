import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/providers/sos_provider.dart';
import 'package:pbak/widgets/loading_widget.dart';
import 'package:pbak/widgets/error_widget.dart';
import 'package:intl/intl.dart';

class SOSDetailScreen extends ConsumerWidget {
  final String sosId;

  const SOSDetailScreen({
    super.key,
    required this.sosId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sosAsync = ref.watch(sosByIdProvider(int.parse(sosId)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS Alert Details'),
        backgroundColor: AppTheme.brightRed,
        foregroundColor: Colors.white,
      ),
      body: sosAsync.when(
        data: (sos) {
          if (sos == null) {
            return const Center(
              child: Text('SOS alert not found'),
            );
          }

          final canCancel = sos.status.toLowerCase() == 'active' ||
              sos.status.toLowerCase() == 'pending';

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(sosByIdProvider(int.parse(sosId)));
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.paddingM),
              child: Column(
                children: [
                  // Status Header
                  _buildStatusCard(context, sos),
                  const SizedBox(height: AppTheme.paddingL),

                  // Alert Information
                  _buildSectionCard(
                    context,
                    'Alert Information',
                    Icons.info_outline_rounded,
                    [
                      _buildInfoRow('Type', _getTypeLabel(sos.type)),
                      _buildInfoRow('Status', sos.status.toUpperCase()),
                      _buildInfoRow(
                        'Timestamp',
                        DateFormat('MMM dd, yyyy • HH:mm').format(sos.timestamp),
                      ),
                      if (sos.responseTime != null)
                        _buildInfoRow(
                          'Response Time',
                          DateFormat('MMM dd, yyyy • HH:mm').format(sos.responseTime!),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.paddingM),

                  // Description
                  if (sos.notes.isNotEmpty) ...[
                    _buildSectionCard(
                      context,
                      'Notes',
                      Icons.description_outlined,
                      [
                        Text(
                          sos.notes,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.paddingM),
                  ],

                  // Location
                  _buildSectionCard(
                    context,
                    'Location',
                    Icons.location_on_outlined,
                    [
                      _buildInfoRow('Latitude', sos.latitude.toStringAsFixed(6)),
                      _buildInfoRow('Longitude', sos.longitude.toStringAsFixed(6)),
                      const SizedBox(height: AppTheme.paddingM),
                      ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Open in maps
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Opening in maps...'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.map_rounded),
                        label: const Text('View on Map'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.paddingM),

                  // Actions
                  if (canCancel) ...[
                    const SizedBox(height: AppTheme.paddingL),
                    OutlinedButton.icon(
                      onPressed: () => _showCancelDialog(context, ref),
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Cancel SOS Alert'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.brightRed,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
        loading: () => const LoadingWidget(message: 'Loading SOS details...'),
        error: (error, stack) => CustomErrorWidget(
          message: 'Failed to load SOS details',
          onRetry: () => ref.invalidate(sosByIdProvider(int.parse(sosId))),
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, sos) {
    final theme = Theme.of(context);
    final color = _getStatusColor(sos.status);

    return Card(
      elevation: 0,
      color: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingL),
        child: Column(
          children: [
            Icon(
              _getTypeIcon(sos.type),
              size: 60,
              color: color,
            ),
            const SizedBox(height: AppTheme.paddingM),
            Text(
              _getTypeLabel(sos.type),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                sos.status.toUpperCase(),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
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

  Widget _buildInfoRow(String label, String value) {
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
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'pending':
        return Colors.orange;
      case 'resolved':
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'accident':
        return AppTheme.brightRed;
      case 'breakdown':
        return Colors.orange;
      case 'medical':
        return Colors.red;
      case 'security':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'accident':
        return Icons.car_crash_rounded;
      case 'breakdown':
        return Icons.build_circle_rounded;
      case 'medical':
        return Icons.medical_services_rounded;
      case 'security':
        return Icons.security_rounded;
      default:
        return Icons.crisis_alert_rounded;
    }
  }

  String _getTypeLabel(String type) {
    return type[0].toUpperCase() + type.substring(1).toLowerCase();
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel SOS Alert'),
        content: const Text('Are you sure you want to cancel this emergency alert?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref
                  .read(sosNotifierProvider.notifier)
                  .cancelSOS(int.parse(sosId));

              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('SOS alert cancelled successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
                context.pop();
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to cancel SOS alert'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.brightRed),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }
}
