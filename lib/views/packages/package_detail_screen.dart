import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/providers/package_provider.dart';
import 'package:pbak/widgets/loading_widget.dart';
import 'package:pbak/widgets/error_widget.dart';
import 'package:pbak/widgets/custom_button.dart';
import 'package:intl/intl.dart';

class PackageDetailScreen extends ConsumerWidget {
  final String packageId;

  const PackageDetailScreen({super.key, required this.packageId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final packageAsync = ref.watch(packageDetailProvider(packageId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Package Details'),
      ),
      body: packageAsync.when(
        data: (package) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.paddingL),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          package.name,
                          style: theme.textTheme.displaySmall,
                        ),
                        const SizedBox(height: AppTheme.paddingS),
                        Text(
                          package.description,
                          style: theme.textTheme.bodyLarge,
                        ),
                        const SizedBox(height: AppTheme.paddingL),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'KES ${NumberFormat('#,###').format(package.price)}',
                              style: theme.textTheme.displayMedium?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: AppTheme.paddingS),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                '/ ${package.durationText}',
                                style: theme.textTheme.titleLarge,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.paddingM),

                Text(
                  'Benefits',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: AppTheme.paddingS),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.paddingM),
                    child: Column(
                      children: package.benefits.map((benefit) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppTheme.paddingS),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                size: 24,
                                color: Colors.green,
                              ),
                              const SizedBox(width: AppTheme.paddingM),
                              Expanded(
                                child: Text(
                                  benefit,
                                  style: theme.textTheme.bodyLarge,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                if (package.addOns.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.paddingM),
                  Text(
                    'Add-Ons',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppTheme.paddingS),
                  ...package.addOns.map((addOn) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: AppTheme.paddingS),
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.paddingM),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    addOn.name,
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  Text(
                                    addOn.description,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '+KES ${NumberFormat('#,###').format(addOn.price)}',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],

                if (package.autoRenew) ...[
                  const SizedBox(height: AppTheme.paddingM),
                  Card(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.paddingM),
                      child: Row(
                        children: [
                          Icon(
                            Icons.autorenew_rounded,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: AppTheme.paddingM),
                          Expanded(
                            child: Text(
                              'Auto-renewal available for this package',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: AppTheme.paddingXL),
                CustomButton(
                  text: 'Subscribe Now',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Subscribing to ${package.name}...'),
                      ),
                    );
                  },
                  icon: Icons.shopping_cart_rounded,
                ),
              ],
            ),
          );
        },
        loading: () => const LoadingWidget(message: 'Loading package...'),
        error: (error, stack) => CustomErrorWidget(
          message: 'Failed to load package details',
          onRetry: () => ref.invalidate(packageDetailProvider(packageId)),
        ),
      ),
    );
  }
}
