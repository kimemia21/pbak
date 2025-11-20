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
    final packageAsync = ref.watch(packageDetailProvider(int.parse(packageId)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Package Details'),
      ),
      body: packageAsync.when(
        data: (package) {
          if (package == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: AppTheme.paddingM),
                  Text(
                    'Package not found',
                    style: theme.textTheme.titleLarge,
                  ),
                ],
              ),
            );
          }
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusL),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.primary.withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusL),
                    ),
                    padding: const EdgeInsets.all(AppTheme.paddingL),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          package.packageName ?? 'Package',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppTheme.paddingS),
                        if (package.packageType != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.paddingS,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(AppTheme.radiusS),
                            ),
                            child: Text(
                              package.packageType!.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        if (package.description != null) ...[
                          const SizedBox(height: AppTheme.paddingM),
                          Text(
                            package.description!,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                        const SizedBox(height: AppTheme.paddingL),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              package.formattedPrice,
                              style: theme.textTheme.displaySmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: AppTheme.paddingS),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                '/ ${package.durationText}',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.paddingL),

                // Package Details
                _buildSection(
                  context,
                  'Package Details',
                  Icons.info_outline_rounded,
                  [
                    if (package.durationDays != null)
                      _DetailRow(
                        icon: Icons.schedule_rounded,
                        label: 'Duration',
                        value: package.durationText,
                      ),
                    if (package.maxBikes != null && package.maxBikes! > 0)
                      _DetailRow(
                        icon: Icons.two_wheeler_rounded,
                        label: 'Max Bikes',
                        value: package.maxBikes.toString(),
                      ),
                    if (package.maxMembers != null)
                      _DetailRow(
                        icon: Icons.people_rounded,
                        label: 'Max Members',
                        value: package.maxMembers.toString(),
                      ),
                    if (package.isRenewable == true)
                      _DetailRow(
                        icon: Icons.autorenew_rounded,
                        label: 'Renewable',
                        value: 'Yes',
                        valueColor: Colors.green,
                      ),
                  ],
                ),
                const SizedBox(height: AppTheme.paddingM),

                // Benefits
                _buildSection(
                  context,
                  'Benefits & Features',
                  Icons.check_circle_outline_rounded,
                  package.benefitsList.map((benefit) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppTheme.paddingS),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                ),

                // Auto-renewal info
                if (package.autoRenewDefault == true) ...[
                  const SizedBox(height: AppTheme.paddingM),
                  Card(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      side: BorderSide(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
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
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
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
                        content: Text('Subscribing to ${package.packageName ?? "package"}...'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  icon: Icons.shopping_cart_rounded,
                ),
                const SizedBox(height: AppTheme.paddingM),
              ],
            ),
          );
        },
        loading: () => const LoadingWidget(message: 'Loading package...'),
        error: (error, stack) => CustomErrorWidget(
          message: 'Failed to load package details',
          onRetry: () => ref.invalidate(packageDetailProvider(int.parse(packageId))),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: AppTheme.paddingS, bottom: AppTheme.paddingS),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppTheme.paddingS),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
            side: BorderSide(
              color: theme.dividerColor.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.paddingM),
            child: Column(
              children: children,
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.paddingM),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
            ),
            child: Icon(
              icon,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppTheme.paddingM),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
