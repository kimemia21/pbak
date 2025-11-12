import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/providers/bike_provider.dart';
import 'package:pbak/widgets/loading_widget.dart';
import 'package:pbak/widgets/error_widget.dart';
import 'package:pbak/widgets/empty_state_widget.dart';
import 'package:pbak/widgets/animated_card.dart';
import 'package:pbak/widgets/custom_button.dart';

class BikesScreen extends ConsumerWidget {
  const BikesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                return AnimatedCard(
                  margin: const EdgeInsets.only(bottom: AppTheme.paddingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                                  '${bike.make} ${bike.model}',
                                  style: theme.textTheme.titleLarge,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  bike.registrationNumber,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.paddingM),
                      const Divider(),
                      const SizedBox(height: AppTheme.paddingS),
                      _InfoRow(
                        icon: Icons.category_rounded,
                        label: 'Type',
                        value: bike.type,
                      ),
                      const SizedBox(height: AppTheme.paddingS),
                      _InfoRow(
                        icon: Icons.calendar_today_rounded,
                        label: 'Year',
                        value: bike.year.toString(),
                      ),
                      if (bike.color != null) ...[
                        const SizedBox(height: AppTheme.paddingS),
                        _InfoRow(
                          icon: Icons.palette_rounded,
                          label: 'Color',
                          value: bike.color!,
                        ),
                      ],
                      const SizedBox(height: AppTheme.paddingS),
                      _InfoRow(
                        icon: Icons.settings_rounded,
                        label: 'Engine',
                        value: bike.engineNumber,
                      ),
                    ],
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
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.textTheme.bodySmall?.color,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall,
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
