import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pbak/theme/app_theme.dart';
import 'package:pbak/models/bike_model.dart';
import 'package:pbak/services/bike_service.dart';

class BikesScreen extends ConsumerStatefulWidget {
  const BikesScreen({super.key});

  @override
  ConsumerState<BikesScreen> createState() => _BikesScreenState();
}

class _BikesScreenState extends ConsumerState<BikesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  List<BikeModel> _bikes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _fetchBikes();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchBikes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final bikeService = BikeService();
      final bikes = await bikeService.getMemberBikes();
      
      if (mounted) {
        setState(() {
          _bikes = bikes;
          _isLoading = false;
        });
        _animationController.forward(from: 0);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load bikes';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF8F9FA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context, theme, isDark),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading your bikes...'),
                  ],
                ),
              ),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: _buildErrorState(context, theme),
            )
          else if (_bikes.isEmpty)
            SliverFillRemaining(
              child: _buildEmptyState(context, theme, isDark),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: _BikeCard(
                        bike: _bikes[index],
                        isDark: isDark,
                        index: index,
                        onTap: () => context.push('/bikes/${_bikes[index].bikeId}'),
                      ),
                    );
                  },
                  childCount: _bikes.length,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/bikes/add'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Bike', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, ThemeData theme, bool isDark) {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : theme.colorScheme.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF2D2D2D), const Color(0xFF1A1A1A)]
                  : [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.85)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.two_wheeler_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Bikes',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _isLoading ? 'Loading...' : '${_bikes.length} ${_bikes.length == 1 ? 'bike' : 'bikes'} registered',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _isLoading ? Icons.hourglass_empty_rounded : Icons.refresh_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            onPressed: _isLoading ? null : _fetchBikes,
            tooltip: 'Refresh',
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: isDark 
                    ? Colors.white.withOpacity(0.05) 
                    : theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.two_wheeler_rounded,
                size: 64,
                color: isDark ? Colors.grey : theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Bikes Yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first motorcycle to get started\nwith PBAK services',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _fetchBikes,
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: const Text('Refresh'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () => context.push('/bikes/add'),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('Add Bike'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.deepRed.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 56,
                color: AppTheme.deepRed,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Failed to load bikes',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _fetchBikes,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
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
}

class _BikeCard extends StatelessWidget {
  final BikeModel bike;
  final bool isDark;
  final int index;
  final VoidCallback onTap;

  const _BikeCard({
    required this.bike,
    required this.isDark,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPrimary = bike.isPrimary ?? false;

    return Padding(
      padding: EdgeInsets.only(top: index == 0 ? 20 : 0, bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: isPrimary
                  ? Border.all(color: AppTheme.goldAccent.withOpacity(0.5), width: 2)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header Section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Bike Icon
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? [const Color(0xFF2D2D2D), const Color(0xFF1A1A1A)]
                                : [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.8)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.two_wheeler_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Bike Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    bike.displayName,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isPrimary) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppTheme.goldAccent.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'PRIMARY',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.darkGold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              bike.registrationNumber?.toUpperCase() ?? 'No Plate',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Arrow
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark 
                              ? Colors.white.withOpacity(0.05) 
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
                // Divider
                Divider(
                  height: 1,
                  color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.1),
                ),
                // Stats Row
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _StatItem(
                        icon: Icons.speed_rounded,
                        label: bike.bikeModel?.engineCapacity != null
                            ? '${bike.bikeModel!.engineCapacity}cc'
                            : 'N/A',
                        isDark: isDark,
                      ),
                      _buildDivider(isDark),
                      _StatItem(
                        icon: Icons.palette_outlined,
                        label: bike.color ?? 'N/A',
                        isDark: isDark,
                      ),
                      _buildDivider(isDark),
                      _StatItem(
                        icon: Icons.shield_outlined,
                        label: _getInsuranceStatus(bike),
                        isDark: isDark,
                        statusColor: _getInsuranceColor(bike),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      height: 24,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
    );
  }

  String _getInsuranceStatus(BikeModel bike) {
    if (bike.insuranceExpiry == null) return 'No Insurance';
    final now = DateTime.now();
    final diff = bike.insuranceExpiry!.difference(now).inDays;
    if (diff < 0) return 'Expired';
    if (diff < 30) return 'Expiring Soon';
    return 'Insured';
  }

  Color _getInsuranceColor(BikeModel bike) {
    if (bike.insuranceExpiry == null) return Colors.grey;
    final now = DateTime.now();
    final diff = bike.insuranceExpiry!.difference(now).inDays;
    if (diff < 0) return AppTheme.deepRed;
    if (diff < 30) return AppTheme.warningOrange;
    return AppTheme.successGreen;
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final Color? statusColor;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.isDark,
    this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = statusColor ?? (isDark ? Colors.grey[400] : Colors.grey[600]);
    
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
