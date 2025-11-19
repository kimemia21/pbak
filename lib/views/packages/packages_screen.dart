import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/providers/package_provider.dart';
import 'package:pbak/widgets/loading_widget.dart';
import 'package:pbak/widgets/error_widget.dart';
import 'package:pbak/widgets/animated_card.dart';
import 'package:intl/intl.dart';

class PackagesScreen extends ConsumerWidget {
  const PackagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final packagesAsync = ref.watch(packagesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Membership Packages'),
      ),
      body: packagesAsync.when(
        data: (packages) {
          return ListView.builder(
            padding: const EdgeInsets.all(AppTheme.paddingM),
            itemCount: packages.length,
            itemBuilder: (context, index) {
              final package = packages[index];
              final isPopular = index == 1; // Premium is popular

              return AnimatedCard(
                margin: const EdgeInsets.only(bottom: AppTheme.paddingM),
                onTap: () => context.push('/packages/${package.id}'),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                package.name,
                                style: theme.textTheme.headlineSmall,
                              ),
                            ),
                            if (isPopular)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.paddingS,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.goldAccent,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                                ),
                                child: Text(
                                  'POPULAR',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppTheme.primaryBlack,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.paddingS),
                        Text(
                          package.description,
                          style: theme.textTheme.bodyMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppTheme.paddingM),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'KES ${NumberFormat('#,###').format(package.price)}',
                              style: theme.textTheme.displaySmall?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: AppTheme.paddingS),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '/ ${package.durationText}',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.paddingM),
                        const Divider(),
                        const SizedBox(height: AppTheme.paddingS),
                        ...package.benefits.take(3).map((benefit) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppTheme.paddingS),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 20,
                                  color: AppTheme.successGreen,
                                ),
                                const SizedBox(width: AppTheme.paddingS),
                                Expanded(
                                  child: Text(
                                    benefit,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        if (package.benefits.length > 3) ...[
                          Text(
                            '+${package.benefits.length - 3} more benefits',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const LoadingWidget(message: 'Loading packages...'),
        error: (error, stack) => CustomErrorWidget(
          message: 'Failed to load packages',
          onRetry: () => ref.invalidate(packagesProvider),
        ),
      ),
    );
  }
}
