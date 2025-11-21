import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/providers/bike_provider.dart';
import 'package:pbak/widgets/loading_widget.dart';
import 'package:pbak/widgets/error_widget.dart';
import 'package:pbak/widgets/empty_state_widget.dart';
import 'package:pbak/widgets/custom_button.dart';
import 'package:intl/intl.dart';

class BikesScreen extends ConsumerStatefulWidget {
  const BikesScreen({super.key});

  @override
  ConsumerState<BikesScreen> createState() => _BikesScreenState();
}

class _BikesScreenState extends ConsumerState<BikesScreen> {
  String? expandedBikeId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bikesState = ref.watch(bikeNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bikes'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/bikes/add'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Bike'),
      ),
      body: bikesState.when(
        data: (bikes) {
          if (bikes.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.two_wheeler_rounded,
              title: 'No Bikes Added',
              message: 'Add your first motorcycle to get started!',
              action: CustomButton(
                text: 'Add Bike',
                icon: Icons.add_rounded,
                onPressed: () => context.push('/bikes/add'),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(bikeNotifierProvider.notifier).loadBikes();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(AppTheme.paddingM),
              itemCount: bikes.length,
              itemBuilder: (context, index) {
                final bike = bikes[index];
                final isExpanded = expandedBikeId == bike.bikeId?.toString();

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.only(bottom: AppTheme.paddingM),
                  child: Material(
                    elevation: isExpanded ? 8 : 2,
                    borderRadius: BorderRadius.circular(AppTheme.radiusL),
                    color: theme.colorScheme.surface,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          expandedBikeId = isExpanded ? null : bike.bikeId?.toString();
                        });
                      },
                      borderRadius: BorderRadius.circular(AppTheme.radiusL),
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.paddingM),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header - Always Visible
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(AppTheme.paddingM),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                                  ),
                                  child: Icon(
                                    Icons.two_wheeler_rounded,
                                    size: 40,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: AppTheme.paddingM),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        bike.displayName,
                                        style: theme.textTheme.titleLarge,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        bike.registrationNumber ?? 'N/A',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  isExpanded 
                                    ? Icons.expand_less_rounded 
                                    : Icons.expand_more_rounded,
                                  color: theme.colorScheme.primary,
                                ),
                              ],
                            ),

                            // Quick Info - Always Visible
                            const SizedBox(height: AppTheme.paddingM),
                            Wrap(
                              spacing: AppTheme.paddingM,
                              runSpacing: AppTheme.paddingS,
                              children: [
                                if (bike.bikeModel?.category != null)
                                  _Chip(
                                    icon: Icons.category_rounded,
                                    label: bike.bikeModel!.category!,
                                  ),
                                if (bike.yom != null)
                                  _Chip(
                                    icon: Icons.calendar_today_rounded,
                                    label: bike.yom!.year.toString(),
                                  ),
                                if (bike.color != null && bike.color!.isNotEmpty)
                                  _Chip(
                                    icon: Icons.palette_rounded,
                                    label: bike.color!,
                                  ),
                              ],
                            ),

                            // Expanded Details
                            AnimatedCrossFade(
                              firstChild: const SizedBox.shrink(),
                              secondChild: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: AppTheme.paddingM),
                                  const Divider(),
                                  const SizedBox(height: AppTheme.paddingM),
                                  
                                  Text(
                                    'Details',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: AppTheme.paddingM),
                                  
                                  _InfoRow(
                                    icon: Icons.settings_rounded,
                                    label: 'Engine Number',
                                    value: bike.engineNumber ?? 'N/A',
                                  ),
                                  const SizedBox(height: AppTheme.paddingS),
                                  _InfoRow(
                                    icon: Icons.tag_rounded,
                                    label: 'Chassis Number',
                                    value: bike.chassisNumber ?? 'N/A',
                                  ),
                                  const SizedBox(height: AppTheme.paddingS),
                                  _InfoRow(
                                    icon: Icons.speed_rounded,
                                    label: 'Odometer',
                                    value: bike.odometerReading ?? 'N/A',
                                  ),
                                  if (bike.insuranceExpiry != null) ...[
                                    const SizedBox(height: AppTheme.paddingS),
                                    _InfoRow(
                                      icon: Icons.shield_rounded,
                                      label: 'Insurance Expiry',
                                      value: DateFormat('MMM dd, yyyy').format(bike.insuranceExpiry!),
                                    ),
                                  ],
                                  if (bike.registrationExpiry != null) ...[
                                    const SizedBox(height: AppTheme.paddingS),
                                    _InfoRow(
                                      icon: Icons.description_rounded,
                                      label: 'Registration Expiry',
                                      value: DateFormat('MMM dd, yyyy').format(bike.registrationExpiry!),
                                    ),
                                  ],
                                  if (bike.createdAt != null) ...[
                                    const SizedBox(height: AppTheme.paddingS),
                                    _InfoRow(
                                      icon: Icons.event_rounded,
                                      label: 'Added',
                                      value: DateFormat('MMM dd, yyyy').format(bike.createdAt!),
                                    ),
                                  ],
                                  
                                  const SizedBox(height: AppTheme.paddingM),
                                  
                                  // Action Buttons
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () {
                                            // Edit bike action
                                            context.push('/bikes/edit/${bike.bikeId}', extra: bike);
                                          },
                                          icon: const Icon(Icons.edit_rounded, size: 18),
                                          label: const Text('Edit'),
                                        ),
                                      ),
                                      const SizedBox(width: AppTheme.paddingS),
                                      Expanded(
                                        child: FilledButton.icon(
                                          onPressed: () {
                                            // View details action
                                            context.push('/bikes/${bike.bikeId}');
                                          },
                                          icon: const Icon(Icons.visibility_rounded, size: 18),
                                          label: const Text('View'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              crossFadeState: isExpanded
                                  ? CrossFadeState.showSecond
                                  : CrossFadeState.showFirst,
                              duration: const Duration(milliseconds: 300),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const LoadingWidget(message: 'Loading bikes...'),
        error: (error, stack) => CustomErrorWidget(
          message: 'Failed to load bikes',
          onRetry: () => ref.read(bikeNotifierProvider.notifier).loadBikes(),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Chip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: theme.colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.textTheme.bodySmall?.color,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}