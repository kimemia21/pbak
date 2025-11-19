import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/providers/sos_provider.dart';
import 'package:pbak/widgets/loading_widget.dart';
import 'package:pbak/widgets/error_widget.dart';
import 'package:pbak/widgets/empty_state_widget.dart';
import 'package:pbak/widgets/animated_card.dart';
import 'package:intl/intl.dart';

class SOSScreen extends ConsumerWidget {
  const SOSScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sosAsync = ref.watch(sosAlertsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS Alerts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
            tooltip: 'SOS Information',
          ),
        ],
      ),
      body: sosAsync.when(
        data: (alerts) {
          if (alerts.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.crisis_alert_rounded,
              title: 'No SOS Alerts',
              message: 'You haven\'t sent any emergency alerts yet.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(sosAlertsProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(AppTheme.paddingM),
              itemCount: alerts.length,
              itemBuilder: (context, index) {
                final sos = alerts[index];
                return AnimatedCard(
                  margin: const EdgeInsets.only(bottom: AppTheme.paddingM),
                  onTap: () => context.push('/sos/${sos.id}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with type and status
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _getTypeColor(sos.type).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _getTypeIcon(sos.type),
                              color: _getTypeColor(sos.type),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: AppTheme.paddingM),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getTypeLabel(sos.type),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  DateFormat('MMM dd, yyyy • HH:mm').format(sos.timestamp),
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          _buildStatusChip(sos.status, theme),
                        ],
                      ),
                      const SizedBox(height: AppTheme.paddingM),

                      // Description
                      if (sos.notes.isNotEmpty) ...[
                        Text(
                          sos.notes,
                          style: theme.textTheme.bodyMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppTheme.paddingS),
                      ],

                      // Location
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${sos.latitude.toStringAsFixed(6)}, ${sos.longitude.toStringAsFixed(6)}',
                              style: theme.textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
        loading: () => const LoadingWidget(message: 'Loading SOS alerts...'),
        error: (error, stack) => CustomErrorWidget(
          message: 'Failed to load SOS alerts',
          onRetry: () => ref.invalidate(sosAlertsProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/sos/send'),
        icon: const Icon(Icons.add_alert_rounded),
        label: const Text('Send SOS'),
        backgroundColor: AppTheme.brightRed,
      ),
    );
  }

  Widget _buildStatusChip(String status, ThemeData theme) {
    Color color;
    String label;

    switch (status.toLowerCase()) {
      case 'active':
      case 'pending':
        color = Colors.orange;
        label = 'Active';
        break;
      case 'resolved':
      case 'completed':
        color = Colors.green;
        label = 'Resolved';
        break;
      case 'cancelled':
        color = Colors.grey;
        label = 'Cancelled';
        break;
      default:
        color = Colors.blue;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
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

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('SOS Alert Types'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoItem('Accident', 'For motorcycle accidents or collisions'),
            _buildInfoItem('Breakdown', 'When your bike breaks down'),
            _buildInfoItem('Medical', 'For medical emergencies'),
            _buildInfoItem('Security', 'For security threats or theft'),
            _buildInfoItem('Other', 'For any other emergency situation'),
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
  }

  Widget _buildInfoItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            description,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
