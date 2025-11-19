import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/providers/bike_provider.dart';
import 'package:pbak/widgets/loading_widget.dart';
import 'package:pbak/widgets/error_widget.dart';
import 'package:intl/intl.dart';

class BikeDetailScreen extends ConsumerWidget {
  final String bikeId;

  const BikeDetailScreen({
    super.key,
    required this.bikeId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final bikeAsync = ref.watch(bikeByIdProvider(int.parse(bikeId)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bike Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              context.push('/bikes/edit/$bikeId');
            },
            tooltip: 'Edit Bike',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _showDeleteDialog(context, ref),
            tooltip: 'Delete Bike',
          ),
        ],
      ),
      body: bikeAsync.when(
        data: (bike) {
          if (bike == null) {
            return const Center(
              child: Text('Bike not found'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(bikeByIdProvider(int.parse(bikeId)));
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.paddingM),
              child: Column(
                children: [
                  // Bike Image Card
                  _buildImageCard(context, bike),
                  const SizedBox(height: AppTheme.paddingL),

                  // Basic Information
                  _buildSectionCard(
                    context,
                    'Basic Information',
                    Icons.info_outline_rounded,
                    [
                      _buildInfoRow('Make', bike.make),
                      _buildInfoRow('Model', bike.model),
                      _buildInfoRow('Type', bike.type),
                      _buildInfoRow('Year', bike.year.toString()),
                      _buildInfoRow('Color', bike.color ?? 'N/A'),
                    ],
                  ),
                  const SizedBox(height: AppTheme.paddingM),

                  // Registration Details
                  _buildSectionCard(
                    context,
                    'Registration Details',
                    Icons.confirmation_number_rounded,
                    [
                      _buildInfoRow('Registration Number', bike.registrationNumber),
                      _buildInfoRow('Engine Number', bike.engineNumber),
                      _buildInfoRow('User ID', bike.userId),
                      if (bike.linkedPackageId != null)
                        _buildInfoRow('Linked Package', bike.linkedPackageId!),
                    ],
                  ),
                  const SizedBox(height: AppTheme.paddingM),

                  // Timestamps
                  _buildSectionCard(
                    context,
                    'Record Information',
                    Icons.access_time_rounded,
                    [
                      _buildInfoRow(
                        'Added Date',
                        DateFormat('MMM dd, yyyy HH:mm').format(bike.addedDate),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const LoadingWidget(message: 'Loading bike details...'),
        error: (error, stack) => CustomErrorWidget(
          message: 'Failed to load bike details',
          onRetry: () => ref.invalidate(bikeByIdProvider(int.parse(bikeId))),
        ),
      ),
    );
  }

  Widget _buildImageCard(BuildContext context, bike) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.primary.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withOpacity(0.8),
              theme.colorScheme.primary,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.two_wheeler_rounded,
              size: 80,
              color: theme.colorScheme.onPrimary,
            ),
            const SizedBox(height: AppTheme.paddingM),
            Text(
              '${bike.make} ${bike.model}',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              bike.registrationNumber,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onPrimary.withOpacity(0.9),
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


  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bike'),
        content: const Text('Are you sure you want to delete this bike? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref
                  .read(bikeNotifierProvider.notifier)
                  .deleteBike(int.parse(bikeId));

              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Bike deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
                context.go('/bikes');
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to delete bike'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
