import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/providers/service_provider.dart';
import 'package:pbak/widgets/loading_widget.dart';
import 'package:pbak/widgets/error_widget.dart';
import 'package:pbak/widgets/empty_state_widget.dart';
import 'package:pbak/widgets/animated_card.dart';

class ServicesScreen extends ConsumerWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final servicesAsync = ref.watch(servicesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Providers'),
      ),
      body: servicesAsync.when(
        data: (services) {
          if (services.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.build_rounded,
              title: 'No Services',
              message: 'No service providers available',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(servicesProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(AppTheme.paddingM),
              itemCount: services.length,
              itemBuilder: (context, index) {
                final service = services[index];
                return AnimatedCard(
                  margin: const EdgeInsets.only(bottom: AppTheme.paddingM),
                  onTap: () => context.push('/service/${service.id}'),
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
                              _getCategoryIcon(service.category),
                              color: theme.colorScheme.primary,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: AppTheme.paddingM),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  service.name,
                                  style: theme.textTheme.titleLarge,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppTheme.paddingS,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                                  ),
                                  child: Text(
                                    service.category,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.paddingM),
                      Text(
                        service.description,
                        style: theme.textTheme.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppTheme.paddingM),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 16,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              service.location,
                              style: theme.textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (service.rating != null) ...[
                        const SizedBox(height: AppTheme.paddingS),
                        Row(
                          children: [
                            ...List.generate(5, (i) {
                              return Icon(
                                i < service.rating!.floor()
                                    ? Icons.star_rounded
                                    : Icons.star_border_rounded,
                                size: 16,
                                color: AppTheme.goldAccent,
                              );
                            }),
                            const SizedBox(width: 4),
                            Text(
                              service.rating!.toStringAsFixed(1),
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                      if (service.openingHours != null) ...[
                        const SizedBox(height: AppTheme.paddingS),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 16,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              service.openingHours!,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          );
        },
        loading: () => const LoadingWidget(message: 'Loading services...'),
        error: (error, stack) => CustomErrorWidget(
          message: 'Failed to load services',
          onRetry: () => ref.invalidate(servicesProvider),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'mechanic':
        return Icons.build_rounded;
      case 'spare parts':
        return Icons.inventory_2_rounded;
      case 'fuel station':
        return Icons.local_gas_station_rounded;
      case 'towing':
        return Icons.local_shipping_rounded;
      case 'tire repair':
        return Icons.tire_repair_rounded;
      case 'wash & detailing':
        return Icons.local_car_wash_rounded;
      default:
        return Icons.business_rounded;
    }
  }
}
