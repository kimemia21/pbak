import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/providers/bike_provider.dart';
import 'package:pbak/widgets/loading_widget.dart';
import 'package:pbak/widgets/error_widget.dart';
import 'package:intl/intl.dart';
import 'package:pbak/models/bike_model.dart';

class BikeDetailScreen extends ConsumerStatefulWidget {
  final String bikeId;

  const BikeDetailScreen({
    super.key,
    required this.bikeId,
  });

  @override
  ConsumerState<BikeDetailScreen> createState() => _BikeDetailScreenState();
}

class _BikeDetailScreenState extends ConsumerState<BikeDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bikeAsync = ref.watch(bikeByIdProvider(int.parse(widget.bikeId)));
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF8F9FA),
      body: bikeAsync.when(
        data: (bike) {
          if (bike == null) {
            return _buildNotFoundState(context, theme);
          }
          return _buildContent(context, theme, bike, isDark);
        },
        loading: () => const LoadingWidget(message: 'Loading bike details...'),
        error: (error, stack) => CustomErrorWidget(
          message: 'Failed to load bike details',
          onRetry: () => ref.invalidate(bikeByIdProvider(int.parse(widget.bikeId))),
        ),
      ),
    );
  }

  Widget _buildNotFoundState(BuildContext context, ThemeData theme) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 56,
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Bike not found',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The bike you\'re looking for doesn\'t exist',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => context.go('/bikes'),
              icon: const Icon(Icons.arrow_back_rounded, size: 20),
              label: const Text('Back to My Bikes'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ThemeData theme, BikeModel bike, bool isDark) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildSliverAppBar(context, theme, bike, isDark),
        SliverToBoxAdapter(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                       const SizedBox(height: 24),
                    _buildRegistrationCard(context, theme, bike, isDark),
                    const SizedBox(height: 24),
                    _buildQuickStats(context, theme, bike, isDark),
                    const SizedBox(height: 28),
                    _buildSectionHeader(context, 'Specifications', Icons.tune_rounded),
                    const SizedBox(height: 12),
                    _buildSpecsCard(context, theme, bike, isDark),
                    const SizedBox(height: 24),
                    _buildSectionHeader(context, 'Documents', Icons.folder_open_rounded),
                    const SizedBox(height: 12),
                    _buildDocumentsCard(context, theme, bike, isDark),
                    if (bike.hasInsurance == true || bike.insuranceExpiry != null) ...[
                      const SizedBox(height: 24),
                      _buildSectionHeader(context, 'Insurance', Icons.verified_user_rounded),
                      const SizedBox(height: 12),
                      _buildInsuranceCard(context, theme, bike, isDark),
                    ],
                    const SizedBox(height: 24),
                    _buildSectionHeader(context, 'Activity', Icons.timeline_rounded),
                    const SizedBox(height: 12),
                    _buildTimelineCard(context, theme, bike, isDark),
                    const SizedBox(height: 32),
                    _buildActionButtons(context, theme, bike),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar(BuildContext context, ThemeData theme, BikeModel bike, bool isDark) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      stretch: true,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : theme.colorScheme.primary,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => context.pop(),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.edit_rounded, color: Colors.white),
              onPressed: () => context.push('/bikes/edit/${widget.bikeId}', extra: bike),
              tooltip: 'Edit',
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
              onPressed: () => _showOptionsMenu(context),
              tooltip: 'More',
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF2D2D2D), const Color(0xFF1A1A1A)]
                  : [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.8)],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
                  ),
                  child: const Icon(
                    Icons.two_wheeler_rounded,
                    size: 56,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  bike.displayName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  bike.bikeModel?.category?.toUpperCase() ?? 'MOTORCYCLE',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.7),
                    letterSpacing: 2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegistrationCard(BuildContext context, ThemeData theme, BikeModel bike, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.goldAccent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.confirmation_number_rounded,
              color: AppTheme.darkGold,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Registration Number',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  bike.registrationNumber?.toUpperCase() ?? 'N/A',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              if (bike.registrationNumber != null) {
                Clipboard.setData(ClipboardData(text: bike.registrationNumber!));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Registration number copied'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              }
            },
            icon: Icon(
              Icons.copy_rounded,
              color: Colors.grey[400],
              size: 20,
            ),
            tooltip: 'Copy',
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, ThemeData theme, BikeModel bike, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _QuickStatChip(
            icon: Icons.speed_rounded,
            label: bike.bikeModel?.engineCapacity != null 
                ? '${bike.bikeModel!.engineCapacity}cc' 
                : 'N/A',
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickStatChip(
            icon: Icons.palette_outlined,
            label: bike.color ?? 'N/A',
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickStatChip(
            icon: Icons.local_gas_station_outlined,
            label: bike.bikeModel?.fuelType?.toUpperCase() ?? 'N/A',
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSpecsCard(BuildContext context, ThemeData theme, BikeModel bike, bool isDark) {
    return _GlassCard(
      isDark: isDark,
      child: Column(
        children: [
          _InfoRow(label: 'Make', value: bike.makeName, isDark: isDark),
          _InfoRow(label: 'Model', value: bike.modelName, isDark: isDark),
          if (bike.bikeModel?.category != null)
            _InfoRow(label: 'Category', value: bike.bikeModel!.category!, isDark: isDark),
          if (bike.bikeModel?.engineCapacity != null)
            _InfoRow(label: 'Engine', value: '${bike.bikeModel!.engineCapacity}cc', isDark: isDark),
          if (bike.yom != null)
            _InfoRow(label: 'Year', value: bike.yom!.year.toString(), isDark: isDark, isLast: true),
          if (bike.yom == null)
            _InfoRow(label: 'Color', value: bike.color ?? 'N/A', isDark: isDark, isLast: true),
        ],
      ),
    );
  }

  Widget _buildDocumentsCard(BuildContext context, ThemeData theme, BikeModel bike, bool isDark) {
    return _GlassCard(
      isDark: isDark,
      child: Column(
        children: [
          if (bike.engineNumber != null)
            _InfoRow(label: 'Engine Number', value: bike.engineNumber!, isDark: isDark),
          if (bike.chassisNumber != null)
            _InfoRow(label: 'Chassis Number', value: bike.chassisNumber!, isDark: isDark),
          if (bike.registrationDate != null)
            _InfoRow(
              label: 'Registration Date',
              value: DateFormat('MMM dd, yyyy').format(bike.registrationDate!),
              isDark: isDark,
            ),
          _InfoRow(
            label: 'Registration Expiry',
            value: bike.registrationExpiry != null
                ? DateFormat('MMM dd, yyyy').format(bike.registrationExpiry!)
                : 'N/A',
            isDark: isDark,
            valueColor: bike.registrationExpiry != null
                ? _getExpiryColor(bike.registrationExpiry!)
                : null,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInsuranceCard(BuildContext context, ThemeData theme, BikeModel bike, bool isDark) {
    final hasValidInsurance = bike.hasInsurance == true;
    
    return _GlassCard(
      isDark: isDark,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: bike.insuranceExpiry != null
                      ? AppTheme.successGreen.withOpacity(0.15)
                      : AppTheme.warningOrange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  bike.insuranceExpiry != null ? Icons.check_circle_rounded : Icons.warning_rounded,
                  color: bike.insuranceExpiry != null ? AppTheme.successGreen : AppTheme.warningOrange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bike.insuranceExpiry != null ? 'Insured' : 'Not Insured',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: bike.insuranceExpiry != null ? AppTheme.successGreen : AppTheme.warningOrange,
                      ),
                    ),
                    if (bike.insuranceExpiry != null)
                      Text(
                        'Expires ${DateFormat('MMM dd, yyyy').format(bike.insuranceExpiry!)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(BuildContext context, ThemeData theme, BikeModel bike, bool isDark) {
    return _GlassCard(
      isDark: isDark,
      child: Column(
        children: [
          if (bike.purchaseDate != null)
            _TimelineItem(
              icon: Icons.shopping_bag_rounded,
              title: 'Purchased',
              date: DateFormat('MMM dd, yyyy').format(bike.purchaseDate!),
              isDark: isDark,
            ),
          if (bike.createdAt != null)
            _TimelineItem(
              icon: Icons.add_circle_outline_rounded,
              title: 'Added to PBAK',
              date: DateFormat('MMM dd, yyyy').format(bike.createdAt!),
              isDark: isDark,
              isLast: bike.status == null,
            ),
          _TimelineItem(
            icon: bike.status == 'active' ? Icons.check_circle_rounded : Icons.pause_circle_rounded,
            title: 'Status',
            date: (bike.status ?? 'active').toUpperCase(),
            isDark: isDark,
            isLast: true,
            statusColor: bike.status == 'active' ? AppTheme.successGreen : Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ThemeData theme, BikeModel bike) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => context.push('/bikes/edit/${widget.bikeId}', extra: bike),
        icon: const Icon(Icons.edit_rounded, size: 20),
        label: const Text('Edit Details'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.3)),
        ),
      ),
    );
  }

  Color _getExpiryColor(DateTime expiryDate) {
    final now = DateTime.now();
    final difference = expiryDate.difference(now).inDays;
    if (difference < 0) return AppTheme.deepRed;
    if (difference < 30) return AppTheme.warningOrange;
    return AppTheme.successGreen;
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.share_rounded),
              title: const Text('Share'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_rounded),
              title: const Text('Show QR Code'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.delete_rounded, color: AppTheme.deepRed),
              title: Text('Delete Bike', style: TextStyle(color: AppTheme.deepRed)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteDialog(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: AppTheme.deepRed),
            SizedBox(width: 12),
            Text('Delete Bike'),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this bike? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref
                  .read(bikeNotifierProvider.notifier)
                  .deleteBike(int.parse(widget.bikeId));
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Bike deleted successfully'),
                    backgroundColor: AppTheme.successGreen,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    margin: const EdgeInsets.all(16),
                  ),
                );
                context.go('/bikes');
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Failed to delete bike'),
                    backgroundColor: AppTheme.deepRed,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.deepRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// Supporting Widgets

class _QuickStatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _QuickStatChip({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.15),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final bool isDark;

  const _GlassCard({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.withOpacity(0.12),
        ),
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final bool isLast;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.isDark,
    this.isLast = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.15),
          ),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String date;
  final bool isDark;
  final bool isLast;
  final Color? statusColor;

  const _TimelineItem({
    required this.icon,
    required this.title,
    required this.date,
    required this.isDark,
    this.isLast = false,
    this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (statusColor ?? theme.colorScheme.primary).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: statusColor ?? theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: statusColor,
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
