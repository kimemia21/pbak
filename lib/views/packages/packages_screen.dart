import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/providers/package_provider.dart';
import 'package:pbak/providers/auth_provider.dart';
import 'package:pbak/widgets/loading_widget.dart';
import 'package:pbak/widgets/error_widget.dart';
import 'package:pbak/models/package_model.dart';
import 'package:intl/intl.dart';

class PackagesScreen extends ConsumerStatefulWidget {
  const PackagesScreen({super.key});

  @override
  ConsumerState<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends ConsumerState<PackagesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authProvider);

    // Get member ID from the logged-in user
    final memberId = userAsync.value?.memberId ?? 2; // Default to 2 for testing

    return Scaffold(
      appBar: AppBar(
        title: const Text('Packages'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.card_membership_rounded), text: 'My Packages'),
            Tab(icon: Icon(Icons.explore_rounded), text: 'Available'),
          ],
        ),
            ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MyPackagesTab(memberId: memberId),
          _AvailablePackagesTab(),
        ],
      ),
    );
  }
}

class _MyPackagesTab extends ConsumerWidget {
  final int memberId;

  const _MyPackagesTab({required this.memberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final packagesAsync = ref.watch(memberPackagesProvider(memberId));

    return packagesAsync.when(
      data: (packages) {
        if (packages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.card_membership_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: AppTheme.paddingM),
                Text(
                  'No Active Packages',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: AppTheme.paddingS),
                Text(
                  'Subscribe to a package to access premium features',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.paddingL),
                FilledButton.icon(
                  onPressed: () {
                    // Switch to Available tab
                    DefaultTabController.of(context).animateTo(1);
                  },
                  icon: const Icon(Icons.explore),
                  label: const Text('Browse Packages'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(memberPackagesProvider(memberId));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(AppTheme.paddingM),
            itemCount: packages.length,
            itemBuilder: (context, index) {
              final package = packages[index];
              return _PackageCard(package: package);
            },
          ),
        );
      },
      loading: () => const LoadingWidget(message: 'Loading your packages...'),
      error: (error, stack) => CustomErrorWidget(
        message: 'Failed to load packages',
        onRetry: () => ref.invalidate(memberPackagesProvider(memberId)),
      ),
    );
  }
}

class _AvailablePackagesTab extends ConsumerWidget {
  const _AvailablePackagesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final packagesAsync = ref.watch(packagesProvider);

    return packagesAsync.when(
      data: (packages) {
        if (packages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: AppTheme.paddingM),
                Text(
                  'No Packages Available',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: AppTheme.paddingS),
                Text(
                  'Check back later for new packages',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(packagesProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(AppTheme.paddingM),
            itemCount: packages.length,
            itemBuilder: (context, index) {
              final package = packages[index];
              return _AvailablePackageCard(package: package);
            },
          ),
        );
      },
      loading: () =>
          const LoadingWidget(message: 'Loading available packages...'),
      error: (error, stack) => CustomErrorWidget(
        message: 'Failed to load packages',
        onRetry: () => ref.invalidate(packagesProvider),
      ),
    );
  }
}

class _AvailablePackageCard extends StatelessWidget {
  final PackageModel package;

