import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/providers/bike_provider.dart';
import 'package:pbak/widgets/loading_widget.dart';
import 'package:pbak/widgets/error_widget.dart';
import 'package:intl/intl.dart';
import 'package:pbak/models/bike_model.dart';

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
                    'Bike not found',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppTheme.paddingM),
                  FilledButton.icon(
                    onPressed: () => context.go('/bikes'),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back to Bikes'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(bikeByIdProvider(int.parse(bikeId)));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // Hero Header with Image
                  _buildHeroHeader(context, bike),
                  
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(AppTheme.paddingM),
                    child: Column(
                      children: [
                        // Quick Stats Cards
                        _buildQuickStats(context, bike),
                        const SizedBox(height: AppTheme.paddingL),

                        // Basic Information
                        _buildModernSection(
                          context,
                          'Basic Information',
                          Icons.info_outline_rounded,
                          [
                            _DetailTile(
                              icon: Icons.business_rounded,
                              label: 'Make',
                              value: bike.makeName,
                            ),
                            _DetailTile(
                              icon: Icons.two_wheeler_rounded,
                              label: 'Model',
                              value: bike.modelName,
                            ),
                            if (bike.bikeModel?.category != null)
                              _DetailTile(
                                icon: Icons.category_rounded,
                                label: 'Category',
                                value: bike.bikeModel!.category!,
                              ),
                            if (bike.bikeModel?.engineCapacity != null)
                              _DetailTile(
                                icon: Icons.speed_rounded,
                                label: 'Engine Capacity',
                                value: bike.bikeModel!.engineCapacity!,
                              ),
                            if (bike.bikeModel?.fuelType != null)
                              _DetailTile(
                                icon: Icons.local_gas_station_rounded,
                                label: 'Fuel Type',
                                value: bike.bikeModel!.fuelType!,
                              ),
                            if (bike.yom != null)
                              _DetailTile(
                                icon: Icons.calendar_today_rounded,
                                label: 'Year',
                                value: bike.yom!.year.toString(),
                              ),
                            _DetailTile(
                              icon: Icons.palette_rounded,
                              label: 'Color',
                              value: bike.color ?? 'N/A',
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.paddingM),

                        // Registration Details
                        _buildModernSection(
                          context,
                          'Registration & Documents',
                          Icons.description_rounded,
                          [
                            _DetailTile(
                              icon: Icons.confirmation_number_rounded,
                              label: 'Registration Number',
                              value: bike.registrationNumber ?? 'N/A',
                              valueColor: theme.colorScheme.primary,
                              isBold: true,
                            ),
                            _DetailTile(
                              icon: Icons.settings_rounded,
                              label: 'Engine Number',
                              value: bike.engineNumber ?? 'N/A',
                            ),
                            _DetailTile(
                              icon: Icons.tag_rounded,
                              label: 'Chassis Number',
                              value: bike.chassisNumber ?? 'N/A',
                            ),
                            if (bike.odometerReading != null)
                              _DetailTile(
                                icon: Icons.speed_rounded,
                                label: 'Odometer Reading',
                                value: '${bike.odometerReading} km',
                              ),
                            if (bike.registrationDate != null)
                              _DetailTile(
                                icon: Icons.event_available_rounded,
                                label: 'Registration Date',
                                value: DateFormat('MMM dd, yyyy').format(bike.registrationDate!),
                              ),
                            if (bike.registrationExpiry != null)
                              _DetailTile(
                                icon: Icons.event_busy_rounded,
                                label: 'Registration Expiry',
                                value: DateFormat('MMM dd, yyyy').format(bike.registrationExpiry!),
                                valueColor: _getExpiryColor(bike.registrationExpiry!, theme),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.paddingM),

                        // Insurance Details
                        if (bike.hasInsurance == true || bike.insuranceExpiry != null)
                          _buildModernSection(
                            context,
                            'Insurance',
                            Icons.shield_rounded,
                            [
                              _DetailTile(
                                icon: Icons.check_circle_rounded,
                                label: 'Has Insurance',
                                value: bike.hasInsurance == true ? 'Yes' : 'No',
                                valueColor: bike.hasInsurance == true 
                                    ? Colors.green 
                                    : Colors.orange,
                              ),
                              if (bike.insuranceExpiry != null)
                                _DetailTile(
                                  icon: Icons.event_rounded,
                                  label: 'Insurance Expiry',
                                  value: DateFormat('MMM dd, yyyy').format(bike.insuranceExpiry!),
                                  valueColor: _getExpiryColor(bike.insuranceExpiry!, theme),
                                ),
                              if (bike.experienceYears != null)
                                _DetailTile(
                                  icon: Icons.military_tech_rounded,
                                  label: 'Riding Experience',
                                  value: '${bike.experienceYears} years',
                                ),
                            ],
                          ),
                        if (bike.hasInsurance == true || bike.insuranceExpiry != null)
                          const SizedBox(height: AppTheme.paddingM),

                        // Owner Details
                        if (bike.member != null)
                          _buildModernSection(
                            context,
                            'Owner Information',
                            Icons.person_rounded,
                            [
                              _DetailTile(
                                icon: Icons.account_circle_rounded,
                                label: 'Name',
                                value: bike.member!.fullName,
                                isBold: true,
                              ),
                              if (bike.member!.email != null)
                                _DetailTile(
                                  icon: Icons.email_rounded,
                                  label: 'Email',
                                  value: bike.member!.email!,
                                ),
                              if (bike.member!.phone != null)
                                _DetailTile(
                                  icon: Icons.phone_rounded,
                                  label: 'Phone',
                                  value: bike.member!.phone!,
                                ),
                            ],
                          ),
                        if (bike.member != null)
                          const SizedBox(height: AppTheme.paddingM),

                        // Additional Information
                        _buildModernSection(
                          context,
                          'Additional Information',
                          Icons.info_rounded,
                          [
                            if (bike.purchaseDate != null)
                              _DetailTile(
                                icon: Icons.shopping_cart_rounded,
                                label: 'Purchase Date',
                                value: DateFormat('MMM dd, yyyy').format(bike.purchaseDate!),
                              ),
                            if (bike.createdAt != null)
                              _DetailTile(
                                icon: Icons.add_circle_rounded,
                                label: 'Added to System',
                                value: DateFormat('MMM dd, yyyy HH:mm').format(bike.createdAt!),
                              ),
                            if (bike.status != null)
                              _DetailTile(
                                icon: Icons.toggle_on_rounded,
                                label: 'Status',
                                value: bike.status!.toUpperCase(),
                                valueColor: bike.status == 'active' 
                                    ? Colors.green 
                                    : Colors.grey,
                              ),
                            _DetailTile(
                              icon: Icons.star_rounded,
                              label: 'Primary Bike',
                              value: bike.isPrimary == true ? 'Yes' : 'No',
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.paddingXL),
                      ],
                    ),
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

  Color _getExpiryColor(DateTime expiryDate, ThemeData theme) {
    final now = DateTime.now();
    final difference = expiryDate.difference(now).inDays;
    
    if (difference < 0) {
      return Colors.red;
    } else if (difference < 30) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  Widget _buildHeroHeader(BuildContext context, BikeModel bike) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.7),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.paddingXL),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.paddingL),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.two_wheeler_rounded,
                  size: 80,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              const SizedBox(height: AppTheme.paddingM),
              Text(
                bike.displayName,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.paddingS),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.paddingM,
                  vertical: AppTheme.paddingS,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusL),
                ),
                child: Text(
                  bike.registrationNumber ?? 'N/A',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, BikeModel bike) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.event_rounded,
            label: 'Year',
            value: bike.yom?.year.toString() ?? 'N/A',
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: AppTheme.paddingM),
        Expanded(
          child: _StatCard(
            icon: Icons.palette_rounded,
            label: 'Color',
            value: bike.color ?? 'N/A',
            color: theme.colorScheme.secondary,
          ),
        ),
        const SizedBox(width: AppTheme.paddingM),
        Expanded(
          child: _StatCard(
            icon: Icons.speed_rounded,
            label: 'Engine',
            value: bike.bikeModel?.engineCapacity ?? 'N/A',
            color: theme.colorScheme.tertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildModernSection(
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

// Stat Card Widget
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        side: BorderSide(
          color: color.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingM),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.paddingS),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: AppTheme.paddingS),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Detail Tile Widget
class _DetailTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;

  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.paddingM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                    color: valueColor ?? theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