  const _AvailablePackageCard({required this.package});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: AppTheme.paddingM),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to package detail
          if (package.packageId != null) {
            // TODO: Navigate to detail screen
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('View details for ${package.packageName}'),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppTheme.paddingM),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withOpacity(0.7),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppTheme.radiusL),
                  topRight: Radius.circular(AppTheme.radiusL),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          package.packageName ?? 'Package',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (package.packageType != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.paddingS,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusS,
                            ),
                          ),
                          child: Text(
                            package.packageType!.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(AppTheme.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description
                  if (package.description != null &&
                      package.description!.isNotEmpty)
                    Text(
                      package.description!,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (package.description != null &&
                      package.description!.isNotEmpty)
                    const SizedBox(height: AppTheme.paddingM),

                  // Price
                  Row(
                    children: [
                      Icon(
                        Icons.payments_rounded,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: AppTheme.paddingS),
                      Text(
                        package.formattedPrice,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        ' / ${package.durationText}',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.paddingM),

                  // Quick benefits (show first 3)
                  ...package.benefitsList.take(3).map((benefit) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppTheme.paddingS),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 16,
                            color: AppTheme.successGreen,
                          ),
                          const SizedBox(width: AppTheme.paddingS),
                          Expanded(
                            child: Text(
                              benefit,
                              style: theme.textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),

                  if (package.benefitsList.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: AppTheme.paddingS),
                      child: Text(
                        '+${package.benefitsList.length - 3} more benefits',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),

                  const SizedBox(height: AppTheme.paddingM),

                  // Action button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        // TODO: Subscribe to package
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Subscribe to ${package.packageName}',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_shopping_cart_rounded),
                      label: const Text('Subscribe'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  final PackageModel package;

  const _PackageCard({required this.package});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isExpired = package.isExpired;
    final isExpiringSoon = package.isExpiringSoon;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: AppTheme.paddingM),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        side: BorderSide(
          color: isExpired
              ? Colors.red.withOpacity(0.3)
              : isExpiringSoon
              ? Colors.orange.withOpacity(0.3)
              : theme.colorScheme.primary.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Header with gradient
          Container(
            padding: const EdgeInsets.all(AppTheme.paddingM),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isExpired
                    ? [Colors.red.shade400, Colors.red.shade600]
                    : isExpiringSoon
                    ? [Colors.orange.shade400, Colors.orange.shade600]
                    : [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withOpacity(0.7),
                      ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTheme.radiusL),
                topRight: Radius.circular(AppTheme.radiusL),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        package.packageName ?? 'Package',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _StatusBadge(
                      status: package.status ?? 'unknown',
                      isExpired: isExpired,
                      isExpiringSoon: isExpiringSoon,
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.paddingS),
                Text(
                  package.packageType?.toUpperCase() ?? 'MEMBERSHIP',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(AppTheme.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description
                if (package.description != null)
                  Text(
                    package.description!,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (package.description != null)
                  const SizedBox(height: AppTheme.paddingM),

                // Price and Duration
                Row(
                  children: [
                    Expanded(
                      child: _InfoChip(
                        icon: Icons.payments_rounded,
                        label: 'Price',
                        value: package.formattedPrice,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: AppTheme.paddingS),
                    Expanded(
                      child: _InfoChip(
                        icon: Icons.schedule_rounded,
                        label: 'Duration',
                        value: package.durationText,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.paddingM),

                // Dates
                _DateInfo(
                  icon: Icons.event_available_rounded,
                  label: 'Start Date',
                  date: package.startDate,
                ),
                const SizedBox(height: AppTheme.paddingS),
                _DateInfo(
                  icon: Icons.event_busy_rounded,
                  label: 'End Date',
                  date: package.endDate,
                  isExpired: isExpired,
                  isExpiringSoon: isExpiringSoon,
                ),

                // Days remaining
                if (!isExpired && package.endDate != null) ...[
                  const SizedBox(height: AppTheme.paddingM),
                  Container(
                    padding: const EdgeInsets.all(AppTheme.paddingS),
                    decoration: BoxDecoration(
                      color: isExpiringSoon
                          ? Colors.orange.withOpacity(0.1)
                          : theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.hourglass_bottom_rounded,
                          size: 18,
                          color: isExpiringSoon
                              ? Colors.orange
                              : theme.colorScheme.primary,
                        ),
                        const SizedBox(width: AppTheme.paddingS),
                        Text(
                          '${package.daysRemaining} days remaining',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isExpiringSoon
                                ? Colors.orange
                                : theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: AppTheme.paddingM),
                const Divider(),
                const SizedBox(height: AppTheme.paddingS),

                // Benefits
                Text(
                  'Benefits',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppTheme.paddingS),
                ...package.benefitsList.map((benefit) {
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
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),

                // Actions
                if (!isExpired) ...[
                  const SizedBox(height: AppTheme.paddingM),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // TODO: View details
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('View details coming soon'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.info_outline),
                          label: const Text('Details'),
                        ),
                      ),
                      if (package.isRenewable == true) ...[
                        const SizedBox(width: AppTheme.paddingS),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () {
                              // TODO: Renew package
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Renew coming soon'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Renew'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final bool isExpired;
  final bool isExpiringSoon;

  const _StatusBadge({
    required this.status,
    required this.isExpired,
    required this.isExpiringSoon,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    String displayText;

    if (isExpired) {
      bgColor = Colors.red.shade900;
      displayText = 'EXPIRED';
    } else if (isExpiringSoon) {
      bgColor = Colors.orange.shade900;
      displayText = 'EXPIRING SOON';
    } else if (status.toLowerCase() == 'active') {
      bgColor = Colors.green.shade700;
      displayText = 'ACTIVE';
    } else {
      bgColor = Colors.grey.shade700;
      displayText = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.paddingS,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
      ),
      child: Text(
        displayText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingS),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DateInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final DateTime? date;
  final bool isExpired;
  final bool isExpiringSoon;

  const _DateInfo({
    required this.icon,
    required this.label,
    required this.date,
    this.isExpired = false,
    this.isExpiringSoon = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color? iconColor;

    if (isExpired) {
      iconColor = Colors.red;
    } else if (isExpiringSoon) {
      iconColor = Colors.orange;
    }

    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor ?? Colors.grey[600]),
        const SizedBox(width: AppTheme.paddingS),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
        const Spacer(),
        Text(
          date != null ? DateFormat('MMM dd, yyyy').format(date!) : 'N/A',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: iconColor,
          ),
        ),
      ],
    );
  }
}
